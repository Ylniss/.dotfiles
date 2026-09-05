---
name: polish
description: >
  Przegląd zmian git lub wskazanej ścieżki pod kątem uproszczeń, optymalizacji
  i nowoczesnego użycia bibliotek. Użyj dla "polish", "review my changes" lub
  pytania, co da się uprościć lub unowocześnić. Nie szuka bugów — to
  code-review.
argument-hint: "[base ref | path]"
---

# Polish

Przegląd zakresu pod kątem jakości i modernizacji. Najpierw raport, potem
zastosuj wyniki wybrane przez użytkownika. NIE szuka bugów (od tego jest
/code-review) i NIE stosuje automatycznie (w odróżnieniu od /simplify).

Przed startem wczytaj `~/.claude/skills/_shared/report.md`. Obowiązuje w
całości: zakres, konflikty, ocena, format raportu, apply, weryfikacja. Poniżej
tylko to, co własne dla tego skilla.

## Granica wobec innych przeglądów

Wynik, który przenosi kod, dzieli jednostkę lub łączy dwie, to /shape. Wynik,
który tylko zmienia nazwę lub przepisuje komentarz, to /clarify. Żadnego z nich
tu nie zgłaszaj.

## 1. Sprawdź nowoczesne wzorce przez context7 (WYMAGANE)

context7 jest obowiązkowy, gdy zakres dotyka zewnętrznej biblioteki lub
frameworka. Nigdy nie oceniaj "nowoczesnego użycia" z pamięci — dane treningowe
są w tyle za realnymi API.

- Wypisz każdą zewnętrzną bibliotekę/framework w zakresie
  (importy/`using`/`require`) z wersją z lockfile/manifestu (package.json,
  *.csproj, Cargo.toml, go.mod itd.).
- Dla każdej pobierz aktualne docs narzędziami MCP context7:
  `resolve-library-id` (nazwa biblioteki + pytanie), potem `query-docs` z
  wybranym ID — dla konkretnej wersji, gdy jest znana.
- Twarda reguła: każdy wynik "modern-pattern" MUSI cytować, co zwrócił context7.
  Jeśli context7 nie ma docs lub nie wspiera sugestii, odrzuć wynik — nie
  twierdź z pamięci.
- Zweryfikuj, że sugerowane API istnieje w zainstalowanej wersji, zanim je
  zgłosisz. Żadnego halucynowanego "po prostu użyj X".
- Jedyny wyjątek: jeśli zakres nie dotyka zewnętrznej biblioteki, nie ma o co
  pytać — powiedz to i pomiń. Sprawdzenia simplify/optimize nadal biegną.

## 2. Zbuduj wyniki

Szukaj, w kolejności priorytetu:
1. Realne uproszczenie — zwiń zbędną złożoność, usuń redundancję, zdeduplikuj
   powtórzoną logikę.
2. Optymalizacja — tylko gdy mierzalnie ma znaczenie; podaj oszczędzany koszt.
3. Nowoczesne wzorce bibliotek — zastąp przestarzałe użycie aktualnym idiomem,
   który biblioteka teraz zaleca (poparte context7).

Trzymaj się zmian wewnątrz oglądanych linii.

Stosuj też własne reguły stylu użytkownika jako kryteria przeglądu. Czytaj je z
globalnego CLAUDE.md, nie z pamięci — są źródłem prawdy i się zmieniają. Nie
powtarzaj ich tutaj.

## 3. Oceń i oflaguj

Poza regułami wspólnymi: szereguj wg wpływu — jasne zyski najpierw,
subiektywny/opcjonalny szlif na końcu.

## 4. Raport (jeszcze nie koduj)

Na wynik: linia nagłówka, blok diff, potem baner na każde pole:

    **N. [category][H|M|L][✓|✗] krótki tytuł**
    ```diff
    @@ <ścieżka od korzenia repo>:linia @@
    - <obecny kod>
    + <proponowany kod>
    ```
    ========== why ==========
    <jedna linia>
    ========== docs ==========
    <co zwrócił context7 — tylko wyniki modern-pattern>

Kategoria w tagu: `simplification`, `optimization` lub `modern-pattern`.

Pole `docs` jest wymagane dla każdego wyniku `modern-pattern`. Podaj ID
biblioteki i konkretną rzecz zwróconą przez context7, która popiera zmianę.
Wynik modern-pattern bez tego nie nadaje się do zgłoszenia — odrzuć go. Dla
dwóch pozostałych kategorii pomiń baner `docs`.

Klasy pominięć w zakończeniu, przykłady: "pliki generowane", "wywołania już w
aktualnym idiomie", "gorące pętle już zmierzone".
