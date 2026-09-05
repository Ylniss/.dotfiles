---
name: plan
description: >
  Wysokopoziomowe planowanie tematu w fazach. Krytykuje pomysł, doprecyzowuje
  przez Q&A, zapisuje samodzielny plan do plans/<slug>.md. Użyj, gdy
  użytkownik wywołuje "/plan <temat>".
argument-hint: "<subject>"
---

# Plan

Zaplanuj temat, który następuje. Wynik: plan w fazach, gotowy do commitów,
zapisany jako jeden plik markdown.

## Twarde reguły

1. **Bez kodu, bez commitów, bez edycji czegokolwiek poza plikiem planu.** Ten
   skill tylko planuje.
2. **Dwie bramki zatwierdzenia: slug i zapis.** Potwierdź slug przed utworzeniem
   pliku (reguła 3) i nie zapisuj, dopóki nie powiesz dokładnej frazy **"Plan is
   ready to save."** i użytkownik nie zatwierdzi. Nie pisz kodu z tego planu —
   szczegół fazy to osobne wywołanie w świeżym kontekście.
3. **Miejsce zapisu.** `<git-root>/plans/<slug>.md`. Utwórz `plans/`, jeśli
   brak. Korzeń git z `git rev-parse --show-toplevel`. Slug z tematu
   (kebab-case); zaproponuj i potwierdź przed zapisem.
4. **Plik jest kanoniczny po zapisie.** Po zapisie plik jest planem. Nie
   przeformułowuj ani nie rewiduj treści planu po cichu w rozmowie — albo zapisz
   zmianę do pliku, albo się zatrzymaj. Inaczej plan w pamięci i na dysku się
   rozjadą, a świeży kontekst odziedziczy nieaktualny.

## Przebieg

### 1. Brutalna krytyka

Najpierw oprzyj krytykę na kodzie. Nieczytane pliki lub systemy, których temat
dotyka, zbadaj przed atakiem — przeczytaj kod, grepuj użycia lub odpal agenta
Explore dla szerokości. Ogólna krytyka z założeń to tryb porażki; nie twórz jej.

Potem zaatakuj pomysł na tych osiach:
- **Rozrost zakresu** — co jest dołączone, a nie musi być?
- **Ukryta złożoność** — co wygląda na małe, a nie jest?
- **Odrzucone alternatywy** — jakie inne podejścia istnieją; czemu to jest
  właściwe?
- **Ryzyko kolejności** — co musi być prawdą, by plan zadziałał, i czy jest?
- **Założenia nośne** — która jedna rzecz, jeśli błędna, unieważnia plan?

Wprost. Bez asekuracji. Potem zadaj pytania doprecyzowujące, które wynikają z
krytyki.

### 2. Doprecyzuj

Pętla: użytkownik odpowiada → wchłoń → pokaż, co nadal nierozstrzygnięte → pytaj
dalej. Trzymaj strukturę planu na widoku (temat, cel, ograniczenia, fazy), żeby
użytkownik widział, jak nabiera kształtu. Gdy nic nie zostało, zatrzymaj się i
powiedz dosłownie: **"Plan is ready to save."** Czekaj na jawne zatwierdzenie
przed zapisem pliku.

### 3. Zapisz

Po zatwierdzeniu zapisz `<git-root>/plans/<slug>.md` wg szablonu poniżej.
Samodzielny: świeży Claude bez pamięci tej rozmowy musi móc go podjąć.

````markdown
# <Subject>

_Last updated: YYYY-MM-DD — commit `<sha>`_
_Reviewed: never_

## Phases
- [ ] 1. <short name>
- [ ] 2. <short name>

## Goal
One paragraph. What "done" looks like.

## Constraints / non-goals
Bulleted. What is explicitly out of scope.

## Key decisions (pre-implementation)
For each: decision, why, what was rejected and why.

## Repo context a fresh Claude needs
Quirks, conventions, file paths, prior incidents, anything not derivable from a quick `ls` or `git log`.

## Phase detail

### [ ] Phase 1: <name>
- **Goal:** ...
- **Scope:** ...
- **Done when:** ... (mergeable check — repo is not broken at end of phase)
- **Risk:** low | medium | high
- **Depends on:** none | phase N

(repeat per phase; single phase is fine if the work is small)

## Decisions log (during implementation)
Append-only. Each entry: `YYYY-MM-DD — decision — why`. Future sessions add to this as choices are made.

## Open questions
Deferred items. Empty if none.
````

Lista **Phases** u góry pliku to indeks: numer fazy i jedna krótka linia na
fazę. Bez celu, bez sha, bez szczegółów. Niesie ten sam znacznik stanu co
odpowiadający nagłówek w **Phase detail**.

### 4. Aktualizacja planu po fazie

Gdy faza zmienia stan, zaktualizuj jej nagłówek w miejscu i ustaw ten sam
znacznik na jej linii w liście **Phases** u góry pliku:
- Oczekująca: `### [ ] Phase 1: <name>`
- Gotowa: `### [x] Phase 1: <name> — <commit-sha-or-range>` (zakres lub ref PR,
  jeśli obejmuje kilka commitów)
- Zablokowana: `### [!] Phase 1: <name>` — dodaj wpis w Decisions log
  wyjaśniający blokadę
- Porzucona: `### [~] Phase 1: <name>` — dodaj wpis w Decisions log wyjaśniający
  dlaczego

Podbij linię **Last updated** u góry pliku przy każdej zmianie (data + aktualny
sha `HEAD`). Decyzje podjęte w trakcie fazy idą do **Decisions log**, nie do
sekcji pre-implementation.

Zostaw linię **Reviewed** w spokoju. Stempluje ją tylko skill plan-review, więc
plan edytowany po ostatnim przeglądzie pokazuje się jako nieprzeglądany — i
słusznie.

## Reguły podziału na fazy

1. **Jedna faza, jeśli małe.** Praca na jeden logiczny PR z jednym zagadnieniem:
   nie fabrykuj faz.
2. **Ryzyko na koniec domyślnie.** Niskie ryzyko idzie wcześnie, więc wychodzi
   nawet, gdy późniejsze fazy utkną.
3. **Wymuszona kolejność wygrywa.** Jeśli wysokoryzykowna zmiana fundamentów
   musi iść pierwsza (nie da się budować na zepsutej abstrakcji), daj ją
   pierwszą i zaznacz dlaczego w tej fazie.
4. **Każda faza mergowalna sama.** Żadna faza nie zostawia repo w zepsutym
   stanie.
5. **Grupowanie logiczne lub wg ryzyka.** Faza może obejmować wiele zmian
   plików, jeśli dzielą jedno zagadnienie. Granulacja gruba, nie drobna.
