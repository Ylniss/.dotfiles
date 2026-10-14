export const meta = {
  name: 'finish-run',
  description: 'Skille przeglądu z finish.json po kolei: podział, równoległe analizy, zastosowanie ✓ z weryfikacją',
}

const { finish, scope, reviewAgent, where } = args
const MAX_ATTEMPTS = 2

const SPLIT_AGENT = { model: 'sonnet', effort: 'medium' }
const LIGHT_AGENT = { model: 'sonnet', effort: 'low' }

const str = { type: 'string' }
const APPLY_RESULT = {
  type: 'object',
  properties: {
    applied: {
      type: 'array',
      items: {
        type: 'object',
        properties: { finding: str, file: str, line: { type: 'integer' } },
        required: ['finding', 'file', 'line'],
      },
    },
    skipped: {
      type: 'array',
      items: {
        type: 'object',
        properties: { finding: str, reason: str, worthUserDecision: { type: 'boolean' } },
        required: ['finding', 'reason', 'worthUserDecision'],
      },
    },
    decisions: {
      type: 'array',
      description: 'Decyzje podjęte bez użytkownika, które mógłby rozstrzygnąć inaczej',
      items: {
        type: 'object',
        properties: { decision: str, why: str, alternative: str },
        required: ['decision', 'why', 'alternative'],
      },
    },
    testCommand: { type: 'string', description: 'Komenda build i testów; pusta, gdy repo ich nie ma' },
  },
  required: ['applied', 'skipped', 'decisions', 'testCommand'],
}
const SPLIT_RESULT = {
  type: 'object',
  properties: {
    tasks: {
      type: 'array',
      minItems: 2,
      items: {
        type: 'object',
        properties: { focus: str, files: { type: 'array', items: str } },
        required: ['focus', 'files'],
      },
    },
  },
  required: ['tasks'],
}
const CHECK_RESULT = {
  type: 'object',
  properties: {
    gaps: { type: 'array', items: str, description: 'Każdy niespełniony punkt jako osobna pozycja; pusta, gdy wszystko się zgadza' },
    warnings: { type: 'array', items: str, description: 'Punkty, których nie dało się sprawdzić przez środowisko, z powodem' },
    blocked: { type: 'array', items: str, description: 'Build lub testy, których nie dało się uruchomić przez środowisko, z powodem' },
  },
  required: ['gaps', 'warnings', 'blocked'],
}

const checklist = []
const decisions = []
const applied = []
const skipped = []

class Stop extends Error {
  constructor(step, gaps) {
    super(`${where} / ${step}`)
    this.stop = { where, step, gaps }
  }
}

async function runAgent(step, label, prompt, opts) {
  const result = await agent(prompt, { ...opts, label, phase: where })
  if (!result) throw new Stop(step, [`brak wyniku: ${label}`])
  return result
}

const NO_TESTS = 'Nie uruchamiaj build ani testów, nawet jeśli reguły lub skill tak każą — zrobi to weryfikator. W testCommand podaj tylko komendę.'

const fixPrompt = (prompt, retry) =>
  `Ten krok nie przeszedł weryfikacji. Drzewo zawiera już zmiany poprzedniej próby — nie zaczynaj od nowa, usuń tylko braki:\n` +
  `${retry.gaps.map(g => `- ${g}`).join('\n')}\n\n` +
  `Wynik poprzedniej próby:\n${JSON.stringify(retry.previous)}\n\n` +
  `Zwróć pełny zaktualizowany wynik: poprzednie pozycje plus poprawki.\n\nPierwotne zadanie kroku:\n${prompt}`

const LOCKED_OUTPUT =
  'Gdy build pada, bo plik wyjściowy trzyma działający proces (komunikat podaje nazwę i PID), sprawdź, czym ten proces jest. ' +
  'Program uruchomiony tylko do ręcznego sprawdzenia, np. gra lub aplikacja z tego repo, zamknij i powtórz komendę; zamknięcie procesu nie jest zmianą plików. ' +
  'Procesu, z którego korzysta sesja Claude Code, nie zamykaj: serwer MCP (także zbudowany z tego repo, patrz .mcp.json), IDE, serwer języka. ' +
  'Wtedy zbuduj i przetestuj bez zablokowanego projektu, a pominięty projekt zgłoś w warnings. ' +
  'Do blocked trafia to tylko, gdy zablokowany projekt sam zawiera zmiany albo bez niego nie da się zbudować reszty.'

const testsCheck = r =>
  r.testCommand
    ? `Uruchom \`${r.testCommand}\` — build i testy muszą przejść. Przy błędzie podaj nieprzechodzące testy i kluczowy fragment komunikatu. ${LOCKED_OUTPUT}`
    : 'Wykonawca twierdzi, że repo nie ma build ani testów. Sprawdź to w CLAUDE.md, AGENTS.md i konfiguracji repo.'

const checkPrompt = points =>
  'Weryfikacja faktów. Nie zmieniaj żadnych plików i niczego nie naprawiaj. Każdy niespełniony punkt zgłoś jako osobną pozycję gaps. ' +
  'Build albo testy, których nie da się uruchomić z powodu środowiska (np. brak Dockera dla testów integracyjnych), zgłoś w blocked, nie w warnings: bez nich zmian nie uznajemy za sprawdzone. ' +
  'Inny punkt, którego nie da się sprawdzić z powodu środowiska (brak narzędzia, usługi lub demona), zgłoś w warnings, nie w gaps.\n' +
  points.map((p, i) => `${i + 1}. ${p}`).join('\n')

async function runVerified(step, prompt, pointsFor) {
  let retry = null
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const result = await runAgent(step, step, retry ? fixPrompt(prompt, retry) : prompt, { ...reviewAgent, schema: APPLY_RESULT })
    const points = pointsFor(result)
    if (!points.length) {
      checklist.push({ where, step, attempt, gaps: [], warnings: [] })
      return result
    }

    const check = await runAgent(step, `weryfikacja ${step}`, checkPrompt(points), { ...LIGHT_AGENT, schema: CHECK_RESULT })
    checklist.push({ where, step, attempt, gaps: check.gaps, warnings: check.warnings })
    // a retry cannot fix the environment
    if (check.blocked.length) throw new Stop(step, check.blocked.map(b => `środowisko: ${b}`))
    if (!check.gaps.length) return result
    retry = { gaps: check.gaps, previous: result }
  }
  throw new Stop(step, retry.gaps)
}

const splitPrompt = skill =>
  `Zaplanuj podział analizy skilla /${skill} na co najmniej 2 zadania dla równoległych analizatorów. ` +
  `Przeczytaj ~/.claude/skills/${skill}/SKILL.md i zakres "${scope.desc}" ` +
  `(pliki z \`${scope.diffCommand} --name-only\` i \`git ls-files --others --exclude-standard\`). ` +
  'Dziel po plikach, po kategoriach skilla albo po obu, tak by zadania się nie dublowały, a razem pokrywały cały zakres ' +
  'i wszystkie kategorie skilla. Niczego nie analizuj i nie zmieniaj.'

const analyzePrompt = (skill, task) =>
  `Uruchom analizę skilla /${skill} dla zakresu "${scope.desc}", ograniczoną do kąta: ${task.focus}\n` +
  `Pliki:\n${task.files.join('\n')}\n` +
  'Tylko raport w formacie skilla — niczego nie stosuj i nie pytaj użytkownika. Zwróć pełny tekst raportu.'

const applyPrompt = (skill, reports) =>
  `Poniżej raporty analizatorów skilla /${skill} dla zakresu "${scope.desc}". Scal je: przenumeruj w jedną listę, ` +
  'odrzuć duplikaty i przepuść scaloną listę przez sekcję Konflikty z ~/.claude/skills/_shared/report.md. Potem zastosuj. ' +
  `${finish.rules} ${NO_TESTS} Nie pytaj użytkownika. ` +
  'W applied podaj każdy zastosowany wynik z plikiem i linią zmiany, w skipped każdy pominięty z powodem.\n\n' +
  reports.map((r, i) => `=== Analizator ${i + 1} ===\n${r}`).join('\n\n')

// Workflow agents cannot spawn subagents, so the script fans each skill's analysis out itself.
async function runSkill(skill) {
  const step = `/${skill}`
  const split = await runAgent(step, `${step} podział`, splitPrompt(skill), { ...SPLIT_AGENT, schema: SPLIT_RESULT })

  log(`${where}: ${step} → ${split.tasks.length} analizatorów`)
  const reports = await parallel(
    split.tasks.map((task, i) => () => agent(analyzePrompt(skill, task), { ...reviewAgent, label: `${step} analiza ${i + 1}`, phase: where })),
  )
  if (reports.some(r => !r)) throw new Stop(step, ['analizator nie zwrócił raportu'])

  // Nothing applied means nothing changed, so there is nothing to verify or test.
  const result = await runVerified(step, applyPrompt(skill, reports), r =>
    r.applied.length
      ? [
          `Każda pozycja applied jest widoczna w \`${scope.diffCommand}\` (lub w nieśledzonym pliku) w podanym pliku blisko podanej linii: ${JSON.stringify(r.applied)}`,
          testsCheck(r),
        ]
      : [],
  )
  decisions.push(...result.decisions.map(d => ({ where, step, ...d })))
  applied.push(...result.applied.map(a => ({ skill, ...a })))
  skipped.push(...result.skipped.filter(s => s.worthUserDecision).map(s => ({ where, skill, ...s })))
}

let stop = null
try {
  for (const skill of finish.skills) await runSkill(skill)
} catch (err) {
  if (!(err instanceof Stop)) throw err
  stop = err.stop
}
return { stop, checklist, decisions, applied, skipped }
