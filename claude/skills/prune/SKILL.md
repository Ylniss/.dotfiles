---
name: prune
description: >
  Wytnij z CLAUDE.md, AGENTS.md lub SKILL.md to, co nie zasługuje na miejsce,
  potem skompresuj resztę. Użyj dla "prune", "trim this file" lub "what here
  is unnecessary".
argument-hint: "[path]"
---

# Prune

Przegląd pliku kontekstu. Najpierw raport, potem zastosuj wyniki wybrane przez
użytkownika. Dwie operacje: **cut** (treść opuszcza ten plik — usunięta lub
przeniesiona) i **compress** (te same fakty, mniej słów).

## Granica wobec innych przeglądów

- /shorten kompresuje dowolny tekst, zachowując każdy fakt. Nigdy żadnego nie
  usuwa.
- /prune decyduje, które fakty w ogóle należą do *tego* pliku, potem kompresuje
  resztę.
- /shape, /polish, /clarify przeglądają kod, nie pliki kontekstu.

## 1. Ustal zakres

- **Brak argumentu** — `CLAUDE.md` w korzeniu repo plus każdy zagnieżdżony
  `CLAUDE.md` / `AGENTS.md`.
- **Ścieżka** — ten plik: plik kontekstu, `SKILL.md` lub plik referencyjny
  skilla.

Wymień pliki i ich rodzaj w jednej linii. Jeśli żaden nie istnieje, powiedz to i
zatrzymaj się.

## 2. Test i poprzeczka

Jedno pytanie do każdej linii: **gdyby zniknęła, czy sesja zrobiłaby coś
inaczej?** Nie "czy prawdziwa", nie "czy dobrze napisana" — czy praca by się
zmieniła. Prawdziwa, dobrze napisana linia, która nic nie zmienia, to właśnie to
usuwa ten skill.

Siła nacisku zależy od częstości ładowania pliku:

| Plik | Ładuje się | Poprzeczka |
|---|---|---|
| `CLAUDE.md`, `AGENTS.md` | każda sesja | najwyższa — musi zmieniać niezwiązaną pracę |
| Treść `SKILL.md` | tylko sesje z tym zadaniem | średnia — musi zmieniać *to* zadanie |
| Plik referencyjny | tylko gdy treść tam odsyła | najniższa — szczegół należy tutaj |

Stąd reguła kierunku: **treść płynie ku plikowi, który ładuje się rzadziej.**
`SKILL.md` powtarzający `CLAUDE.md` to problem skilla; `CLAUDE.md` powtarzający
`SKILL.md` to problem `CLAUDE.md`. Szczegół, którego skill potrzebuje tylko przy
niektórych wywołaniach, należy do jego pliku referencyjnego, nie do treści.

## 3. Najpierw zmierz

Wydrukuj liczbę bajtów na element, malejąco, zanim cokolwiek ocenisz. Tłuszcz
skupia się w kilku liniach, a liczenie znajduje je szybciej niż czytanie. Dla
listy punktowanej:

```bash
awk '/^- \*\*/ {n=$0; sub(/^- \*\*/,"",n); sub(/\*\*.*/,"",n); printf "%5d  %s\n", length($0), n}' FILE | sort -rn
```

## 4. Kategorie cięć

Każdy wynik cut dostaje dokładnie jedną.

### discoverable

Widoczne z drzewa plików, pliku konfiguracji lub manifestu, albo jednego grepa —
listing katalogu przepisany prozą. Nazwy projektów, `.editorconfig`, nazwy
plików w folderze, którego nazwa już mówi, co trzyma.

**Dowód:** podaj komendę, która to ujawnia, i uruchom ją.

### duplicate

Fakt już dociera do sesji inną drogą: plikiem, który ładuje się częściej (sekcja
2), skillem ładowanym na żądanie, schematem narzędzia lub inną linią tego samego
pliku.

Streszczenie duplikujące szczegółowe źródło staje się pułapką nieaktualności w
chwili rozjazdu — tabela z trzema, gdy źródło wymienia już sześć. Wytnij; nie
naprawiaj.

**Dowód:** podaj drugą lokalizację i otwórz ją. "Skill pewnie to pokrywa" to nie
dowód — przeczytaj i potwierdź, że fakt naprawdę tam jest.

### inconsequential

Prawdziwe, nie zduplikowane, a nadal nic nie zmienia. Fallbacki, które i tak by
się znalazło, wskaźnik na już kompletną listę, wykluczenie, którego nikt by
inaczej nie założył.

**Dowód:** powiedz, co zrobiono by z tą linią, i pokaż, że to samo co bez niej.

### belongs-elsewhere

Dobra treść, zły plik. Szczegół w treści `SKILL.md`, potrzebny tylko niektórym
wywołaniom → jego plik referencyjny. Reguła w `CLAUDE.md`, potrzebna tylko
jednemu zadaniu → skill tego zadania. Prawda o całym projekcie powtórzona w
skillu → usuń, `CLAUDE.md` już ją niesie.

Proponowana zmiana to przeniesienie. Podaj plik docelowy.

### too-local

*Tylko pliki zawsze ładowane.* Jedna funkcja, mechanika lub podsystem opisany w
sekcji o całym projekcie. Test: **czy to zmieniłoby podejście do _niezwiązanego_
zadania?** Model tur lub stos warstwy wejścia kształtuje każdą zmianę i zostaje;
podział folderu jednej mechaniki nie — zadanie, które jej dotyka, i tak skanuje
te pliki.

W `SKILL.md` lokalność jest celem. Nigdy nie podnoś tego tam.

### enumeration

Lista, gdzie reguła jest krótsza *i* poprawniejsza. Lista sześciu miejsc, które
muszą być po angielsku, pomija siódme; "wszystko, co zapisane" pokrywa je
wszystkie w trzech słowach. Wybieraj regułę, ilekroć lista jest jej instancją.

## 5. Co zostawić (sprawdź przed cięciem)

Nie wycinaj żadnej z poniższych, choćby była długa:

- **Strażnik cichej porażki** — błąd, któremu zapobiega, pada po cichu. "Nowy
  asset wymaga wpisu w manifeście" zapobiega assetowi, który nigdy się nie
  ładuje i nigdy nie ostrzega.
- **Nieoczywisty przepływ działania lub sterowania** — kolejność startu, co
  pauzuje pętlę, jaka jest kolejność dispatchu. Nie do wywnioskowania z nazw.
- **Dlaczego za zaskakującym ograniczeniem** — czemu projekt jest wyłączony z
  builda, czemu wywołanie blokuje zamiast await. Bez tego ograniczenie wygląda
  jak bug i zostaje "naprawione".
- **Routing przez granice** — wspólny kontrakt w trzecim projekcie, folder poza
  oczywistym drzewem.
- **Reguła decyzji między dwoma kształtami** — kiedy A, a kiedy B. Tu sesja bez
  wskazówek myli się najczęściej.
- **Przykład blokujący zły kształt** (tylko `SKILL.md`) — skill zasługuje na
  przykład, na który `CLAUDE.md` nie może sobie pozwolić.

Długość nie jest kryterium. Najdłuższy element często najbardziej zasługuje na
miejsce.

## 6. Wyniki compress

Do tego, co przetrwa, zastosuj techniki /shorten: scal zdania składowe, usuń
wypełniacze, forma rozkazująca, symbole (`→`, `=`, `—`), reguła zamiast listy.
**Zero utraty informacji** — wynik compress, który gubi fakt, jest wynikiem cut
i musi być tak zgłoszony.

## 7. Rozwiąż konflikty

- Dwa wyniki na tej samej linii → zostaw lepszy.
- Wynik compress na linii, którą inny wynik wycina → odrzuć compress.
- Każdy wynik musi dać się zastosować sam, w dowolnej kolejności.

## 8. Oceń i oflaguj

- Pewność: H / M / L. Flaga rekomendacji: `✓`, gdy zastosowanie nie budzi
  wątpliwości.
- Oflaguj `✗`, gdy cięcie opiera się na skillu, którego wyzwalania nie dało się
  potwierdzić, gdy linia strzeże czegoś, czego nie da się zweryfikować, lub gdy
  to gust.
- Jeśli nic nie wymaga zmiany, powiedz to i zatrzymaj się. Nie wymyślaj wyniku.

## 9. Raport (jeszcze nie edytuj)

Dwie literowane sekcje, żeby użytkownik mógł wziąć jedną bez drugiej: **A. Cut**
(treść opuszcza plik), **B. Compress** (nic nie opuszcza). Numeruj wewnątrz
każdej: `A1`, `A2`, `B1`. Przed pierwszym wynikiem podaj w jednej linii pliki,
liczbę wyników i obecny rozmiar.

Na wynik:

    **A1. [category][H|M|L][✓|✗] krótki tytuł**
    ```diff
    @@ <ścieżka>:linia @@
    - <obecny tekst>
    + <proponowany tekst, lub nic przy usunięciu>
    ```
    ========== why ==========
    <jedna linia: co się zmieni, gdy zniknie>
    ========== proof ==========
    <uruchomiona komenda, otwarty plik, lokalizacja, która już to trzyma>
    ========== saves ==========
    <bajty, a przy przeniesieniu plik docelowy>

Tagi, banery i słowa wyboru wg `~/.claude/skills/_shared/report.md` (sekcje Tagi
nagłówka, Format ciała, Słowa wyboru). Reszta tego pliku dotyczy kodu, nie
plików kontekstu.

`proof` jest wymagany dla `discoverable`, `duplicate` i `inconsequential`. Bez
niego odrzuć wynik. Wyniki compress nie potrzebują `proof`.

Po ostatnim wyniku wypisz, co przejrzano i celowo zostawiono, po jednej linii, z
nazwą reguły z sekcji 5, która to uratowała. Ta połowa dowodzi, że przegląd był
agresywny, a nie destrukcyjny.

Zakończ: "Which to apply? (e.g. A1,B2 / all / recommended / none)"

## 10. Zastosuj wybrane

- Zrób dokładnie proponowaną zmianę. Nie formatuj sąsiednich linii.
- Zachowaj końce linii, znak wcięcia i końcowy newline pliku.
- Przy przeniesieniu zapisz treść w pliku docelowym, zanim usuniesz ją tutaj.
- Po cięciu przeczytaj sekcję ponownie: jeden pozostały element lub akapit,
  który tylko wprowadzał wyciętą linię, wymaga tego samego osądu.

## 11. Weryfikuj

- Przeczytaj plik od góry do dołu. Musi stać sam dla sesji, która nigdy nie
  widziała tej rozmowy. `SKILL.md` musi nadal wykonać swoje zadanie bez
  wyciętych linii.
- Podaj rozmiar przed i po, z procentem.
- Powiedz wprost, które fakty żyją teraz **tylko** w skillu lub pliku
  referencyjnym, i że docierają do sesji tylko, dopóki ten skill się wyzwala, a
  treść wskazuje na tę referencję. To jedyny sposób, w jaki ten skill może po
  cichu pogorszyć sprawę.
