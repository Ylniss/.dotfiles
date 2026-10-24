export const meta = {
  name: 'code-review-run',
  description: 'Code-review zakresu: jeden przegląd, potem obalanie i naprawa znalezisk z weryfikacją',
}

const { scope, reviewAgent, where } = args
const MAX_REPAIRS = 3

const LIGHT_AGENT = { model: 'sonnet', effort: 'low' }

const str = { type: 'string' }
const FINDING = {
  type: 'object',
  properties: {
    summary: str,
    file: str,
    line: { type: 'integer' },
    failureScenario: { type: 'string', description: 'Konkretne wejście lub stan → zły wynik lub błąd' },
  },
  required: ['summary', 'file', 'line', 'failureScenario'],
}
const REVIEW_RESULT = {
  type: 'object',
  properties: { findings: { type: 'array', items: FINDING } },
  required: ['findings'],
}
const APPLY_RESULT = {
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
  required: ['findings', 'decisions', 'testCommand'],
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

const step = 'code-review'
const checklist = []
const rejected = []
const repairs = []

class Stop extends Error {
  constructor(gaps) {
    super(`${where} / ${step}`)
    this.stop = { where, step, gaps }
  }
}

async function runAgent(label, prompt, opts) {
  const result = await agent(prompt, { ...opts, label, phase: where })
  if (!result) throw new Stop([`brak wyniku: ${label}`])
  return result
}

const NO_TESTS = 'Nie uruchamiaj build ani testów, nawet jeśli reguły lub skill tak każą — zrobi to weryfikator. W testCommand podaj tylko komendę.'

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

async function runVerified(prompt, pointsFor) {
  let result = await runAgent(`${step} zastosowanie`, prompt, { ...reviewAgent, schema: APPLY_RESULT })
  let repair = null
  for (let round = 1; ; round++) {
    const points = pointsFor(result)
    if (!points.length) {
      checklist.push({ where, step, round, gaps: [], warnings: [] })
      return result
    }

    const check = await runAgent(`weryfikacja ${step}`, checkPrompt(points, repair), { ...LIGHT_AGENT, schema: CHECK_RESULT })
    checklist.push({ where, step, round, gaps: check.gaps, warnings: check.warnings })
    if (!check.gaps.length && !check.blocked.length) return result

    const failures = [...check.gaps, ...check.blocked.map(b => `środowisko: ${b}`)]
    if (round > MAX_REPAIRS) throw new Stop(failures)

    log(`${where}: ${step} → naprawa ${round}`)
    const { repair: report, ...repaired } = await runAgent(`${step} naprawa`, repairPrompt(prompt, result, check), {
      ...reviewAgent,
      schema: withRepair(APPLY_RESULT),
    })
    result = repaired
    repair = report
    repairs.push({ where, step, round, ...report })
    // Nothing changed, so the next verification would fail the same way.
    if (!report.fixed.length && !report.falseAlarms.length) throw new Stop([...failures, ...report.unresolved])
  }
}

const reviewPrompt =
  `Wywołaj skill code-review z argumentami "${reviewAgent.effort}" (zakres: ${scope.desc}, \`${scope.diffCommand}\`). ` +
  'Tylko raport — niczego nie naprawiaj i nie pytaj użytkownika. ' +
  'Jeśli skill zwróci wynik bez listy znalezisk (np. komunikat o czekaniu na testy), nie wywołuj go ponownie — przejrzyj ten sam zakres sam. ' +
  'Zwróć każde znalezisko z plikiem, linią i konkretnym scenariuszem błędu.'

const applyPrompt = findings =>
  `Poniżej znaleziska code-review dla zakresu "${scope.desc}" (\`${scope.diffCommand}\`). ` +
  'Najpierw spróbuj obalić każde: sprawdź w kodzie, czy scenariusz naprawdę zachodzi, czy gałąź jest osiągalna i czy czegoś nie chroni kod wyżej lub niżej. ' +
  `Obalone i takie, których realności nie jesteś pewien, odrzuć, resztę napraw. ${NO_TESTS} Nie pytaj użytkownika. ` +
  'W findings podaj każde znalezisko: fixed, gdy naprawione, rejected z powodem, gdy nie.\n\n' +
  JSON.stringify(findings)

let stop = null
let decisions = []
try {
  const review = await runAgent(step, reviewPrompt, { ...reviewAgent, schema: REVIEW_RESULT })
  log(`${where}: ${step} → ${review.findings.length} znalezisk`)

  if (!review.findings.length) {
    checklist.push({ where, step, round: 1, gaps: [], warnings: [] })
  } else {
    // Nothing fixed means nothing changed, so there is nothing to verify or test.
    const result = await runVerified(applyPrompt(review.findings), r => {
      const fixed = r.findings.filter(f => f.outcome === 'fixed')
      if (!fixed.length) return []

      return [
        `Każde znalezisko fixed jest naprawione w \`${scope.diffCommand}\` w podanym pliku blisko podanej linii: ${JSON.stringify(fixed)}`,
        testsCheck(r),
      ]
    })
    decisions = result.decisions.map(d => ({ where, step, ...d }))
    rejected.push(...result.findings.filter(f => f.outcome === 'rejected').map(f => ({ where, ...f })))
  }
} catch (err) {
  if (!(err instanceof Stop)) throw err
  stop = err.stop
}
return { stop, checklist, decisions, rejected, repairs }
