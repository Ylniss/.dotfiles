# Wspólne reguły przeglądu

Czytają go skille clarify, polish i shape (w całości) oraz plan-review i prune
(tylko sekcje wskazane w tych skillach). Własna reguła skilla wygrywa z regułą
stąd.

## Granica między /polish, /clarify i /shape

- /polish zmienia kod w miejscu: lepszy zapis tych samych linii.
- /clarify zmienia nazwy w kodzie i treść komentarzy.
- /shape zmienia, gdzie kod leży, na ile jednostek jest pocięty, która jednostka
  zależy od której i w jakiej kolejności rzeczy stoją w pliku.

## Zakres

Argument wyznacza zakres. Rozpoznaj jego rodzaj:

- **Brak argumentu** — `git diff HEAD` (zmiany staged i unstaged w śledzonych
  plikach) oraz nowe nieśledzone pliki z `git ls-files --others
  --exclude-standard`. Jeśli oba są puste, drzewo jest czyste: zaproponuj
  `HEAD~1` (ostatni commit) lub merge-base z gałęzią główną i zapytaj. Nie
  wybieraj sam.
- **Ref lub zakres git** (`main`, `HEAD~3`, gałąź) — `git diff <arg>`.
- **Ścieżka** (istniejący katalog lub plik) — cała treść tej ścieżki, nie diff.
  Powiedz to w jednej linii przed startem: zakres to każdy plik tam, nie tylko
  zmienione linie.

Jeśli zakres jest pusty — pusty diff lub ścieżka bez plików źródłowych — powiedz
to i zatrzymaj się.

### Wyniki spoza zakresu są pożądane

Wynik nie musi należeć do bieżącego zadania użytkownika ani dotykać linii, którą
użytkownik napisał. Zgłoś go tak samo.

Nigdy się nie asekuruj. Nie pisz "to poza zakresem twojej zmiany", "to istniało
wcześniej" ani "niezwiązane z twoją pracą". Użytkownik chce tych wyników, a
zastrzeżenie tylko dodaje szum.

## Konflikty

Sprzeczne wyniki czytają się jak szum i psują zbiorcze zastosowanie. Sprawdź
całą listę przed wypisaniem:

- Dwa wyniki edytujące te same linie → zostaw lepszy, odrzuć drugi.
- Wynik, którego użytkownik nie może zastosować, bo inny usuwa edytowany kod →
  złóż oba w jeden wynik.
- Dwa wyniki mówiące to samo w dwóch plikach → trzymaj osobno tylko, gdy
  użytkownik mógłby chcieć jednego, a nie drugiego.

Każdy zgłoszony wynik musi dać się zastosować sam, a wybrane wyniki w dowolnej
kolejności. Rozwiąż to przed raportem. Nie zgłaszaj konfliktu z prośbą, by
użytkownik go rozstrzygnął.

## Ocena i flagi

- Odrzuć trywialne drobiazgi. Zgłaszaj tylko to, co warte zmiany.
- Pewność każdego wyniku: H (wysoka), M (średnia), L (niska).
- Flaga rekomendacji dla każdego wyniku. Rekomenduj, gdy zastosowanie nie budzi
  wątpliwości: zysk realny, ryzyko niskie. Nie rekomenduj wyniku, który jest
  kwestią gustu, łamie konwencję celowo utrzymaną w pliku, lub opiera się na
  założeniu lub zasięgu rażenia, którego nie dało się sprawdzić.
- Jeśli nic nie wymaga zmiany, powiedz to i zatrzymaj się. Nie wymyślaj wyniku,
  żeby mieć co zgłosić.

## Raport

Numerowana lista, żeby użytkownik mógł wybrać. Numer zaczyna wynik, więc nic nie
stoi nad nim. Nigdy nie drukuj ścieżki pliku nad wynikiem.

### Tagi nagłówka

Trzy tagi, bez spacji między nimi, zawsze w tej kolejności:

1. Kategoria: z listy skilla.
2. Pewność: jedna litera — `H`, `M` lub `L`.
3. Flaga rekomendacji: `✓` gdy rekomendujesz zastosowanie, `✗` gdy nie.

Nigdy nie pisz "(confidence: high)" na końcu linii — tagi to niosą.

### Format ciała

- Linia nagłówka w `**`, pogrubiona. Nigdy jako nagłówek markdown — ten dodaje
  pod sobą pustą linię i rozbija zwarty blok.
- Baner: `========== <etykieta> ==========` — dziesięć `=` z każdej strony,
  spacja wokół etykiety. Zawsze dziesięć, bez względu na długość etykiety. Nie
  dopełniaj do stałej szerokości, nie centruj etykiety.
- Bez pustej linii wewnątrz wyniku: nagłówek, banery i pola w kolejnych liniach.
  Jedna pusta linia rozdziela wyniki, i nic więcej.
- Baner to zwykły tekst: nigdy w bloku kodu, bez backticków, pogrubienia ani
  znacznika nagłówka.
- Drukuj banery i pola jako zwykłe linie markdown. Nigdy nie wkładaj wyniku w
  blok kodu — blok pokazuje backticki jako tekst i zabija kolor.

### Blok diff

Tylko skille, których wynik ma blok diff:

- Blok diff to jedyny blok kodu w wyniku.
- Tekst przed i po pojawia się tylko w bloku diff. Nie powtarzaj go prozą.
- Lokalizacja pojawia się tylko w `@@ ścieżka:linia @@`, jako ścieżka od
  korzenia repo. Nigdy nie powtarzaj jej w linii nagłówka.
- Pokaż tylko zmieniane linie plus minimum kontekstu do ich odczytania. Nie
  wklejaj całej funkcji.
- Terminal koloruje linie `-` na czerwono, a `+` na zielono. Kolorowanie jest
  per linia, więc jeden wynik = jedna zmiana — nie łącz dwóch niezależnych
  edycji w jeden blok.
- Dla czystego usunięcia pisz tylko linie `-`. Dla czystego dodania tylko `+`.

### Zakończenie

Po ostatnim wyniku wypisz, co przejrzano i celowo pominięto w raporcie, i
dlaczego — jedna linia na klasę. To dowodzi, że pokrycie było agresywne, a
edycje wybiórcze.

Zakończ: "Which to apply? (e.g. 1,3,5 / all / recommended / none)"

## Zastosuj wybrane

Zastosuj tylko wyniki wybrane przez użytkownika.

### Słowa wyboru

- **numery** (`1,3,5` lub `A1,B2`) — dokładnie te wyniki.
- **all** — każdy wynik z raportu, `✓` i `✗` tak samo. "all" nigdy nie znaczy
  "recommended". Nie pomijaj wyniku, bo nie był rekomendowany, i nie mów
  użytkownikowi, że "all" coś pomija.
- **recommended** — każdy wynik z tagiem `✓`, nic z tagiem `✗`.
- **none** — nie stosuj nic.

### Reguły

- Zrób dokładnie proponowaną zmianę, nic więcej.
- Zmieniaj tylko linie wskazane przez wynik. Niczego innego nie formatuj, nie
  wcinaj, nie zawijaj.
- Zachowaj konwencje pliku: końce linii, znak wcięcia, końcowy newline. Przed
  zapisem przeczytaj aktualny stan pliku.

## Weryfikuj

- Uruchom testy projektu. Zawsze, gdy repo je ma — znajdź komendę w konfiguracji
  repo. Podaj komendę i jej wynik. Potwierdź, że każdy zmieniony plik nadal się
  parsuje lub kompiluje.
- Uruchom formatter i linter projektu, jeśli je ma, w trybie sprawdzania, nie
  zapisu (check / dry-run). Zapis przepisałby linie spoza wyniku. Zgłoszenie na
  linii wyniku: napraw. Zgłoszenie na linii spoza wyniku: zostaw i powiedz.
- Nieudane sprawdzenie: napraw je lub cofnij ten wynik. Nigdy nie zgłaszaj pracy
  jako gotowej z niezaliczonym sprawdzeniem.
