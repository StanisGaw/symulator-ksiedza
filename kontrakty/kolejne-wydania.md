# Kolejne wydania — plan i stan

Zgoda: 12.09.2026 „kontynuuj z dalszymi wydaniami”. Kontynuujemy istniejącą
ROADMAP.md, publikując każde wydanie po weryfikacji. Seria: 2.4–2.6, zgodnie z podanym użytkownikowi założeniem po pytaniu o zakres.
Pierwsze: 2.4. Każde kolejne dopiero po publikacji poprzedniego.
Źródło: ROADMAP.md, README AC. Baza: 89510f2.

## Zespół i zależności

| ID | Zadanie | Właściciel / model żądany | Warunek startu | Stan |
|---|---|---|---|---|
| K24 | kontrakt, Game, SaveGame, integracja | rodzic, bieżący model nieujawniony | zgoda | verified |
| C24 | reguły kariery, wiara, oceny, testy | career / gpt-5.6-sol high | kontrakt poniżej | verified |
| E24 | łańcuchy, dziekanat, testy definicji | events / gpt-5.6-sol high | kontrakt poniżej | verified |
| U24 | ekran kariery i kroniki | career_ui / gpt-5.6-terra medium | kontrakt poniżej | verified |
| I24 | testy wspólne, dokumentacja, notes, Web, Pages | rodzic | C24/E24/U24 sprawdzone | running: publikacja |

Wspólny checkout, jeden autor każdego pliku. Git, import głównego projektu i
publikacja należą do rodzica. Agenci testują runnerem w izolowanych kopiach.
Modele żądane przy dispatchu; efektywne tylko jeśli runtime je ujawni.
K24 → (C24 || E24 || U24) → I24. Kolejne wydanie po zielonej publikacji poprzedniego.

## Kontrakt 2.4, rewizja 1

Właściciel Game/SaveGame: rodzic. Nowe pola: `rank: String = "wikary"`,
`faith: int = 0`, `career: Dictionary`, `faith_history: Array`, `flags: Dictionary`,
`chronicle: Array`, `pending_events: Array` (ID wydarzeń do pokazania następnego poranka).
Wszystkie zapisane, resetowane dla nowej gry i brakujących pól starego zapisu.
Stary zapis migruje jako proboszcz (zachowuje dotychczasową samodzielność), nowa gra
jako wikary. Pierwsza ocena starego zapisu za 91 dni od migracji; bez ocen wstecz.

Career (C24) ma API: `reset(game, legacy=false)`, `normalize(game)`,
`record(kind:String, amount:int=1)` (attendance/sacraments/groups),
`morning()->Array[String]`, `rank_label()->String`, `next_review_day()->int`,
`review_components()->Dictionary`, `accept_promotion()->bool`,
`needs_approval(option:Dictionary)->bool`, `request_approval(event:Dictionary, option:Dictionary)->bool`,
`add_chronicle(text:String)`, `record_crisis(id:String)`.
`career` zawiera `next_review`, `good_streak`, `bad_streak`, `promotion_offer` (String),
`transfer_pending` (bool), `pastor_relation` (0–100), `reviews` (Array),
`approvals` (Array), `resolved_crises` (Array unikatowych ID w kwartale).
Ocena co 91 dni (13 tygodni), przypomnienie 7 dni wcześniej. Pięć jawnych składowych
0–100, średnia; dobre >=70, złe <40, reszta przerywa serie. Dwie dobre proponują
kolejną rangę, dwie złe ostrzegają, trzecia rejestruje decyzję o przeniesieniu.
Faktyczna zmiana parafii i nadzór dziekana pozostają w 3.3; UI opisuje ten zakres.
Wiara: wyłącznie wykonane czynności z ostatnich 7 zakończonych dni; frekwencja,
spowiedzi i aktywność duszpasterska (odwiedziny). Pieniądze/popularność same nie
dają wiary. Career publikuje formułę i składowe UI. Brak aktywności => 0.
Uzgodnienie: opcja zmiany rozkładu (`set` sunday_hours/weekday_hours) albo
`needs_approval: true` przy wikarym; 2 dni opóźnienia i relacja proboszcza -2.
Wszystkie skutki opcji wykonywane po zgodzie; bez podwójnego wykonania.
Career.morning wywołuje `EventFlow.apply_option(event, option)` dla gotowej zgody.

E24 jest jedynym autorem scripts/events.gd, event_flow.gd,
tools/check_definitions.gd i nowych chain_events.gd / tools/check_chains.gd.
EventFlow rozdziela `choose_option` (oznacza decyzję, pyta Career o zgodę) od
`apply_option(event,option)` (wykonuje skutki). Obie ścieżki zapisują kronikę;
rozwiązanie kryzysu rejestruje się raz. Flagi opcji w `flags`, warunek `require.flags`.
Skutek odroczony może mieć `event` / `else_event` (ID) i `flags` / `else_flags`.
Rodzic w pętli poranka wywoła `EventFlow.apply_delayed_branch(item,hit)`;
helper dodaje ID do Game.pending_events i ustawia flagi. Pending przetwarzane
w _morning_events i usuwane dopiero przy wyborze (odporność na zapis poranka).
Nowe warunkowane wydarzenia są dostępne przez Events.by_id i wspólną walidację.
Co najmniej jeden łańcuch: 3 wybory, każdy ma koszt, dalsze wydarzenie po 14–35 dniach
z gałęzią losową. 2–3 wydarzenia sąsiedniego proboszcza, w tym reakcja na zmianę godzin.

U24 jest autorem scripts/ui/status_view.gd i nowego scripts/ui/career_view.gd.
`CareerView.show_career(ui)` — przewijany ekran rangi, wiary, kalendarza, wyników,
uzgodnień, propozycji awansu i trwałej kroniki; przycisk akceptacji używa API Career.
Rodzic dodaje wejście z telefonu, routing `career`, etykiety uzgodnień w opcjach.
U24 może dodać link z ekranu statusu; nie pisze ui.gd/phone_view.gd.

## Pokrycie i weryfikacja

| AC / źródło | Zadania | Wymagany dowód | Wynik |
|---|---|---|---|
| 2.4 / R4 | K24 C24 U24 | czynności, 7 dni, brak wpływu samej kasy/reputacji | passed |
| 3.1–3.6, 3.8 / R7 | K24 C24 U24 | nowa/stara gra, 91 dni, serie, awans, zgoda | passed |
| 3.7 | C24 | decyzja i kronika; nowa parafia dopiero 3.3 | partial scope |
| 5.6 / R12 | E24 K24 | 3 kosztowne gałęzie, los, flagi, zapis i kolejka | passed |
| 6.1, 6.3, 6.4 | C24 E24 | list przed terminem, ocena i wydarzenia sąsiada | passed |
| Kronika / AC8.1 | C24 E24 U24 | trwałe wpisy decyzji i ocen | passed |
| Wydanie | I24 | --check, testy systemów, --simulate=120, UI, Web, Pages | passed |

## Wznowienie

Kontrakt gotowy; następne: dispatch C24/E24/U24 oraz implementacja K24.

## Dowody 2.4

- `artifacts/release-2.4/career-final.log`: import i --check-career PASS,
  w tym JSON z dwoma oczekującymi zgodami, ocenami, wiarą i kroniką.
- `check-integrated.log`, `chains-final.log`: definicje oraz łańcuchy PASS;
  3 wybory odpustu, 6 następstw, flagi, uzgodnienia, progi kryzysów.
- `career-ui-final.log`: czynności, poranki, zgoda, zapis, wczytanie oczekującego
  wydarzenia, odpowiedź i awans przez przyciski PASS.
- `screenshots/phase-1.log`: natywny OpenGL1280×720 PASS; obejrzano
  career-start, career-approval, career-history. Okna mieszczą się i przewijają.
- `budget.log`, `budget-ui.log`: regresje2.3 PASS; zwykły tydzień mszy9542zł.
- `simulate.log`:120dni seed7,69dni z wydarzeniem,32różne, maksymalna cisza3dni,
  brak błędów. Przebieg losuje decyzje bez codziennych czynności, nie jest testem balansu.
- `export.log`: Web eksport PASS. CI powtarza wszystkie kontrole przed Pages.
- Poprawione podczas integracji: przesuwany termin oceny, listy istniejące tylko
  w raporcie, wielokrotne zgody, zaliczanie pogorszenia kryzysu jako rozwiązania,
  zbyt szerokie etykiety uzgodnień. Wiara bez aktywności pozostaje0.

Stan wznowienia: I24 publikuje; po zielonym Pages rozpocząć plan2.5.
