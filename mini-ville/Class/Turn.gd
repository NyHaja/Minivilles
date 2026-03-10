extends Node
class_name Turn

enum GAMEPHASE {
	INIT, # pas dans ULM
	WAITING,
	ROLL_DICE,
	REROLL_DECISION,
	ACTIVATE_RED,
	ACTIVATE_BLUE_GREEN,
	ACTIVATE_PURPLE,
	BUILD,
	AIRPORT_CHECK,
	BONUS_TURN_CHECK,
	END_TURN,
	GAME_OVER
}

var joueurActif :Player
var phaseActuelle :GAMEPHASE
var resultatDes :Array[int]
var aRelance :bool
var estTourBonus :bool
var aConstruit :bool

func demarrer(joueur:Player) ->void:
	joueurActif = joueur
	
	phaseLancerDes()
	
	phaseActivationRouge()
	phaseActivationBleuVert()
	phaseActivationViolet()
	
	 # choix :
	# rien faire -> areoport
	# construire

	
func phaseLancerDes() ->void:
	
	pass

func phaseDecisionRelance() ->void:
	pass
func phaseActivationRouge() ->void:
	pass
func phaseActivationBleuVert() ->void:
	pass
func phaseActivationViolet() ->void:
	pass
func phaseConstruction() ->void:
	pass
func phaseVerificationAeroport() ->void:
	pass
func phaseVerificationTourBonus() ->void:
	pass

func terminer() -> void:
	pass

func peutRelancer() -> bool:
	return false
func doitRejouer() -> bool:
	return false

func _init(joueurActif : Player) -> void:
	joueurActif = joueurActif
	
