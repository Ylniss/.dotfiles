export const meta = {
  name: 'exec-plan-run',
  description: 'Fazy planu: phase → finish → code-review → commit z weryfikacją każdego kroku, potem przy wielu fazach finish i code-review względem bazy',
}

const { plan, planTracked, phases, phaseModel, phaseEffort, reviewModel, reviewEffort, base, finish } = args
let verifiedHead = args.head
const MAX_ATTEMPTS = 2

const PHASE_AGENT = { model: phaseModel, effort: phaseEffort }
const REVIEW_AGENT = { model: reviewModel, effort: reviewEffort }
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
const TEST_COMMAND_PROPERTY = {
  testCommand: { type: 'string', description: 'Komenda build i testów; pusta, gdy repo ich nie ma' },
}
const PHASE_RESULT = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['done', 'blocked'] },
    blockReason: str,
    decisions: DECISIONS,
    ...TEST_COMMAND_PROPERTY,
  },
  required: ['status', 'decisions', 'testCommand'],
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
    ...TEST_COMMAND_PROPERTY,
  },
  required: ['findings', 'decisions', 'testCommand'],
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
    warnings: { type: 'array', items: str, description: 'Punkty, których nie dało się sprawdzić przez środowisko, z powodem' },
  },
  required: ['gaps', 'warnings'],
}

const PHASE_SCOPE = { reviewTarget: '', diffCommand: 'git diff HEAD', desc: 'niezacommitowane zmiany i nowe nieśledzone pliki' }
const BASE_SCOPE = {
  reviewTarget: `wszystkie zmiany na obecnym branchu względem brancha ${base}`,
  diffCommand: `git diff $(git merge-base ${base} HEAD)`,
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
  const result = await agent(prompt, { ...opts, label, phase: where })
  if (!result) throw new Stop(where, step, [`brak wyniku: ${label}`])
  return result
}

const fixPrompt = (prompt, retry) =>
  `Ten krok nie przeszedł weryfikacji. Drzewo zawiera już zmiany poprzedniej próby — nie zaczynaj od nowa, usuń tylko braki:\n` +
  `${retry.gaps.map(g => `- ${g}`).join('\n')}\n\n` +
  `Wynik poprzedniej próby:\n${JSON.stringify(retry.previous)}\n\n` +
  `Zwróć pełny zaktualizowany wynik: poprzednie pozycje plus poprawki.\n\nPierwotne zadanie kroku:\n${prompt}`

const NO_TESTS = 'Nie uruchamiaj build ani testów, nawet jeśli reguły lub skill tak każą — zrobi to weryfikator. W testCommand podaj tylko komendę.'

const testsCheck = r =>
  r.testCommand
    ? `Uruchom \`${r.testCommand}\` — build i testy muszą przejść. Przy błędzie podaj nieprzechodzące testy i kluczowy fragment komunikatu.`
    : 'Wykonawca twierdzi, że repo nie ma build ani testów. Sprawdź to w CLAUDE.md, AGENTS.md i konfiguracji repo.'

const checkPrompt = points =>
  'Weryfikacja faktów. Nie zmieniaj żadnych plików i niczego nie naprawiaj. Każdy niespełniony punkt zgłoś jako osobną pozycję gaps. ' +
  'Punkt, którego nie da się sprawdzić z powodu środowiska (brak narzędzia, usługi lub demona), zgłoś w warnings, nie w gaps.\n' +
  points.map((p, i) => `${i + 1}. ${p}`).join('\n')

async function runVerified(where, step, opts, prompt, schema, pointsFor) {
  let retry = null
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const result = await runAgent(where, step, step, retry ? fixPrompt(prompt, retry) : prompt, { ...opts, schema })
    if (result.status === 'blocked') throw new Stop(where, step, [`faza zablokowana: ${result.blockReason}`])

    const points = pointsFor(result)
    if (!points.length) {
      checklist.push({ where, step, attempt, gaps: [], warnings: [] })
      return result
    }

    const check = await runAgent(where, step, `weryfikacja ${step}`, checkPrompt(points), { ...LIGHT_AGENT, schema: CHECK_RESULT })
    checklist.push({ where, step, attempt, gaps: check.gaps, warnings: check.warnings })
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

async function runFinish(where, scope) {
  const result = await workflow('finish-run', { finish, scope, reviewAgent: REVIEW_AGENT, where })
  checklist.push(...result.checklist)
  decisions.push(...result.decisions)
  skipped.push(...result.skipped)
  if (result.stop) throw new Stop(result.stop.where, result.stop.step, result.stop.gaps)
}

async function runCodeReview(where, scope) {
  const result = await runVerified(
    where,
    'code-review',
    REVIEW_AGENT,
    `Wywołaj skill code-review z argumentami "${reviewEffort} --fix${scope.reviewTarget ? ` ${scope.reviewTarget}` : ''}" (zakres: ${scope.desc}). ` +
      `${NO_TESTS} Nie pytaj użytkownika. Jeśli skill zwróci wynik bez listy znalezisk (np. komunikat o czekaniu na testy), nie wywołuj go ponownie — przejrzyj ten sam zakres sam. W findings podaj każde znalezisko: fixed, gdy naprawione, rejected z powodem, gdy nie.`,
    CODE_REVIEW_RESULT,
    // Nothing fixed means nothing changed, so there is nothing to verify or test.
    r => {
      const fixed = r.findings.filter(f => f.outcome === 'fixed')
      if (!fixed.length) return []

      return [
        `Każde znalezisko fixed jest naprawione w \`${scope.diffCommand}\` w podanym pliku blisko podanej linii: ${JSON.stringify(fixed)}`,
        testsCheck(r),
      ]
    },
  )
  keepDecisions(where, 'code-review', result)
  rejected.push(...result.findings.filter(f => f.outcome === 'rejected').map(f => ({ where, ...f })))
}

// Pinned to the last verified HEAD so only one fresh commit on top of it passes.
async function runCommit(where, withPlan) {
  const result = await runVerified(
    where,
    'commit',
    LIGHT_AGENT,
    'Zacommituj wszystkie zmiany: `git add -A`, potem `git commit` z jedną krótką linią opisującą, co zmieniono w kodzie. ' +
      'Bez nazwy planu, sluga i numeru fazy. Jeśli drzewo jest czyste, nie commituj i zwróć committed: false. ' +
      'Jeśli ostatnie commity w `git log --oneline -10` mają prefiks ticketu (np. `WELLMIFY-1234 - `), poprzedź wiadomość takim prefiksem z numerem z nazwy bieżącego brancha. ' +
      'Zwróć sha HEAD po kroku i wiadomość.',
    COMMIT_RESULT,
    r => [
      '`git status --porcelain` jest pusty.',
      ...(r.committed
        ? [
            `HEAD to ${r.sha}, a \`git rev-parse HEAD~1\` to ${verifiedHead}.`,
            `Wiadomość ostatniego commita to jedna krótka linia: "${r.message}".`,
          ]
        : [`HEAD to ${verifiedHead}.`]),
      ...(withPlan ? [`Ostatni commit zawiera zmianę ${plan}.`] : []),
    ],
  )
  verifiedHead = result.sha
}

let stop = null
try {
  for (const { n, name } of phases) {
    const where = `F${n} · ${name}`
    phase(where)
    log(`Faza ${n}: ${name}`)
    await runPhase(where, n)
    await runFinish(where, PHASE_SCOPE)
    await runCodeReview(where, PHASE_SCOPE)
    await runCommit(where, planTracked)
  }

  // A single phase was already reviewed against the same changes.
  if (phases.length > 1) {
    const where = `Końcowy (${base})`
    phase(where)
    await runFinish(where, BASE_SCOPE)
    await runCodeReview(where, BASE_SCOPE)
    await runCommit(where, false)
  }
} catch (err) {
  if (!(err instanceof Stop)) throw err
  stop = err.stop
}
return { stop, checklist, decisions, skipped, rejected }
