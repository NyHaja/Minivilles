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
		# acheter
			

	
func phaseLancerDes() ->void:
	phaseActuelle = GAMEPHASE.ROLL_DICE
	
	var d = Dice.new()
	var nbdice = 1
	if joueurActif.dicecount == 2:
		# INPUT : 1 ou 2
		# nbdice = INPUT
		pass
	
	d.lancer(nbdice)
	if joueurActif.HasRadio():
		if d.estDouble():
			phaseDecisionRelance()



func phaseDecisionRelance() ->void:
	phaseActuelle = GAMEPHASE.REROLL_DECISION
	
	var veutRelancer = false
	#INPUT propose au joueur de relancer
	# veutRelancer = INPUT
	if veutRelancer:
		var d2 = Dice.new()
		var nbdice2 = 1
		if joueurActif.dicecount == 2:
			# INPUT : 1 ou 2
			# nbdice = INPUT
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
	
