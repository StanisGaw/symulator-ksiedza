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

### AC-1. Ekonomia parafii

**AC-1.1 – Źródła przychodów**
- Given: gracz prowadzi parafię
- When: mija okres rozliczeniowy
- Then: parafia otrzymuje przychody co najmniej z tacy i darowizn, a ich wysokość jest widoczna dla gracza

**AC-1.2 – Kategorie wydatków**
- Given: parafia posiada środki
- When: gracz otwiera panel finansów
- Then: może przeznaczyć pieniądze na co najmniej: bieżące wydatki, remonty, inwestycje, infrastrukturę parafii oraz działalność duszpasterską

**AC-1.3 – Budżet jest ograniczony**
- Given: gracz próbuje wydać więcej, niż posiada
- When: zatwierdza wydatek
- Then: gra nie pozwala na wydatek ponad stan (lub jasno komunikuje konsekwencje zadłużenia, jeśli taka mechanika zostanie dodana)

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

### AC-4. Specjalizacja księdza

**AC-4.1 – Dostępne style kariery**
- Given: gracz rozwija postać
- When: podejmuje decyzje lub wybiera ścieżkę rozwoju
- Then: może kierować postać w stronę co najmniej jednego z profili: **administrator**, **charyzmatyczny duszpasterz**, **budujący wpływy**

**AC-4.2 – Specjalizacja wpływa na rozgrywkę**
- Given: gracz ma wyraźną specjalizację
- When: pojawia się wydarzenie lub decyzja
- Then: specjalizacja zmienia dostępne opcje, ich koszt lub skuteczność

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

### AC-6. Hierarchia i kuria

**AC-6.1 – Kuria jako aktor gry**
- Given: gracz podjął istotną decyzję
- When: decyzja wpływa na parafię lub reputację
- Then: kuria reaguje, a relacje z kurią rosną lub maleją

**AC-6.2 – Tłumaczenie się z decyzji**
- Given: gracz podjął kontrowersyjną decyzję
- When: kuria się o niej dowiaduje
- Then: gracz musi wybrać sposób jej uzasadnienia, a wybór wpływa na relacje z kurią i dalszą karierę

### AC-7. Grupy interesów w parafii

**AC-7.1 – Parafianie nie są jednolici**
- Given: gra jest uruchomiona
- When: gracz przegląda parafię
- Then: widzi co najmniej dwie grupy parafian o różnych oczekiwaniach

**AC-7.2 – Konflikty między grupami**
- Given: grupy mają sprzeczne interesy
- When: gracz podejmuje decyzję faworyzującą jedną z nich
- Then: zadowolenie drugiej grupy spada, a konflikt może eskalować do wydarzenia

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
- Finanse: konto, wpływy i wydatki tygodnia, stałe koszty rozliczane w poniedziałek rano, pięć inwestycji z odroczonym efektem (remont dachu, ogrzewanie, nagłośnienie, festyn, przelew do kurii).
- Zasoby niefinansowe: reputacja, stan budynków, tradycjonaliści, młode rodziny, kuria. Zły stan budynków obniża reputację co tydzień, minus na koncie psuje relacje z kurią.
- Wydarzenia z wyborem i odroczoną konsekwencją: spór o godzinę mszy (dzień 2), pogrzeb sołtysa (dzień 3), telefon z kurii (dzień 5) oraz przeciek w dachu, gdy stan budynków spadnie poniżej 30.
- Zapis gry: jeden slot, zapisywany automatycznie przy każdym przejściu do nowego dnia. Zapisujemy tylko stan poranka, więc po wczytaniu gra zaczyna się o 7:00 na plebanii i nie trzeba odtwarzać pozycji gracza ani trwającej scenki. Przy starcie, gdy zapis istnieje, pojawia się okno „Kontynuuj / Nowa gra”.
- Świat czyta stan parafii: ukończone inwestycje trafiają na listę `built`, a zmiana stanu przebudowuje bieżącą lokację w miejscu, bez ruszania gracza.
- Cykl dnia: zegar biegnie w czasie rzeczywistym, czynności przesuwają go skokowo, sen na plebanii zaczyna nowy dzień o 7:00, zaśnięcie o północy kosztuje energię. Poranek pokazuje raport z konsekwencjami i rozliczeniem tygodnia, potem wydarzenia.
- Interfejs w rozdzielczości 1280×720 nad sceną renderowaną w 320×180: pasek stanu, podpowiedź interakcji, powiadomienia, okna wydarzeń, raportów, finansów i kroniki.

**Pliki:**
- `project.godot` – okno 1280×720 ze skalowaniem interfejsu, scena 3D w `SubViewport` 320×180 skalowanym bez wygładzania.
- `scripts/game.gd` – autoload ze stanem gry, zegarem, czynnościami, inwestycjami, rozliczeniem tygodnia i kolejką konsekwencji.
- `scripts/save_game.gd` – zapis i odczyt jednego slotu (`user://parafia.save`, JSON z numerem wersji). Nieznane pola są pomijane, brakujące zostawiają wartość domyślną, więc dołożenie nowego pola stanu nie unieważnia starych zapisów.
- `scripts/events.gd` – definicje wydarzeń.
- `scripts/location_manager.gd` – ładowanie lokacji, trwały gracz i kamera, punkty pojawienia.
- `scripts/location_base.gd` i `scripts/locations/*.gd` – lokacje budowane z brył, z kolizjami, drzwiami i obiektami interakcji.
- `scripts/interactable.gd` – obiekt interakcji: drzwi, czynność, biurko, łóżko, kronika.
- `scripts/mass_director.gd` – reżyser sceny mszy: wejście, komunia, wyjście parafian, raportowanie postępu do zegara.
- `scripts/locations/visit.gd` – lokacja i zarazem reżyser sceny odwiedzin chorej: kamienica, sylwetka w oknach, pokój chorej, najazd kamery.
- `scripts/ui.gd` – cały interfejs.
- `shaders/toon.gdshader` i `shaders/outline.gdshader` – cieniowanie toon w trzech stopniach oraz obrys metodą odwróconej bryły (`next_pass`).
- `scripts/palette.gd` – paleta kierunku „mroczny” w jednym miejscu.
- `scripts/player.gd` – ksiądz z brył, ruch względem stałej kamery, czujnik obiektów interakcji, spadek energii przy chodzeniu.
- `scripts/camera_rig.gd` – kamera ortograficzna pod stałym kątem, podąża za graczem, gracz nie może jej obracać.
- `scripts/day_night.gd` – cykl dnia z pochmurnym, zimnym światłem za dnia i bursztynowymi akcentami nocą; latarnie włączają się o zmierzchu.
- `scripts/touch_controls.gd` – wirtualny joystick i przyciski dotykowe, zasilają te same akcje co klawiatura.

**Argumenty debugowe** (po `--`): `--loc=church|rectory` startuje w lokacji, `--modal=finance|status|event|report` otwiera okno, `--sleep` przechodzi do dnia 2, `--mass` razem z `--loc=church` uruchamia scenę mszy, `--visit` uruchamia scenę odwiedzin chorej (z `--trace` wypisuje momenty faz), `--touch` pokazuje sterowanie dotykowe na komputerze, `--wipe` kasuje zapis przed startem, `--continue` otwiera okno wczytania. Przykład:

```bash
godot --path . -- --loc=church
```

**Sprawdzenie bez okna** (import i 120 klatek w trybie headless):

```bash
godot --headless --path . --import && godot --headless --path . --quit-after 120
```

**Wersja w przeglądarce:** każdy push na gałąź `main` uruchamia workflow w `.github/workflows/deploy-pages.yml`, który pobiera Godota i szablony eksportu, buduje wersję webową (preset `Web` z wyłączonymi wątkami, żeby działała na GitHub Pages bez specjalnych nagłówków) i publikuje ją na GitHub Pages. Renderer to Compatibility, bo tylko on działa w przeglądarce.

**Zrzut klatek do PNG** (wymaga okna, zapisuje do wskazanego katalogu):

```bash
godot --path . --quit-after 40 --fixed-fps 30 --write-movie /tmp/frames/f.png
```

---

## Plan rozwoju

Kolejność wynika z tego, co najszybciej zamienia prototyp w grę, którą da się przejść i ocenić. Każdy etap kończy się wersją na GitHub Pages.

Rama kampanii: gra zaczyna się 1 grudnia i trwa cztery tygodnie Adwentu. Finał to Pasterka i ocena kurii, a kolęda jest epilogiem. Pełny rok liturgiczny z Wielkim Postem, Niedzielą Palmową i odpustem to Etap 3.

### Etap 1. Pętla, którą da się przegrać i wygrać (rdzeń)
- **Zapis i wczytanie gry** ✅ – jeden slot, zapis przy przejściu do nowego dnia, okno „Kontynuuj / Nowa gra”. Razem z tym pamięć o ukończonych inwestycjach i przebudowa lokacji w miejscu.
- **Widoczne efekty działań** – kościół, plac i plebania wyglądają inaczej zależnie od stanu budynków i tego, co zbudowano: łatany albo nowy dach, wiadro w nawie, chwasty, głośniki, grzejniki, kwiaty. Po zakończeniu prac krótka scenka pokazująca zmianę.
- **Koniec gry i cel** – po czterech tygodniach ocena kurii: awans na proboszcza, „zostajesz wikarym” albo przeniesienie karne. Ocena z reputacji, finansów, stanu budynków, relacji z kurią i liczby rozwiązanych kryzysów. Razem z tym kalendarz: prawdziwe daty, okresy liturgiczne, Adwent.
- **Koszty utrzymania jako funkcja** – stała tygodniowa zamienia się w sumę rachunków i pensji, zanim dojdą etaty.
- **Ekran tygodnia** – rozbudowany poniedziałkowy raport z wykresem tacy, zmianami wskaźników, listą decyzji i prognozą oceny kurii.
- **Więcej wydarzeń** – docelowo 20–25, w tym łańcuchy (decyzja z dnia 2 wraca w dniu 9), wydarzenia zależne od stanu (bunt parafian przy niskiej reputacji, kontrola z kurii przy minusie na koncie) i losowe drobne (pogrzeb, ślub, chrzest).
- **Epilog: kolęda** – seria krótkich scen w mieszkaniach parafian, domykająca kampanię.

### Etap 2. Parafia jako mikropaństwo (strategia)
- **Pracownicy** – kościelny, gosposia, organista, wikary, katechetka. Zatrudnianie z puli kandydatów z cechami, delegowanie zadań na dzień, pensje w kosztach tygodnia, morale, odejścia, trzy poziomy rozwoju ze ścieżkami.
- **Różnorodność postaci** – jeden generator postaci dla całej gry: archetypy (babcia w chuście, dziecko, ministrant, siostra zakonna), wzrost, tusza, dodatki, stały wygląd danej osoby między niedzielami.
- **Rozbudowa terenu i budynków** – wyznaczone sloty zamiast dowolnej siatki: parking, plac zabaw, gablota, dzwonnica; ogród plebanii z warzywnikiem i pasieką; zakrystia, kaplica boczna, chór; pokoje na plebanii. Pokój dla wikarego i kuchnia są warunkiem zatrudnienia.
- **Grupy interesów z twarzami** – po jednej postaci na grupę, prośby z terminem, wdzięczność albo obraza.
- **Drzewko rozwoju gracza i kuria jako aktor** – trzy ścieżki (administrator, duszpasterz, budujący wpływy), sprawozdania, wezwania, scena wizyty w kurii.

### Etap 3. Pełny rok i klimat
- **Rok liturgiczny** – święta ruchome liczone z Wielkanocy, Wielki Post, Niedziela Palmowa, Wielkanoc, Boże Ciało, odpust parafialny, festyn.
- **Pogoda i pory roku** – deszcz, śnieg, długość dnia, wygląd placu.
- **Postacie niezależne z rutyną** – parafianie chodzą po placu, przychodzą na mszę o ustalonej godzinie, kościelny sprząta.
- **Więcej czynności rzemieślniczych** – warsztat: naprawa ławek, odnawianie figur, pisanie kazania wpływające na tacę.
- **Więcej scen filmowych** – pogrzeb na cmentarzu, ślub, festyn.

### Etap 4. Ciało i dźwięk
- **Animacje postaci** – prosty model z kończynami z Blendera pod tym samym interfejsem co generator brył.
- **Dźwięk** – dzwony, kroki, deszcz, szum telewizora, organy. Zasoby na licencji CC0.
- **Interfejs na telefon** – większe przyciski, menu dostępne dotykiem z paska, testy na prawdziwym urządzeniu.

### Etap 5. Warstwa fabularna
- **Historia przejścia** – kronika generowana z decyzji, do przeczytania na końcu gry i do udostępnienia.
- **Postać księdza** – wybór imienia, pochodzenia i wady na start, które generują własne wydarzenia.
- **Drugi rok i wyższe stanowiska** – po awansie większa parafia, dziekanat, inne skale pieniędzy i problemów.
