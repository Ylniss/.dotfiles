---
name: phase
description: >
  Wykonuje jedną fazę zapisanego planu z plans/<slug>.md, od bramki zarysu
  do bramki przeglądu. Użyj, gdy użytkownik wywołuje "/phase [plan] [N] [auto]".
argument-hint: "[plan] [N] [auto]"
---

# Phase

Wykonaj jedną fazę planu ze skilla plan. Dwie bramki: zarys przed kodem,
przegląd po weryfikacji. Argument `auto` wyłącza bramki i pytania — patrz
sekcja Tryb auto.

## Twarde reguły

1. **Jedna faza na wywołanie.** Zakres to sekcja Scope tej fazy — nic więcej.
   Sąsiednie ulepszenia trafiają na listę wyników lub do Open questions planu,
   nie do diffa.
2. **Dwie bramki zatwierdzenia** (poza trybem auto). Żadnego kodu przed zatwierdzeniem zarysu.
   Żadnej zmiany z listy wyników przed zatwierdzeniem na bramce przeglądu.
3. **Plik planu jest kanoniczny.** Każdą zmianę stanu (faza done/blocked,
   podjęte decyzje) zapisuj do pliku planu wg reguł aktualizacji ze skilla plan.
   Plik i rzeczywistość nigdy nie mogą się rozjechać.
4. **Zielona bramka.** Czysty build i pełny zestaw testów przechodzi przed
   bramką przeglądu. Nigdy nie zgłaszaj fazy jako gotowej na czerwono.
5. **Nigdy nie commituj.** Ten skill nie robi `git commit` i nie pyta o commit.
   Faza kończy się niezacommitowanymi zmianami w drzewie roboczym. Commit wydaje
   użytkownik.

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

- Uruchom build i pełny zestaw testów projektu (komendy z CLAUDE.md lub
  AGENTS.md projektu albo oczywistej konwencji; zapytaj, jeśli niejasne).
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

### 6. Bramka przeglądu

Przedstaw razem: podsumowanie diffa (pliki + co się zmieniło per zagadnienie),
wynik testów, listę wyników. Zapytaj, które wyniki zastosować.

Po zatwierdzeniu:

- Zastosuj tylko wybrane wyniki; uruchom testy ponownie, jeśli zmieniły kod.
- Zaktualizuj plan: oznacz fazę `[x]` w Phase detail, oznacz `[x]` na liście
  Phases u góry, podbij Last updated (data + sha `HEAD`).
- Zgłoś: faza gotowa, zmiany niezacommitowane, następna oczekująca faza.

## Tryb auto

Wywołanie bez człowieka przy klawiaturze (np. z /exec-plan). Nie pytaj o nic i
na nic nie czekaj. Plan i N są zawsze podane. Reszta przebiegu bez zmian, poza:

- **Krok 1:** pomiń pytanie o `/plan-review`. Rozjazd planu z repo lub
  niespełnione `Depends on` → nie implementuj, zgłoś powód i zakończ.
- **Krok 2:** zarys zrób dla siebie i przejdź od razu do implementacji.
- **Krok 3:** faza niewykonalna jak zaplanowano → oznacz ją `[!]` z wpisem w
  Decisions log i zakończ.
- **Krok 4:** niejasna komenda build lub testów → wybierz oczywistą konwencję
  repo.
- **Krok 5:** pomiń — przegląd robi później /finish.
- **Krok 6:** bez bramki. Po zielonych testach od razu zaktualizuj plan i
  zgłoś.

Każde miejsce, w którym zwykle pytasz, rozstrzygnij wg własnej rekomendacji.
Decyzję, którą użytkownik mógłby podjąć inaczej, zapisz w Decisions log jako
wpis ⚠ wg skilla plan.
