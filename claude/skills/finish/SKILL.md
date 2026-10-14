---
name: finish
description: >
  Uruchamia etapy skilli przeglądu z finish.json po kolei jako workflow:
  równoległe analizy skilli etapu, wspólne zastosowanie ✓ i weryfikacja etapu.
  Użyj, gdy użytkownik wywołuje "/finish".
argument-hint: "[branch bazowy]"
---

# Finish

## 1. Zakres

- Bez argumentu: `git status --porcelain` pusty → wypisz „Drzewo czyste. Podaj
  branch bazowy: /finish <branch>.” i zakończ. W przeciwnym razie zakres to
  `diffCommand` = `git diff HEAD`, `desc` = „niezacommitowane zmiany i nowe
  nieśledzone pliki”.
- Z branchem: weź `git merge-base <branch> HEAD`, nie czubek brancha — czubek,
  który poszedł dalej, wniósłby do diffu cudze commity na odwrót.
  - Błąd → wypisz „Brak merge-base z <branch>: <stderr>” i zakończ.
  - `git diff --quiet <sha>` bez różnic → wypisz „Brak zmian względem
    <branch>.” i zakończ.
  - W przeciwnym razie `diffCommand` = `git diff <sha>`, `desc` = „zmiany od
    merge-base <sha> z <branch>, łącznie z niezacommitowanymi”.

## 2. Uruchom workflow

- Wczytaj `~/.claude/skills/finish/finish.json`.
- Uruchom Workflow z `name` = `finish-run` i `args`:
  - `finish` — zawartość `finish.json`,
  - `scope` — `{ diffCommand, desc }` z kroku 1,
  - `reviewAgent` — `{}`, agenci dziedziczą model i effort sesji,
  - `where` — `finish`.
- Powiedz w jednej linii, że workflow ruszył i że postęp widać w `/workflows`.
  Czekaj na powiadomienie o końcu — nie odpytuj.

## 3. Raport

Z wyniku workflowu:

- **Stan:** wszystkie etapy gotowe albo zatrzymany — na którym etapie, z
  jakimi brakami. Przy stopie dodaj: zmiany leżą niezacommitowane do
  przejrzenia.
- **Ostrzeżenia** (`warnings` z `checklist`): czego weryfikator nie mógł
  sprawdzić przez środowisko i dlaczego. Pomiń, gdy brak.
- **Zastosowane** (`applied`): per skill, z plikiem i linią.
- **Decyzje** (`decisions`): decyzja, dlaczego, alternatywa — oznaczone A1,
  A2...
- **Pominięte ✗ warte decyzji** (`skipped`) — B1, B2...
