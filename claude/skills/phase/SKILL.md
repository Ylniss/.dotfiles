---
name: phase
description: >
  Wykonuje jedną fazę zapisanego planu z plans/<slug>.md, od bramki zarysu
  do commita. Użyj, gdy użytkownik wywołuje "/phase [plan] [N]".
argument-hint: "[plan] [N]"
---

# Phase

Wykonaj jedną fazę planu ze skilla plan. Dwie bramki: zarys przed kodem,
przegląd przed commitem.

## Twarde reguły

1. **Jedna faza na wywołanie.** Zakres to sekcja Scope tej fazy — nic więcej.
   Sąsiednie ulepszenia trafiają na listę wyników lub do Open questions planu,
   nie do diffa.
2. **Dwie bramki zatwierdzenia.** Żadnego kodu przed zatwierdzeniem zarysu.
   Żadnego commita przed zatwierdzeniem na bramce commita.
3. **Plik planu jest kanoniczny.** Każdą zmianę stanu (faza done/blocked,
   podjęte decyzje) zapisuj do pliku planu wg reguł aktualizacji ze skilla plan.
   Plik i rzeczywistość nigdy nie mogą się rozjechać.
4. **Zielona bramka.** Czysty build i pełny zestaw testów przechodzi przed
   bramką commita. Nigdy nie commituj na czerwono.

## Przebieg

### 1. Wczytaj i zweryfikuj

- Rozwiąż plan: arg to slug lub ścieżka pod `<git-root>/plans/`. Jeśli się nie
  rozwiązuje, wypisz dostępne plany i zatrzymaj się. Brak argumentu: jeden plan
  w `plans/` → weź go; więcej → wypisz je i zapytaj.
- Wybierz fazę: jawne N, jeśli podano, inaczej pierwsza faza `[ ]` w **Phase
  detail**. Jeśli żadna nie została, powiedz to i zatrzymaj się.
- Sprawdź nieaktualność: porównaj commit z Last updated planu z `HEAD`;
  przeczytaj pliki z Repo context i potwierdź, że nadal istnieją i działają jak
  opisano. Przy rozjeździe: zgłoś go, zaktualizuj plan z użytkownikiem, jeszcze
  nie implementuj.
- Sprawdź przegląd: linia **Reviewed** planu. `never` lub brak = plan nigdy nie
  był przeglądany. Powiedz to i zapytaj, czy najpierw uruchomić `/plan-review`.
  Użytkownik może pominąć — nie blokuj na tym. Stempel starszy niż **Last
  updated** jest w porządku — nie pytaj ponownie.
- Sprawdź, że fazy z `Depends on` są `[x]`. Jeśli nie, zatrzymaj się i powiedz,
  których brakuje.

### 2. Bramka zarysu

Przedstaw krótki zarys implementacji oparty na aktualnym kodzie: podejście,
dotykane pliki, kolejność zmian i jak zweryfikujesz "Done when". Jeszcze bez
kodu. Poproś o zgodę — zatwierdza ona kod tylko dla zakresu tej fazy.

### 3. Implementuj

- Trzymaj się Scope fazy.
- Wybory podjęte po drodze dopisuj do Decisions log planu (`YYYY-MM-DD — decyzja
  — dlaczego`).
- Jeśli faza okaże się niewykonalna jak zaplanowano: zatrzymaj się, zgłoś
  dlaczego, zaproponuj oznaczenie `[!]` blocked z wpisem w Decisions log i
  czekaj.

### 4. Weryfikuj

- Uruchom build i pełny zestaw testów projektu (komendy z CLAUDE.md projektu lub
  oczywistej konwencji; zapytaj, jeśli niejasne).
- Sprawdź jawnie kryterium "Done when" fazy.
- Czerwono → napraw w zakresie. Nie da się w zakresie → zatrzymaj się i zgłoś;
  nie poszerzaj zakresu po cichu.

### 5. Samoprzegląd

Wczytaj `~/.claude/skills/clarify/SKILL.md`, `~/.claude/skills/polish/SKILL.md`
i ich plik wspólny `~/.claude/skills/_shared/report.md`. Zastosuj kryteria
przeglądu obu skilli (clarify: esencja komentarzy + bezpośredniość nazw; polish:
uproszczenie, optymalizacja, nowoczesne wzorce bibliotek — poparte context7)
tylko do diffa fazy — zmian tej fazy, nie całego `git diff HEAD`. Tylko raport:
pomiń własne kroki apply/ask tych skilli i scal oba przeglądy w jedną numerowaną
listę wyników.

### 6. Bramka commita

Przedstaw razem: podsumowanie diffa (pliki + co się zmieniło per zagadnienie),
wynik testów, listę wyników. Zapytaj, które wyniki zastosować i czy commitować.

Po zatwierdzeniu:

- Zastosuj tylko wybrane wyniki; uruchom testy ponownie, jeśli zmieniły kod.
- Commit: jeden, jeśli faza to jedno zagadnienie, inaczej podziel per
  zagadnienie.
- Zaktualizuj plan: oznacz fazę `[x] — <sha lub zakres>` w Phase detail, oznacz
  `[x]` na liście Phases u góry, podbij Last updated (data + sha `HEAD`), potem
  osobny commit aktualizacji planu.
- Zgłoś: faza gotowa, wykonane commity, następna oczekująca faza.
