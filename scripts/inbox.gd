class_name Inbox
## Skrzynka w telefonie: jak wiadomość wchodzi, jak się na nią odpowiada i co robi
## poranek z tymi, na które nie zdążyłeś odpowiedzieć.
##
## Treści wiadomości siedzą w phone.gd, sama lista w Game.phone_inbox (bo się zapisuje).
## Tutaj jest mechanika, więc ocena kwartalna i kalendarz kurii (wydanie 2.4) dopisują
## się w tym pliku.

const INBOX_MAX := 30
const MEDIA_CHANCE := 0.35
const CURIA_MAIL_THRESHOLD := 35
const CURIA_MAIL_COOLDOWN := 14
const BANK_ALERT_COOLDOWN := 7

const WELCOME_MAIL := {
	"app": "poczta", "from": "Kuria diecezjalna", "id": "welcome",
	"title": "Objęcie parafii",
	"text": "Ksiądz kanclerz wita w nowej parafii i przypomina, że sprawozdania finansowe składa się co kwartał, a biskup lubi, gdy w parafii coś się dzieje. Na końcu, mniejszą czcionką: poprzednik zostawił budynki w stanie, który wymaga uwagi.",
}


## Nowa wiadomość w telefonie. Wiadomości z terminem dostają dzień, do którego czekają.
static func send(msg: Dictionary) -> void:
	var item: Dictionary = msg.duplicate(true)
	item["day"] = Game.day
	item["read"] = false
	item["answered"] = -1
	if item.has("deadline"):
		item["due"] = Game.day + int(item["deadline"])
	Game.phone_inbox.push_front(item)
	if item.get("app", "") == "media" and item.has("id"):
		Game.media_recent[str(item["id"])] = Game.day
	Game.toast.emit("Telefon: %s - %s" % [item.get("from", "?"), item.get("title", "")])
	Game.state_changed.emit()


static func unread() -> int:
	var n := 0
	for m in Game.phone_inbox:
		if not bool(m.get("read", true)):
			n += 1
	return n


## Ile wiadomości czeka na odpowiedź; to one mają termin, więc HUD może je wyróżnić.
static func waiting() -> int:
	var n := 0
	for m in Game.phone_inbox:
		if is_open_question(m):
			n += 1
	return n


static func is_open_question(msg: Dictionary) -> bool:
	return msg.has("options") and int(msg.get("answered", -1)) < 0 and not bool(msg.get("expired", false))


static func mark_read(index: int) -> void:
	if index < 0 or index >= Game.phone_inbox.size():
		return
	Game.phone_inbox[index]["read"] = true
	Game.state_changed.emit()


## Odpowiedź na wiadomość działa jak wybór w wydarzeniu: skutki od ręki, skutki odroczone
## i wpis w kronice. Wiadomość zostaje w skrzynce z zaznaczoną odpowiedzią.
static func answer(index: int, option_index: int) -> void:
	if index < 0 or index >= Game.phone_inbox.size():
		return
	var msg: Dictionary = Game.phone_inbox[index]
	if not is_open_question(msg):
		return
	var opt: Dictionary = msg["options"][option_index]
	if opt.has("effects"):
		Game.apply_effects(opt["effects"], str(msg.get("title", "Telefon")))
	if opt.has("set"):
		for key in opt["set"]:
			Game.set(key, opt["set"][key])
	if opt.has("delayed"):
		var d: Dictionary = opt["delayed"]
		Game.scheduled.append({"day": Game.day + int(d["days"]), "text": str(d.get("text", "")),
			"effects": d.get("effects", {})})
	msg["answered"] = option_index
	msg["read"] = true
	Game.add_log("%s: %s." % [msg.get("title", "Telefon"), opt["label"]])
	Game.state_changed.emit()


## Rano: wiadomości po terminie rozliczają się same, a media czasem coś wrzucają.
static func morning() -> Array[String]:
	var lines: Array[String] = []
	for msg in Game.phone_inbox:
		if not is_open_question(msg) or not msg.has("due"):
			continue
		if Game.day <= int(msg["due"]):
			continue
		msg["expired"] = true
		msg["read"] = true
		var expire: Dictionary = msg.get("expire", {})
		if expire.has("effects"):
			Game.apply_effects(expire["effects"], str(msg.get("title", "Telefon")))
		var text := str(expire.get("text", "Nie odpowiedziałeś na wiadomość: %s." % msg.get("title", "")))
		lines.append(text)
		Game.add_log(text)
	if Game.phone_inbox.size() > INBOX_MAX:
		Game.phone_inbox.resize(INBOX_MAX)
	# kuria odzywa się sama, gdy relacje siadają - i chce wyjaśnień na piśmie
	if Game.curia < CURIA_MAIL_THRESHOLD and Game.day - Game._last_curia_mail >= CURIA_MAIL_COOLDOWN:
		Game._last_curia_mail = Game.day
		send(Phone.curia_mail("ogólny stan relacji z kurią", Phone.excuses(), 4))
		lines.append("Kuria pyta o stan relacji z parafią. Odpowiedź czeka w telefonie.")
	# bank przypomina o debecie, bo to widać dopiero na wyciągu
	if Game.money < 0 and Game.day - Game._last_bank_alert >= BANK_ALERT_COOLDOWN:
		Game._last_bank_alert = Game.day
		send(Phone.make("bank", "Bank Spółdzielczy", "Debet na koncie parafii",
			"Saldo rachunku parafii jest ujemne (%s zł). Odsetki naliczamy od dnia dzisiejszego." % Game.money_text(Game.money),
			{"id": "debet"}))
	if randf() < MEDIA_CHANCE:
		var post: Dictionary = Phone.draw_media(Game, Game.media_recent)
		if not post.is_empty():
			send(post)
			lines.append("W mediach: %s" % post["title"])
	return lines
