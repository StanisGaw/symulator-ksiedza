class_name Events
## Wydarzenia. Trzy rodzaje, wszystkie w tym samym formacie:
##
## SCRIPTED – pierwszy tydzień, sztywno na dany dzień. Uczą gracza, że decyzja ma skutki.
## POOL     – właściwa gra: losowane z wagami spośród tych, których warunki są spełnione.
## CRISES   – progi. Nie są losowane: wchodzą same, gdy parafia jest w złym stanie.
##
## Warunki w "require":
##   min_day / max_day  – zakres dni gry
##   season             – okres liturgiczny (Adwent, Wielki Post, ...)
##   part               – pora roku (zima, wiosna, lato, jesień)
##   built / not_built   – ukończone inwestycje
##   breakdown / no_breakdown – trwające awarie
##   min / max          – progi wskaźników, np. {"reputation": 60} albo {"condition": 30}
##   flags              – zapamiętane decyzje, np. {"dean_plan": "together"}
##
## Opcje mogą mieć: "effects" (od ręki), "set" (zmiana stanu gry), "special" (kod),
## "breakdown" (awaria od ręki), "fix" (koniec awarii) oraz "delayed" – skutek odroczony,
## który może być niepewny: przy "chance" losuje się między "text"/"effects"
## a "else_text"/"else_effects".

const SCRIPTED := [
	{
		"id": "mass_hour", "day": 2, "title": "Spór o godzinę głównej mszy w niedzielę",
		"text": "Po porannej mszy czekają na Ciebie dwie delegacje. W niedziele i święta odprawiasz o 7:00, 12:00 i 19:00, w dni powszednie o 7:00 i 19:00. Starsi parafianie chcą, żeby główna msza, którą po staremu nazywają sumą, wróciła na 7:00, a południową żebyś odwołał. Młode rodziny proszą o 11:00, bo dzieci nie wstaną wcześniej. Kościelny przypomina, że każda msza to godzina Twojego czasu, a opuszczonej nikt nie wybaczy. Zmiana dotyczy tylko niedziel i świąt.",
		"options": [
			{"label": "Niedziele i święta: 7:00 i 19:00, bez południowej", "effects": {"trad": 8, "young": -6}, "set": {"sunday_hours": [7, 19]},
				"flags": {"mass_hours_changed": true, "mass_hours_choice": "early"},
				"delayed": {"days": 4, "text": "Kilka młodych rodzin zaczęło jeździć na mszę do sąsiedniej parafii. Młode rodziny -5, reputacja -2.", "effects": {"young": -5, "reputation": -2}}},
			{"label": "Niedziele i święta: 11:00 i 19:00, główna z dziećmi", "effects": {"young": 8, "trad": -6}, "set": {"sunday_hours": [11, 19]},
				"flags": {"mass_hours_changed": true, "mass_hours_choice": "families"},
				"delayed": {"days": 4, "text": "Tradycjonaliści napisali list do kurii w sprawie „nowinek”. Kuria -4.", "effects": {"curia": -4},
					"mail": {"curia_about": "przeniesienie sumy na 11:00"}}},
			{"label": "Niedziele i święta: 7:00, 11:00 i 19:00, trzy msze", "effects": {"trad": 3, "young": 3}, "set": {"sunday_hours": [7, 11, 19]},
				"flags": {"mass_hours_changed": true, "mass_hours_choice": "three_masses"},
				"delayed": {"days": 7, "text": "Organista upomina się o dodatek za trzecią mszę w niedzielę. -600 zł.", "effects": {"money": -600}}},
		]
	},
	{
		"id": "funeral", "day": 3, "title": "Telefon: pogrzeb pana Zenona",
		"text": "Dzwoni rodzina Zenona Kowalczyka, znanego w parafii sołtysa. Pogrzeb ma być jutro, rodzina liczy na ciebie osobiście i sugeruje hojną ofiarę. Masz jednak już zaplanowany cały dzień.",
		"options": [
			{"label": "Odprawię pogrzeb osobiście", "effects": {"money": 800, "reputation": 2, "energy": -30, "respect": 2}},
			{"label": "Poproszę księdza z sąsiedniej parafii", "effects": {"reputation": -2},
				"delayed": {"days": 3, "text": "Rodzina Zenona opowiada we wsi, że ksiądz nie miał czasu dla sołtysa. Reputacja -3.", "effects": {"reputation": -3}}},
		]
	},
	{
		"id": "curia_call", "day": 5, "title": "Telefon z kurii",
		"text": "Ksiądz kanclerz pyta uprzejmie o sprawozdanie finansowe za pierwszy tydzień. Dodaje, że biskup „interesuje się młodymi księżmi”.",
		"options": [
			{"label": "Wyślę uczciwe sprawozdanie", "special": "honest_report", "honest": true},
			{"label": "Poproszę o tydzień zwłoki",
				"delayed": {"days": 3, "text": "Kuria przypomina o zaległym sprawozdaniu, tym razem mniej uprzejmie. Kuria -5.", "effects": {"curia": -5}}},
			{"label": "Dołączę 1 500 zł „na cele diecezji”", "effects": {"money": -1500, "curia": 6},
				"delayed": {"days": 6, "text": "Ktoś z rady parafialnej dowiedział się o przelewie do kurii. Ludzie gadają. Reputacja -4.", "effects": {"reputation": -4}}},
		]
	},
]


const POOL := [
	{
		"id": "organ_silent", "weight": 10, "cooldown": 40, "require": {"min_day": 8},
		"title": "Organy zamilkły",
		"text": "W środku pieśni na wejście organy zacharczały i ucichły. Organista twierdzi, że to dmuchawa i że on tego nie ruszy, bo instrument jest z lat pięćdziesiątych. Do niedzieli zostały cztery dni.",
		"options": [
			{"label": "Wezwij firmę od organów, 2 500 zł", "effects": {"money": -2500, "trad": 3},
				"scale": "zarzadzanie"},
			{"label": "Na razie puszczaj pieśni z odtwarzacza", "effects": {"young": 2, "trad": -5},
				"delayed": {"days": 5, "text": "W parafii mówi się, że „u nas teraz gra radio”. Reputacja -3.", "effects": {"reputation": -3}}},
			{"label": "Śpiewamy bez organów, jak na misjach", "effects": {"trad": 2, "reputation": -1, "respect": 2}},
		]
	},
	{
		"id": "first_communion", "weight": 14, "cooldown": 300, "require": {"part": "wiosna", "min_day": 10},
		"title": "Przygotowania do Pierwszej Komunii",
		"text": "Rodzice dzieci z trzeciej klasy przyszli ustalić szczegóły. Część chce skromnie, po staremu. Część już wynajęła salę i pyta, czy fotograf może wejść do prezbiterium i czy da się zamówić białe alby dla wszystkich, żeby nie było widać, kogo na co stać.",
		"options": [
			{"label": "Skromnie, jednakowe alby, fotograf z boku", "effects": {"money": 900, "trad": 4, "young": -3, "reputation": 3}},
			{"label": "Wielka oprawa, wynajęta dekoracja", "effects": {"money": -1800, "young": 6, "trad": -3},
				"delayed": {"days": 5, "text": "Ofiary po Komunii przerosły oczekiwania. +2 600 zł.", "effects": {"money": 2600}}},
			{"label": "Przygotowanie zrzuć na siostrę katechetkę", "effects": {"energy": 15, "reputation": -3, "young": -2}},
		]
	},
	{
		"id": "local_media", "weight": 9, "cooldown": 35, "require": {"min_day": 12},
		"title": "Portal lokalny pyta o finanse parafii",
		"text": "Dziennikarka z portalu powiatowego pisze uprzejmego maila z pytaniem, ile parafia zebrała na remont i na co dokładnie poszły pieniądze. Na końcu dodaje, że tekst ukaże się tak czy inaczej.",
		"options": [
			{"label": "Udziel wywiadu i pokaż zestawienie", "effects": {"reputation": 5},
				"delayed": {"days": 4, "text": "Kuria przypomina, że z mediami rozmawia rzecznik, nie proboszcz. Kuria -3.", "effects": {"curia": -3}}},
			{"label": "Bez komentarza", "effects": {"reputation": -4},
				"delayed": {"days": 3, "chance": 0.5,
					"text": "Tekst wyszedł z akapitem „ksiądz odmówił odpowiedzi”. Reputacja -3.", "effects": {"reputation": -3},
					"else_text": "Tekst przeszedł bez echa, wyparło go otwarcie marketu. Nic się nie stało.", "else_effects": {}}},
			{"label": "Odeślij ją do rzecznika kurii", "effects": {"curia": 4, "reputation": -1}},
		]
	},
	{
		"id": "caritas_fire", "weight": 10, "cooldown": 45, "require": {"min_day": 9},
		"title": "Spalił się dom Wiśniewskich",
		"text": "W nocy poszedł dach, rodzina z trójką dzieci wyszła w tym, co miała na sobie. Nikomu nic się nie stało. Ludzie już pytają, co parafia zrobi, i pytają w sposób, który nie zakłada odpowiedzi „nic”.",
		"options": [
			{"label": "Cała niedzielna taca idzie do Wiśniewskich", "effects": {"money": -1800, "reputation": 8, "curia": 3, "respect": 3}},
			{"label": "Zbiórka po mszach i apel w ogłoszeniach", "effects": {"money": -400, "reputation": 4, "energy": -10}},
			{"label": "Wspomnę o nich w modlitwie wiernych", "effects": {"reputation": -3, "trad": -2}},
		]
	},
	{
		"id": "rich_wedding", "weight": 9, "cooldown": 30, "require": {"min_day": 14},
		"title": "Ślub z listą życzeń",
		"text": "Państwo młodzi przyjechali z wydrukowanym planem ceremonii. Chcą własnego wokalistę zamiast organisty, fotografa przy ołtarzu i wejścia panny młodej do utworu, którego tytułu wolisz nie powtarzać z ambony. Ofiara, o której mówią, jest bardzo konkretna.",
		"options": [
			{"label": "Zgoda na wszystko, ofiara 3 500 zł", "effects": {"money": 3500, "trad": -6},
				"delayed": {"days": 6, "text": "Nagranie ze ślubu obeszło parafię. Starsi pytają, czy to był jeszcze kościół. Reputacja -3.", "effects": {"reputation": -3}}},
			{"label": "W kościele obowiązują zasady kościoła", "effects": {"trad": 5, "young": -3, "money": 600}},
			{"label": "Fotograf z boku, wokalista z chóru, reszta jak chcą", "effects": {"money": 1800, "trad": -1, "young": 2}},
		]
	},
	{
		"id": "school_hours", "weight": 9, "cooldown": 60, "require": {"part": "jesień", "min_day": 10},
		"title": "Dyrektor tnie godziny religii",
		"text": "Dyrektorka szkoły informuje, że od listopada religia będzie na siódmej lekcji, po wszystkim, bo tak wyszło z arkusza. Wszyscy wiedzą, ile dzieci zostaje na siódmą lekcję.",
		"options": [
			{"label": "Idź do niej i postaw sprawę twardo", "effects": {"trad": 5, "young": -4, "energy": -15}},
			{"label": "Przyjmij to i zrób spotkania w salce", "effects": {"young": 4, "trad": -5, "money": -300}},
			{"label": "Napisz do kurii o interwencję", "effects": {"curia": 3},
				"delayed": {"days": 5, "text": "Kuria napisała do gminy ponad głową dyrektorki. W szkole jest zimno. Reputacja -3.", "effects": {"reputation": -3}}},
		]
	},
	{
		"id": "sacristan_drinking", "weight": 8, "cooldown": 50, "require": {"min_day": 15},
		"title": "Kościelny znów pachnie od rana",
		"text": "Pan Mietek jest w parafii dłużej niż trzech poprzednich proboszczów. Dziś nie zapalił świec przed mszą i przewrócił stojak przy chrzcielnicy. Ludzie widzieli.",
		"options": [
			{"label": "Zwolnij go", "effects": {"condition": -5, "reputation": -2, "trad": -4},
				"delayed": {"days": 6, "text": "Nikt nie chce pracować za te pieniądze. Kościół otwierasz sam. Energia -10.", "effects": {"energy": -10},
					"mail": {"curia_about": "zwolnienie kościelnego po dwudziestu latach"}}},
			{"label": "Ostatnia szansa i klucze od piwnicy zostają u ciebie", "effects": {"energy": -15},
				"delayed": {"days": 7, "chance": 0.55,
					"text": "Mietek wytrzymał tydzień. Kościół lśni, a on chodzi wyprostowany. Stan budynków +5, szacunek +2.", "effects": {"condition": 5, "respect": 2},
					"else_text": "Mietek wytrzymał cztery dni. W sobotę nie otworzył kościoła na pogrzeb. Reputacja -4.", "else_effects": {"reputation": -4}}},
			{"label": "Udawaj, że nie widzisz", "effects": {"reputation": -2, "trad": -2}},
		]
	},
	{
		"id": "grave_vandalism", "weight": 9, "cooldown": 40, "require": {"min_day": 12, "built": "cemetery"},
		"title": "Przewrócone nagrobki",
		"text": "Rano na nowej kwaterze leży osiem przewróconych krzyży i rozbita lampka. Rodziny już dzwonią. Ktoś przypomina, że mur ma bramę, która nie ma zamka.",
		"options": [
			{"label": "Zgłoś na policję i postaw krzyże z ludźmi", "effects": {"reputation": 3, "energy": -20, "respect": 2}},
			{"label": "Monitoring i zamek w bramie, 3 000 zł", "effects": {"money": -3000, "condition": 3, "reputation": 4}},
			{"label": "Niech rodziny poprawią swoje", "effects": {"reputation": -5, "trad": -4},
				"delayed": {"days": 2, "text": "", "mail": {"curia_about": "odmowę uprzątnięcia zdewastowanych grobów"}}},
		]
	},
	{
		"id": "bishop_visitation", "weight": 7, "cooldown": 70, "require": {"min_day": 20},
		"title": "Wizytacja biskupa za trzy dni",
		"text": "Kanclerz uprzedza życzliwie: biskup będzie w dekanacie i wstąpi do ciebie. Zobaczy kościół, księgi i to, jak wygląda parafia w zwykły dzień. Życzliwość w jego głosie jest wyraźnie ostrzeżeniem.",
		"options": [
			{"label": "Rzuć wszystko i doprowadź parafię do porządku", "effects": {"energy": -25, "money": -1200},
				"delayed": {"days": 3, "special": "visitation_ready", "text": "Biskup przyjechał."}},
			{"label": "Niech zobaczy, jak jest naprawdę", "effects": {},
				"delayed": {"days": 3, "special": "visitation_raw", "text": "Biskup przyjechał."}},
		]
	},
	{
		"id": "heating_bill", "weight": 10, "cooldown": 30, "require": {"part": "zima", "built": "heating"},
		"title": "Rachunek za ogrzewanie kościoła",
		"text": "Przyszedł rachunek za miesiąc grzania nawy, w której jest dwanaście metrów do sklepienia. Kwota jest taka, że kościelny obejrzał ją pod światło.",
		"options": [
			{"label": "Zapłać w całości", "effects": {"money": -2200, "trad": 2}},
			{"label": "Grzejemy tylko w niedziele i święta", "effects": {"money": -900, "trad": -4}},
			{"label": "Do wiosny wytrzymamy w kurtkach", "effects": {"trad": -8, "young": -4},
				"delayed": {"days": 6, "text": "Na porannych mszach zostało po kilkanaście osób. Reputacja -3.", "effects": {"reputation": -3}}},
		]
	},
	{
		"id": "youth_band", "weight": 9, "cooldown": 40, "require": {"min_day": 12},
		"title": "Młodzież chce grać na mszy",
		"text": "Czwórka licealistów z gitarami i cajonem pyta, czy mogliby grać raz w miesiącu. Ćwiczą w garażu u Kacpra i, sądząc po nagraniu, ćwiczą naprawdę. Pani Krystyna od różańca już wie i już jest przeciw.",
		"options": [
			{"label": "Zgoda, raz w miesiącu na sumie", "effects": {"young": 7, "trad": -5}},
			{"label": "Tylko na mszy wieczornej", "effects": {"young": 4, "trad": -1, "reputation": 1}},
			{"label": "W kościele grają organy", "effects": {"young": -5, "trad": 4},
				"delayed": {"days": 8, "text": "Trzech z nich nie widziałeś od tamtej rozmowy. Młode rodziny -3.", "effects": {"young": -3}}},
		]
	},
	{
		"id": "attic_noise", "weight": 8, "cooldown": 30, "require": {"min_day": 8, "no_breakdown": "martens"},
		"title": "Coś chodzi nad sklepieniem",
		"text": "Od kilku nocy słychać na strychu kroki, za ciężkie jak na ptaki. Kościelny mówi, że to kuny i że jak się je zostawi, to przegryzą kable i zrzucą tynk. Firma z miasta może przyjechać jutro.",
		"options": [
			{"label": "Wezwij firmę, 900 zł", "effects": {"money": -900}},
			{"label": "Sam wejdź na strych z latarką", "effects": {"energy": -15},
				"delayed": {"days": 2, "chance": 0.5,
					"text": "Zabita deska w szczycie wystarczyła. Cicho.", "effects": {},
					"else_text": "Wróciły i jest ich więcej.", "else_effects": {}, "else_breakdown": "martens"}},
			{"label": "Strych to nie priorytet", "effects": {},
				"delayed": {"days": 3, "text": "Na posadzce leży tynk zrzucony ze sklepienia.", "breakdown": "martens"}},
		]
	},
	{
		"id": "storm_warning", "weight": 10, "cooldown": 25, "require": {"min_day": 6, "no_breakdown": "roof_storm"},
		"title": "Ostrzeżenie o wichurze",
		"text": "W nocy ma wiać osiemdziesiąt kilometrów na godzinę. Blacha na połaci od północy jest podwinięta od lat i wszyscy o tym wiedzą, łącznie z tobą.",
		"options": [
			{"label": "Zabezpiecz połać jeszcze dziś, 800 zł", "effects": {"money": -800, "energy": -15},
				"delayed": {"days": 1, "chance": 0.12,
					"text": "Mimo zabezpieczenia wiatr zerwał kawałek blachy.", "effects": {}, "breakdown": "roof_storm",
					"else_text": "Wiało całą noc, ale dach został na miejscu.", "else_effects": {"respect": 1}}},
			{"label": "Zdejmij chociaż to, co wisi na wieży", "effects": {"energy": -8},
				"delayed": {"days": 1, "chance": 0.35,
					"text": "Blacha poszła nad prezbiterium.", "effects": {}, "breakdown": "roof_storm",
					"else_text": "Wichura przeszła bokiem. Leży tylko gałąź na parkingu.", "else_effects": {}}},
			{"label": "Dach przetrwał gorsze noce", "effects": {},
				"delayed": {"days": 1, "chance": 0.6,
					"text": "Dach nie przetrwał tej nocy.", "effects": {}, "breakdown": "roof_storm",
					"else_text": "Dach przetrwał także tę noc. Na razie.", "else_effects": {}}},
		]
	},
	{
		"id": "tax_office", "weight": 7, "cooldown": 60, "require": {"min_day": 25},
		"title": "Pismo z urzędu skarbowego",
		"text": "Urząd prosi o wyjaśnienie darowizn wpłaconych na konto parafii w ostatnim kwartale. Pismo jest grzeczne, ma cztery strony i termin czternastu dni.",
		"options": [
			{"label": "Usiądź do papierów i odpisz sam", "effects": {"energy": -25, "curia": 3, "respect": 2}},
			{"label": "Przekaż sprawę księgowej kurii", "effects": {"money": -700, "curia": 2}},
			{"label": "Odłóż to, termin jeszcze jest", "effects": {},
				"delayed": {"days": 10, "text": "Urząd wezwał ponownie, tym razem z pouczeniem. Kuria -5, -900 zł.", "effects": {"curia": -5, "money": -900}}},
		]
	},
	{
		"id": "homeless_man", "weight": 8, "cooldown": 30, "require": {"part": "zima", "min_day": 8},
		"title": "W kruchcie śpi człowiek",
		"text": "Pan Rysiek mieszkał kiedyś w bloku przy szkole. Od tygodnia sypia w kruchcie, bo jest tam kaloryfer. Rano zostaje po nim zapach, o którym parafianie mówią do ciebie, a nie do niego. Na dworze minus dwanaście.",
		"options": [
			{"label": "Niech śpi, dostanie koc i herbatę", "effects": {"reputation": 5, "trad": -5, "condition": -1, "respect": 3}},
			{"label": "Zawieź go do schroniska w powiecie", "effects": {"energy": -20, "reputation": 2, "trad": 1}},
			{"label": "Zamknij kruchtę na noc", "effects": {"trad": 4, "reputation": -5},
				"delayed": {"days": 5, "text": "Rysiek trafił do szpitala z odmrożeniami. Ludzie pamiętają, kto zamknął kruchtę. Reputacja -4, szacunek -3.", "effects": {"reputation": -4, "respect": -3}}},
		]
	},
	{
		"id": "businessman_donation", "weight": 8, "cooldown": 45, "require": {"min_day": 18},
		"title": "Darowizna z prośbą",
		"text": "Właściciel największej firmy w gminie wpłaca osiem tysięcy na remont. Przy okazji wspomina, że rada gminy głosuje w przyszłym tygodniu nad jego działką i że dobre słowo z ambony bardzo by pomogło.",
		"options": [
			{"label": "Przyjmij i podziękuj mu z ambony", "effects": {"money": 8000, "curia": 2},
				"delayed": {"days": 8, "text": "Ludzie połączyli kazanie z głosowaniem rady. Reputacja -6, kuria -3.", "effects": {"reputation": -6, "curia": -3}}},
			{"label": "Przyjmij, ale bez słowa z ambony", "effects": {"money": 5000},
				"delayed": {"days": 8, "chance": 0.35,
					"text": "I tak się rozeszło, że dał na kościół przed głosowaniem. Reputacja -4.", "effects": {"reputation": -4},
					"else_text": "Sprawa ucichła. Pieniądze zostały, działka też.", "else_effects": {}}},
			{"label": "Podziękuj i odmów", "effects": {"reputation": 4, "trad": 3, "respect": 3}},
		]
	},
	{
		"id": "pilgrimage", "weight": 9, "cooldown": 300, "require": {"part": "lato", "min_day": 15},
		"title": "Piesza pielgrzymka na Jasną Górę",
		"text": "Grupa z parafii idzie co roku. W tym roku pytają, czy pójdziesz z nimi. To dziewięć dni, trzysta kilometrów i parafia zostaje bez księdza albo z zastępstwem, za które trzeba zapłacić.",
		"options": [
			{"label": "Idź z nimi", "effects": {"money": -1500, "energy": -30, "reputation": 8, "trad": 6, "respect": 5}},
			{"label": "Odprowadź ich i wróć na plebanię", "effects": {"reputation": 2, "energy": -10}},
			{"label": "Nie w tym roku", "effects": {"trad": -4, "reputation": -2}},
		]
	},
	{
		"id": "advent_prep", "weight": 12, "cooldown": 300, "require": {"season": "Adwent"},
		"title": "Oprawa świąt",
		"text": "Do Wigilii zostały niecałe trzy tygodnie. Kwiaciarka pyta o zamówienie, kościelny o szopkę, a chór o dodatkowe próby. Wszyscy pamiętają, jak to wyglądało w zeszłym roku, i wszyscy o tym mówią.",
		"options": [
			{"label": "Pełna oprawa: szopka, kwiaty, chór", "effects": {"money": -3200, "trad": 5, "young": 3},
				"delayed": {"days": 7, "text": "Pasterka i świąteczne msze były pełne. Reputacja +5, taca to pokazała.", "effects": {"reputation": 5, "money": 2800}}},
			{"label": "Skromnie, ale porządnie", "effects": {"money": -1200, "trad": 1},
				"delayed": {"days": 7, "text": "Święta przeszły spokojnie. Nikt nie narzekał, nikt nie zachwycał się. Reputacja +1.", "effects": {"reputation": 1}}},
			{"label": "Stoi szopka z zeszłego roku i wystarczy", "effects": {"trad": -5},
				"delayed": {"days": 7, "text": "Zdjęcia szopki krążą po parafii jako żart. Reputacja -4, młode rodziny -3.", "effects": {"reputation": -4, "young": -3}}},
		]
	},
	{
		"id": "neighbour_parish", "weight": 8, "cooldown": 50, "require": {"min_day": 22, "max": {"reputation": 55}},
		"title": "U sąsiada jest ładniej",
		"text": "Ksiądz z sąsiedniej parafii wyremontował kościół, założył ogrzewanie podłogowe i prowadzi profil, który ogląda pół powiatu. Twoi parafianie zaczęli jeździć tam na niedzielę. Sześć kilometrów to nie jest daleko.",
		"options": [
			{"label": "Pojedź do niego i poproś o radę", "effects": {"curia": 2, "reputation": 2, "respect": 2, "energy": -10}},
			{"label": "Powiedz z ambony, gdzie jest ich parafia", "effects": {"trad": 3, "young": -5, "reputation": -4}},
			{"label": "Rób swoje i nie komentuj", "effects": {"respect": 1},
				"delayed": {"days": 9, "chance": 0.5,
					"text": "Kilka rodzin wróciło. Mówią, że u sąsiada jest ładnie, ale obco. Reputacja +3.", "effects": {"reputation": 3},
					"else_text": "Nie wrócili. Na sumie widać puste ławki z tyłu. Młode rodziny -4.", "else_effects": {"young": -4}}},
		]
	},
	{
		"id": "choir_conflict", "weight": 8, "cooldown": 40, "require": {"min_day": 14},
		"title": "Wojna w chórze",
		"text": "Chór rozpadł się na dwie części: te, które śpiewają od trzydziestu lat, i te, które przyszły przed rokiem i chcą śpiewać czterogłosowo. Obie strony przyszły osobno i obie mówią, że odejdą.",
		"options": [
			{"label": "Stań po stronie starych", "effects": {"trad": 6, "young": -5}},
			{"label": "Stań po stronie nowych", "effects": {"young": 6, "trad": -5}},
			{"label": "Posadź obie strony przy jednym stole", "needs": {"charyzma": 6},
				"effects": {"energy": -10, "trad": 4, "young": 4, "reputation": 3}},
			{"label": "Dwa chóry, dwie msze", "effects": {"energy": -10, "money": -400, "trad": 2, "young": 2},
				"delayed": {"days": 6, "chance": 0.55,
					"text": "Oba chóry śpiewają i udają, że drugiego nie ma. Działa. Reputacja +3.", "effects": {"reputation": 3},
					"else_text": "Na sumie zaśpiewały oba naraz. Ludzie wychodzili wcześniej. Reputacja -3.", "else_effects": {"reputation": -3}}},
		]
	},
	{
		"id": "night_call", "weight": 11, "cooldown": 20, "require": {"min_day": 6},
		"title": "Telefon o drugiej w nocy",
		"text": "Córka pani Heleny mówi, że matka słabnie i prosi o księdza. To dwanaście kilometrów w jedną stronę, a rano masz mszę o siódmej.",
		"options": [
			{"label": "Ubierz się i jedź", "effects": {"energy": -30, "reputation": 5, "respect": 4}},
			{"label": "Powiedz, że przyjedziesz zaraz po porannej mszy", "effects": {"reputation": -3, "respect": -2},
				"delayed": {"days": 2, "chance": 0.45,
					"text": "Pani Helena zmarła nad ranem, zanim dojechałeś. Rodzina to powtarza. Reputacja -5, szacunek -3.", "effects": {"reputation": -5, "respect": -3},
					"else_text": "Pani Helena dotrwała do rana i przyjęła sakramenty. Reputacja +2.", "else_effects": {"reputation": 2}}},
		]
	},
	{
		"id": "viral_sermon", "weight": 7, "cooldown": 50, "require": {"min_day": 20},
		"title": "Ktoś nagrał twoje kazanie",
		"text": "Półtoraminutowy fragment niedzielnego kazania wisi w sieci i ma już kilkanaście tysięcy wyświetleń. Komentarze są takie, jakie zwykle są komentarze.",
		"options": [
			{"label": "Nie reaguj", "special": "viral_quiet"},
			{"label": "Nagraj odpowiedź i wrzuć ją sam", "special": "viral_answer"},
			{"label": "Poproś o usunięcie nagrania", "effects": {"young": -4, "reputation": -2},
				"delayed": {"days": 3, "text": "Prośba o usunięcie trafiła do sieci razem z nagraniem. Reputacja -3.", "effects": {"reputation": -3}}},
		]
	},
	{
		"id": "collection_theft", "weight": 6, "cooldown": 60, "require": {"min_day": 24},
		"title": "Z zakrystii zginęły pieniądze",
		"text": "W szufladzie brakuje tacy z soboty. Klucz mają trzy osoby, w tym ty. Kościelny blednie, gdy o tym mówisz, i to niczego nie rozstrzyga.",
		"options": [
			{"label": "Zgłoś na policję", "effects": {"money": -900, "reputation": -3, "trad": -3},
				"delayed": {"days": 5, "chance": 0.4,
					"text": "Sprawa się wyjaśniła: to nie był nikt z parafii. Reputacja +4.", "effects": {"reputation": 4},
					"else_text": "Sprawę umorzono. Zostało podejrzenie i trzy osoby, które na siebie patrzą. Reputacja -3.", "else_effects": {"reputation": -3}}},
			{"label": "Załatw to po cichu i wymień zamki", "effects": {"money": -1400, "condition": 2, "respect": 1}},
			{"label": "Nie było tacy, nie ma sprawy", "effects": {"money": -900, "reputation": -1},
				"delayed": {"days": 7, "text": "Zginęła kolejna taca. -1 100 zł.", "effects": {"money": -1100}}},
		]
	},
	{
		"id": "roof_leak", "weight": 12, "cooldown": 20, "require": {"max": {"condition": 30}, "no_breakdown": "roof_storm"},
		"title": "Przeciek w dachu",
		"text": "Kościelny pokazuje ci wiadro na środku nawy. Dach przecieka nad prezbiterium, tynk zaczyna odpadać. Ekipa może przyjechać od razu, ale za gotówkę.",
		"options": [
			{"label": "Doraźna naprawa za 2 000 zł", "effects": {"money": -2000, "condition": 8}},
			{"label": "Wiadro wystarczy do wiosny", "effects": {"trad": -3},
				"delayed": {"days": 4, "text": "Po ulewie zalało zakrystię. Stan budynków -12, tradycjonaliści -5.", "effects": {"condition": -12, "trad": -5}}},
		]
	},
	{
		"id": "parish_council", "weight": 9, "cooldown": 35, "require": {"min_day": 16},
		"title": "Rada parafialna chce współdecydować o pieniądzach",
		"text": "Na zebraniu pada propozycja: rada chce wglądu w konto i głosu przy wydatkach powyżej pięciu tysięcy. Formalnie to twoja decyzja i wszyscy przy stole o tym wiedzą.",
		"options": [
			{"label": "Zgoda, pełna jawność", "effects": {"reputation": 7, "trad": 3, "curia": -4}},
			{"label": "Wgląd tak, głos nie", "effects": {"reputation": 3, "curia": -1}},
			{"label": "Parafią zarządza proboszcz", "effects": {"curia": 4, "reputation": -5, "trad": -3},
				"delayed": {"days": 6, "text": "Dwóch członków rady złożyło rezygnację. Reputacja -3.", "effects": {"reputation": -3}}},
		]
	},
	{
		"id": "car_dies", "weight": 7, "cooldown": 45, "require": {"min_day": 10, "no_breakdown": "car"},
		"title": "Samochód nie odpala",
		"text": "Na parkingu przed plebanią stoi auto, które od trzech dni odpalało coraz gorzej, a dziś już nie odpaliło wcale. W kolejce czekają chorzy.",
		"options": [
			{"label": "Warsztat od ręki, 2 400 zł", "effects": {"money": -2400}},
			{"label": "Pojeździ na kablach jeszcze tydzień", "effects": {"energy": -10}, "breakdown": "car"},
			{"label": "Poproś parafian o podwożenie", "effects": {"reputation": 2, "trad": 2}, "breakdown": "car",
				"delayed": {"days": 4, "text": "Ludzie wożą cię do chorych i uważają, że to dobrze o tobie świadczy. Reputacja +2.", "effects": {"reputation": 2}}},
		]
	},
	{
		"id": "anonymous_letter", "weight": 7, "cooldown": 40, "require": {"min_day": 18},
		"title": "Anonim do kurii",
		"text": "Kanclerz przesyła ci kopię listu bez podpisu. Autor pisze o twoich wydatkach, o tym, kto bywa na plebanii, i o rzeczach, które w dwóch trzecich są nieprawdą. Ta jedna trzecia jest problemem.",
		"options": [
			{"label": "Odpisz punkt po punkcie z dokumentami", "effects": {"energy": -20, "curia": 6, "respect": 2}},
			{"label": "Powiedz o liście z ambony", "effects": {"reputation": 3, "trad": -3, "curia": -5}},
			{"label": "Zignoruj anonim", "effects": {"curia": -3},
				"delayed": {"days": 6, "chance": 0.5,
					"text": "Przyszedł drugi anonim, tym razem z załącznikami. Kuria -6.", "effects": {"curia": -6},
					"else_text": "Sprawa ucichła sama. Kuria odłożyła list do teczki.", "else_effects": {}}},
		]
	},
	{
		"id": "harvest_festival", "weight": 9, "cooldown": 300, "require": {"part": "jesień", "min_day": 12},
		"title": "Dożynki parafialne",
		"text": "Sołtysi z trzech wsi przyszli ustalić, czyj wieniec stanie przy ołtarzu i kto poniesie chleb. Rozmowa trwa czterdzieści minut i nie dotyczy wieńca.",
		"options": [
			{"label": "Losowanie przy wszystkich", "effects": {"trad": 4, "reputation": 3, "respect": 2}},
			{"label": "Wieniec od największej wsi", "effects": {"trad": 2, "reputation": -3},
				"delayed": {"days": 5, "text": "Dwie mniejsze wsie nie przyszły na odpust. Reputacja -2.", "effects": {"reputation": -2}}},
			{"label": "Wszystkie trzy wieńce przy ołtarzu", "effects": {"money": -600, "trad": 5, "reputation": 4}},
		]
	},
]


const CRISES := [
	{
		"id": "group_faction", "crisis": true, "cooldown": 21,
		"require": {"min_day": 10, "flags": {"group_fracture": true}},
		"title": "KRYZYS: skargi grup do rady parafialnej",
		"text": "Wpływowe, niezadowolone grupy przyszły do rady parafialnej. Każda ma inną skargę i oczekuje konkretnej odpowiedzi.",
		"options": [
			{"label": "Przyjmij sześciopunktowy plan pomocy — 9 000 zł", "effects": {"money": -9000, "energy": -20}},
			{"label": "Zwołaj otwarte posiedzenie rady i mediuj", "effects": {"energy": -30, "reputation": 3}},
			{"label": "Oprzyj się na najgłośniejszych delegatach", "effects": {"reputation": -3, "curia": -2}},
		]
	},
	{
		"id": "revolt", "crisis": true, "cooldown": 14,
		"require": {"min_day": 10, "max": {"reputation": 22}},
		"title": "KRYZYS: rada parafialna zwołała zebranie bez ciebie",
		"text": "W salce siedzi czterdzieści osób, a ty dowiedziałeś się o tym od kościelnego pół godziny wcześniej. Na kartce, którą ktoś ci podaje, jest osiem punktów. Pod nią sto dwadzieścia podpisów. Ostatni punkt to wniosek do kurii o twoje odwołanie.",
		"options": [
			{"label": "Wejdź tam, wysłuchaj wszystkiego i przyznaj się do błędów", "effects": {"reputation": 10, "curia": -3, "energy": -25, "respect": 2},
				"delayed": {"days": 5, "chance": 0.6,
					"text": "Zebranie rozeszło się bez wniosku. Ludzie mówią, że przynajmniej przyszedł. Reputacja +5.", "effects": {"reputation": 5},
					"else_text": "Wniosek i tak poszedł do kurii, choć bez części podpisów. Kuria -5.", "else_effects": {"curia": -5}}},
			{"label": "Zrób porządek twardą ręką i przypomnij, kto tu rządzi", "effects": {"trad": 3, "young": -6, "reputation": -3, "curia": 3},
				"delayed": {"days": 5, "text": "Podpisów pod wnioskiem jest teraz sto sześćdziesiąt. Reputacja -5, kuria -4.", "effects": {"reputation": -5, "curia": -4}}},
			{"label": "Napisz do kurii pierwszy, że to bunt garstki", "effects": {"curia": -6, "reputation": -5},
				"delayed": {"days": 4, "text": "Kuria wysłała wizytatora, bo wersje się nie zgadzają. Kuria -4.", "effects": {"curia": -4}}},
		]
	},
	{
		"id": "curia_intervention", "crisis": true, "cooldown": 14,
		"require": {"min_day": 12, "max": {"curia": 22}},
		"title": "KRYZYS: pismo z kurii z terminem",
		"text": "Koperta z herbem, w środku dwie strony i zdanie, którego nie da się przeczytać dwa razy inaczej: „prosimy o osobiste stawienie się i wyjaśnienie sposobu prowadzenia parafii”. Termin to siedem dni. W dekanacie mówi się, że dwie parafie dalej skończyło się to przeniesieniem.",
		"options": [
			{"label": "Jedź do kurii z kompletem dokumentów", "effects": {"curia": 12, "energy": -25, "money": -400}},
			{"label": "Przyjmij wizytatora u siebie i pokaż parafię", "effects": {"energy": -15},
				"delayed": {"days": 4, "special": "visitation_raw", "text": "Wizytator przyjechał."}},
			{"label": "Odpisz, że nie masz czasu", "effects": {"curia": -8},
				"delayed": {"days": 5, "text": "Kuria odnotowała brak współpracy. Kuria -6, reputacja -3.", "effects": {"curia": -6, "reputation": -3}}},
		]
	},
	{
		"id": "debt", "crisis": true, "cooldown": 12,
		"require": {"min_day": 8, "max": {"money": -6000}},
		"title": "KRYZYS: parafia nie ma z czego zapłacić",
		"text": "Konto jest na minusie, a w szufladzie leżą trzy niezapłacone faktury i wezwanie od dostawcy prądu. Księgowa kurii już to widzi w zestawieniu, bo widzi wszystko.",
		"options": [
			{"label": "Poproś kurię o pożyczkę", "effects": {"money": 10000, "curia": -8},
				"delayed": {"days": 21, "text": "Rata pożyczki z kurii. -2 000 zł.", "effects": {"money": -2000}}},
			{"label": "Sprzedaj parafialną działkę za szkołą", "effects": {"money": 14000, "trad": -10, "reputation": -6},
				"delayed": {"days": 7, "text": "Ludzie pytają, czyja właściwie była ta ziemia. Reputacja -4.", "effects": {"reputation": -4}}},
			{"label": "Apel z ambony wprost: parafia nie ma pieniędzy", "effects": {"reputation": -4, "trad": -3},
				"delayed": {"days": 4, "chance": 0.5,
					"text": "Ludzie zrzucili się na faktury. +6 500 zł, reputacja +3.", "effects": {"money": 6500, "reputation": 3},
					"else_text": "Zebrało się niewiele. Zostało wrażenie, że ksiądz nie umie liczyć. +1 400 zł, reputacja -3.", "else_effects": {"money": 1400, "reputation": -3}}},
		]
	},
	{
		"id": "ruin", "crisis": true, "cooldown": 12,
		"require": {"min_day": 8, "max": {"condition": 15}},
		"title": "KRYZYS: nadzór budowlany ogląda kościół",
		"text": "Inspektor chodzi po nawie z latarką i notuje. Przy pęknięciu nad prezbiterium stoi dłużej, niż chciałbyś. Mówi, że w tym stanie budynek nie powinien przyjmować ludzi.",
		"options": [
			{"label": "Zamknij kościół i rób remont", "effects": {"money": -9000, "condition": 28, "trad": -8, "reputation": -4},
				"delayed": {"days": 6, "text": "Kościół otwarty, sklepienie podbite, pęknięcie zszyte. Reputacja +5, kuria +4.", "effects": {"reputation": 5, "curia": 4}}},
			{"label": "Doraźne podbicie i podpory w nawie", "effects": {"money": -2500, "condition": 10},
				"delayed": {"days": 6, "chance": 0.4,
					"text": "Podpory nie wystarczyły. Poszedł tynk ze sklepienia razem z kawałkiem dachu.", "effects": {"condition": -6}, "breakdown": "roof_storm",
					"else_text": "Podpory trzymają. Inspektor odpuścił do wiosny.", "else_effects": {}}},
			{"label": "Msze odprawiamy dalej, jakoś było dotąd", "effects": {"curia": -5},
				"delayed": {"days": 4, "text": "Inspektor wrócił z decyzją i kopią do kurii. Reputacja -6, kuria -6.", "effects": {"reputation": -6, "curia": -6}}},
		]
	},
]


## Wydarzenia, które muszą wejść dziś: scenariusz pierwszego tygodnia i kryzysy progowe.
static func due_events(game: Node) -> Array:
	var out: Array = []
	for ev in SCRIPTED:
		if game.fired_events.has(ev["id"]):
			continue
		if int(ev.get("day", 0)) == game.day:
			out.append(GroupEvents.runtime_event(ev, game))
	for ev in CRISES:
		# Kryzys rzeczywistych frakcji ma pierwszeństwo przed ogólnym buntem reputacji.
		if str(ev.get("id", "")) == "revolt" and bool(game.flags.get("group_fracture", false)):
			continue
		if _eligible(game, ev):
			out.append(GroupEvents.runtime_event(ev, game))
	return out


## Jedno wydarzenie z puli, losowane z wagami spośród tych, których warunki są spełnione.
## Pusty słownik, gdy dziś nic nie wychodzi.
static func draw(game: Node) -> Dictionary:
	var eligible: Array = []
	var total := 0.0
	for pool in [POOL, ChainEvents.POOL]:
		for ev in pool:
			if not _eligible(game, ev):
				continue
			eligible.append(ev)
			total += float(ev.get("weight", 10))
	if eligible.is_empty():
		return {}
	var roll := randf() * total
	for ev in eligible:
		roll -= float(ev.get("weight", 10))
		if roll <= 0.0:
			return GroupEvents.runtime_event(ev, game)
	return GroupEvents.runtime_event(eligible.back(), game)


## Szansa, że dziś w ogóle coś się wydarzy. Po cichych dniach rośnie, żeby gra
## nie potrafiła zamilknąć na tydzień, ale nigdy nie jest pewna.
static func daily_chance(quiet_days: int) -> float:
	return clampf(0.40 + 0.12 * float(quiet_days), 0.0, 0.85)


static func _eligible(game: Node, ev: Dictionary) -> bool:
	var id: String = ev["id"]
	if game.fired_events.has(id):
		return false
	if int(game.event_cooldowns.get(id, 0)) > game.day:
		return false
	var req: Dictionary = ev.get("require", {})
	if game.day < int(req.get("min_day", 0)):
		return false
	if req.has("max_day") and game.day > int(req["max_day"]):
		return false
	if req.has("season") and Calendar.season(game.day) != str(req["season"]):
		return false
	if req.has("part") and Calendar.time_of_year(game.day) != str(req["part"]):
		return false
	if req.has("built") and not game.built.has(str(req["built"])):
		return false
	if req.has("not_built") and game.built.has(str(req["not_built"])):
		return false
	if req.has("breakdown") and not game.breakdowns.has(str(req["breakdown"])):
		return false
	if req.has("no_breakdown") and game.breakdowns.has(str(req["no_breakdown"])):
		return false
	for key in req.get("min", {}):
		if float(game.get(key)) < float(req["min"][key]):
			return false
	for key in req.get("max", {}):
		if float(game.get(key)) > float(req["max"][key]):
			return false
	for key in req.get("flags", {}):
		if game.flags.get(key, false) != req["flags"][key]:
			return false
	return true


## Wydarzenie po identyfikatorze, także z odroczonych łańcuchów.
static func by_id(id: String) -> Dictionary:
	for list in [SCRIPTED, POOL, CRISES, ChainEvents.POOL, ChainEvents.FOLLOWUPS]:
		for ev in list:
			if ev["id"] == id:
				return GroupEvents.runtime_event(ev, Game)
	return {}


## Wszystkie katalogi w formacie używanym przez walidatory i narzędzia.
static func catalogs() -> Array:
	var out: Array = []
	for entry in [["SCRIPTED", SCRIPTED], ["POOL", POOL], ["CRISES", CRISES]] + ChainEvents.catalogs():
		var decorated: Array = []
		for event in entry[1]:
			decorated.append(GroupEvents.decorate_event(event))
		out.append([entry[0], decorated])
	return out
