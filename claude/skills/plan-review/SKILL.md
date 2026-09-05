---
name: plan-review
description: >
  Adwersarialny przegląd zapisanego planu w plans/<slug>.md: weryfikuje
  twierdzenia wobec repo, znajduje luki, proponuje alternatywy. Użyj, gdy
  użytkownik wywołuje "/plan-review [plan]".
argument-hint: "[plan]"
---

# Plan review

Przejrzyj plan napisany przez skill plan, zanim /phase włoży w niego pracę.
Tylko raport, dopóki użytkownik nie wybierze; potem edytuj plik planu. Ten skill
edytuje plik planu i nic więcej — nigdy nie dotyka kodu.

Najlepiej uruchomić w świeżym kontekście — po `/clear` lub kompaktowaniu. Sesja,
która napisała plan, ma skłonność go zatwierdzać. To rada, nie bramka.

Przed raportem wczytaj `~/.claude/skills/_shared/report.md`. Obowiązują z niego
tylko sekcje Tagi nagłówka, Format ciała i Słowa wyboru. Reszta dotyczy kodu,
nie planu.

## 1. Wybierz plan

- **Podano argument** — rozwiąż go jako slug lub ścieżkę pod
  `<git-root>/plans/`. Jeśli się nie rozwiązuje, przejdź do listy poniżej.
- **Brak argumentu** — wypisz każdy plan w `<git-root>/plans/`, numerowany, z
  datą last-updated, datą reviewed i liczbą faz (done/total). Zapytaj, który.
  Nigdy nie zakładaj najnowszego.
- Brak katalogu `plans/` lub pusty — powiedz to i zatrzymaj się.

Przeczytaj cały plik planu przed czymkolwiek innym.

## 2. Sprawdź rozjazd

Porównaj commit z **Last updated** planu z aktualnym `HEAD`. Przeczytaj pliki
wymienione w **Repo context** i potwierdź, że nadal istnieją i działają, jak
opisuje plan.

Rozjazd to wynik jak każdy inny (kategoria `claim`), zgłaszany z resztą. Nie
naprawiaj go po cichu i nie chowaj w preambule.

## 3. Weryfikuj twierdzenia (WYMAGANE)

Sprawdź każde stwierdzenie, które repo może potwierdzić lub obalić. Czytaj i
grepuj — pamięć nie jest dowodem.

Co najmniej:

- ścieżki plików i katalogów
- nazwy symboli — funkcje, typy, komendy, klucze konfiguracji, zmienne
  środowiskowe
- liczby i ilości — "12 miejsc wywołania", "trzy miejsca", "używane tylko tu"
- wersje, z lockfile lub manifestu
- "X już istnieje" i "Y jeszcze nie istnieje"
- twierdzenia o tym, jak działa istniejący kod

Wynik `claim` bez pola `evidence` nie nadaje się do zgłoszenia — odrzuć go.
Twierdzenia, których repo nie rozstrzygnie (zewnętrzne usługi, przyszła praca,
gust), są poza tym krokiem; mogą nadal być `gap`.

## 4. Znajdź luki

Wymóg miękki, wycelowany w to, czego plan faktycznie dotyka. Najpierw przeczytaj
kod, który plan zmieni, potem zapytaj, czego plan nie mówi. Odpal agenta
Explore, gdy temat obejmuje więcej, niż da się przeczytać bezpośrednio.

Punkty wyjścia, nie zamknięty zbiór:

- faza bez "Done when" lub z takim, którego nie da się sprawdzić
- faza, która sama zostawia repo zepsute
- kolejność `Depends on` niezgodna z tym, jak kod naprawdę zależy
- brak rollbacku, migracji lub ścieżki danych tam, gdzie zmiana ich wymaga
- założenie nośne, którego plan nigdy nie wypowiada
- praca, którą plan implikuje, ale nie przypisuje żadnej fazie

Luka znaleziona przez czytanie kodu bije lukę znalezioną przez czytanie planu.

## 5. Alternatywy (max dwie)

Tylko gdy inne podejście istotnie zmieniłoby plan — inny kształt, nie wariant.
Dwie to sufit; zero to normalny wynik.

Każda alternatywa musi nazwać, co obecny plan robi lepiej. Alternatywa bez
podanego kompromisu to nie analiza — odrzuć ją.

Nie powtarzaj krytyki, którą skill plan zrobił przed zapisem planu. Podnoś tylko
to, co zapisany plan czyni widocznym.

## 6. Oceń i oflaguj

- Odrzuć drobiazgi. Zgłaszaj tylko to, co warto zmienić w planie.
- Szereguj wg wpływu: najpierw to, co zmarnowałoby najwięcej pracy.
- Nadaj każdemu wynikowi pewność: H, M lub L. Dla `claim` H znaczy, że dowód
  rozstrzyga.
- Nadaj flagę rekomendacji. `✓`, gdy zastosowanie nie budzi wątpliwości — zysk
  realny, ryzyko dla planu niskie. `✗` dla gustu, dla celowego wyboru, który
  plan już uzasadnia, lub dla czegokolwiek opartego na założeniu, którego nie
  dało się zweryfikować.
- Jeśli nie ma nic wartego zmiany, powiedz to, ostempluj przegląd (krok 9) i
  zatrzymaj się. Nie wymyślaj wyniku, żeby mieć co zgłosić.

## 7. Raport (jeszcze nie edytuj)

Numerowana lista, żeby użytkownik mógł wybrać:

    **N. [category][H|M|L][✓|✗] <sekcja planu lub faza> — krótki tytuł**
    ========== why ==========
    <jedna linia>
    ========== evidence ==========
    <co zwróciło repo — tylko wyniki claim>
    ========== fix ==========
    <co zmienia się w planie, jedna linia>

Kategoria w tagu: `claim`, `gap`, `sequencing`, `scope` lub `alternative`.

Wskazuj sekcję lub nazwę fazy planu, nie numer linii — zastosowanie przepisuje
plik.

Pole `evidence` jest wymagane dla każdego wyniku `claim` i nazywa, co
przeczytano lub zgrepowano, i co wróciło. Dla innych kategorii pomiń jego baner.

Bez bloków diff. Proza planu źle czyta się jako diff; pole `fix` niesie zmianę.

Zakończ: "Which to apply? (e.g. 1,3,5 / all / recommended / none)"

## 8. Zastosuj — wplataj, nigdy nie dopisuj

Zastosuj tylko wyniki wybrane przez użytkownika, wg słów wyboru z pliku
wspólnego.

Plan ma wyjść tak, jakby od początku był tak napisany:

- Poprawione twierdzenie jest przepisane w swoim zdaniu, w miejscu.
- Nowa faza jest wstawiona na właściwej pozycji, przenumerowana, z każdą
  referencją `Depends on` i listą **Phases** u góry pliku zaktualizowanymi do
  zgodności.
- Usunięty zakres znika z linii Scope. Nie jest przekreślony, nie w nawiasie,
  nie oznaczony "dropped".
- Żadnego śladu przeglądu w treści planu: bez "(fixed in review)", bez sekcji
  "Review findings", bez datowanej adnotacji przy poprawce.
- Wyjątek: alternatywa odrzucona przez użytkownika trafia do **Key decisions**
  jako odrzucona opcja z powodem. Ta sekcja istnieje dokładnie po to.
- **Decisions log** jest append-only i należy do implementacji. Wyniki przeglądu
  nigdy tam nie idą.
- Każdą nietkniętą sekcję zostaw bajt w bajt. Nie zawijaj, nie zmieniaj wcięć
  ani stylu prozy, której żaden wynik nie wskazał.

## 9. Ostempluj przegląd

Zawsze, nawet gdy nic nie znaleziono i nic nie zastosowano:

- Ustaw `_Reviewed: YYYY-MM-DD — commit <sha>_` bezpośrednio pod linią Last
  updated, z dzisiejszą datą i aktualnym `HEAD`. Wstaw ją, jeśli plan jest
  starszy niż ta konwencja.
- Podbij `_Last updated:_` tylko, jeśli treść pliku się zmieniła.

Potem zgłoś: które wyniki zastosowano, które pominięto i co plik planu teraz
mówi. Bez commita — reguły skilla plan obowiązują.
