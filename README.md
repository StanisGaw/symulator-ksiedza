# Symulator Księdza

Gra strategiczno-symulacyjna, w której parafia działa jak małe państwo / organizacja. Gracz zaczyna jako młody wikary i musi jednocześnie zarządzać pieniędzmi, ludźmi, własną pozycją oraz konsekwencjami swoich decyzji.

To **nie** jest gra o odprawianiu mszy. Punktem odniesienia dla mechanik są *RimWorld*, *Crusader Kings* i *This War of Mine*, ale w mikroskali parafii: ograniczone zasoby, grupy interesów, hierarchia nad graczem, własne statystyki i ciąg zdarzeń, których nie da się w pełni kontrolować.

Punktem odniesienia dla **formy rozgrywki i stylistyki** jest *Graveyard Keeper*, przeniesiony do czasów współczesnych.

## Inspiracja: Graveyard Keeper we współczesności

Gra ma działać na zasadzie *Graveyard Keeper*: gracz osobiście porusza się po terenie parafii, wykonuje codzienne czynności, rozbudowuje miejsce, w którym pracuje, i stopniowo odblokowuje nowe możliwości. Zarządzanie strategiczne (finanse, ludzie, kuria) jest nadbudowane nad tą pętlą, a nie zastępuje jej.

**Co przejmujemy z Graveyard Keeper:**
- widok z góry / rzut izometryczny, sterowanie jedną postacią, która chodzi po świecie gry,
- rozbudowa terenu parafii: kościół, plebania, otoczenie, kolejne budynki i ulepszenia,
- praca fizyczna i rzemiosło jako część codzienności (naprawy, porządki, przygotowania),
- cykl dnia i nocy oraz ograniczona energia postaci,
- drzewko rozwoju i odblokowywanie technologii / umiejętności,
- postacie niezależne z własnymi zadaniami, relacjami i rutyną,
- mroczny humor i lekko satyryczny ton, bez wyśmiewania wiary jako takiej.

**Co zmieniamy względem Graveyard Keeper:**
- czasy współczesne, nie średniowiecze: telefon, internet, media społecznościowe, samochód, przelewy, faktury, urząd, media lokalne,
- zamiast cmentarza i sekcji zwłok centrum gry jest parafia jako organizacja,
- warstwa strategiczna (reputacja, grupy interesów, kuria, kariera) jest znacznie mocniejsza niż w pierwowzorze.

**Stylistyka (decyzja z 10.09.2026, kierunek „mroczny” w wariancie D z macierzy stylistyk):**
- **3D low poly renderowane w niskiej rozdzielczości**, bez wygładzania. Efekt wizualny zbliżony do pixel artu z *Graveyard Keeper*, ale modele, animacje i światło pochodzą z 3D (podejście jak w *Dead Cells*, tylko w czasie rzeczywistym),
- cieniowanie toon w kilku stopniach z ciemnym obrysem, **bez** dodatkowej kwantyzacji palety i ditheringu (wariant E odrzucony na rzecz czystszego obrazu),
- stała kamera ortograficzna, rzut z góry pod kątem, bez obracania kamery przez gracza,
- współczesna polska parafia: blokowisko lub małe miasteczko, plebania, parking, sklep, przystanek, szkoła,
- współczesne przedmioty i ubiór postaci,
- interfejs stylizowany na pixel art, ale z elementami współczesnymi (ekran telefonu, powiadomienia, bankowość).

**Kierunek artystyczny „mroczny”:**
- paleta wygaszona i chłodna: brązowawa trawa, szarobeżowy tynk, wypłowiały dach, ciemna sutanna,
- ciepłe akcenty tylko tam, gdzie są ludzie: okna kościoła, świece, wnętrze plebanii, latarnie,
- światło rozproszone, zachmurzone niebo, miękkie i długie cienie, mgła w dalszych planach,
- rekwizyty klimatu: cmentarz przy murze, wrony, kałuże, gołe drzewa, opadłe liście, zardzewiałe ogrodzenie,
- **pełny cykl dnia i nocy**: mroczny to ton i paleta, nie pora dnia. Dzień jest pochmurny i listopadowy, noc to ciemniejsza wersja tego samego z księżycem i światłem z okien,
- ton: poważny, lekko niepokojący, z mrocznym humorem w treści.

**Dlaczego ten wariant:** zachowuje klimat pikselowy przy kosztach produkcji 3D. Modele z brył i darmowe paczki low poly wyglądają w nim celowo, a cykl dnia, cienie i animacje są z silnika. Porównano pięć wariantów renderu (pixel art 2D, 3D czyste, 3D toon, 3D pikselizowane, 3D pikselizowane z paletą) w trzech kierunkach (mroczny, cukierkowy, cyberpunk). Wybór: mroczny, wariant D. Odrzucone kierunki cukierkowy i cyberpunk mogą wrócić jako lokalne akcenty, np. festyn parafialny albo sceny w kurii.

## Technologia

- **Silnik:** Godot 4. Pikselizowany render 3D to w Godot ustawienie niskiej rozdzielczości viewportu i filtrowania „nearest”, bez własnego pipeline'u renderowania.
- **Modele:** Blender, low poly. Na etapie prototypu modele z brył generowane skryptem, docelowo do podmiany przez artystę lub darmowe paczki na licencji CC0.
- **Render:** rozdzielczość wewnętrzna rzędu 240×135 do 320×180, skalowana całkowitą krotnością do ekranu. Kamera ortograficzna pod kątem 30 do 45 stopni. Toon shader z obrysem, filtrowanie „nearest”, bez kwantyzacji palety i ditheringu. Mgła i cykl dnia z silnika.
- **Interfejs:** natywne 2D Godota, osobna warstwa nad sceną 3D.

## Główna pętla gry

```
zarządzanie parafią
  → decyzje
  → konsekwencje społeczne i finansowe
  → konflikty / wydarzenia
  → wzrost lub spadek wpływów
  → awans albo kryzys
```

Każde przejście ma tworzyć emergentną historię. Decyzja „Na co wydam 20 000 zł?” ma być równie ważna jak „Jak rozwiążę konflikt między dwiema grupami parafian?” oraz „Jak wytłumaczę swoją decyzję kurii?”.

## Filary projektu

1. **Parafia jako mikropaństwo** – gracz zarządza organizacją, a nie pojedynczą czynnością.
2. **Wiele zasobów, nie tylko pieniądze** – bogata parafia może mieć fatalną reputację albo otwarty konflikt z parafianami.
3. **Kariera zależna od wyników** – awans trzeba wypracować, nie przychodzi automatycznie.
4. **Dynamiczne wydarzenia** – gra polega na ciągłym reagowaniu na sytuację, a nie na optymalizowaniu liczb.
5. **Rozgrywka w stylu Graveyard Keeper** – gracz fizycznie chodzi po parafii, pracuje, rozbudowuje ją i odblokowuje rozwój, a wszystko dzieje się w realiach współczesnych.

---

## Kryteria akceptacji (AC)

Poniższe kryteria opisują minimalny zakres, który musi spełniać gra, aby była zgodna z ustaloną koncepcją. Zapisane są w formacie *Given / When / Then*.

Kryteria mają dwa źródła: pierwotną listę oraz punkty z rozmowy projektowej (R1–R12 w [ROADMAP.md](ROADMAP.md)), które w liście nie występowały albo były słabsze. Oznaczenia:

- 🆕 **dopisane** – kryterium dodane z rozmowy projektowej, z numerem R w nawiasie;
- 🔁 **zastąpione** – kryterium, którego minimalna wersja przestała wystarczać; zostaje w tekście, ale spełnienie liczy się dopiero przez kryterium wskazane strzałką. Kod, który spełnia tylko starą wersję, jest do przebudowy w wydaniu podanym w roadmapie;
- ⛔ **poza zakresem** – świadomie odłożone, żeby nie zgubić powodu.

### AC-1. Ekonomia parafii

**AC-1.1 – Źródła przychodów**
- Given: gracz prowadzi parafię
- When: mija okres rozliczeniowy
- Then: parafia otrzymuje przychody co najmniej z tacy i darowizn, a ich wysokość jest widoczna dla gracza

**AC-1.2 – Kategorie wydatków**
- Given: parafia posiada środki
- When: gracz otwiera panel finansów
- Then: może przeznaczyć pieniądze na co najmniej: bieżące wydatki, remonty, inwestycje, infrastrukturę parafii oraz działalność duszpasterską

**AC-1.3 – Budżet jest ograniczony** 🔁 → AC-1.5
- Given: gracz próbuje wydać więcej, niż posiada
- When: zatwierdza wydatek
- Then: gra nie pozwala na wydatek ponad stan (lub jasno komunikuje konsekwencje zadłużenia, jeśli taka mechanika zostanie dodana)
- *Zastąpione:* wybraliśmy zadłużenie z konsekwencjami, nie blokadę. Inwestycje dalej wymagają pieniędzy, ale koszty tygodnia mogą wpędzić parafię w debet – i to ma być widoczne wcześniej, nie po fakcie.

**AC-1.5 – Zadłużenie jest widoczne przed faktem** 🆕 (R10, wydanie 2.3)
- Given: zaplanowane koszty tygodnia przekraczają stan konta
- When: gracz otwiera bank albo zatwierdza wydatek, który to powoduje
- Then: widzi prognozę salda na koniec tygodnia i skutki debetu (odsetki, relacje z kurią), a wydatek ponad stan wymaga potwierdzenia

**AC-1.6 – Budżet w kategoriach z poziomami** 🆕 (R10, wydanie 2.3)
- Given: gracz ustawia budżet tygodnia
- When: zmienia poziom kategorii (bieżące, remonty, infrastruktura, duszpasterstwo, ludzie)
- Then: zmienia się koszt tygodniowy i co najmniej jeden skutek poza pieniędzmi (tempo niszczenia budynków, ryzyko awarii, nastroje grupy), a inwestycje mogą wykluczać się przez zajęcie tej samej kategorii

**AC-1.4 – Wydatki mają skutki poza finansami**
- Given: gracz wydaje środki na dowolną kategorię
- When: wydatek zostaje zrealizowany
- Then: zmienia się co najmniej jeden zasób niefinansowy (np. reputacja, zadowolenie parafian, relacje z kurią), a gracz może zobaczyć tę zmianę

### AC-2. Zasoby niefinansowe

**AC-2.1 – Pieniądze nie są jedynym zasobem**
- Given: gra jest uruchomiona
- When: gracz przegląda stan parafii
- Then: widzi oprócz finansów co najmniej: reputację, relacje z parafianami oraz relacje z kurią

**AC-2.2 – Zasoby są niezależne**
- Given: parafia ma wysoki stan finansów
- When: gracz podejmuje decyzje niekorzystne społecznie
- Then: reputacja lub relacje z parafianami mogą spaść niezależnie od stanu kasy

**AC-2.3 – Zły stan zasobów niefinansowych prowadzi do kryzysu**
- Given: reputacja lub relacje z parafianami spadną poniżej progu krytycznego
- When: mija kolejna tura / okres
- Then: gra uruchamia kryzys (np. bunt parafian, interwencję kurii), który gracz musi rozwiązać

**AC-2.4 – Życie religijne parafii jest osobnym zasobem** 🆕 (R4, wydanie 2.4)
- Given: gra trwa
- When: mija poranek
- Then: wskaźnik życia religijnego jest liczony z frekwencji na mszach, udzielonych sakramentów i aktywności grup, a nie ustawiany wprost; parafia bogata i popularna może mieć niskie życie religijne, i odwrotnie

**AC-2.5 – Reputacja rozłożona na aktorów** ⛔ (R8)
- Zamysł: osobna reputacja u parafian, mieszkańców, innych księży i biskupa.
- Odłożone: parafianie dostają zaufanie przez grupy (AC-7.3), inni księża przez dziekanat (AC-6.4), biskup przez relacje z kurią. Jedna liczba `reputacja` zostaje reputacją u mieszkańców. Wracamy, jeśli po 2.6 gracze nie odróżniają tych źródeł.

### AC-3. Kariera i awans

**AC-3.1 – Start jako wikary**
- Given: gracz rozpoczyna nową grę
- When: gra się ładuje
- Then: postać gracza ma stanowisko *wikary* i ograniczony zakres decyzji odpowiadający tej funkcji

**AC-3.2 – Ścieżka awansu**
- Given: gracz spełnia warunki awansu
- When: kuria ocenia gracza
- Then: gracz może awansować po ścieżce: **wikary → proboszcz → wyższe stanowiska w hierarchii**

**AC-3.3 – Awans nie jest automatyczny**
- Given: mija czas gry
- When: gracz nie poprawia wyników, reputacji ani relacji z kurią
- Then: awans nie następuje samoczynnie

**AC-3.4 – Warunki awansu są wieloczynnikowe**
- Given: gra ocenia możliwość awansu
- When: obliczana jest pozycja gracza
- Then: pod uwagę brane są co najmniej: jakość zarządzania, reputacja, wpływy, wyniki parafii, relacje z kurią oraz rozwiązane kryzysy

**AC-3.5 – Awans zmienia zakres gry**
- Given: gracz awansował na proboszcza lub wyżej
- When: kontynuuje grę
- Then: ma dostęp do nowych decyzji lub odpowiedzialności niedostępnych na niższym stanowisku

**AC-3.6 – Ocena kwartalna jest jawna** 🆕 (R7, wydanie 2.4)
- Given: mija kwartał gry
- When: kuria wystawia ocenę
- Then: gracz dostaje ją na piśmie z rozbiciem na finanse, życie religijne, stan budynków, reputację i rozwiązane kryzysy, a dwie kolejne oceny decydują o awansie, ostrzeżeniu albo przeniesieniu

**AC-3.7 – Przeniesienie jest stratą, nie końcem** 🆕 (R7, wydania 2.4 i 3.3)
- Given: gracz dostał trzecią złą ocenę albo skandal uderzył w kurię
- When: kuria decyduje o przeniesieniu
- Then: gra trwa dalej w gorszej parafii; statystyki, drzewka i kronika księdza zostają, stan parafii startuje od nowa

**AC-3.8 – Wikary ma nad sobą proboszcza** 🆕 (R7, wydanie 2.4)
- Given: gracz jest wikarym
- When: podejmuje decyzję zastrzeżoną dla proboszcza
- Then: ta sama opcja jest dostępna „do uzgodnienia”, z opóźnieniem i kosztem relacji, a po awansie ograniczenie znika

### AC-4. Specjalizacja księdza

**AC-4.1 – Dostępne style kariery**
- Given: gracz rozwija postać
- When: podejmuje decyzje lub wybiera ścieżkę rozwoju
- Then: może kierować postać w stronę co najmniej jednego z profili: **administrator**, **charyzmatyczny duszpasterz**, **budujący wpływy**

**AC-4.2 – Specjalizacja wpływa na rozgrywkę**
- Given: gracz ma wyraźną specjalizację
- When: pojawia się wydarzenie lub decyzja
- Then: specjalizacja zmienia dostępne opcje, ich koszt lub skuteczność

**AC-4.3 – Ksiądz ma własne cechy** 🆕 (R3, wydanie 2.5)
- Given: gra trwa
- When: gracz otwiera profil księdza
- Then: widzi co najmniej pięć cech (charyzma, wiarygodność, zarządzanie, wpływy, odporność) w skali 1–10, które rosną z tego, co ksiądz naprawdę robi, a nie z przydzielanych punktów

**AC-4.4 – Cechy otwierają i skalują decyzje** 🆕 (R3, wydanie 2.5)
- Given: wydarzenie ma opcję z wymaganiem cechy
- When: cecha jest poniżej progu
- Then: opcja jest widoczna, ale niedostępna, z podanym progiem; opcje skalowane cechą pokazują skutek policzony dla aktualnej wartości

### AC-5. Wydarzenia, konflikty i kryzysy

**AC-5.1 – Wydarzenia losowe i dynamiczne**
- Given: gra trwa
- When: mija tura / okres
- Then: może pojawić się wydarzenie, którego wystąpienie zależy zarówno od losowości, jak i od aktualnego stanu parafii

**AC-5.2 – Źródła problemów**
- Given: generowane jest wydarzenie
- When: gra wybiera jego pochodzenie
- Then: wydarzenia mogą pochodzić zarówno **z wewnątrz parafii** (np. konflikt między grupami parafian), jak i **z zewnątrz** (np. kuria, otoczenie)

**AC-5.3 – Wydarzenia wymagają decyzji**
- Given: pojawiło się wydarzenie
- When: jest prezentowane graczowi
- Then: gracz ma co najmniej dwie różne opcje reakcji, a każda ma odmienne konsekwencje

**AC-5.4 – Konsekwencje są odroczone**
- Given: gracz podjął decyzję w wydarzeniu
- When: mija czas gry
- Then: co najmniej część skutków ujawnia się później, a nie tylko natychmiast

**AC-5.5 – Poważne kryzysy**
- Given: stan parafii jest krytyczny lub seria decyzji była niekorzystna
- When: warunek kryzysu zostaje spełniony
- Then: gra uruchamia kryzys zarządzania (w tym możliwy bunt parafian), który może zakończyć karierę gracza lub cofnąć jego pozycję

**AC-5.6 – Wydarzenia pamiętają decyzje** 🆕 (R12, wydanie 2.4)
- Given: gracz podjął decyzję w wydarzeniu
- When: mijają tygodnie
- Then: decyzja może wrócić jako inne wydarzenie w innej postaci (łańcuch), a jego gałąź zależy od wcześniejszego wyboru i od losu; co najmniej jeden łańcuch ma trzy rozgałęzienia z różnymi kosztami i żadne nie jest bezkosztowe

### AC-6. Hierarchia i kuria

**AC-6.1 – Kuria jako aktor gry**
- Given: gracz podjął istotną decyzję
- When: decyzja wpływa na parafię lub reputację
- Then: kuria reaguje, a relacje z kurią rosną lub maleją

**AC-6.2 – Tłumaczenie się z decyzji**
- Given: gracz podjął kontrowersyjną decyzję
- When: kuria się o niej dowiaduje
- Then: gracz musi wybrać sposób jej uzasadnienia, a wybór wpływa na relacje z kurią i dalszą karierę

**AC-6.3 – Kuria ma kalendarz** 🆕 (R7, wydanie 2.4)
- Given: gra trwa
- When: mija termin oceny albo relacje spadają poniżej progu
- Then: kuria odzywa się sama, z wyprzedzeniem i na piśmie, a nie tylko jako liczba w pasku

**AC-6.4 – Inni księża są aktorami** 🆕 (R8, wydanie 2.4)
- Given: w okolicy jest sąsiednia parafia
- When: decyzja gracza dotyka jej interesów (godziny mszy, odpust, parafianie)
- Then: sąsiedni proboszcz reaguje wydarzeniem, które zmienia reputację albo relacje z kurią

### AC-7. Grupy interesów w parafii

**AC-7.1 – Parafianie nie są jednolici** 🔁 → AC-7.3
- Given: gra jest uruchomiona
- When: gracz przegląda parafię
- Then: widzi co najmniej dwie grupy parafian o różnych oczekiwaniach
- *Zastąpione:* dwie grupy jako dwie liczby (tradycjonaliści, młode rodziny) spełniają ten zapis, ale nie zamysł. Zapis zostaje jako minimum do 2.6; potem liczy się AC-7.3.

**AC-7.2 – Konflikty między grupami** 🔁 → AC-7.4
- Given: grupy mają sprzeczne interesy
- When: gracz podejmuje decyzję faworyzującą jedną z nich
- Then: zadowolenie drugiej grupy spada, a konflikt może eskalować do wydarzenia
- *Zastąpione:* eskalacja przez ogólny kryzys reputacji nie pokazuje, kto z kim. AC-7.4 wymaga, żeby konflikt miał strony.

**AC-7.3 – Sześć grup z zadowoleniem i wpływem** 🆕 (R2, wydanie 2.6)
- Given: gra jest uruchomiona
- When: gracz otwiera widok parafii
- Then: widzi młodzież, młode rodziny, pracujących, seniorów, przedsiębiorców i potrzebujących, każdą z zadowoleniem, wpływem i ostatnią zmianą; każda decyzja w wydarzeniu różnicuje co najmniej dwie grupy

**AC-7.4 – Wpływ grupy przekłada się na działanie** 🆕 (R2, wydanie 2.6)
- Given: grupa ma wysoki wpływ
- When: mija tydzień
- Then: grupa robi coś sama (daje tacę, organizuje wydarzenie, składa skargę do kurii, tworzy frakcję), a dwie niezadowolone i wpływowe grupy uruchamiają kryzys z nazwanymi stronami

**AC-7.5 – Działalność społeczna buduje grupy** 🆕 (R9, wydanie 2.6)
- Given: gracz uruchamia działalność (Caritas, świetlica, katecheza, festyn)
- When: działalność trwa
- Then: kosztuje czas w kalendarzu i pieniądze z duszpasterstwa, a podnosi zadowolenie i rozmiar konkretnych grup, nie ogólną reputację

### AC-8. Emergentna historia

**AC-8.1 – Różne przejścia, różne historie**
- Given: dwóch graczy zaczyna od tego samego stanu początkowego
- When: podejmują różne decyzje
- Then: po kilku turach ich parafie, pozycje i dostępne wydarzenia wyraźnie się różnią

**AC-8.2 – Brak pełnej kontroli**
- Given: gracz prowadzi parafię optymalnie pod względem liczb
- When: gra trwa
- Then: nadal mogą pojawić się wydarzenia, których nie da się całkowicie przewidzieć ani wyeliminować

### AC-9. Rozgrywka w stylu Graveyard Keeper

**AC-9.1 – Sterowanie postacią w świecie gry**
- Given: gra jest uruchomiona
- When: gracz steruje postacią
- Then: postać księdza porusza się po terenie parafii w widoku z góry lub izometrycznym, a interakcje z obiektami i postaciami odbywają się przez podejście do nich

**AC-9.2 – Rozbudowa terenu parafii**
- Given: gracz ma potrzebne zasoby lub odblokowane ulepszenie
- When: wybiera miejsce i element do zbudowania lub ulepszenia
- Then: element pojawia się fizycznie w świecie gry i wpływa na mechaniki (np. finanse, reputację, dostępne czynności)

**AC-9.3 – Praca fizyczna i codzienne czynności**
- Given: postać znajduje się przy obiekcie roboczym (np. warsztat, kościół, ogród)
- When: gracz uruchamia czynność
- Then: czynność zużywa czas i energię postaci, a jej efekt jest widoczny w świecie gry lub w zasobach parafii

**AC-9.4 – Cykl dnia i energia**
- Given: gra trwa
- When: mija czas w grze
- Then: zmienia się pora dnia, a energia postaci spada podczas pracy i regeneruje się przez sen; wyczerpanie ogranicza dostępne działania

**AC-9.5 – Drzewko rozwoju**
- Given: gracz zdobył punkty rozwoju (przez pracę, decyzje lub wydarzenia)
- When: otwiera drzewko rozwoju
- Then: może odblokować nowe umiejętności, budynki lub czynności, a odblokowania są powiązane ze specjalizacją z AC-4

**AC-9.6 – Postacie niezależne z rutyną**
- Given: świat gry jest aktywny
- When: gracz obserwuje postacie niezależne
- Then: mają własne miejsca, godziny obecności i zadania, a rozmowa z nimi jest możliwa tylko wtedy, gdy są dostępne

**AC-9.7 – Warstwa strategiczna nad pętlą codzienną**
- Given: gracz wykonuje codzienne czynności
- When: kończy się dzień lub okres rozliczeniowy
- Then: efekty pracy fizycznej i decyzji przekładają się na zasoby z AC-1 i AC-2, a wydarzenia z AC-5 mogą przerwać rutynę

### AC-10. Czasy współczesne i stylistyka

**AC-10.1 – Realia współczesne**
- Given: gracz przegląda świat gry
- When: obserwuje otoczenie, przedmioty i postacie
- Then: widzi elementy współczesne (np. samochody, telefony, sklepy, media), a nie średniowieczne lub historyczne

**AC-10.2 – Współczesne narzędzia w mechanikach**
- Given: gracz zarządza parafią
- When: korzysta z interfejsu
- Then: ma dostęp do co najmniej jednego współczesnego kanału (np. telefon, e-mail, bankowość, media społecznościowe), który realnie wpływa na rozgrywkę

**AC-10.3 – Pikselizowany render 3D**
- Given: gra jest wyświetlana
- When: gracz ogląda dowolną scenę
- Then: scena 3D jest renderowana w niskiej rozdzielczości bez wygładzania, z cieniowaniem toon i obrysem, a efekt jest spójny we wszystkich scenach

**AC-10.3d – Kierunek mroczny w każdej porze dnia**
- Given: gra pokazuje dowolną porę dnia
- When: gracz obserwuje scenę
- Then: paleta pozostaje wygaszona i chłodna, ciepłe akcenty ograniczają się do źródeł światła związanych z ludźmi, a dzień nie wygląda jak w kierunku cukierkowym

**AC-10.3a – Stała kamera**
- Given: gracz porusza się po świecie gry
- When: postać zmienia położenie
- Then: kamera podąża za postacią, ale zachowuje stały kąt i rzut ortograficzny; gracz nie może jej obracać

**AC-10.3b – Cykl dnia w renderze**
- Given: zmienia się pora dnia (AC-9.4)
- When: gracz obserwuje scenę
- Then: zmienia się oświetlenie, kolor światła i cienie, a źródła światła nocnego (np. latarnie, okna) są widoczne po zmroku

**AC-10.3c – Interfejs w spójnej stylistyce**
- Given: gracz otwiera dowolny ekran interfejsu
- When: interfejs jest wyświetlany nad sceną 3D
- Then: interfejs jest stylizowany na pixel art i nie łamie spójności z renderem sceny

**AC-10.4 – Ton i humor**
- Given: gra prezentuje dialogi i opisy wydarzeń
- When: gracz je czyta
- Then: ton jest lekko satyryczny i z mrocznym humorem, ale nie wyśmiewa wiary jako takiej

### AC-11. Warianty startu i rozwój fizyczny parafii 🆕

**AC-11.1 – Wybór parafii na start** (R1, wydanie 3.0)
- Given: gracz zaczyna nową grę
- When: wybiera wielkość (małe / duże miasto) i typ (stary kościół / nowa parafia)
- Then: cztery kombinacje różnią się startowym budżetem, liczbą i składem grup, stanem budynków i częstością wydarzeń, a różnica jest odczuwalna w pierwszym tygodniu

**AC-11.2 – Stary kościół remontuje się etapami** (R11, wydanie 3.0)
- Given: gracz gra starym kościołem
- When: przegląda stan budynków
- Then: widzi osobne stany dachu, wnętrza, ogrzewania, plebanii i domu parafialnego, a remont jest sekwencją inwestycji, po których świat pokazuje kolejny etap

**AC-11.3 – Nowa parafia rośnie od salki** (R1, wydanie 3.0)
- Given: gracz gra nową parafią
- When: kończy inwestycję w kolejny stopień
- Then: lokacja przebudowuje się fizycznie po ścieżce salka → kaplica → kościół → kompleks, a frekwencja i taca rosną z każdym stopniem

**AC-11.4 – Budynki są wykluczającym się wyborem** (R10, wydania 2.3 i 3.1)
- Given: gracz ma pieniądze na jedną z dwóch inwestycji
- When: wybiera jedną
- Then: druga jest odsunięta o czas zajęcia budżetu, a grupy zainteresowane odsuniętą reagują spadkiem zadowolenia

### AC-12. Kalendarz tygodnia i sakramenty 🆕

**AC-12.1 – Kancelaria ma kolejkę** (R5, wydanie 2.8)
- Given: parafianie zgłaszają sprawy (chrzest, ślub, pogrzeb, zaświadczenie)
- When: gracz otwiera kancelarię
- Then: widzi sprawy z terminem i grupą, której zależy, a zaległości kosztują zadowolenie tej grupy

**AC-12.2 – Sakramenty są czynnościami ze sceną** (R5, wydanie 2.8)
- Given: w kolejce jest ślub albo chrzest
- When: gracz go udziela
- Then: czynność zużywa czas i energię, ma scenę, daje ofiarę i zmienia zadowolenie grupy oraz życie religijne

**AC-12.3 – Tydzień da się zaplanować i przeładować** (R5, wydanie 2.8)
- Given: gracz ma zaplanowane msze, spowiedź, kancelarię i spotkania
- When: otwiera planer tygodnia
- Then: widzi konflikty terminów z wyprzedzeniem, a im większa parafia, tym więcej wpisów walczy o te same pory

### AC-13. Pracownicy i wikary 🆕

**AC-13.1 – Zatrudnianie i delegowanie** (R6, wydanie 2.9)
- Given: gracz zatrudnił pracownika
- When: deleguje mu czynność
- Then: czynność dzieje się bez udziału gracza, jej jakość zależy od morale, a pensja wchodzi do kategorii „ludzie” w budżecie

**AC-13.2 – Wikary ma charakter** (R6, wydanie 2.9)
- Given: gracz jest proboszczem i dostał wikarego
- When: przegląda jego profil
- Then: widzi jego cechy (te same pięć co u księdza) i relacje z grupami, a delegowane mu msze i spowiedzi dają skutki zależne od jego cech

**AC-13.3 – Błędy podwładnych obciążają księdza** (R6, R12, wydanie 2.9)
- Given: wikary albo pracownik popełnił błąd lub wywołał skandal
- When: sprawa dociera do parafian albo kurii
- Then: skutki spadają na reputację i relacje z kurią gracza, a co najmniej jeden łańcuch (kobieta wikarego) ma trzy drogi: zignorować, porozmawiać, zgłosić – każda z późnymi, niepewnymi skutkami

---

## Zakres nieustalony

Poniższe elementy **nie zostały jeszcze ustalone** i wymagają osobnych decyzji projektowych. Nie należy traktować ich jako części obecnych AC:

- pełna lista wydarzeń i kryzysów,
- lista budynków i elementów infrastruktury parafii,
- mechanika okresu rozliczeniowego (tydzień / miesiąc) ponad cyklem dnia,
- szczegółowy system fabularny,
- konkretne wartości liczbowe (progi, koszty, wagi),
- platforma docelowa (komputer, konsola, urządzenia mobilne),
- dokładna wartość rozdzielczości wewnętrznej i finalne wartości palety materiałów,
- lista budynków i ulepszeń w drzewku rozwoju,
- lista czynności rzemieślniczych i roboczych,
- konkretne postacie niezależne i ich rutyny,
- szczegóły systemu energii i czasu (długość dnia, koszty czynności).

---

## Jak uruchomić prototyp

Projekt w tym katalogu to szkielet gry w Godot 4.7. Wszystkie modele są zastępczymi bryłami budowanymi w kodzie, docelowo do podmiany.

1. Zainstaluj Godot 4.7 (na macOS: `brew install --cask godot`).
2. Otwórz katalog projektu w Godocie albo uruchom z terminala:

```bash
godot --path .
```

**Sterowanie:** WSAD lub strzałki to chodzenie, `E` lub spacja to działanie, `T` przyspiesza czas. Na ekranach dotykowych pojawia się wirtualny joystick po lewej i przyciski `E` oraz `T` po prawej. W przeglądarce na komputerze można je wymusić, dodając `?touch` do adresu.

**Co jest w prototypie:**
- Trzy lokacje z przejściami przez drzwi: plac przed kościołem z plebanią, parkingiem i cmentarzem, wnętrze kościoła, wnętrze plebanii. Wnętrza w widoku „domku dla lalek”: dwie ściany widoczne, dwie niewidoczne.
- Czynności zużywające czas i energię: naprawa rynny, zamiatanie placu, odwiedziny chorej, msza, spowiedź, sprzątanie kościoła. Odwiedziny chorej to scena filmowa w dwóch kadrach: dojazd pod starą kamienicę pod światło, gdzie na przeszklonej klatce schodowej widać tylko sylwetkę wchodzącą płynnie zygzakiem aż na piętro chorej, a w oknie chorej stojak na kroplówkę i butelki na parapecie; potem zaniedbany pokój chorej w chłodnym świetle dziennym, ze śmieciami na podłodze, kroplówką, listkami po tabletkach, skotłowaną pościelą, obrazem Jana Pawła II, krzyżem i kineskopowym telewizorem z Telewizją Trwam. Za matową szybą drzwi przesuwa się cień wchodzącej postaci, drzwi się otwierają i ksiądz klęka przy łóżku. Msza jest krótką sceną w przyspieszeniu: parafianie wchodzą i siadają w ławkach, podchodzą do komunii i wychodzą, zegar biegnie razem ze sceną, a przycisk „Pomiń” kończy ją od razu. Taca zależy od reputacji, stanu budynków i nastrojów parafian, w niedzielę jest ponad dwukrotnie większa.
- Finanse (2.3): bank ma budżet pięciu kategorii — bieżące, remonty, infrastruktura, duszpasterstwo i ludzie — z poziomami 0–3 i opisem skutków. Domyślne 4200 zł rozlicza się w poniedziałek. Prognoza pokazuje saldo po najbliższych rachunkach i pewnych dochodach z inwestycji; nie zakłada niepewnej tacy, ofiar ani zdarzeń i kosztów awarii. Zmiana budżetu, inwestycja lub naprawa prowadząca do prognozowanego deficytu wymaga potwierdzenia. Debet kosztuje 2% odsetek tygodniowo (zaokrąglone w górę) i -3 relacji z kurią. Historia konta rozróżnia kategorie.
- Dach (8000 zł) albo salka młodzieżowa (7000 zł): obie inwestycje rezerwują remonty na 14 dni i wymagają utrzymania co najmniej poziomu 1 tej kategorii. W tym czasie drugi projekt czeka, nawet gdy pojawi się gotówka; awaryjne naprawy pozostają dostępne. Dach rozczarowuje młode rodziny (-2), salka tradycjonalistów (-2). Salka daje po ukończeniu +10 młodym rodzinom i +2 reputacji; osobny budynek i slot terenu dojdą w 3.1. Pozostałe inwestycje zachowują opis kosztów, skutków i dochodów.
- Cmentarz parafialny (12 000 zł, 5 dni) to pierwsza inwestycja z powtarzalnym zyskiem. Za kościołem staje mur z bramą, żwirowa alejka, kwatery z nagrobkami, cyprysy i kaplica cmentarna. Od tej pory co kilka dni ktoś w parafii umiera, a rodzina czeka najwyżej dwa dni na pogrzeb: odprawiony daje 800–1 200 zł ofiary, reputację i szacunek, zaniedbany oznacza pochówek u sąsiada i utratę reputacji. Pogrzeb to scena z trumną nad grobem i żałobnikami w półkolu. Do tego 150 zł tygodniowo z opłat za miejsca.
- Zasoby niefinansowe: reputacja, stan budynków, tradycjonaliści, młode rodziny, kuria. Zły stan budynków obniża reputację co tydzień, minus na koncie psuje relacje z kurią.
- Wydarzenia: trzydzieści pięć definicji w trzech rodzajach. Pierwszy tydzień prowadzi scenariusz (spór o godzinę mszy, pogrzeb sołtysa, telefon z kurii), potem rano losuje się jedno wydarzenie z puli dwudziestu ośmiu, ale tylko spośród tych, których warunki są spełnione: zakres dni, pora roku, okres liturgiczny, ukończone inwestycje, trwające awarie i progi wskaźników. Szansa na wydarzenie rośnie po cichych dniach, więc gra nie potrafi zamilknąć na tydzień, i nigdy nie jest pewna. Wydarzenie z puli wraca po karencji, zwykle po miesiącu, więc rok gry nie powtarza tych samych scen.
- Skutki odroczone bywają niepewne. Decyzja potrafi zostawić po sobie termin z monetą: zabezpieczony dach przetrwa wichurę w ośmiu przypadkach na dziewięć, kościelny po ostatniej szansie wytrzyma tydzień albo nie wytrzyma czterech dni, darowizna od przedsiębiorcy wyjdzie na jaw albo ucichnie. Tego samego wyboru nie da się więc zoptymalizować na pamięć.
- Kryzysy progowe: bunt parafian przy reputacji poniżej 22, pismo z kurii z terminem przy relacjach poniżej 22, brak pieniędzy na faktury przy dużym minusie na koncie i nadzór budowlany przy stanie budynków poniżej 15. Kryzysu nie da się odłożyć, wchodzi zamiast wydarzenia z puli i wraca co dwa tygodnie, dopóki parafia jest w tym stanie. Okno kryzysu jest podpisane wprost i wygląda inaczej niż zwykły wybór.
- Awarie jako stany trwałe: zerwana część dachu, padnięty piec, kuny na strychu, pęknięta rura na plebanii i samochód, który nie odpala. Awaria kosztuje co rano, dopóki się jej nie naprawi, a raport mówi, ile już trwa. Samochód odbiera odwiedziny chorych, dopóki stoi. Naprawa idzie tą samą drogą co inwestycja: płacisz dziś, prace kończą się rano. Awarie biorą się z decyzji w wydarzeniach albo psują się same, tym częściej, im gorszy jest stan budynków, a pora roku decyduje, co pada: zimą piec, jesienią dach.
- Kalendarz i rok liturgiczny: gra zaczyna się w dniu, w którym zaczęto nową grę, i toczy się bez końca. Pasek stanu pokazuje prawdziwą datę i okres liturgiczny. Święta ruchome (Popielec, Palmowa, Triduum, Wielkanoc, Boże Ciało) liczą się z Niedzieli Wielkanocnej algorytmem Meeusa, reszta to daty stałe, od Trzech Króli po odpust parafialny. Święta ściągają więcej ludzi i hojniejszą tacę, ale tylko o właściwej porze: mnożnik Pasterki działa dopiero po dwudziestej, a poranna msza 24 grudnia jest zwykłą mszą. Msza w dzień powszedni Adwentu przed ósmą to roraty. Święto nakazane bez mszy kosztuje tradycjonalistów, reputację i kurię.
- Klimat okresu i pory roku: w Adwencie stoi wieniec, na którym co niedzielę zapala się kolejna świeca, w Wigilię dochodzi choinka i szopka, w Wielkim Poście ołtarz jest fioletowy, krzyż zasłonięty, a światło zimne, w Wielkanoc pojawia się paschał i kwiaty. Na placu zimą leży śnieg na ziemi i na dachach, jesienią drzewa są rude, latem zielone.
- Sen na godziny: przy łóżku suwak od jednej do dwunastu godzin, z podglądem godziny pobudki i energii, oraz gotowy przycisk „Śpij do 6:00”, gdy to najwyżej dwanaście godzin. Godzina snu to +12 energii, więc krótka noc sama w sobie jest karą i nie trzeba osobnej. Sen po północy rozpoczyna nowy dzień o godzinie pobudki, a nie sztywno o siódmej.
- Bałagan kosztuje: przy każdej mszy sprawdzane jest, czy tego dnia zamieciono plac i posprzątano kościół. Za każde zaniedbane miejsce, które parafianie widzą, schodzi punkt reputacji i punkt szacunku, a komunikat po mszy wprost mówi, co zobaczyli.
- Śmieci widać i widać, że znikają: na placu leżą puszki, niedopałki, papierki i naniesione liście, w kościele kurz, ogarki świec i papierki. Po zamiataniu wszystko znika do końca dnia, zostaje tylko kupka liści przy miotle.
- Jabłoń przy placu: od lata do końca jesieni wiszą na niej trzy jabłka dziennie. Każde to pięć minut i +6 energii, a następnego dnia dojrzewają nowe.
- Rynnę naprawia się raz na zawsze: po naprawie znika obszar interakcji i kałuża pod ścianą, a rura stoi prosto.
- Msze o stałych porach: w dzień powszedni o 7:00 i 19:00, a w niedziele i święta nakazane dochodzi suma o 12:00. Rozkład jest stanem gry, nie stałą, więc wydarzenia potrafią go przestawić: po sporze o godzinę sumy niedziela może mieć 7:00 i 19:00, 11:00 i 19:00 albo trzy msze 7:00, 11:00 i 19:00. Przy trzech mszach ludzie rozkładają się na wszystkie, więc każda ma mniejszą frekwencję, a organista upomni się o dodatek. Podpowiedź przy ołtarzu zawsze podaje cały dzisiejszy rozkład i najbliższą godzinę, a kronika pokazuje rozkład na dziś, na niedziele i święta oraz na dni powszednie. Żeby zacząć, trzeba być przy ołtarzu najwyżej kwadrans przed i najwyżej dziesięć minut po. Każda odprawiona msza to +2 punkty szacunku (w niedzielę i święta +4), każda opuszczona to -3 szacunku, -2 tradycjonalistów i -1 reputacji, rozliczane w chwili, gdy mija jej pora. Frekwencja zależy od pory dnia: msza przed dziewiątą ma trzy czwarte normy, po szesnastej pięć szóstych, w środku dnia pełną. Poranna daje tradycjonalistów, południowa młode rodziny, wieczorna reputację. Szacunek jest widoczny w pasku i będzie walutą drzewek rozwoju.
- Odpoczynek w ciągu dnia: na ławce przed kościołem wybiera się suwakiem, ile czasu tam spędzić, skokiem co pół godziny aż do końca doby. Godzina daje +10 energii, czyli mniej niż godzina snu, więc siedzenie nigdy nie bije nocy. Jest też gotowy przycisk „Poczekaj do mszy”, który odlicza czas dokładnie do otwarcia okna najbliższej mszy. Na plebanii można zjeść obiad, najwyżej dwa razy dziennie.
- Odwiedziny chorych są za każdym razem u kogo innego: pani Halina z telewizorem, pan Zdzisław z butlą tlenową i bałaganem po butelkach, pani Marianna z wysprzątanym pokojem i kotem na łóżku, Wojtek po wypadku z wózkiem inwalidzkim, siostra Stefania ze stosami książek. Zmieniają się kolory ścian i podłogi, pościel, rekwizyty (telewizor albo radio, kroplówka albo tlen, portret albo makatka), ilość bałaganu i skutki wizyty. Kolejka idzie po kolei, a napis przy samochodzie mówi, do kogo dziś jedziesz.
- Telefon jako kanał gry: trzy aplikacje pod klawiszem `P`. **Poczta** przynosi listy z kurii - po kontrowersyjnych decyzjach (przeniesienie sumy, zwolnienie kościelnego, odmowa uprzątnięcia grobów) kanclerz prosi o wyjaśnienie na piśmie, a gracz wybiera, jak się tłumaczy: prawdą z liczbami, zwaleniem winy na poprzednika albo zbyciem sprawy. Każdy list ma termin i brak odpowiedzi też jest odpowiedzią, tylko droższą. **Media** to lokalny portal i grupa parafialna: posty biorą się ze stanu parafii (zapuszczone budynki, minus na koncie, zadowolone młode rodziny), część z nich można sprostować, zanim rozejdzie się dalej. **Bank** pokazuje stan konta, wpływy i wydatki tygodnia oraz historię operacji, więc widać, z czego zrobiła się dziura. Wiadomości przychodzą rano razem z resztą poranka i zapisują się z grą.
- Krótkie sceny czynności: zamiatanie placu, sprzątanie kościoła, spowiedź, brewiarz i sen mają własne scenki. Zamiatanie to krótkie wymachy miotłą w lewo i w prawo, w miejscu i tak samo na placu jak w kościele. Miotła stojąca w lokacji znika na czas sprzątania, bo to właśnie ją ksiądz bierze do ręki. Kij i główka to jedna bryła, a w pozach roboczych prawa ręka opada do trzonka i telefon znika sprzed ucha. Ksiądz siada w konfesjonale, do którego podchodzą kolejni penitenci, czyta na ławce, kładzie się na łóżku, a ekran ciemnieje. Każdą scenę można pominąć przyciskiem, a zegar biegnie razem z nią.
- Zapis gry: jeden slot, zapisywany automatycznie przy każdym przejściu do nowego dnia. Zapisujemy tylko stan poranka, więc po wczytaniu gra zaczyna się o 6:00 na plebanii i nie trzeba odtwarzać pozycji gracza ani trwającej scenki. Przy starcie, gdy zapis istnieje, pojawia się okno „Kontynuuj / Nowa gra”.
- Świat czyta stan parafii. Zaniedbane budynki mają łaty na dachu, odpadający tynk, zabite deskami okno, chwasty przy ścianach, zaciek i wiadro w nawie oraz jedną zapaloną świecę zamiast dwóch; zadbane dostają czysty kolor, kwiaty przy wejściu i pełne oświetlenie. Remont dachu zmienia kolor połaci, ogrzewanie stawia grzejniki i komin z dymem, nagłośnienie wiesza kolumny na wieży i przy prezbiterium, naprawiona rynna przestaje wisieć krzywo, a kałuża pod ścianą znika. Zamiecenie placu i sprzątanie kościoła widać od razu i do końca dnia, papiery na biurku plebanii rosną z liczbą spraw w toku, a przy żywej parafii na parkingu stoi drugie auto i stojak na rowery.
- Nowa rzecz w lokacji jest pokazywana raz: kamera najeżdża na nią z podpisem, gdy gracz pierwszy raz po zmianie tam wejdzie. Zmiana stanu przebudowuje lokację w miejscu, bez ruszania gracza.
- Cykl dnia: zegar biegnie w czasie rzeczywistym, czynności przesuwają go skokowo, nowy dzień zaczyna się o godzinie pobudki (domyślnie 6:00, czyli w porę na poranną mszę), a zaśnięcie na stojąco o północy kosztuje energię. Poranek pokazuje raport z konsekwencjami i rozliczeniem tygodnia, potem wydarzenia.
- Interfejs w rozdzielczości 1280×720 nad sceną renderowaną w 320×180: pasek stanu, podpowiedź interakcji, powiadomienia, okna wydarzeń, raportów, finansów i kroniki.

**Pliki:**
- `project.godot` – okno 1280×720 ze skalowaniem interfejsu, scena 3D w `SubViewport` 320×180 skalowanym bez wygładzania.
- `scripts/game.gd` – autoload ze stanem gry, zegarem, czynnościami i pętlą dnia. Trzyma **stan**, bo to on się zapisuje; reguły siedzą w modułach obok i sięgają po `Game.pole`.
- `scripts/finance.gd` – budżet kategorii, prognoza, potwierdzenia długu, odsetki, rezerwacje inwestycji, rozliczenie tygodnia i historia konta.
- `scripts/parish.gd` – jedyne przejście przez wskaźniki: `apply_effects` i opis skutku dla gracza. Nic nie zmienia reputacji ani relacji z pominięciem tego pliku.
- `scripts/inbox.gd` – mechanika skrzynki w telefonie: jak wiadomość wchodzi, jak się odpowiada i co poranek robi z tymi po terminie.
- `scripts/event_flow.gd` – wykonanie wyboru w wydarzeniu: skutki od ręki, skutki odroczone, karencje i skutki specjalne liczone ze stanu parafii.
- `scripts/repairs.gd` – awarie jako stany trwałe: skąd się biorą, ile kosztują co rano i jak idzie naprawa.
- `scripts/calendar.gd` – daty, dni tygodnia, okresy liturgiczne, święta i ich mnożniki, roraty, świece na wieńcu adwentowym.
- `scripts/world_state.gd` – progi stanu parafii i to, jak przekładają się na wygląd świata: kolory, warianty brył, podpisy najazdów kamery.
- `scripts/save_game.gd` – zapis i odczyt jednego slotu (`user://parafia.save`, JSON z numerem wersji). Nieznane pola są pomijane, brakujące zostawiają wartość domyślną, więc dołożenie nowego pola stanu nie unieważnia starych zapisów.
- `scripts/events.gd` – definicje wydarzeń w trzech listach (scenariusz, pula, kryzysy), warunki wejścia i losowanie z wagami.
- `scripts/breakdowns.gd` – definicje awarii: co kosztują każdego dnia, ile trwa naprawa, którą czynność odbierają.
- `scripts/tools/check_definitions.gd` – kontrola spójności definicji i przejścia stanu przez JSON (`--check`).
- `scripts/tools/check_budget.gd` – scenariusze budżetu, długu, rezerwacji, migracji zapisu i przychodów z odprawionych mszy (`--check-budget`).
- `scripts/ci/run_godot.py` – uruchamianie kontroli z limitem czasu, wykrywaniem błędów silnika i odseparowanym zapisem testowym.
- `scripts/tools/simulate.gd` – przebieg wielu dni bez gracza, do podglądu rozkładu wydarzeń (`--simulate=N`). Z `--seed=N` przebieg jest powtarzalny, więc nadaje się na dowód, że zmiana w kodzie niczego nie przestawiła.
- `scripts/location_manager.gd` – ładowanie lokacji, trwały gracz i kamera, punkty pojawienia.
- `scripts/location_base.gd` i `scripts/locations/*.gd` – lokacje budowane z brył, z kolizjami, drzwiami i obiektami interakcji.
- `scripts/interactable.gd` – obiekt interakcji: drzwi, czynność, biurko, łóżko, kronika.
- `scripts/visits.gd` – lista chorych parafian: kolory pokoju, rekwizyty, teksty i skutki każdej wizyty.
- `scripts/phone.gd` – treści telefonu: posty w mediach z warunkami na stan parafii, prośby kurii o wyjaśnienie decyzji i wspólna lista sposobów tłumaczenia się.
- `scripts/person.gd` – generator parafian z brył: archetypy (dorosły, babcia w chustce, dziadek w kaszkiecie, dziecko, nastolatek), wzrost, tusza i kolory z ziarna, więc ta sama osoba wygląda tak samo za każdym razem. Używany przez mszę i spowiedź, docelowo też przez tłum i postacie z rutyną.
- `scripts/activity_scene.gd` – reżyser krótkich scen czynności, jeden na lokację. Miejsca akcji podaje lokacja, więc ta sama scena wygląda inaczej na placu i w kościele.
- `scripts/mass_director.gd` – reżyser sceny mszy: wejście, komunia, wyjście parafian, raportowanie postępu do zegara.
- `scripts/locations/visit.gd` – lokacja i zarazem reżyser sceny odwiedzin chorej: kamienica, sylwetka w oknach, pokój chorej, najazd kamery.
- `scripts/ui.gd` – szkielet interfejsu: motyw, pasek stanu, powiadomienia, kolejka okien i wspólne klocki, z których buduje się każde okno.
- `scripts/ui/finance_view.gd`, `scripts/ui/phone_view.gd`, `scripts/ui/status_view.gd` – poszczególne ekrany. Nowy ekran to nowy plik w tym katalogu, nie kolejna funkcja w `ui.gd`.
- `shaders/toon.gdshader` i `shaders/outline.gdshader` – cieniowanie toon w trzech stopniach oraz obrys metodą odwróconej bryły (`next_pass`).
- `scripts/palette.gd` – paleta kierunku „mroczny” w jednym miejscu.
- `scripts/player.gd` – ksiądz z brył, ruch względem stałej kamery, czujnik obiektów interakcji, spadek energii przy chodzeniu. Ręce mają staw łokciowy, a pozy robocze to kąty barku i łokcia policzone solverem z podglądu blenderowego.
- `scripts/blender/` – modele budowane kodem i eksportowane do `assets/models/*.glb` przez `scripts/blender/build.sh`. W `preview/priest.py` siedzi podgląd księdza: odtwarza rig z `player.gd` w Blenderze i liczy pozy (IK dwóch kości), żeby dłonie trafiały w kij miotły, a ręce nie wchodziły w tułów. Uruchamiany ręcznie, nie jest częścią `build.sh`.
- `scripts/camera_rig.gd` – kamera ortograficzna pod stałym kątem, podąża za graczem, gracz nie może jej obracać.
- `scripts/day_night.gd` – cykl dnia z pochmurnym, zimnym światłem za dnia i bursztynowymi akcentami nocą; latarnie włączają się o zmierzchu.
- `scripts/touch_controls.gd` – wirtualny joystick i przyciski dotykowe, zasilają te same akcje co klawiatura.

**Argumenty debugowe** (po `--`): `--loc=church|rectory` startuje w lokacji, `--modal=finance|status|event|report` otwiera okno, `--sleep` przesypia osiem godzin, `--mass` razem z `--loc=church` uruchamia scenę mszy, `--visit` uruchamia scenę odwiedzin chorej (z `--trace` wypisuje momenty faz), `--hires` renderuje świat w pełnej rozdzielczości zamiast w 320x180 (do oglądania animacji), `--stroll` prowadzi księdza przed siebie, żeby dało się nagrać chód, `--phone` (albo `--phone=bank|media`) otwiera telefon, `--mail` wrzuca do niego list z kurii i post w mediach, `--touch` pokazuje sterowanie dotykowe na komputerze, `--wipe` kasuje zapis przed startem, `--continue` otwiera okno wczytania. Do oglądania wariantów świata: `--condition=15` i `--rep=80` ustawiają wskaźniki, `--built=roof,heating,sound,gutter,cemetery` stawia inwestycje (z `--unseen` kamera je pokaże jak przy ukończeniu prac), `--start=2026-12-24` ustawia datę startu, `--day=30` przeskakuje o tyle dni gry, `--hour=12` ustawia porę dnia, `--zoom=24` oddala kamerę, `--energy=30` ustawia energię, `--visitor=2` wybiera, do kogo jedziemy z posługą, `--broom=34.4,-35.2,1.861` ustawia kąt kija do pionu, skręt w bok i długość miotły do podglądu, `--do=sweep` uruchamia czynność (`sweep`, `confession`, `read_breviary`, `meal`, `clean_church`), `--event=organ_silent` otwiera konkretne wydarzenie po identyfikatorze, także kryzys, `--breakdown=car,furnace` startuje z trwającymi awariami, `--seed=7` ustala ziarno losowania, więc ten sam przebieg da ten sam wynik. Przykład:

```bash
godot --path . -- --loc=church
```

**Sprawdzenie bez okna** (import i 120 klatek w trybie headless):

```bash
godot --headless --path . --import && godot --headless --path . --quit-after 120
```

**Kontrola definicji** (wyłapuje literówki w kluczach, błędne warunki, nieznane awarie, niepełne skutki losowe, niespójny budżet i migrację JSON). Runner tworzy świeżą kopię projektu z osobnym zapisem, importuje ją i kończy błędem przy błędzie skryptu albo przekroczeniu limitu czasu:

```bash
python3 scripts/ci/run_godot.py --log artifacts/check.log -- --check
```

**Scenariusze budżetu oraz obsługi interfejsu:**

```bash
python3 scripts/ci/run_godot.py --log artifacts/budget.log -- --check-budget
python3 scripts/ci/run_godot.py --log artifacts/budget-ui.log -- --check-budget-ui
```

**Podgląd rozkładu wydarzeń** (przebieg wielu dni bez gracza, z losowym wyborem opcji; każdy przebieg jest inny). Pokazuje, na ilu dniach coś się wydarzyło, jaka była najdłuższa cisza, ile różnych wydarzeń weszło i jakie awarie się pojawiły:

```bash
python3 scripts/ci/run_godot.py --timeout 120 --log artifacts/simulate.log -- --simulate=120
```

Z ziarnem przebieg jest powtarzalny, więc porównanie wydruku sprzed zmiany i po zmianie
jest dowodem, że przenoszenie kodu między plikami niczego nie przestawiło w rozgrywce:

```bash
python3 scripts/ci/run_godot.py --timeout 120 --log artifacts/simulate.log -- --simulate=120 --seed=7 --start=2026-09-12 --wipe
```

Symulacja bez gracza bada zdarzenia i awarie, a nie opłacalność zwykłej gry: nie
odprawia regularnych mszy. Przychody z nich sprawdza osobny scenariusz budżetu.
Runner izoluje także `--wipe`; bezpośrednie uruchomienie Godota z tym argumentem
kasuje zwykły slot gracza.

**Wersja w przeglądarce:** każdy push na `main` uruchamia `.github/workflows/deploy-pages.yml`: import, kontrolę definicji, testy budżetu i UI, symulację 120 dni, eksport Web i publikację na GitHub Pages. Etapy Godota mają limit czasu i zapisują logi jako artefakt workflow. Web korzysta z renderera Compatibility i wyłączonych wątków, więc działa na Pages bez specjalnych nagłówków.

**Zrzut klatek do PNG** (wymaga okna, zapisuje do wskazanego katalogu):

```bash
godot --path . --quit-after 40 --fixed-fps 30 --write-movie /tmp/frames/f.png
```

---

## Plan rozwoju

Gra nie ma końca: rok liturgiczny wraca co roku, a rozwój idzie przez pieniądze, punkty i poziomy parafii. Każdy etap kończy się wersją na GitHub Pages.

Szczegółowy plan wydań z podpunktami, audyt kryteriów akceptacji i mapowanie zasobów na pierwotny zamysł gry są w [ROADMAP.md](ROADMAP.md). Poniżej zostaje przegląd etapów.

### Etap 1. Pętla bez końca (rdzeń)
- **Zapis i wczytanie gry** ✅ – jeden slot, zapis przy przejściu do nowego dnia.
- **Widoczne efekty działań** ✅ – świat czyta stan parafii i listę ukończonych prac, nowa rzecz dostaje najazd kamery.
- **Kalendarz i pełny rok liturgiczny** ✅ – prawdziwe daty, pięć okresów, święta stałe i ruchome, roraty, klimat okresów, pory roku, przewijanie dni.
- **Odpoczynek w ciągu dnia** ✅ – ławka z brewiarzem, sen na godziny, posiłek. Dziś po mszy i sprzątaniu zostaje pół dnia bez energii i jedynym wyjściem jest sen do rana.
- **Animacje czynności** ✅ – zamiatanie, spowiedź i sen jako krótkie sceny zamiast skoku zegara.
- **Oprawa świąt** – przygotowania przed Bożym Narodzeniem, Wielkanocą i odpustem, wynik oprawy 0–100 mnożący frekwencję i tacę, pamięć zeszłego roku jako poprzeczka.
- **Raport tygodnia i roku** – wykres tacy, zmiany wskaźników, statystyki parafian, kronika lat.
- **Wydarzenia i awarie** ✅ – 35 wydarzeń na warunkach i sezonach zamiast sztywnych dni, niepewne skutki odroczone, cztery kryzysy progowe i pięć awarii jako stanów trwałych, które kosztują codziennie, dopóki się ich nie naprawi.
- **Kolęda** – seria scen w mieszkaniach parafian, co roku w styczniu.

### Etap 2. Parafia jako mikropaństwo
- **Komputer na plebanii** – katalog inwestycji z zakładkami, poziomami i wymaganiami, podgląd tego, co inwestycja postawi w świecie, co odblokuje i ile daje tygodniowo.
- **Poziomy parafii 1–5** – liczone z parafian, stanu budynków, reputacji i ukończonych prac; otwierają kolejne półki katalogu. Inwestycje mają stopnie (nagłośnienie I–III, ogrzewanie I–III, parking I–III).
- **Inwestycje, po których można chodzić** – festyn stawia namioty, grill, dmuchaniec i tłum, cmentarz za kościołem otwiera pogrzeby, ministrant z koszykiem podnosi tacę. Każda inwestycja daje cykliczną korzyść, nie tylko liczbę.
- **Ludzie i rozmowy** – generator postaci z archetypami, parafianie z rutyną, rozmowy i nawracanie, stali parafianie jako zasób ze statystykami.
- **Punkty rozwoju i trzy drzewka** – administrator, duszpasterz, gospodarz; odblokowania skracają dzień i obniżają koszty.
- **Pracownicy** – kościelny, gosposia, organista, wikary, katechetka: zatrudnianie, delegowanie zadań, pensje w kosztach tygodnia, morale.
- **Kuria i ranga** – ocena kwartalna, awans na proboszcza i dalej, przeniesienie do gorszej parafii jako strata, nie koniec gry.

### Etap 3. Rozbudowa terenu i głębia
- **Rozbudowa budynków** – wyznaczone sloty: ogród plebanii, zakrystia, kaplica boczna, salka, dzwonnica, plac zabaw, pokoje na plebanii warunkujące zatrudnienie.
- **Warsztat i rzemiosło** – naprawa ławek, odnawianie figur, pisanie kazań wpływające na tacę.
- **Zużycie i przeglądy** – budynki się starzeją, przeglądy i ubezpieczenie parafii jako stały wydatek obniżający ryzyko awarii.
- **Więcej scen filmowych** – pogrzeb, ślub, chrzest, procesja Bożego Ciała.
- **Pogoda** – deszcz i śnieg wpływające na frekwencję i na to, czy festyn się uda.

### Etap 4. Ciało i dźwięk
- **Animacje postaci** – prosty model z kończynami z Blendera pod tym samym interfejsem co generator brył.
- **Dźwięk** – dzwony, kroki, deszcz, szum telewizora, organy. Zasoby na licencji CC0.
- **Interfejs na telefon** – większe przyciski, menu dostępne dotykiem z paska, testy na prawdziwym urządzeniu.

### Etap 5. Warstwa fabularna
- **Historia przejścia** – kronika generowana z decyzji, do przeczytania na końcu gry i do udostępnienia.
- **Postać księdza** – wybór imienia, pochodzenia i wady na start, które generują własne wydarzenia.
- **Drugi rok i wyższe stanowiska** – po awansie większa parafia, dziekanat, inne skale pieniędzy i problemów.
