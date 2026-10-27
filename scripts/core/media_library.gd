class_name MediaLibrary
extends RefCounted
## Accès aux fichiers de médias (sons, musiques, images) déclarés dans les
## fichiers de données. Un fichier absent n'est jamais une erreur : on renvoie
## null et le jeu garde son repli (silence, décor dessiné).
##
## Pour remplacer facilement un média, l'extension n'est pas imposée : si
## « tampon.ogg » est déclaré mais que seul « tampon.wav » existe, c'est lui
## qui est utilisé.

const AUDIO_EXTENSIONS := ["ogg", "wav", "mp3"]
const IMAGE_EXTENSIONS := ["png", "webp", "jpg", "jpeg"]


## Chemin réellement présent pour ce fichier (même nom, autre extension
## acceptée) ; "" si aucun.
static func resolve(path: String) -> String:
	if path == "":
		return ""
	if ResourceLoader.exists(path):
		return path
	var extension := path.get_extension().to_lower()
	var family: Array = AUDIO_EXTENSIONS if extension in AUDIO_EXTENSIONS else IMAGE_EXTENSIONS
	var base := path.get_basename()
	for other in family:
		if other != extension and ResourceLoader.exists("%s.%s" % [base, other]):
			return "%s.%s" % [base, other]
	return ""


static func exists(path: String) -> bool:
	return resolve(path) != ""


## Son ou musique ; loop : jouer en boucle sans réglage d'import.
static func load_stream(path: String, loop := false) -> AudioStream:
	var found := resolve(path)
	if found == "":
		return null
	var stream := load(found) as AudioStream
	if stream != null and loop:
		set_loop(stream)
	return stream


static func load_texture(path: String) -> Texture2D:
	var found := resolve(path)
	return load(found) as Texture2D if found != "" else null


## Lecture en boucle, quel que soit le format du fichier.
static func set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif "loop" in stream:
		stream.set("loop", true)
