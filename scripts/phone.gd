class_name Phone
## Telefon księdza: trzy aplikacje, przez które świat sam się odzywa.
##
## POCZTA – kuria, firmy i parafianie. Część listów wymaga odpowiedzi i ma termin;
##          brak odpowiedzi to też decyzja, tylko gorsza.
## BANK   – stan konta i historia operacji. Nic tu nie klikasz, ale widać, z czego
##          zrobiła się dziura w budżecie.
## MEDIA  – lokalny portal i grupa parafialna. Posty biorą się ze stanu parafii,
##          a na część można odpowiedzieć, zanim rozejdą się dalej.
##
## Wiadomość to słownik: id, app, from, title, text, day, read, answered,
## opcjonalnie options (jak w wydarzeniach), deadline (ile dni na odpowiedź)
## i expire (co się dzieje, gdy termin minie).

const APPS := ["poczta", "bank", "media"]
## Ile dni ten sam post w mediach nie wraca. Bez karencji portal powtarzałby się
## co drugi dzień, bo pasujących tematów jest zwykle dwa albo trzy.
const MEDIA_COOLDOWN := 12
const APP_LABELS := {"poczta": "Poczta", "bank": "Bank", "media": "Media"}


static func make(app: String, sender: String, title: String, text: String,
		extra: Dictionary = {}) -> Dictionary:
	var msg := {"app": app, "from": sender, "title": title, "text": text,
		"read": false, "answered": -1}
	for key in extra:
		msg[key] = extra[key]
	return msg


## Posty w mediach biorą się ze stanu parafii: każdy ma warunek i wagę.
## "min"/"max" to progi wskaźników, tak samo jak w wydarzeniach.
const MEDIA := [
	{
		"id": "media_remont", "from": "Powiatowy Serwis Informacyjny", "weight": 2,
		"require": {"max": {"condition": 35}},
		"title": "Kościół w parafii straszy wyglądem",
		"text": "Czytelnik przysłał zdjęcia elewacji. „Ile można patrzeć na taki dach” - pisze. W komentarzach dyskusja o tym, na co idą pieniądze z tacy.",
		"options": [
			{"label": "Odpisz: trwa zbiórka na remont", "effects": {"reputation": 2, "young": 1}},
			{"label": "Nie komentuj", "effects": {"reputation": -2}},
		],
		"deadline": 2,
		"expire": {"text": "Artykuł o kościele żyje w komentarzach drugi dzień, nikt go nie prostuje. Reputacja -3.",
			"effects": {"reputation": -3}},
	},
	{
		"id": "media_mlodzi", "from": "Grupa parafialna: Nasza Parafia", "weight": 2,
		"require": {"min": {"young": 60}},
		"title": "Rodzice chwalą mszę z dziećmi",
		"text": "Pod zdjęciem z niedzielnej mszy zebrało się kilkadziesiąt komentarzy. Ktoś pyta, czy będzie więcej takich spotkań.",
		"options": [
			{"label": "Zapowiedz kolejne spotkanie", "effects": {"young": 3, "energy": -5}},
			{"label": "Podziękuj i nic nie obiecuj", "effects": {"young": 1}},
		],
	},
	{
		"id": "media_tradycja", "from": "Grupa parafialna: Nasza Parafia", "weight": 2,
		"require": {"max": {"trad": 35}},
		"title": "Starsi parafianie skarżą się na zmiany",
		"text": "„Za poprzedniego proboszcza było inaczej” - zaczyna się wątek, który ma już sto komentarzy. Kilka osób pisze, że jeżdżą teraz do sąsiedniej parafii.",
		"options": [
			{"label": "Zaproś do rozmowy po mszy", "effects": {"trad": 3, "energy": -5}},
			{"label": "Zostaw wątek własnemu losowi", "effects": {"trad": -2}},
		],
		"deadline": 2,
		"expire": {"text": "Wątek o zmianach w parafii skończył się zbiórką podpisów. Tradycjonaliści -3, kuria -1.",
			"effects": {"trad": -3, "curia": -1}},
	},
	{
		"id": "media_dobra_opinia", "from": "Powiatowy Serwis Informacyjny", "weight": 1,
		"require": {"min": {"reputation": 70}},
		"title": "Parafia stawiana za wzór w powiecie",
		"text": "Krótka notka o tym, że u ciebie „coś się dzieje”. Bez nazwiska, ale wszyscy wiedzą, o kogo chodzi.",
		"options": [{"label": "Udostępnij dalej", "effects": {"reputation": 1, "young": 1}}],
	},
	{
		"id": "media_dziura", "from": "Powiatowy Serwis Informacyjny", "weight": 2,
		"require": {"max": {"money": 0}},
		"title": "Parafia na minusie",
		"text": "Ktoś doliczył się, że parafia nie zapłaciła w terminie za ogrzewanie. Redakcja prosi o komentarz.",
		"options": [
			{"label": "Przyznaj i podaj plan wyjścia", "effects": {"reputation": -1, "curia": 2}},
			{"label": "Odmów komentarza", "effects": {"reputation": -3}},
		],
		"deadline": 2,
		"expire": {"text": "Tekst o długach parafii wyszedł bez twojego komentarza. Reputacja -3, kuria -2.",
			"effects": {"reputation": -3, "curia": -2}},
	},
]


## Wiadomość z kurii, w której trzeba uzasadnić decyzję. Treść zależy od tego,
## co gracz wybrał, dlatego składamy ją z opisu decyzji.
static func curia_mail(decision: String, options: Array, deadline: int = 3) -> Dictionary:
	return make("poczta", "Kuria diecezjalna",
		"Prośba o wyjaśnienie: " + decision,
		"Ksiądz kanclerz pisze krótko i uprzejmie. Do kurii dotarła wiadomość o twojej decyzji (%s). "
		% decision + "Biskup prosi o wyjaśnienie na piśmie. Ton listu jest łagodny, ale pytanie jest konkretne.",
		{"options": options, "deadline": deadline,
			"expire": {"text": "Nie odpisałeś kurii w sprawie: %s. Kuria -6." % decision,
				"effects": {"curia": -6}}})


## Standardowe sposoby tłumaczenia się, wspólne dla większości decyzji.
## Każdy kosztuje co innego: prawda bywa droga, wykręt tani do czasu.
static func excuses() -> Array:
	return [
		{"label": "Napisz prawdę, z liczbami", "effects": {"curia": 5, "energy": -10}},
		{"label": "Zwal na poprzednika i stan budynków", "effects": {"curia": 2, "reputation": -2}},
		{"label": "Odpisz zdawkowo, że sprawa jest zamknięta", "effects": {"curia": -3}},
	]


## Losuje post pasujący do stanu parafii; pusty słownik, gdy nic nie pasuje.
static func draw_media(game: Node, recent: Dictionary) -> Dictionary:
	var pool: Array = []
	for post in MEDIA:
		if int(game.day) - int(recent.get(post["id"], -MEDIA_COOLDOWN)) < MEDIA_COOLDOWN:
			continue
		if not _fits(post.get("require", {}), game):
			continue
		for _i in int(post.get("weight", 1)):
			pool.append(post)
	if pool.is_empty():
		return {}
	var picked: Dictionary = pool[randi() % pool.size()]
	var extra := {"id": picked["id"]}
	for key in ["options", "deadline", "expire"]:
		if picked.has(key):
			extra[key] = picked[key]
	return make("media", picked["from"], picked["title"], picked["text"], extra)


static func _fits(require: Dictionary, game: Node) -> bool:
	for key in require.get("min", {}):
		if float(game.get(key)) < float(require["min"][key]):
			return false
	for key in require.get("max", {}):
		if float(game.get(key)) > float(require["max"][key]):
			return false
	return true
