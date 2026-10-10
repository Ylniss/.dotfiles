---
name: exec-plan
description: >
  Wykonuje cały plan z plans/<slug>.md bez nadzoru: pytania na starcie, potem
  workflow phase → finish → code-review → commit dla każdej fazy i finish z
  code-review względem bazy na końcu. Użyj, gdy użytkownik wywołuje
  "/exec-plan".
argument-hint: "<model-phase> <effort-phase> <model-review> <effort-review> <plan> [baza]"
---

# Exec plan

Jedyny moment rozmowy z użytkownikiem to pytania na starcie i raport na końcu.
Wszystko pomiędzy robi workflow, który weryfikuje każdy krok niezależnym
agentem i staje, zamiast iść dalej z luką.

## 1. Argumenty

- Modele: `haiku`, `sonnet`, `opus`, `fable`. Efforty: `low`, `medium`, `high`,
  `xhigh`, `max`. Para phase obsługuje skill phase; para review obsługuje
  finish i code-review.
- Plan: ścieżka (także z `@`) lub slug pod `<git-root>/plans/`.
- Baza: domyślnie `develop`.

Brak wymaganego argumentu lub nieznana wartość → wypisz składnię z
argument-hint i zakończ.

## 2. Kontrole

Zatrzymaj się z powodem, gdy:

- bieżący branch to baza,
- drzewo robocze nie jest czyste,
- baza nie istnieje,
- w planie nie została żadna faza `[ ]`.

## 3. Pytania

- Przeczytaj cały plan, pliki z Repo context i kod, którego dotykają fazy
  `[ ]`.
- Zbierz każde pytanie, którego odpowiedź może zmienić implementację:
  niejasny zakres, wybór między podejściami, konwencja, ryzyko, Open questions
  planu. Nie pytaj o to, co plan lub repo już rozstrzyga.
- Plan z `Reviewed: never` → dodaj pytanie, czy najpierw uruchomić
  `/plan-review`. Tak → zakończ z prośbą o `/plan-review`, a potem ponowne
  `/exec-plan`.
- Pytaj przez AskUserQuestion, do 4 pytań na wywołanie, w kolejnych rundach aż
  do wyczerpania. Rekomendowana opcja pierwsza.
- Brak pytań → powiedz to w jednej linii i idź dalej.

## 4. Zapisz odpowiedzi

- Dopisz odpowiedzi do Key decisions (pre-implementation) planu: decyzja,
  dlaczego, co odrzucono. Podbij Last updated.
- Zacommituj sam plan jedną krótką linią opisującą zmianę, żeby odpowiedzi nie
  wpadły do commitu fazy 1.

## 5. Uruchom workflow

Wywołanie tego skilla to zgoda użytkownika na workflow i na jego commity.

- Wczytaj `~/.claude/skills/finish/finish.json`.
- Uruchom Workflow ze `scriptPath` = `~/.claude/skills/exec-plan/workflow.js`
  rozwiniętym do ścieżki absolutnej i `args`:
  - `plan` — ścieżka planu od korzenia repo,
  - `phases` — fazy `[ ]` w kolejności, każda `{ n, name }`,
  - `phaseModel`, `phaseEffort`, `reviewModel`, `reviewEffort`, `base`,
  - `finish` — zawartość `finish.json`.
- Powiedz w jednej linii, że workflow ruszył i że postęp widać w `/workflows`.
  Czekaj na powiadomienie o końcu — nie odpytuj.

## 6. Raport

Z wyniku workflowu:

- **Stan:** wszystkie fazy gotowe albo zatrzymany — gdzie, na którym kroku, z
  jakimi brakami. Przy stopie dodaj: zmiany tej fazy leżą niezacommitowane;
  po naprawie zacommituj je lub odrzuć i uruchom `/exec-plan` ponownie.
- **Checklista:** każda faza i krok ze statusem i liczbą prób.
- **Decyzje** (`decisions`): decyzja, dlaczego, alternatywa — oznaczone A1,
  A2...
- **Pominięte ✗ warte decyzji** (`skipped`) — B1, B2...
- **Odrzucone znaleziska code-review** (`rejected`) — C1, C2...
- **Commity:** `git log --oneline` od commitu z kroku 4.
