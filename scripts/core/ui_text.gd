class_name UiText
extends RefCounted
## Traduction d'un texte d'interface depuis du code statique (règles, mises en
## forme), où tr() n'est pas disponible. Renvoie toujours un String, ce qui
## permet d'enchaîner avec l'opérateur % et le typage statique.


static func of(source: String) -> String:
	return String(TranslationServer.translate(source))
