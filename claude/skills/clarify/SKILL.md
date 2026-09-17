---
name: clarify
description: >
  Przegląd zmian git lub wskazanej ścieżki pod kątem esencji komentarzy i
  bezpośredniości nazw. Użyj dla "clarify", zwięźlejszych komentarzy lub
  lepszego nazewnictwa.
argument-hint: "[base ref | path]"
---

# Clarify

Przegląd zakresu pod kątem jasnych komentarzy i bezpośrednich nazw. Najpierw
raport, potem zastosuj wyniki wybrane przez użytkownika. Tylko jakość — bez
zmian logiki.

Przed startem wczytaj `~/.claude/skills/_shared/report.md`. Obowiązuje w
całości: zakres, konflikty, ocena, format raportu, apply, weryfikacja. Poniżej
tylko to, co własne dla tego skilla.

Jednostką zakresu jest deklaracja, nie linia: gdy diff dotyka sygnatury, ciała
lub komentarza funkcji, klasy albo pola, oceń jej nazwę i cały komentarz.

## Granica wobec innych przeglądów

Wynik, który przepisuje logikę, to /polish. Wynik, który przenosi kod, dzieli
jednostkę lub łączy dwie, to /shape. Żadnego z nich tu nie zgłaszaj.

## 1. Przejrzyj komentarze

Cel: mało komentarzy, a każdy to sama esencja — jeden fakt, proste słowa,
wprost, zrozumiały bez wysiłku.

Oceń KAŻDY komentarz w zakresie — nie próbkuj, nie wybieraj. Każdy komentarz
dostaje jeden werdykt: zostaw / skróć / przeredaguj / usuń. Agresywne pokrycie,
wybiórcze edycje — zgłaszaj tylko to, co wymaga zmiany.

Domyślny werdykt to USUŃ. Komentarz musi zasłużyć na miejsce: zostaje tylko,
gdy bez niego czytelnik popełni błąd albo straci czas na odtworzenie tej
informacji z kodu. Komentarz prawdziwy, ale drugorzędny, też usuń.

Stosuj w tej kolejności — najpierw pytaj "usunąć?", potem "skrócić?", na końcu
"przeredagować?":

1. Usuń:
   - Komentarz, który tylko powtarza to, co mówi kod. Nie skracaj go — usuń.
     Zbędny komentarz jest gorszy niż żaden.
   - Komentarz zbędny wobec nazwy. Jasna nazwa (klasy, metody, zmiennej) plus
     oczywiste ciało często mówią wszystko, co komentarz. Test zasłonięcia:
     zakryj komentarz — czy czytelnik nadal rozumie, co się dzieje, z samej
     nazwy i kodu? Jeśli tak, usuń. (Sprawdź też miejsce użycia: jeśli
     DLACZEGO stoi już tam, gdzie rzecz jest podpięta, definicja nie musi tego
     powtarzać.) Wybieraj jaśniejszą nazwę zamiast zachowania komentarza.
   - Komentarz, który nie przechodzi testu wartości z góry.
2. Skróć:
   - Jeden fakt na komentarz. Tnij nawiasy, wyliczenia przypadków, przykłady,
     odsyłacze do innych komentarzy i docs oraz informacje poboczne.
   - Limit: jedna linia. Dwie tylko dla nieoczywistego DLACZEGO, którego nie da
     się skrócić. Dłuższy komentarz to zawsze wynik.
3. Przeredaguj:
   - Prosty język — zastąp żargon, wewnętrzne skróty i slang domenowy
     codziennymi słowami (np. "flake the suite" → "break the tests"). Zachowaj
     sens; zmień tylko słownictwo. Słowo domeny to nazwa z kodu lub pojęcie
     zdefiniowane w docs repo; słowo żyjące tylko w komentarzach ("nestles",
     "crowd-part") to żargon.
   - Test zimnego czytelnika: z samej nazwy i komentarza, bez ciała, wiesz, co
     jednostka zwraca, co zmienia i kiedy się poddaje? Jeśli nie, najpierw
     popraw nazwę. Komentarz tylko skróć lub przeredaguj.
   - Przeredagowanie nigdy nie wydłuża: nowy tekst jest krótszy od starego. Nie
     dopisuj brakujących informacji.

NIE ruszaj:

- Komentarzy TODO i nagłówków licencyjnych/prawnych.
- Kontraktu publicznego API — ale tylko informacji, której nie widać w
  sygnaturze: znaczenie null, jednostki, rzucane wyjątki. Doc prywatnej
  składowej i doc, który streszcza ciało, to nie kontrakt.
- Nieoczywistego DLACZEGO — ale tylko samego DLACZEGO. Resztę tego komentarza
  tnij jak każdy inny.

Testy: komentarz zostaje, gdy wyjaśnia liczby z asercji albo opisuje przypadek
testu parametryzowanego (np. wiersz `[InlineData]` przy `[Theory]`). Resztę mówi
nazwa testu — usuń.

### Gęstość

Porównaj gęstość komentarzy każdego pliku w zakresie z 3 sąsiednimi plikami tego
samego rodzaju. Plik wyraźnie gęstszy dostaje osobny wynik `comment` z listą
najsłabszych komentarzy do usunięcia.

## 2. Przejrzyj nazwy

Cel: bez wysiłku wiadomo, co nazwa reprezentuje. Wprost i jednoznacznie — NIE
tylko dłużej.

Oceń KAŻDĄ nazwę zadeklarowaną w zakresie — nie próbkuj, nie wybieraj. Czyli
wszystkie: zmienne lokalne, pola, właściwości, parametry, stałe, funkcje,
metody, klasy, typy, interfejsy, enumy i ich elementy, moduły i pliki. Każda
nazwa dostaje jeden werdykt: zostaw / zmień. Zgłoś każdą zmianę nazwy; nie
zgłaszaj nazw, które zostają. Agresywne pokrycie, wybiórcze edycje.

### Oceniaj w kontekście, nie na linii deklaracji

Zanim ocenisz nazwę, przeczytaj, jak jest używana:

- Przeczytaj miejsca użycia. Nazwa jest zła, gdy to, co tam trzyma lub robi, nie
  zgadza się z tym, co mówi.
- Przeczytaj wartość, jaką przyjmuje. Nazwa, która mówi mniej (lub więcej) niż
  niesie wartość, to zmiana nazwy.
- Sprawdź zasięg i czas życia. Krótka nazwa jest w porządku w trzyliniowym
  bloku, a za mglista na poziomie pliku lub publicznym.
- Sprawdź sąsiadów. Nazwa nie może pokrywać się znaczeniem z inną nazwą w tym
  samym typie, funkcji lub liście parametrów.
- Sprawdź słownictwo wołającego. Użyj słowa, którym otaczający kod i domena już
  nazywają to pojęcie.

### Zmień nazwę, gdy jest

- Myląca — sugeruje coś innego. Najwyższy priorytet; gorsza niż mglista.
- Mglista — za krótka lub zbyt ogólna, by nieść znaczenie (`d`, `tmp`, `data`,
  `mgr`).
- Obrazowa — metafora zamiast tego, co jednostka zwraca lub zmienia
  (`Accommodate`, `Nestle`).
- Rozwlekła — dłuższa niż trzeba, bez zysku na jasności.
- Niespójna — inne słowo na pojęcie, które otaczający kod już nazywa.
- Do pobicia — istnieje lepsze słowo, które usuwa wysiłek umysłowy. Zgłoś to
  nawet, gdy obecna nazwa nie jest zła. Nie zatrzymuj się na "akceptowalnej";
  jeśli da się ująć lepiej, zaproponuj i zostaw decyzję użytkownikowi.

### Ograniczenia

- Trzymaj się konwencji nazewnictwa z otaczającego kodu.
- Przy każdej zmianie nazwy podaj zasięg rażenia: ile referencji dotyka i czy
  przekracza granicę pliku lub publiczną/eksportowaną (safe vs risky).
- Jeśli zmiana nazwy czyni pobliski komentarz zbędnym, też to zaznacz.

## 3. Oceń i oflaguj

Poza regułami wspólnymi: flaga rekomendacji hamuje regułę "Do pobicia". Zgłoś
marginalną zmianę nazwy, ale oflaguj ✗. Nigdy nie pompuj listy ✓, żeby wyglądać
na dokładnego.

## 4. Raport (jeszcze nie koduj)

Wyniki w jednej numerowanej sekwencji, w kolejności plików w zakresie, żeby
użytkownik mógł wybrać `7,12`. Przed pierwszym wynikiem podaj w jednej linii
liczbę wyników i liczbę plików.

Na wynik: linia nagłówka, blok diff, potem baner na każde pole:

    **N. [comment|name][H|M|L][✓|✗] krótki tytuł**
    ```diff
    @@ <ścieżka od korzenia repo>:linia @@
    - <obecny kod>
    + <proponowany kod>
    ```
    ========== why ==========
    <jedna linia>
    ========== scope ==========
    <tylko dla zmian nazw: liczba referencji + safe/risky>

Kategoria w tagu: `comment` lub `name`.

Reguły własne:

- Dla usuwanego komentarza pisz tylko linie `-`.
- Usunięcia zgłaszaj zbiorczo: jeden wynik "usuń N komentarzy" na plik, z
  blokiem diff samych linii `-` (hunk na każde miejsce). Skrócenie i
  przeredagowanie to nadal osobne wyniki.
- Dla zmiany nazwy pokaż tylko linię deklaracji. Pole `scope` niesie pozostałe
  referencje; nigdy nie wypisuj ich jako linii diff.

Klasy pominięć w zakończeniu, przykłady: "banery sekcji", "aliasy modułów
bibliotek", "słownictwo domeny: bufnr, lnum".

## 5. Zastosuj wybrane

Poza regułami wspólnymi: przy zmianie nazwy zaktualizuj każdą referencję w
zakresie. Potem przeszukaj cały zakres pod kątem starej nazwy i potwierdź zero
trafień.
