class_name EffectGainBanqueMonumentsInferieur
extends EffectGainBanque

var seuil_monuments : int  # nb max monuments (<)

func _init(p_id: int, p_montant: int, p_seuil_monuments: int):
	super._init(p_id, p_montant)
	
	# MAJ description pour inclure la condition
	description = "Gagner " + str(p_montant) + " pièce(s) (si < " + str(p_seuil_monuments) + " monuments construits)"
	
	seuil_monuments = p_seuil_monuments
 
 
# SURCHARGE de peutActiver pour ajouter la condition des monuments
func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	# verif que owner a STRICTEMENT MOINS de seuil_monuments construits

	var nb_monuments_construits = owner.monumentCount
	
	# Retourner true si owner a < seuil monuments
	return nb_monuments_construits < seuil_monuments
 
