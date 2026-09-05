---
name: shape
description: >
  Przegląd zmian git lub wskazanej ścieżki pod kątem organizacji kodu:
  jednostki, które nie zasługują na istnienie, zduplikowana logika, kod w złym
  miejscu, odstępstwa od wzorców repo. Użyj dla "shape", "architecture
  review", overengineeringu lub duplikacji.
argument-hint: "[base ref | path]"
---

# Shape

Przegląd zakresu pod kątem organizacji kodu. Najpierw raport, potem zastosuj
wyniki wybrane przez użytkownika. Ocenia, gdzie kod leży i jak jest pocięty —
nie co mówią linie ani jak są napisane.

Przed startem wczytaj `~/.claude/skills/_shared/report.md`. Obowiązuje w całości
poza sekcją Blok diff — wynik shape nie ma diffa. Poniżej tylko to, co własne
dla tego skilla.

## Granica wobec innych przeglądów

Wynik, który jest lokalnym przepisaniem jednego wyrażenia, należy do /polish.
Nie zgłaszaj go tutaj.

## 1. Ustal zakres

Ten skill ocenia całe pliki. Diff tylko wskazuje które. Zakres wg pliku
wspólnego, z jedną różnicą: każdy plik dotknięty przez diff lub leżący pod
ścieżką wchodzi w całości. Czytaj i oceniaj całą treść każdego pliku. Nigdy nie
ograniczaj wyniku do zmienionych linii.

Każdy wynik nadal wskazuje plik w zakresie. Proponowana zmiana może dotknąć
dowolnego pliku w repo.

## 2. Czytaj repo, oceniaj zakres

Zakres mówi, co oceniasz. Nie mówi, co czytasz. Z samego zakresu nie da się
stwierdzić, czy jednostka zasługuje na istnienie ani czy plik odstaje od wzorca.

Zanim cokolwiek ocenisz, zbuduj brief wzorców:

- Jak repo jest podzielone — katalogi, warstwy, jaki rodzaj rzeczy gdzie leży.
- Jak repo robi ten rodzaj zadania w miejscach, które już go robią.
- W którą stronę wskazują zależności między warstwami.
- Jak porównywalne pliki są zorganizowane w środku — kolejność składników,
  grupowanie, znaczniki sekcji.

### Ogranicz czytanie

Czytaj pliki porównywalne z tymi w zakresie: ten sam rodzaj, katalog, warstwa,
zadanie. Nie czytaj całego drzewa.

Zatrzymaj się, gdy masz trzy przykłady wzorca. Trzy go dowodzą (sekcja 4), a
czwarty niczego nie uczy.

### Duże zakresy

Gdy zakres ma więcej niż około 15 plików, podziel pracę. Daj każdemu subagentowi
wycinek plików, zbudowany brief wzorców i reguły sekcji 3 i 4. Poproś każdego o
wyniki w formacie raportu z sekcji 6.

Potem scal raporty samodzielnie. Przenumeruj w jedną sekwencję, odrzuć wynik
znaleziony przez dwa wycinki i przepuść sekcję Konflikty pliku wspólnego przez
scaloną listę. Subagenci nie widzą się nawzajem, więc tylko ty wyłapiesz
konflikt między dwoma wycinkami.

## 3. Zbuduj wyniki

Osiem kategorii. Każdy wynik dostaje dokładnie jedną.

### overengineering

Jednostka, która nie zasługuje na istnienie: klasa z jedną metodą i jednym
wołającym, wrapper, który tylko przekazuje, interfejs z jedną implementacją,
warstwa, która dodaje skok i nic więcej, abstrakcja zbudowana pod drugi
przypadek, którego nie ma.

Policz wołających i podaj liczbę w wyniku. Liczba niesprawdzona to nie liczba.

Zanim zgłosisz, poszukaj powodu istnienia jednostki. Przeszukaj repo pod kątem
drugiej implementacji, testu, który ją podmienia, frameworka, który wymaga tego
kształtu, i punktu rejestracji lub pluginu, który potrzebuje tego szwu. Jeśli
znajdziesz, to nie overengineering. Jeśli szukano i nic nie znaleziono, powiedz,
czego szukano.

### duplication

Kod robi ponownie to, co repo już robi gdzie indziej: helper powtarzający
istniejący helper, reguła zaimplementowana dwa razy, stała zadeklarowana w dwóch
miejscach.

Wskaż istniejący z plikiem i linią i powiedz, jak blisko są — identyczne,
bliskie lub ta sama intencja.

Nie zgłaszaj dwóch rzeczy, które tylko wyglądają podobnie. Jeśli obie będą się
zmieniać z różnych powodów, podobieństwo jest przypadkiem, a scalenie sprzęga
kod, który musi zostać osobno.

### boundary

Podział, który tnie jedną odpowiedzialność na kawałki zmieniające się razem, lub
jednostka, która łączy dwie odpowiedzialności zmieniające się z różnych powodów.

### placement

Kod działa, ale leży w złym pliku, module lub katalogu — takim, którego nazwa
lub warstwa go nie opisuje.

### dependency

Jednostka sięga przez granicę, którą repo utrzymuje: niższa warstwa importuje
wyższą, nowa zależność wskazuje przeciwnie do kierunku reszty repo, moduł
ciągnie coś, czego żaden z jego sąsiadów nie ciągnie.

### deviation

Struktura odstaje od tego, jak repo robi ten sam rodzaj rzeczy w innych plikach:
jak podpina, jak nazywa i dzieli jednostki, gdzie kładzie ten rodzaj kodu.

### layout

Organizacja wewnątrz jednego pliku odstaje od porównywalnych plików w repo:
kolejność składników, grupowanie, znaczniki sekcji, co plik trzyma.

Wynik layout może proponować dodanie komentarza, który repo utrzymuje z
konwencji — znacznik sekcji jak `// Cleanup`. Nie proponuj takiego, który tylko
powtarza kod; to walczy z /clarify. Zgłoś go z flagą ✗ i powiedz, że sama
konwencja jest wątpliwa.

### redesign

Kierunek, nie przeniesienie: kształt, który lepiej służyłby temu kodowi, za duży
na jedną zmianę. Zgłoś go. Użytkownik zbiera takie i wraca do nich później.

Reguły wyniku redesign:

- Zawsze flaga ✗. Nigdy nie jest rekomendowany, choćby pomysł był świetny.
- Podaj, co daje i co kosztuje, po jednej linii. Pomysł bez kosztu to nie
  propozycja.
- "recommended" nigdy go nie stosuje, bo nigdy nie jest ✓. "all" go stosuje — to
  wynik jak każdy inny.

## 4. Reguła dowodu (WYMAGANA)

Wyniki `deviation`, `layout` i `dependency` twierdzą, że repo utrzymuje wzorzec.
Każdy MUSI wskazać miejsca, które go ustanawiają, i ich liczbę. Wzorzec to to,
co repo robi raz za razem. Jeden inny przykład to przypadek.

- Mniej niż trzy inne miejsca → odrzuć wynik.
- Chyba że repo ma łącznie mniej niż trzy porównywalne miejsca. Wtedy podaj
  łączną liczbę i zgłoś wynik z pewnością L.
- Nigdy nie pisz "repo zwykle robi X" bez nazwania plików.

Wynik `duplication` musi wskazać istniejącą implementację z plikiem i linią.
Opis nie wystarczy.

Wyniki `overengineering`, `boundary` i `placement` nie potrzebują wzorca, ale
potrzebują szukania kontrprzypadku z sekcji 3.

## 5. Oceń i oflaguj

Poza regułami wspólnymi:

- Konflikt dwóch wyników proponujących inne miejsce dla tego samego kodu →
  zostaw lepszy, odrzuć drugi.
- Struktura to miejsce, gdzie pewny siebie strzał szkodzi najbardziej. Gdy powód
  obecnego kształtu nie jest widoczny, to L i ✗, nie H.
- Każdy wynik `redesign` to ✗.

## 6. Raport (jeszcze nie koduj)

Wydaj werdykt dla KAŻDEGO pliku w zakresie, w kolejności plików — czyste też.
Przed pierwszym plikiem podaj w jednej linii liczbę plików i liczbę wyników.

Lista werdyktów idzie pierwsza: jedna linia na plik, ścieżka i werdykt, dla
każdego pliku w zakresie. Wyniki drukuj po niej, nigdy pogrupowane pod ścieżką
pliku. Nagłówek wyniku niesie ścieżkę, więc nic nie stoi między numerem a
nagłówkiem.

Na wynik:

    **N. [category][H|M|L][✓|✗] <ścieżka od korzenia repo>:linia — krótki tytuł**
    ========== move ==========
    `obecne` → `proponowane`
    ========== why ==========
    <jedna linia>
    ========== pattern ==========
    <deviation, layout, dependency: pliki, które go ustanawiają + liczba>
    ========== scope ==========
    <dotknięte pliki + safe/risky>

Wynik `redesign` ma inne ciało: pole `idea` zamiast `move`, potem `buys` i
`costs` zamiast `why`. Każde ma własny baner.

Numeruj wyniki w jednej sekwencji, w kolejności plików w zakresie, żeby
użytkownik mógł wybrać `7,12`.

Kategoria w tagu: `overengineering`, `duplication`, `boundary`, `placement`,
`dependency`, `deviation`, `layout` lub `redesign`.

Reguły własne pola `move`:

- Owiń każdą stronę w backticki. Terminal koloruje obie strony i zostawia
  strzałkę zwykłą. Nigdy nie drukuj backticków jako tekstu.
- Między stronami użyj zwykłego `→`.
- Lewa strona nazywa, co się przenosi. Prawa nazywa, gdzie ląduje — plik,
  jednostkę lub pozycję. Przy inline prawa strona to jednostka, która wchłania.
- Trzymaj pole `move` w jednej linii. Bez bloków diff; przeniesienie w diffie
  czyta się jak szum.

## 7. Zastosuj wybrane

Poza regułami wspólnymi:

- Zastosuj wszystkie w jednym przebiegu. Wynik zostaje niezacommitowany do
  przeczytania przez użytkownika.
- Edytuj każdy plik, którego zmiana wymaga, w zakresie lub poza nim. Zakres
  wybiera, co oceniasz, nie co wolno dotknąć.
- Przenoś plik przez `git mv`, żeby historia szła za nim.
- Przeniesienie to nie licencja na przepisanie: przenoszone linie zachowują
  treść.
- Po przeniesieniu lub inline przeszukaj całe repo pod kątem starej lokalizacji
  i potwierdź, że nie została żadna referencja.
- Jeśli wynik okaże się niewykonalny jak zaproponowano — zepsułby build lub
  wymaga redesignu, którego nie zgłoszono — cofnij ten jeden wynik, dokończ
  resztę i powiedz, który odrzucono i dlaczego.
