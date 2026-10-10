export const meta = {
  name: 'exec-plan',
  description: 'Fazy planu: phase → finish → code-review → commit z weryfikacją każdego kroku, potem finish i code-review względem bazy',
}

const { plan, phases, phaseModel, phaseEffort, reviewModel, reviewEffort, base, finish } = args
const MAX_ATTEMPTS = 2

const PHASE_AGENT = { model: phaseModel, effort: phaseEffort }
const REVIEW_AGENT = { model: reviewModel, effort: reviewEffort }
const SPLIT_AGENT = { model: 'sonnet', effort: 'medium' }
const LIGHT_AGENT = { model: 'sonnet', effort: 'low' }

const str = { type: 'string' }
const DECISIONS = {
  type: 'array',
  description: 'Decyzje podjęte bez użytkownika, które mógłby rozstrzygnąć inaczej',
  items: {
    type: 'object',
    properties: { decision: str, why: str, alternative: str },
    required: ['decision', 'why', 'alternative'],
  },
}
const TEST_COMMAND = {
  testCommand: { type: 'string', description: 'Komenda build i testów; pusta, gdy repo ich nie ma' },
}
const PHASE_RESULT = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['done', 'blocked'] },
    blockReason: str,
    decisions: DECISIONS,
    ...TEST_COMMAND,
  },
  required: ['status', 'decisions', 'testCommand'],
}
const FINISH_RESULT = {
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
    decisions: DECISIONS,
    ...TEST_COMMAND,
  },
  required: ['applied', 'skipped', 'decisions', 'testCommand'],
}
const CODE_REVIEW_RESULT = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          summary: str,
          file: str,
          line: { type: 'integer' },
          outcome: { type: 'string', enum: ['fixed', 'rejected'] },
          reason: str,
        },
        required: ['summary', 'file', 'line', 'outcome', 'reason'],
      },
    },
    decisions: DECISIONS,
    ...TEST_COMMAND,
  },
  required: ['findings', 'decisions', 'testCommand'],
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
const COMMIT_RESULT = {
  type: 'object',
  properties: { committed: { type: 'boolean' }, sha: str, message: str },
  required: ['committed', 'sha', 'message'],
}
const CHECK_RESULT = {
  type: 'object',
  properties: {
    gaps: { type: 'array', items: str, description: 'Każdy niespełniony punkt jako osobna pozycja; pusta, gdy wszystko się zgadza' },
  },
  required: ['gaps'],
}

const PHASE_SCOPE = { reviewTarget: '', diff: 'git diff HEAD', desc: 'niezacommitowane zmiany i nowe nieśledzone pliki' }
const BASE_SCOPE = {
  reviewTarget: `wszystkie zmiany na obecnym branchu względem brancha ${base}`,
  diff: `git diff $(git merge-base ${base} HEAD)`,
  desc: `zmiany od merge-base z ${base}, łącznie z niezacommitowanymi`,
}

const checklist = []
const decisions = []
const skipped = []
const rejected = []

const keepDecisions = (where, step, result) => decisions.push(...result.decisions.map(d => ({ where, step, ...d })))

class Stop extends Error {
  constructor(where, step, gaps) {
    super(`${where} / ${step}`)
    this.stop = { where, step, gaps }
  }
}

async function runAgent(where, step, label, prompt, opts) {
  const result = await agent(prompt, { ...opts, label: `${where}: ${label}`, phase: where })
  if (!result) throw new Stop(where, step, [`brak wyniku: ${label}`])
  return result
}

const fixPrompt = (prompt, retry) =>
  `Ten krok nie przeszedł weryfikacji. Drzewo zawiera już zmiany poprzedniej próby — nie zaczynaj od nowa, usuń tylko braki:\n` +
  `${retry.gaps.map(g => `- ${g}`).join('\n')}\n\n` +
  `Wynik poprzedniej próby:\n${JSON.stringify(retry.previous)}\n\n` +
  `Zwróć pełny zaktualizowany wynik: poprzednie pozycje plus poprawki.\n\nPierwotne zadanie kroku:\n${prompt}`

const testsCheck = r =>
  r.testCommand
    ? `Uruchom \`${r.testCommand}\` — build i testy muszą przejść.`
    : 'Wykonawca twierdzi, że repo nie ma build ani testów. Sprawdź to w CLAUDE.md, AGENTS.md i konfiguracji repo.'

const checkPrompt = points =>
  'Weryfikacja faktów. Nie zmieniaj żadnych plików i niczego nie naprawiaj. Każdy niespełniony punkt zgłoś jako osobną pozycję gaps.\n' +
  points.map((p, i) => `${i + 1}. ${p}`).join('\n')

async function runVerified(where, step, opts, prompt, schema, pointsFor) {
  let retry = null
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const result = await runAgent(where, step, step, retry ? fixPrompt(prompt, retry) : prompt, { ...opts, schema })
    if (result.status === 'blocked') throw new Stop(where, step, [`faza zablokowana: ${result.blockReason}`])

    const check = await runAgent(where, step, `weryfikacja ${step}`, checkPrompt(pointsFor(result)), { ...LIGHT_AGENT, schema: CHECK_RESULT })
    checklist.push({ where, step, attempt, gaps: check.gaps })
    if (!check.gaps.length) return result
    retry = { gaps: check.gaps, previous: result }
  }
  throw new Stop(where, step, retry.gaps)
}

async function runPhase(where, n) {
  const result = await runVerified(
    where,
    'phase',
    PHASE_AGENT,
    `Wywołaj skill phase z argumentami "${plan} ${n} auto". ` +
      'W decisions zwróć każdy wpis ⚠ dopisany w tej fazie do Decisions log planu.',
    PHASE_RESULT,
    r => [
      'git status pokazuje zmiany w drzewie roboczym.',
      `W ${plan} faza ${n} ma znacznik [x] w nagłówku w Phase detail i na liście Phases.`,
      testsCheck(r),
    ],
  )
  keepDecisions(where, 'phase', result)
}

const splitPrompt = (skill, scope) =>
  `Zaplanuj podział analizy skilla /${skill} na co najmniej 2 zadania dla równoległych analizatorów. ` +
  `Przeczytaj ~/.claude/skills/${skill}/SKILL.md i zakres "${scope.desc}" ` +
  `(pliki z \`${scope.diff} --name-only\` i \`git ls-files --others --exclude-standard\`). ` +
  'Dziel po plikach, po kategoriach skilla albo po obu, tak by zadania się nie dublowały, a razem pokrywały cały zakres ' +
  'i wszystkie kategorie skilla. Niczego nie analizuj i nie zmieniaj.'

const analyzePrompt = (skill, scope, task) =>
  `Uruchom analizę skilla /${skill} dla zakresu "${scope.desc}", ograniczoną do kąta: ${task.focus}\n` +
  `Pliki:\n${task.files.join('\n')}\n` +
  'Tylko raport w formacie skilla — niczego nie stosuj i nie pytaj użytkownika. Zwróć pełny tekst raportu.'

const applyPrompt = (skill, scope, reports) =>
  `Poniżej raporty analizatorów skilla /${skill} dla zakresu "${scope.desc}". Scal je: przenumeruj w jedną listę, ` +
  'odrzuć duplikaty i przepuść scaloną listę przez sekcję Konflikty z ~/.claude/skills/_shared/report.md. Potem zastosuj. ' +
  `${finish.rules} Nie pytaj użytkownika. ` +
  'W applied podaj każdy zastosowany wynik z plikiem i linią zmiany, w skipped każdy pominięty z powodem.\n\n' +
  reports.map((r, i) => `=== Analizator ${i + 1} ===\n${r}`).join('\n\n')

// Workflow agents cannot spawn subagents, so the script fans each skill's analysis out itself.
async function runSkill(where, skill, scope) {
  const split = await runAgent(where, `/${skill}`, `/${skill} podział`, splitPrompt(skill, scope), { ...SPLIT_AGENT, schema: SPLIT_RESULT })

  log(`${where}: /${skill} → ${split.tasks.length} analizatorów`)
  const reports = await parallel(
    split.tasks.map((task, i) => () =>
      runAgent(where, `/${skill}`, `/${skill} analiza ${i + 1}`, analyzePrompt(skill, scope, task), REVIEW_AGENT),
    ),
  )
  if (reports.some(r => !r)) throw new Stop(where, `/${skill}`, ['analizator nie zwrócił raportu'])

  const result = await runVerified(
    where,
    `/${skill}`,
    REVIEW_AGENT,
    applyPrompt(skill, scope, reports),
    FINISH_RESULT,
    r => [
      `Każda pozycja applied jest widoczna w \`${scope.diff}\` (lub w nieśledzonym pliku) w podanym pliku blisko podanej linii: ${JSON.stringify(r.applied)}`,
      testsCheck(r),
    ],
  )
  keepDecisions(where, `/${skill}`, result)
  skipped.push(...result.skipped.filter(s => s.worthUserDecision).map(s => ({ where, skill, ...s })))
}

async function runFinish(where, scope) {
  for (const skill of finish.skills) await runSkill(where, skill, scope)
}

async function runCodeReview(where, scope) {
  const result = await runVerified(
    where,
    'code-review',
    REVIEW_AGENT,
    `Wywołaj skill code-review z argumentami "${reviewEffort} --fix${scope.reviewTarget ? ` ${scope.reviewTarget}` : ''}" (zakres: ${scope.desc}). ` +
      'Nie pytaj użytkownika. W findings podaj każde znalezisko: fixed, gdy naprawione, rejected z powodem, gdy nie.',
    CODE_REVIEW_RESULT,
    r => [
      `Każde znalezisko fixed jest naprawione w \`${scope.diff}\` w podanym pliku blisko podanej linii: ${JSON.stringify(r.findings.filter(f => f.outcome === 'fixed'))}`,
      testsCheck(r),
    ],
  )
  keepDecisions(where, 'code-review', result)
  rejected.push(...result.findings.filter(f => f.outcome === 'rejected').map(f => ({ where, ...f })))
}

const runCommit = (where, withPlan) =>
  runVerified(
    where,
    'commit',
    LIGHT_AGENT,
    'Zacommituj wszystkie zmiany: `git add -A`, potem `git commit` z jedną krótką linią opisującą, co zmieniono w kodzie. ' +
      'Bez nazwy planu, sluga i numeru fazy. Jeśli drzewo jest czyste, nie commituj i zwróć committed: false. ' +
      'Zwróć sha HEAD po kroku i wiadomość.',
    COMMIT_RESULT,
    r => [
      '`git status --porcelain` jest pusty.',
      `HEAD to ${r.sha}.`,
      ...(r.committed ? [`Wiadomość ostatniego commita to jedna krótka linia: "${r.message}".`] : []),
      ...(withPlan ? [`Ostatni commit zawiera zmianę ${plan}.`] : []),
    ],
  )

let stop = null
try {
  for (const { n, name } of phases) {
    const where = `Faza ${n}: ${name}`
    phase(where)
    await runPhase(where, n)
    await runFinish(where, PHASE_SCOPE)
    await runCodeReview(where, PHASE_SCOPE)
    await runCommit(where, true)
  }

  const where = `Etap końcowy względem ${base}`
  phase(where)
  await runFinish(where, BASE_SCOPE)
  await runCodeReview(where, BASE_SCOPE)
  await runCommit(where, false)
} catch (err) {
  if (!(err instanceof Stop)) throw err
  stop = err.stop
}
return { completed: !stop, stop, checklist, decisions, skipped, rejected }
