export const meta = {
  name: 'finish-run',
  description: 'Etapy skilli przeglądu z finish.json po kolei: równoległe analizy skilli etapu, scalenie i równoległe zastosowanie ✓ po rozłącznych plikach z weryfikacją',
}

const { finish, scope, reviewAgent, where } = args
const MAX_ATTEMPTS = 2
const FINDINGS_PER_APPLIER = 6

const SPLIT_AGENT = { model: 'sonnet', effort: 'medium' }
const LIGHT_AGENT = { model: 'sonnet', effort: 'low' }

const str = { type: 'string' }
const SKIPPED = {
  type: 'array',
  items: {
    type: 'object',
    properties: { skill: str, finding: str, reason: str, worthUserDecision: { type: 'boolean' } },
    required: ['skill', 'finding', 'reason', 'worthUserDecision'],
  },
}
const DECISIONS = {
  type: 'array',
  description: 'Decyzje podjęte bez użytkownika, które mógłby rozstrzygnąć inaczej',
  items: {
    type: 'object',
    properties: { decision: str, why: str, alternative: str },
    required: ['decision', 'why', 'alternative'],
  },
}
const MERGE_RESULT = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: { skill: str, text: str, files: { type: 'array', minItems: 1, items: str } },
        required: ['skill', 'text', 'files'],
      },
    },
    skipped: SKIPPED,
    decisions: DECISIONS,
  },
  required: ['findings', 'skipped', 'decisions'],
}
const APPLY_RESULT = {
  type: 'object',
  properties: {
    applied: {
      type: 'array',
      items: {
        type: 'object',
        properties: { skill: str, finding: str, file: str, line: { type: 'integer' } },
        required: ['skill', 'finding', 'file', 'line'],
      },
    },
    skipped: SKIPPED,
    decisions: DECISIONS,
    testCommand: { type: 'string', description: 'Komenda build i testów; pusta, gdy repo ich nie ma' },
  },
  required: ['applied', 'skipped', 'decisions', 'testCommand'],
}
const PARALLEL_APPLY_RESULT = {
  type: 'object',
  properties: {
    ...APPLY_RESULT.properties,
    outside: {
      type: 'array',
      items: { type: 'integer', minimum: 1 },
      description: 'Numery wyników, które wymagają zmiany pliku spoza listy',
    },
  },
  required: [...APPLY_RESULT.required, 'outside'],
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

const fixPrompt = (prompt, gaps, previous) =>
  `Ten krok nie przeszedł weryfikacji. Drzewo zawiera już zmiany poprzedniej próby — nie zaczynaj od nowa, usuń tylko braki:\n` +
  `${gaps.map(g => `- ${g}`).join('\n')}\n\n` +
  `Wynik poprzedniej próby:\n${JSON.stringify(previous)}\n\n` +
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
  'Testy, których nie uruchomiono, bo build pada przez kod, to gap, nie blocked. Demona Dockera sprawdzaj przez `docker info --format "{{.ServerVersion}}"`: wersja znaczy, że działa (początek pełnego `docker info` to tylko sekcja Client). ' +
  'Inny punkt, którego nie da się sprawdzić z powodu środowiska (brak narzędzia, usługi lub demona), zgłoś w warnings, nie w gaps.\n' +
  points.map((p, i) => `${i + 1}. ${p}`).join('\n')

async function verifyAndFix(step, applyAgent, firstResult, prompt, pointsFor) {
  let result = firstResult
  for (let attempt = 1; ; attempt++) {
    const points = pointsFor(result)
    if (!points.length) {
      checklist.push({ where, step, attempt, gaps: [], warnings: [] })
      return result
    }

    const check = await runAgent(step, `weryfikacja ${step}`, checkPrompt(points), { ...LIGHT_AGENT, schema: CHECK_RESULT })
    checklist.push({ where, step, attempt, gaps: check.gaps, warnings: check.warnings })
    // a retry cannot fix the environment, but a gap such as a build broken by the code can be what blocked the tests
    if (check.blocked.length && !check.gaps.length) throw new Stop(step, check.blocked.map(b => `środowisko: ${b}`))
    if (!check.gaps.length) return result
    if (attempt === MAX_ATTEMPTS) throw new Stop(step, check.gaps)
    result = await runAgent(step, `${step} poprawka`, fixPrompt(prompt, check.gaps, result), { ...applyAgent, schema: APPLY_RESULT })
  }
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

const mergePrompt = (step, analyses) =>
  `Poniżej raporty analizatorów ${step} dla zakresu "${scope.desc}". Scal je: odrzuć duplikaty i przepuść scaloną listę ` +
  `przez sekcję Konflikty z ~/.claude/skills/_shared/report.md. Potem wybierz wyniki do zastosowania według reguły: ${finish.rules} ` +
  'Niczego nie zmieniaj i nie pytaj użytkownika. ' +
  'W findings podaj każdy wybrany wynik ze skillem bez /, pełną treścią z raportu (nagłówek, pola, blok diff) ' +
  'i wszystkimi plikami, które zmienia, ze ścieżkami od korzenia repo. Zmiana nazwy lub przeniesienie kodu zmienia też pliki z użyciami — ' +
  'znajdź je w repo, bo po plikach wyniki trafiają do równoległych agentów stosujących. ' +
  'W skipped podaj każdy niewybrany wynik ze skillem bez / i powodem.\n\n' +
  analyses.flatMap(({ skill, reports }) => reports.map((r, i) => `=== /${skill} · analizator ${i + 1} ===\n${r}`)).join('\n\n')

const applyPrompt = (findings, files) =>
  `Zastosuj poniższe wyniki przeglądu dla zakresu "${scope.desc}". ${NO_TESTS} Nie pytaj użytkownika. ` +
  (files
    ? `Zmieniaj tylko pliki: ${files.join(', ')} — inne pliki zmieniają w tym czasie równolegli agenci. ` +
      'Wynik, który wymaga zmiany innego pliku, zostaw w całości niezastosowany i podaj tylko jego numer w outside, bez wpisu w skipped. '
    : '') +
  'W applied podaj każdy zastosowany wynik ze skillem bez /, plikiem i linią zmiany, w skipped każdy pominięty ze skillem bez / i powodem.\n\n' +
  findings.map((f, i) => `=== ${i + 1} · /${f.skill} ===\n${f.text}`).join('\n\n')

// Lowercasing may wrongly join two files; that only costs parallelism.
const fileKey = path => path.replace(/\\/g, '/').replace(/^\.\//, '').toLowerCase()

// Parallel appliers must not edit the same file, so findings sharing a file stay in one task.
function splitByFiles(findings) {
  let groups = []
  for (const finding of findings) {
    const keys = finding.files.map(fileKey)
    const touching = groups.filter(g => keys.some(k => g.keys.has(k)))
    groups = groups.filter(g => !touching.includes(g))
    groups.push({
      keys: new Set([...keys, ...touching.flatMap(g => [...g.keys])]),
      findings: [...touching.flatMap(g => g.findings), finding],
    })
  }

  const tasks = Array.from({ length: Math.min(groups.length, Math.ceil(findings.length / FINDINGS_PER_APPLIER)) }, () => [])
  for (const group of groups.sort((a, b) => b.findings.length - a.findings.length)) {
    tasks.reduce((min, t) => (t.length < min.length ? t : min)).push(...group.findings)
  }
  return tasks
}

async function applyFindings(step, applyAgent, findings) {
  const tasks = splitByFiles(findings)
  log(`${where}: ${step} → agenci stosujący: ${tasks.length}`)
  // A lone applier collides with no one, so the file limit would only push findings out to a second agent.
  if (tasks.length === 1) return runAgent(step, `${step} zastosowanie`, applyPrompt(findings), { ...applyAgent, schema: APPLY_RESULT })

  const results = await parallel(
    tasks.map((task, i) => () =>
      agent(applyPrompt(task, [...new Set(task.flatMap(f => f.files))]), {
        ...applyAgent,
        schema: PARALLEL_APPLY_RESULT,
        label: `${step} zastosowanie ${i + 1}`,
        phase: where,
      }),
    ),
  )
  if (results.some(r => !r)) throw new Stop(step, ['agent stosujący nie zwrócił wyniku'])

  const outside = results.flatMap((r, i) => r.outside.map(n => tasks[i][n - 1]))
  if (outside.length) results.push(await runAgent(step, `${step} poza grupami`, applyPrompt(outside), { ...applyAgent, schema: APPLY_RESULT }))

  return {
    applied: results.flatMap(r => r.applied),
    skipped: results.flatMap(r => r.skipped),
    decisions: results.flatMap(r => r.decisions),
    testCommand: results.map(r => r.testCommand).find(Boolean) ?? '',
  }
}

// Workflow agents cannot spawn subagents, so the script fans each skill's analysis out itself.
async function analyze(skill) {
  const step = `/${skill}`
  const split = await runAgent(step, `${step} podział`, splitPrompt(skill), { ...SPLIT_AGENT, schema: SPLIT_RESULT })

  log(`${where}: ${step} → ${split.tasks.length} analizatorów`)
  const reports = await parallel(
    split.tasks.map((task, i) => () => agent(analyzePrompt(skill, task), { ...reviewAgent, label: `${step} analiza ${i + 1}`, phase: where })),
  )
  if (reports.some(r => !r)) throw new Stop(step, ['analizator nie zwrócił raportu'])
  return { skill, reports }
}

async function runStage({ skills, applyModel }) {
  const step = skills.map(s => `/${s}`).join(' + ')
  // parallel() would turn a Stop into null and lose its gaps
  const settled = await Promise.allSettled(skills.map(analyze))
  const failed = settled.find(s => s.status === 'rejected')
  if (failed) throw failed.reason

  const applyAgent = applyModel ? { ...reviewAgent, model: applyModel } : reviewAgent
  const merged = await runAgent(step, `${step} scalenie`, mergePrompt(step, settled.map(s => s.value)), { ...applyAgent, schema: MERGE_RESULT })
  const firstResult = await applyFindings(step, applyAgent, merged.findings)
  const result = await verifyAndFix(step, applyAgent, firstResult, applyPrompt(merged.findings), r =>
    r.applied.length
      ? [
          `Każda pozycja applied jest widoczna w \`${scope.diffCommand}\` (lub w nieśledzonym pliku) w podanym pliku blisko podanej linii: ${JSON.stringify(r.applied)}`,
          testsCheck(r),
        ]
      : [],
  )
  decisions.push(...[...merged.decisions, ...result.decisions].map(d => ({ where, step, ...d })))
  applied.push(...result.applied)
  skipped.push(...[...merged.skipped, ...result.skipped].filter(s => s.worthUserDecision).map(s => ({ where, ...s })))
}

let stop = null
try {
  for (const stage of finish.stages) await runStage(stage)
} catch (err) {
  if (!(err instanceof Stop)) throw err
  stop = err.stop
}
return { stop, checklist, decisions, applied, skipped }
