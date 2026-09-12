# Roadmapa: Symulator Księdza

Plan wydań pogodzony z dwoma źródłami: kryteriami akceptacji z README (AC-1…AC-10)
i pierwotnym zamysłem z rozmowy projektowej („Football Manager dla proboszcza połączony
z Crusader Kings”). Tam, gdzie AC i rozmowa mówią co innego, wygrywa rozmowa – AC były
pisane jako minimum do sprawdzenia, nie jako sufit.

Zasady: każde wydanie kończy się buildem na GitHub Pages i przejściem `--check`
oraz `--simulate=120`. Jedno wydanie domyka jeden system do końca zamiast dotykać pięciu
po trochu. Kolejność jest zależnościowa, nie z sufitu – patrz uzasadnienia.

Stan na 12.09.2026: wydane jest wszystko do **2.2** (telefon).

---

## 1. Audyt: gdzie jesteśmy wobec AC

| AC | Stan | Co jest, czego brakuje |
|---|---|---|
| 1.1 przychody | ✅ | taca, ofiary pogrzebowe, dochód inwestycji – widoczne w banku |
| 1.2 kategorie wydatków | ⚠️ | są remonty i inwestycje; **brak** bieżących, infrastruktury i duszpasterstwa jako kategorii, stałe koszty to jedna liczba `WEEKLY_EXPENSES` |
| 1.3 budżet ograniczony | ⚠️ | inwestycji nie można kupić bez pieniędzy, ale debet z tygodnia wchodzi cicho; bank przypomina dopiero po fakcie |
| 1.4 skutki poza finansami | ✅ | każda inwestycja i naprawa zmienia wskaźnik niefinansowy |
| 2.1–2.3 zasoby niefinansowe | ✅ | reputacja, stan budynków, dwie grupy, kuria; cztery kryzysy progowe |
| 3.1 start jako wikary | ❌ | nie ma stanowiska w stanie gry |
| 3.2–3.5 ścieżka, ocena, zakres | ❌ | kuria jest wskaźnikiem, nie oceniającym |
| 4.1–4.2 specjalizacja | ❌ | jest tylko „szacunek” jako przyszła waluta |
| 5.1–5.5 wydarzenia i kryzysy | ✅ | 35 wydarzeń, skutki odroczone i niepewne, kryzysy progowe |
| 6.1 kuria jako aktor | ⚠️ | reaguje liczbą i kryzysem; brak oceny, przeniesienia, kariery |
| 6.2 tłumaczenie się z decyzji | ✅ | listy z kurii w telefonie z terminem i trzema sposobami odpowiedzi |
| 7.1 grupy parafian | ⚠️ | dwie grupy jako liczby (tradycjonaliści, młode rodziny), nie byty z wpływem |
| 7.2 konflikty grup | ⚠️ | decyzje różnicują obie liczby; eskalacja tylko przez kryzys reputacji |
| 8.1–8.2 emergencja | ✅ | losowanie na warunkach, moneta w skutkach, karencje; brak kroniki przejścia |
| 9.1–9.4 świat, rozbudowa, praca, dzień | ✅ | |
| 9.5 drzewko rozwoju | ❌ | |
| 9.6 postacie z rutyną | ⚠️ | parafianie istnieją tylko w scenach mszy, spowiedzi i pogrzebu |
| 9.7 warstwa strategiczna | ✅ | |
| 10.1–10.2 współczesność | ✅ | telefon: poczta, bank, media |
| 10.3 a/b/d render | ✅ | |
| 10.3c interfejs w stylistyce | ⚠️ | font systemowy, nie pikselowy |
| 10.4 ton | ✅ | |
| 1.5–1.6 zadłużenie, budżet w kategoriach 🆕 | ❌ | wydanie 2.3 |
| 2.4 życie religijne 🆕 | ❌ | wydanie 2.4 |
| 2.5 reputacja rozłożona | ⛔ | odłożone, patrz część 5 |
| 3.6–3.8 ocena kwartalna, przeniesienie, wikary pod proboszczem 🆕 | ❌ | wydania 2.4 i 3.3 |
| 4.3–4.4 cechy księdza 🆕 | ❌ | wydanie 2.5 |
| 5.6 łańcuchy wydarzeń 🆕 | ❌ | wydanie 2.4 |
| 6.3–6.4 kalendarz kurii, dziekanat 🆕 | ❌ | wydanie 2.4 |
| 7.3–7.5 grupy z wpływem, działalność społeczna 🆕 | ❌ | wydanie 2.6; zastępują 7.1 i 7.2 |
| 11.1–11.4 warianty startu, remont etapami 🆕 | ❌ | wydania 2.3, 3.0, 3.1 |
| 12.1–12.3 kancelaria, sakramenty, planer 🆕 | ❌ | wydanie 2.8 |
| 13.1–13.3 pracownicy, wikary 🆕 | ❌ | wydanie 2.9 |

Kryteria 1.3, 7.1 i 7.2 są w README oznaczone jako 🔁 zastąpione – dzisiejszy kod spełnia
ich literę, ale od wskazanego wydania liczy się kryterium następcze.

## 2. Rozmowa projektowa: co AC nie pokrywały

Rzeczy z pierwotnego zamysłu, których w AC nie było albo były słabsze. Od 12.09.2026
każda ma swoje kryterium w README (AC-1.5 i dalej, oznaczone 🆕); numery R zostają jako
odsyłacz do źródła.

- **R1 Warianty startu** – duże miasto / małe miasto oraz stary kościół do remontu /
  nowa parafia od salki. Dziś jest jeden start: mała parafia, stary kościół.
- **R2 Sześć grup interesów z wpływem** – młodzież, młode rodziny, pracujący, seniorzy,
  przedsiębiorcy, potrzebujący. Grupa ma zadowolenie **i** wpływ; silna grupa daje tacę
  i frekwencję, ale też składa skargi i tworzy frakcje.
- **R3 Statystyki księdza** – charyzma, wiarygodność, zarządzanie, wpływy, odporność.
  Różne style gry: świetny duszpasterz i kiepski administrator, albo odwrotnie.
- **R4 Wiara / życie religijne parafii** – osobny zasób liczony z frekwencji, sakramentów
  i aktywności grup. AC-2 mówi tylko o reputacji i relacjach.
- **R5 Kalendarz tygodnia** – msze, spowiedź, kancelaria, katecheza, śluby, chrzty,
  spotkania z grupami. Im większa parafia, tym więcej dzieje się naraz.
- **R6 Wikary z charakterem** – delegowanie, jego relacje z parafianami, jego błędy
  spadają na ciebie. Wątek kobiety wikarego jako łańcuch decyzji z rozgałęzieniami
  (ignorujesz / rozmawiasz / zgłaszasz kurii) i późnymi, niepewnymi skutkami.
- **R7 Kariera w hierarchii** – wikary → proboszcz → większa parafia → kuria;
  przeniesienie do gorszej parafii jako strata, nie koniec gry.
- **R8 Reputacja rozłożona** – osobno u parafian, mieszkańców, innych księży i biskupa.
  Dziś: jedna liczba plus kuria.
- **R9 Działalność społeczna** – Caritas, świetlica, festyny, inicjatywy: kosztują czas
  i pieniądze, budują inne zasoby.
- **R10 Budynki jako realny wybór** – „dach za 70 tys. albo sala dla młodzieży za 50”;
  parafia rozwija się fizycznie: plebania, dom parafialny, sale, świetlica.
- **R11 Remont starego kościoła etapami** – dach, wnętrze, ogrzewanie, plebania jako
  kolejne stopnie, a nie jedna inwestycja.
- **R12 Dziwne konsekwencje po czasie** – decyzja wraca po tygodniach w innej postaci
  (romans wikarego → skandal → reprymenda). Mechanika: łańcuchy wydarzeń z pamięcią.

## 3. Zasoby: co mamy, a co miało być

| Zasób z rozmowy | Dziś w grze | Decyzja |
|---|---|---|
| pieniądze | `money` + bank | zostaje; w 2.3 dochodzą kategorie budżetu |
| reputacja (parafianie, mieszkańcy, inni księża, biskup) | `reputation` (jedna) + `curia` | `reputation` zostaje reputacją u mieszkańców (media, otoczenie); zaufanie parafian przechodzi do grup w 2.6; „inni księża” dochodzą w 2.4 jako dziekanat |
| zaufanie kurii | `curia` | zostaje; w 2.4 dochodzi ocena kwartalna i ranga |
| zaufanie grup | `trad`, `young` | migracja w 2.6: `trad` → seniorzy, `young` → młode rodziny, cztery nowe grupy startują od 50 |
| wiara / życie religijne | brak | nowy wskaźnik `faith` w 2.4, liczony, nie ustawiany: frekwencja, sakramenty, aktywność grup |
| statystyki księdza (5) | brak | nowe w 2.5, rosną z czynności i decyzji |
| stanowisko / ranga | brak | `rank` w 2.4: wikary, proboszcz, dziekan |
| stan budynków | `condition` | nie było w rozmowie wprost, ale wynika z R11; zostaje i w 3.1 rozpada się na budynki |
| szacunek | `respect` | zostaje jako punkty rozwoju na drzewka (AC-9.5) |
| energia | `energy` | zostaje jako warstwa mikro |

---

## 4. Plan wydań

Numeracja ciągnie dotychczasową (2.1 wydarzenia, 2.2 telefon). Każde wydanie ma:
co się zmienia w stanie gry, w świecie i w interfejsie, oraz które AC / R domyka.

### 2.3 Budżet tygodnia (AC-1.2, 1.5, 1.6, 11.4, R10)

Zamiast stałej `WEEKLY_EXPENSES = 4200` pięć kategorii, każda z suwakiem w telefonie
(bank) i skutkiem poza pieniędzmi.

- Stan gry: `budget: Dictionary` z pozycjami `biezace`, `remonty`, `infrastruktura`,
  `duszpasterstwo`, `ludzie` (pensje). Suma rozliczana w poniedziałek jak dziś.
- Kategoria ma poziom 0–3. Poziom decyduje o koszcie tygodniowym i o skutku:
  `biezace` 0 → co tydzień stan budynków −4 zamiast −2 i szansa awarii ×1.5;
  `duszpasterstwo` 2 → młode rodziny +1 tygodniowo; `remonty` 3 → awarie same
  się nie pojawiają, koszt ×2.
- Debet nie jest cichy: przy planowaniu tygodnia widać prognozę „za 7 dni: −3 200 zł”,
  a przekroczenie stanu konta wymaga potwierdzenia z opisem skutków (kuria, odsetki).
- Bank w telefonie: zakładka „Budżet” z pięcioma pozycjami i prognozą; historia
  operacji dostaje kategorię.
- Inwestycje wykluczające się: karta inwestycji mówi, że zabierze pieniądze
  z `remonty` przez N tygodni. Pierwszy realny dylemat „dach albo sala”.
- `--check`: suma poziomów × koszt nie może przekraczać typowego tygodniowego
  przychodu więcej niż dwukrotnie (żeby budżetu dało się dopiąć).

### 2.4 Kuria, ocena i ranga (AC-2.4, 3.1–3.8, 5.6, 6.1, 6.3, 6.4, R4, R7, R12)

Kuria przestaje być liczbą, a staje się oceniającym z kalendarzem.

- Stan gry: `rank` (wikary / proboszcz / dziekan), `faith` liczone co poranek
  z frekwencji na mszach z ostatnich 7 dni, liczby sakramentów i aktywności grup.
- Start jako wikary: proboszcz istnieje jako postać w tle, część decyzji jest
  „do uzgodnienia z proboszczem” (ta sama opcja, ale z opóźnieniem i kosztem
  relacji). Po awansie te ograniczenia znikają – to jest AC-3.5.
- Ocena kwartalna: co 13 tygodni list z kurii w telefonie z pięcioma pozycjami
  (finanse, życie religijne, stan budynków, reputacja, rozwiązane kryzysy) i wynikiem.
  Dwie dobre oceny z rzędu → propozycja awansu; dwie złe → ostrzeżenie, trzecia →
  przeniesienie do gorszej parafii (start w 3.3 z mniejszym budżetem, nie koniec gry).
- Łańcuchy wydarzeń: wydarzenie może ustawić flagę (`flags: Dictionary`), a inne
  wymagać jej w `require`. Skutek odroczony może wystawić kolejne wydarzenie, nie
  tylko liczby. To infrastruktura pod R6 i R12 – bez niej wątek wikarego się nie
  napisze.
- Dziekanat jako „inni księża”: dwa–trzy wydarzenia z sąsiednim proboszczem
  (podbieranie parafian, wspólny odpust), wpływające na `reputation` i `curia`.
- Kronika przejścia (AC-8.1): wpisy z kluczowych decyzji zbierane do jednej listy,
  do pokazania przy zmianie parafii.

### 2.5 Statystyki księdza i trzy drzewka (AC-4.1–4.4, 9.5, R3)

- Stan gry: `stats` – charyzma, wiarygodność, zarządzanie, wpływy, odporność, 1–10.
  Rosną z tego, co ksiądz robi: msze i spowiedź → charyzma, uczciwe odpowiedzi kurii
  → wiarygodność, dopięty budżet → zarządzanie, festyny i media → wpływy, krótkie
  noce bez załamania → odporność.
- Statystyka zmienia wydarzenia: opcja może mieć `needs: {"charyzma": 6}` (inaczej
  wyszarzona) albo `scale: "zarzadzanie"` (skutek pieniężny mnożony).
- Drzewka za szacunek: administrator (koszty −, przeglądy), duszpasterz (frekwencja,
  grupy), gospodarz (wpływy, media, kuria). Odblokowanie to nowa czynność, budynek
  albo skrócenie czynności. Okno drzewek w telefonie albo na biurku.
- Profil widoczny w kronice: „duszpasterz o słabym zarządzaniu” z liczbami.

### 2.6 Grupy parafian jako byty (AC-7.3–7.5, R2, R8, R9)

- Stan gry: `groups` – sześć grup, każda z `satisfaction`, `influence`, `size`.
  Migracja zapisu: `trad` → seniorzy, `young` → młode rodziny; reszta od 50.
- Wpływ liczy się z rozmiaru i zadowolenia; grupa z wpływem > 70 co tydzień coś robi:
  daje tacę, organizuje wydarzenie, składa skargę do kurii, tworzy frakcję.
- Wydarzenia dostają pole `groups` w skutkach; stare `trad`/`young` mapowane
  automatycznie, `--check` pilnuje, że każda decyzja różnicuje co najmniej dwie grupy.
- Konflikt eskaluje: dwie grupy z zadowoleniem < 30 i wpływem > 60 → kryzys
  „frakcja w radzie parafialnej” zamiast ogólnego buntu.
- Działalność społeczna jako inwestycje cykliczne: Caritas, świetlica, katecheza –
  kosztują czas w kalendarzu i pieniądze z `duszpasterstwo`, budują konkretne grupy.
- Widok „Parafia” w telefonie: sześć grup z zadowoleniem, wpływem i ostatnią
  zmianą, żeby konflikt było widać, zanim wybuchnie.

### 2.7 Parafianie z rutyną (AC-9.6)

- Osoby z generatora dostają dom, godziny i miejsce: rano na placu, w południe przy
  sklepie, wieczorem na mszy. Kilka postaci stałych z imieniem i grupą.
- Rozmowa przez podejście: dwie–trzy kwestie zależne od zadowolenia grupy, czasem
  z małą decyzją. Niedostępni poza godzinami.
- Świat czyta grupy: przy zadowolonej młodzieży rowery pod salką, przy niezadowolonych
  seniorach puste pierwsze ławki.

### 2.8 Kalendarz tygodnia, kancelaria i sakramenty (AC-12, R5)

- Kancelaria na plebanii: kolejka spraw (chrzest, ślub, pogrzeb, zaświadczenie),
  każda z terminem i grupą, której zależy. Zaległości kosztują zadowolenie grupy.
- Śluby i chrzty jako sceny z ofiarą i skutkiem dla grup; katecheza jako cotygodniowa
  czynność budująca młodzież.
- Planer tygodnia: tabela dni × pory dnia z tym, co jest zaplanowane; konflikt
  terminów widać z wyprzedzeniem. Im większa parafia (2.9), tym więcej wpisów.

### 2.9 Pracownicy i wikary (AC-13, R6, R12)

- Pracownicy: kościelny, gosposia, organista, katechetka – zatrudnianie, pensje
  w `ludzie`, morale, delegowanie czynności (delegowana czynność dzieje się sama,
  ale jej jakość zależy od morale).
- Wikary jako postać z własnymi statystykami i charakterem; przydzielany po awansie
  na proboszcza. Delegujesz mu msze i spowiedzi; jego błędy idą na twoje konto.
- Łańcuch „kobieta wikarego”: odkrycie → ignorujesz / rozmawiasz / zgłaszasz →
  po 2–5 tygodniach jedna z gałęzi: związek zakończony i cisza; porzucona kobieta
  rozpowiada, skandal, wikary przeniesiony, ty z reprymendą; wikary rzuca sutannę
  i mówi, że go kryłeś. Każda gałąź z monetą, żadna bez kosztu. Wzorzec dla
  kolejnych łańcuchów.

### 3.0 Warianty startu (AC-11.1–11.3, R1, R11, R10)

- Ekran nowej gry: wielkość (małe miasto / duże miasto) × typ (stary kościół /
  nowa parafia). Cztery kombinacje, różne startowe `money`, `groups`, `condition`,
  liczba parafian i szansa wydarzeń.
- Stary kościół: `condition` rozpada się na budynki (kościół: dach, wnętrze,
  ogrzewanie; plebania; dom parafialny) z osobnymi stanami i remontami etapami.
  Świat pokazuje etap remontu, nie jedną liczbę.
- Nowa parafia: start w salce, ścieżka salka → kaplica → kościół → kompleks.
  Każdy stopień to inwestycja, po której lokacja się przebudowuje i rośnie
  frekwencja. Osobna lokacja startowa zamiast dzisiejszego placu.
- Duże miasto: dwa razy więcej grup w grze naraz, media częstsze, kuria bliżej.

### 3.1 Rozbudowa terenu i sloty (AC-9.2, 11.4, R10)

- Sloty na placu i przy plebanii: ogród, zakrystia, kaplica boczna, salka, dzwonnica,
  plac zabaw, pokoje na plebanii warunkujące zatrudnienie.
- Komputer na plebanii jako katalog z zakładkami, poziomami i wymaganiami;
  poziomy parafii 1–5 otwierają półki katalogu.
- Zużycie i przeglądy: budynki się starzeją, ubezpieczenie jako stały wydatek
  obniżający ryzyko awarii.

### 3.2 Rok w parafii (z etapu 1: oprawa świąt, kolęda, raport roku)

- Oprawa Bożego Narodzenia, Wielkanocy i odpustu: przygotowania w tygodniach
  przed, wynik 0–100 mnożący frekwencję i tacę, pamięć zeszłego roku jako poprzeczka.
- Kolęda w styczniu jako seria scen w mieszkaniach z ofiarą i rozmową (używa 2.7).
- Raport roku: wykres tacy, zmiany wskaźników, statystyki grup, kronika lat.

### 3.3 Druga parafia i awans (AC-3.5, 3.7, R7)

- Po awansie albo przeniesieniu: nowa parafia generowana z parametrów rangi
  (większa lub gorsza), przeniesienie stanu księdza (statystyki, drzewka, kronika),
  reset stanu parafii.
- Dziekan: nadzór nad dwiema–trzema parafiami jako warstwa decyzji bez chodzenia.

### 4.x Oprawa

- Interfejs w stylu pikselowym: font, ramki, ikony w telefonie (AC-10.3c).
- Dźwięk CC0: dzwony, kroki, deszcz, organy, szum telewizora.
- Więcej scen: ślub, chrzest, procesja Bożego Ciała, pogoda wpływająca na festyn.
- Interfejs dotykowy na telefonie fizycznym.

---

## 5. Co świadomie odkładamy

- Reputacja rozbita na cztery liczby (R8, w README jako AC-2.5 ⛔) – zamiast tego grupy
  (2.6) i dziekanat (2.4) dają ten sam efekt bez czwartego paska w HUD. Wracamy, jeśli po
  2.6 gracze nie odróżniają tych źródeł.
- Pełna symulacja miasta w dużej parafii – „duże miasto” to więcej grup i częstsze
  media, nie nowa mapa.
- Multiplayer, mody, tryb nieskończonej kariery poza kurią.

## 6. Jak utrzymywać ten plik

Przy każdym wydaniu: przenieść pozycję do README do sekcji „Co jest w prototypie”,
oznaczyć tu ✅ w audycie i dopisać, co wyszło inaczej niż planowano. Nowe pomysły
z rozmów dopisywać jako kolejne R-numery w części 2, żeby nie ginęły w czacie.
