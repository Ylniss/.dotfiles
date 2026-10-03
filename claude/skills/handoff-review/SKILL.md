---
name: handoff-review
description: >
  Przegląd handoffu zapisanego po sesji projektowej wobec bieżącej sesji:
  znajduje pominięte decyzje i ślady decyzji, które później nadpisano. Użyj,
  gdy użytkownik wywołuje "/handoff-review [plik]" lub prosi o sprawdzenie, czy
  handoff czegoś nie zgubił.
argument-hint: "[plik handoffu]"
---

# Handoff review

Porównaj zapisany handoff z sesją, która go wytworzyła. Dwa cele, równie ważne:

- nic ważnego z sesji nie zostało pominięte,
- nic w handoffie nie jest wcześniejszą wersją decyzji, którą potem zmieniono.

Późniejsza decyzja zawsze nadpisuje wcześniejszą. Nigdy odwrotnie.

Pewne poprawki stosuj od razu i zgłoś, co zmieniono. O niepewne zapytaj i nie
edytuj przed odpowiedzią. Skill edytuje handoff i pliki notatek zapisane razem
z nim, i nic więcej — nigdy kodu.

Przed raportem wczytaj `~/.claude/skills/_shared/report.md`. Obowiązują z niego
tylko sekcje Tagi nagłówka i Format ciała.

## 1. Sprawdź, czy sesja jest w kontekście

Źródłem prawdy jest rozmowa, nie handoff. Skill działa tylko w sesji, która
handoff napisała.

- Sesja była kompaktowana lub jej początek jest streszczeniem — powiedz to
  przed raportem. Decyzje znane tylko ze streszczenia dostają pewność
  najwyżej M.
- Sesji projektowej nie ma w kontekście — powiedz to i zatrzymaj się. Bez niej
  nie ma z czym porównać.

## 2. Wybierz handoff

- **Podano argument** — rozwiąż go jako ścieżkę lub slug.
- **Brak argumentu** — handoff zapisany w tej sesji. Gdy było ich kilka,
  zapytaj, który.

Przeczytaj plik z dysku, w całości. Nie polegaj na tym, co pamiętasz z zapisu:
plik mógł być potem edytowany.

Przeczytaj też pliki notatek zapisane w tej sesji razem z handoffem. Ta sama
decyzja musi brzmieć w nich tak samo.

## 3. Zbuduj rejestr decyzji (WYMAGANE)

Przejdź sesję od pierwszej wiadomości do ostatniej, po kolei. Nie skacz i nie
próbkuj. Dla każdego tematu zanotuj każdą wypowiedź, która go dotyczy, w
kolejności, w jakiej padła:

- pomysł wyjściowy użytkownika,
- propozycja asystenta i odpowiedź na nią,
- wartość domyślna, którą asystent ustawił sam,
- poprawka, cofnięcie, doprecyzowanie,
- fakt sprawdzony w repo, który zmienił ustalenie.

Stan końcowy tematu to ostatnie słowo w nim. Reguły rozstrzygania:

- Późniejsze nadpisuje wcześniejsze, także wtedy, gdy wcześniejsze było
  wyraźniej sformułowane lub dłużej omawiane.
- Wypowiedź użytkownika bije propozycję asystenta.
- Propozycja bez odpowiedzi nie jest decyzją. Zbiorcze "reszta ok" zatwierdza
  wszystko, co było wtedy na stole.
- Decyzję może unieważnić fakt: sprawdzenie repo, które pokazało, że założenie
  było błędne. Liczy się stan po sprawdzeniu.
- Decyzję może unieważnić inna decyzja, o innym temacie. Reguła ogólna przyjęta
  później kasuje wcześniejsze wyjątki od niej. Zmiana liczby kasuje wszystko,
  co z tej liczby wyliczono.
- Częściowe nadpisanie: gdy późniejsza wypowiedź zmienia tylko część decyzji,
  reszta zostaje w mocy.

Przy każdym wpisie rejestru trzymaj oznaczenie miejsca w sesji: etykietę punktu
(`G3`, `B2`) albo krótki cytat.

## 4. Porównaj handoff z rejestrem

Dwa przejścia, oba pełne.

**Sesja → handoff.** Dla każdego stanu końcowego z rejestru: czy handoff go
niesie, z tymi samymi liczbami i tym samym zakresem?

**Handoff → sesja.** Dla każdego zdania handoffu, w każdej sekcji: z której
wypowiedzi sesji pochodzi i czy ta wypowiedź jest ostatnim słowem w swoim
temacie? Sekcje poboczne (przypadki brzegowe, powiązania, poza zakresem,
streszczenie na górze) czytaj tak samo uważnie jak reguły — tam zostają ślady
po nadpisanych decyzjach, bo poprawka zwykle trafia tylko w jedno miejsce.

Kategorie wyników:

- `missing` — stan końcowy, którego handoff nie niesie.
- `stale` — handoff niesie wersję, którą sesja potem zmieniła.
- `leftover` — reguła jest aktualna, ale inna sekcja nadal mówi po staremu.
- `conflict` — dwa miejsca handoffu lub handoff i notatki mówią co innego.
- `invented` — zdanie, którego sesja nie ustaliła: domysł asystenta zapisany
  jak decyzja.
- `consequence` — późniejsza decyzja zmienia przypadek, którego nikt po niej
  nie omówił, a handoff opisuje go po staremu lub wcale.
- `open` — pytanie, które padło i zostało bez odpowiedzi, a handoff tego nie
  rozstrzyga lub rozstrzyga po cichu.

## 5. Pułapka: wynik, który cofa późniejszą decyzję

Najgroźniejszy błąd tego skilla to "przywrócenie" czegoś, co sesja świadomie
zmieniła. Zanim zgłosisz jakikolwiek wynik:

- Od wypowiedzi, na której wynik się opiera, przeczytaj sesję **do końca** i
  szukaj wszystkiego, co ten temat zmieniło, zawęziło lub cofnęło — także
  pośrednio, przez regułę ogólną lub sprawdzony fakt.
- Wynik `missing` jest ważny tylko wtedy, gdy nic późniejszego go nie
  unieważnia. Brak czegoś w handoffie częściej znaczy "zmieniono" niż
  "zapomniano".
- Poprawka w polu `fix` musi brzmieć jak stan końcowy, nigdy jak którakolwiek
  wersja pośrednia.
- Gdy dwie wypowiedzi się kłócą i nie da się ustalić, która jest późniejsza
  albo czy późniejsza naprawdę dotyczy tego samego, nie rozstrzygaj. Zgłoś jako
  `open` i zapytaj.

Wynik bez pola `evidence` wskazującego ostatnią wypowiedź w temacie nie nadaje
się do zgłoszenia — odrzuć go.

## 6. Oceń i oflaguj

- Odrzuć drobiazgi: styl, kolejność zdań, sformułowania, które niosą tę samą
  treść.
- Szereguj wg szkody: najpierw to, co kazałoby zbudować coś innego, niż
  ustalono.
- Pewność H tylko, gdy ostatnie słowo w temacie jest jednoznaczne.
- `✓` znaczy "stosuję od razu": `missing`, `stale`, `leftover` i `conflict` z
  pewnością H.
- `✗` znaczy "pytam": każdy wynik `invented`, `consequence` i `open`, oraz każdy
  wynik z pewnością M lub L. To decyzje użytkownika, nie poprawki.
- Jeśli handoff zgadza się z sesją, powiedz to i zatrzymaj się. Nie wymyślaj
  wyniku, żeby mieć co zgłosić.

## 7. Zastosuj pewne — wplataj, nigdy nie dopisuj

Zastosuj każdy wynik `✓` przed raportem. Wyników `✗` nie dotykaj.

- Popraw zdanie w miejscu, w jego sekcji. Bez sekcji "Poprawki" i bez adnotacji
  "(zmienione po przeglądzie)".
- Jedna poprawka dotyka każdego miejsca, które niesie tę decyzję: reguły,
  przypadki brzegowe, powiązania, poza zakresem, streszczenie, notatki.
- Usunięta decyzja znika. Nie jest przekreślona ani oznaczona jako cofnięta.
- Handoff ma być samodzielny: żadnego odsyłania do rozmowy.
- Nietknięte sekcje zostaw bajt w bajt.

Po edycji przeczytaj handoff jeszcze raz w całości i sprawdź, czy poprawki nie
stworzyły nowej sprzeczności.

## 8. Raport

Dwie numerowane listy w jednej sekwencji numerów: najpierw zastosowane, potem
pytania.

    **N. [category][H|M|L][✓|✗] <sekcja handoffu> — krótki tytuł**
    ========== problem ==========
    <co handoff mówił lub czego nie mówił, maks. 2 zdania>
    ========== evidence ==========
    <ostatnia wypowiedź w temacie: etykieta lub cytat; dla stale i leftover
    także wcześniejsza wersja, którą handoff niósł>
    ========== fix ==========
    <dla ✓: co zmieniono i w których plikach, jedna linia; dla ✗: pytanie do
    użytkownika z rekomendacją>

Wskazuj sekcję handoffu, nie numer linii.

Po ostatnim wyniku wypisz w jednej linii na klasę, które decyzje nadpisane
sprawdzono i potwierdzono, że handoff niesie ich wersję końcową. To dowodzi, że
pułapka z kroku 5 była sprawdzona.

Gdy są pytania, zakończ prośbą o odpowiedzi po numerach. Gdy użytkownik uzna
zastosowaną poprawkę za błędną, cofnij ją w miejscu.

## 9. Po odpowiedziach

Odpowiedź użytkownika to nowa, najpóźniejsza decyzja: wpleć ją regułami kroku 7
i sprawdź, czy nie unieważnia czegoś, co handoff już niesie. Zgłoś, co
zmieniono. Bez commita.
