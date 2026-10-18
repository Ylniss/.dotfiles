export const meta = {
  name: 'code-review-run',
  description: 'Code-review zakresu: jeden przegląd, potem obalanie i naprawa znalezisk z weryfikacją',
}

const { scope, reviewAgent, where } = args
const MAX_ATTEMPTS = 2

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

const step = 'code-review'
const checklist = []
const rejected = []

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
  'Testy, których nie uruchomiono, bo build pada przez kod, to gap, nie blocked. Demona Dockera sprawdzaj przez `docker info --format "{{.ServerVersion}}"`: wersja znaczy, że działa (początek pełnego `docker info` to tylko sekcja Client). ' +
  'Inny punkt, którego nie da się sprawdzić z powodu środowiska (brak narzędzia, usługi lub demona), zgłoś w warnings, nie w gaps.\n' +
  points.map((p, i) => `${i + 1}. ${p}`).join('\n')

async function runVerified(prompt, pointsFor) {
  let retry = null
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    const result = await runAgent(`${step} zastosowanie`, retry ? fixPrompt(prompt, retry) : prompt, { ...reviewAgent, schema: APPLY_RESULT })
    const points = pointsFor(result)
    if (!points.length) {
      checklist.push({ where, step, attempt, gaps: [], warnings: [] })
      return result
    }

    const check = await runAgent(`weryfikacja ${step}`, checkPrompt(points), { ...LIGHT_AGENT, schema: CHECK_RESULT })
    checklist.push({ where, step, attempt, gaps: check.gaps, warnings: check.warnings })
    // a retry cannot fix the environment, but a gap such as a build broken by the code can be what blocked the tests
    if (check.blocked.length && !check.gaps.length) throw new Stop(check.blocked.map(b => `środowisko: ${b}`))
    if (!check.gaps.length) return result
    retry = { gaps: check.gaps, previous: result }
  }
  throw new Stop(retry.gaps)
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
    checklist.push({ where, step, attempt: 1, gaps: [], warnings: [] })
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
return { stop, checklist, decisions, rejected }
