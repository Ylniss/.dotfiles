export const meta = {
  name: 'exec-plan-run',
  description: 'Fazy planu: phase → finish etapów eachPhase → commit z weryfikacją i naprawą każdego kroku, potem finish, code-review i commit względem bazy',
}

const { plan, planTracked, phases, multiPhase, finalFrom = 'finish', phaseModel, phaseEffort, reviewModel, reviewEffort, base, finish } = args
let verifiedHead = args.head
const MAX_REPAIRS = 3

const PHASE_AGENT = { model: phaseModel, effort: phaseEffort }
const REVIEW_AGENT = { model: reviewModel, effort: reviewEffort }
const LIGHT_AGENT = { model: 'sonnet', effort: 'low' }
const COMMIT_AGENT = { model: 'haiku', effort: 'low' }

const str = { type: 'string' }
const PHASE_RESULT = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['done', 'blocked'] },
    blockReason: str,
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
  required: ['status', 'decisions', 'testCommand'],
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
    blocked: { type: 'array', items: str, description: 'Build lub testy, których nie dało się uruchomić przez środowisko, z powodem' },
  },
  required: ['gaps', 'warnings', 'blocked'],
}
const REPAIR_REPORT = {
  type: 'object',
  properties: {
    cause: { type: 'string', description: 'Przyczyna każdej pozycji, ustalona przed zmianami' },
    fixed: { type: 'array', items: str, description: 'Co naprawa zmieniła: pliki, zamknięte procesy, ustawienia' },
    falseAlarms: { type: 'array', items: str, description: 'Pozycje, które są fałszywym alarmem weryfikatora, każda z dowodem' },
    unresolved: { type: 'array', items: str, description: 'Czego nie dało się naprawić i dlaczego' },
  },
  required: ['cause', 'fixed', 'falseAlarms', 'unresolved'],
}

const withRepair = schema => ({
  ...schema,
  properties: { ...schema.properties, repair: REPAIR_REPORT },
  required: [...schema.required, 'repair'],
})

const PHASE_SCOPE = { diffCommand: 'git diff HEAD', desc: 'niezacommitowane zmiany i nowe nieśledzone pliki' }
const BASE_SCOPE = {
  diffCommand: `git diff $(git merge-base ${base} HEAD)`,
  desc: `zmiany od merge-base z ${base}, łącznie z niezacommitowanymi`,
}

const PHASE_FINISH = { ...finish, stages: finish.stages.filter(s => s.eachPhase) }
// A single phase already went through its eachPhase stages on the same changes.
const FINAL_FINISH = multiPhase ? finish : { ...finish, stages: finish.stages.filter(s => !s.eachPhase) }

const checklist = []
const decisions = []
const skipped = []
const rejected = []
const repairs = []

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

const LOCKING_PROCESS =
  'Gdy build pada, bo plik wyjściowy trzyma działający proces (komunikat podaje nazwę i PID), sprawdź, czym ten proces jest. ' +
  'Program uruchomiony tylko do sprawdzenia, np. gra lub aplikacja z tego repo, zamknij i powtórz komendę: narzędziem serwera MCP, który go uruchomił (np. `close`), ' +
  'a gdy takiego nie ma, zamknij sam proces. Zamknięcie procesu nie jest zmianą plików. ' +
  'Procesu, z którego korzysta sesja Claude Code, nie zamykaj: serwer MCP (także zbudowany z tego repo, patrz .mcp.json), IDE, serwer języka.'

const LOCKED_OUTPUT =
  `${LOCKING_PROCESS} Wtedy zbuduj i przetestuj bez zablokowanego projektu, a pominięty projekt zgłoś w warnings. ` +
  'Do blocked trafia to tylko, gdy zablokowany projekt sam zawiera zmiany albo bez niego nie da się zbudować reszty.'

const repairPrompt = (task, previous, check) =>
  'Weryfikacja kroku nie przeszła. Jesteś agentem naprawczym. Drzewo zawiera już zmiany kroku, więc nie zaczynaj od nowa.\n' +
  'Przy każdej pozycji najpierw ustal przyczynę: kod, środowisko czy fałszywy alarm weryfikatora. Potem usuń przyczynę. ' +
  'Nie wyłączaj, nie pomijaj i nie osłabiaj testów ani nie zmieniaj zakresu kroku. ' +
  'Build i testy uruchamiaj, żeby zbadać problem i sprawdzić naprawę, także gdy zadanie kroku tego zabrania. ' +
  `Fałszywy alarm zostaw bez zmian i podaj dowód w repair.falseAlarms. ${LOCKING_PROCESS}\n\n` +
  `Braki:\n${check.gaps.map(g => `- ${g}`).join('\n') || '- brak'}\n` +
  `Blokady środowiska:\n${check.blocked.map(b => `- ${b}`).join('\n') || '- brak'}\n\n` +
  `Wynik kroku:\n${JSON.stringify(previous)}\n\n` +
  'Zwróć pełny zaktualizowany wynik kroku (poprzednie pozycje plus zmiany z naprawy) i raport naprawy w repair.\n\n' +
  `Zadanie kroku:\n${task}`

const testsCheck = r =>
  r.testCommand
    ? `Uruchom \`${r.testCommand}\` — build i testy muszą przejść. Przy błędzie podaj nieprzechodzące testy i kluczowy fragment komunikatu. ${LOCKED_OUTPUT}`
    : 'Wykonawca twierdzi, że repo nie ma build ani testów. Sprawdź to w CLAUDE.md, AGENTS.md i konfiguracji repo.'

const checkPrompt = (points, repair) =>
  'Weryfikacja faktów. Nie zmieniaj żadnych plików i niczego nie naprawiaj. Każdy niespełniony punkt zgłoś jako osobną pozycję gaps. ' +
  'Build albo testy, których nie da się uruchomić z powodu środowiska (np. brak Dockera dla testów integracyjnych), zgłoś w blocked, nie w warnings: bez nich zmian nie uznajemy za sprawdzone. ' +
  'Testy, których nie uruchomiono, bo build pada przez kod, to gap, nie blocked. Demona Dockera sprawdzaj przez `docker info --format "{{.ServerVersion}}"`: wersja znaczy, że działa (początek pełnego `docker info` to tylko sekcja Client). ' +
  'Inny punkt, którego nie da się sprawdzić z powodu środowiska (brak narzędzia, usługi lub demona), zgłoś w warnings, nie w gaps.\n' +
  (repair
    ? `Przed tą weryfikacją agent naprawczy zgłosił: ${JSON.stringify(repair)}. Pozycję z falseAlarms uznaj za spełnioną tylko wtedy, gdy sam potwierdzisz jej dowód.\n`
    : '') +
  points.map((p, i) => `${i + 1}. ${p}`).join('\n')

async function runVerified(where, step, { executor, checker, repairer }, prompt, schema, pointsFor) {
  let result = await runAgent(where, step, step, prompt, { ...executor, schema })
  if (result.status === 'blocked') throw new Stop(where, step, [`faza zablokowana: ${result.blockReason}`])

  let repair = null
  for (let round = 1; ; round++) {
    const points = pointsFor(result)
    if (!points.length) {
      checklist.push({ where, step, round, gaps: [], warnings: [] })
      return result
    }

    const check = await runAgent(where, step, `weryfikacja ${step}`, checkPrompt(points, repair), { ...checker, schema: CHECK_RESULT })
    checklist.push({ where, step, round, gaps: check.gaps, warnings: check.warnings })
    if (!check.gaps.length && !check.blocked.length) return result

    const failures = [...check.gaps, ...check.blocked.map(b => `środowisko: ${b}`)]
    if (round > MAX_REPAIRS) throw new Stop(where, step, failures)

    log(`${where}: ${step} → naprawa ${round}`)
    const { repair: report, ...repaired } = await runAgent(where, step, `naprawa ${step}`, repairPrompt(prompt, result, check), {
      ...repairer,
      schema: withRepair(schema),
    })
    result = repaired
    repair = report
    repairs.push({ where, step, round, ...report })
    // Nothing changed, so the next verification would fail the same way.
    if (!report.fixed.length && !report.falseAlarms.length) throw new Stop(where, step, [...failures, ...report.unresolved])
  }
}

async function runPhase(where, n) {
  const result = await runVerified(
    where,
    'phase',
    { executor: PHASE_AGENT, checker: LIGHT_AGENT, repairer: PHASE_AGENT },
    `Wywołaj skill phase z argumentami "${plan} ${n} auto". ` +
      'W decisions zwróć każdy wpis ⚠ dopisany w tej fazie do Decisions log planu.',
    PHASE_RESULT,
    r => [
      'git status pokazuje zmiany w drzewie roboczym.',
      `W ${plan} faza ${n} ma znacznik [x] w nagłówku w Phase detail i na liście Phases.`,
      testsCheck(r),
    ],
  )
  decisions.push(...result.decisions.map(d => ({ where, step: 'phase', ...d })))
}

// A sub-workflow loads by name at call time, so a mid-run edit can break it; a Stop keeps the result.
async function runWorkflow(where, step, name, workflowArgs) {
  try {
    return await workflow(name, workflowArgs)
  } catch (err) {
    throw new Stop(where, step, [`błąd ${name}: ${err}`])
  }
}

async function runFinish(where, config, scope) {
  const result = await runWorkflow(where, 'finish', 'finish-run', { finish: config, scope, reviewAgent: REVIEW_AGENT, where })
  checklist.push(...result.checklist)
  decisions.push(...result.decisions)
  skipped.push(...result.skipped)
  repairs.push(...result.repairs)
  if (result.stop) throw new Stop(result.stop.where, result.stop.step, result.stop.gaps)
}

async function runCodeReview(where) {
  const result = await runWorkflow(where, 'code-review', 'code-review-run', { scope: BASE_SCOPE, reviewAgent: REVIEW_AGENT, where })
  checklist.push(...result.checklist)
  decisions.push(...result.decisions)
  rejected.push(...result.rejected)
  repairs.push(...result.repairs)
  if (result.stop) throw new Stop(result.stop.where, result.stop.step, result.stop.gaps)
}

// Pinned to the last verified HEAD so only one fresh commit on top of it passes.
async function runCommit(where, withPlan) {
  const result = await runVerified(
    where,
    'commit',
    { executor: COMMIT_AGENT, checker: COMMIT_AGENT, repairer: REVIEW_AGENT },
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

const PHASE_STEPS = ['phase', 'finish', 'commit']
const FINAL_STEPS = ['finish', 'code-review', 'commit']

let stop = null
try {
  // `from` and `finalFrom` resume where a previous run stopped.
  for (const { n, name, from = 'phase' } of phases) {
    const where = `F${n} · ${name}`
    phase(where)
    log(`Faza ${n}: ${name}${from === 'phase' ? '' : ` (od ${from})`}`)
    const start = PHASE_STEPS.indexOf(from)
    if (start <= 0) await runPhase(where, n)
    if (start <= 1) await runFinish(where, PHASE_FINISH, PHASE_SCOPE)
    await runCommit(where, planTracked)
  }

  const where = `Końcowy (${base})`
  phase(where)
  const start = FINAL_STEPS.indexOf(finalFrom)
  if (start <= 0) await runFinish(where, FINAL_FINISH, BASE_SCOPE)
  if (start <= 1) await runCodeReview(where)
  await runCommit(where, false)
} catch (err) {
  if (!(err instanceof Stop)) throw err
  stop = err.stop
}
return { stop, checklist, decisions, skipped, rejected, repairs }
