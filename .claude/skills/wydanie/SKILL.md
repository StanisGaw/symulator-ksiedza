---
name: wydanie
description: Prowadzi jedno wydanie z ROADMAP.md od kontraktu do commita, rozdzielając robotę między subagentów w trzech falach. Użyj, gdy użytkownik prosi o zrobienie wydania (np. "zróbmy 2.3", "/wydanie 2.4") albo o rozpisanie wydania na równoległe zadania.
---

# Wydanie

Prowadzisz **jedno** wydanie z `ROADMAP.md` przez trzy fale. Nie bierzesz dwóch wydań
naraz - 2.3, 2.4 i 2.6 przechodzą przez te same pliki i nie da się ich pogodzić.

Argument to numer wydania (np. `2.3`). Bez argumentu: bierzesz pierwsze niewydane
z części 4 ROADMAP i mówisz użytkownikowi, które to.

## Zasady, które obowiązują wszystkie fale

1. **Jeden plik ma w jednej fali jednego piszącego.** Własność jest na falę, nie na
   zawsze - patrz tabela stref niżej.
2. **Godota uruchamia wyłącznie `bramkarz`.** Katalog `.godot` jest jeden i dwa
   przebiegi naraz psują import.
3. **Blendera dotyka wyłącznie `model`.** Instancja jest jedna.
4. **`git` należy do ciebie.** Subagenci nie mają Bash (poza `bramkarzem` i `modelem`),
   więc nie mogą commitować nawet przez pomyłkę.
5. **Commitujesz dopiero po zielonych bramkach**, na gałęzi `wydanie/<numer>-<nazwa>`.
   Merge do `main` dopiero na wyraźne słowo użytkownika.

## Strefy własności

| Strefa | Pliki | Agent |
|---|---|---|
| stan i reguły | `game.gd`, moduły mechaniki (`finance`, `parish`, `inbox`, `event_flow`, `repairs`, nowe) | `mechanika` |
| interfejs | `ui.gd`, `scripts/ui/` | `interfejs` |
| treść | `events.gd`, `phone.gd`, `visits.gd`, `breakdowns.gd` | `tresc` |
| świat | `world_state.gd`, `location*`, `scripts/locations/`, `scenes/` | `swiat` |
| postać i model | `player.gd`, `person.gd`, `activity_scene.gd`, `mass_director.gd`, `blender/` | `model` |
| bramki | `scripts/tools/`, uruchamianie Godota | `bramkarz` |
| dokumentacja | `README.md`, `ROADMAP.md` | `kronikarz` |

Wyjątek: w fali 0 `save_game.gd` i `tools/check_definitions.gd` należą do `architekta`.

## Fala 0 - kontrakt (szeregowo, jeden agent)

Uruchamiasz `architekt` z sekcją wydania z ROADMAP i odpowiednimi AC z README.
Czekasz na wynik. Bez kontraktu **nie ruszasz** dalej - to on pozwala fali 1 pracować
równocześnie.

Kontrakt przeczytaj sam i sprawdź trzy rzeczy: czy każde nowe pole stanu jest
w `save_game.gd`, czy kształty `modal_requested` są opisane, i czy nazwy ustalone
„na zapas” zgadzają się z tym, co ROADMAP planuje na kolejne wydania.

Commitujesz kontrakt osobno, zanim ruszy fala 1.

## Fala 1 - budowa (równolegle)

Uruchamiasz **w jednej wiadomości** tych agentów, których wydanie dotyczy - zwykle
`mechanika`, `interfejs`, `tresc`, czasem `swiat` i `model`. Każdy dostaje:

- ścieżkę do pliku kontraktu (ma go przeczytać w całości),
- swój wycinek roboty z sekcji wydania w ROADMAP,
- listę swoich plików i zdanie: „cudzych plików nie dotykasz, brak czegoś zgłaszasz
  w raporcie”.

Gdy agent zgłosi brak w kontrakcie: **nie łataj tego sam i nie każ mu zgadywać.**
Albo dosyłasz `architekta` z jedną poprawką i restartujesz tego agenta, albo zostawiasz
rzecz na potem i mówisz o tym użytkownikowi.

## Fala 2 - integracja (szeregowo, z jednym wyjątkiem)

1. `bramkarz` - `--import`, `--check`, `--simulate=120` na ziarnach 1, 7 i 42,
   przebieg headless. Przy wydaniu porządkowym wynik symulacji ma być identyczny
   z poprzednim; przy wydaniu z mechaniką - wytłumaczalny.
2. Równolegle z bramkarzem: `recenzent` (czyta diff, niczego nie uruchamia).
3. Gdy bramki zielone: `kronikarz` (README i ROADMAP).
4. Commit i podsumowanie dla użytkownika: co weszło, co nie weszło i dlaczego.

## Gdy bramka nie przejdzie

Wracasz do **właściciela pliku**, nie naprawiasz sam. Bramkarz opisuje objaw,
właściciel poprawia, bramkarz sprawdza ponownie. Dwie nieudane rundy na tym samym
błędzie to sygnał, że kontrakt był zły - wtedy zatrzymujesz falę i pytasz użytkownika.

## Czego nie robisz

- Nie zaczynasz kolejnego wydania, dopóki poprzednie nie jest scalone.
- Nie przenosisz pozycji w ROADMAP na ✅ bez zielonych bramek.
- Nie zwiększasz liczby agentów ponad liczbę rozłącznych stref. Piąty agent w fali,
  który nie ma własnych plików, nie przyspiesza wydania, tylko produkuje konflikty.
