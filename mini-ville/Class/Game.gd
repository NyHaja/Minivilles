@abstract  class_name Game
extends Node


var gameId:int
var timer:int
var playerCount:int
var currentPlayerIndex:int
var playerArray : Array[Player]

enum CHOIX {
	SKIP,
	Build_MONUMENT,
	Build_ETABLISHMENT
}

func demarrerPartie() ->void:
	# INIT
		#Generer les 160 (a voir) carte dans la pioche
		#Donner champ blé et boulangerie a tout les joueur et 3 gold
		
	# LOOP de partie
	var AunGagnant = false
	var aConstruit = false
	var TourBonus = false
	while not(AunGagnant):
		aConstruit = false
		TourBonus = false
		
		var resDice:int = DicePhase()
		EffectPhase(resDice)
		
		var choix
		# choix = INPUT
		
		match  choix:
			CHOIX.Build_MONUMENT : 
				buildPhase(0)
			CHOIX.Build_MONUMENT : 
				buyPhase(0)
			CHOIX.SKIP : 
				skipPhase(aConstruit)
			
		skipPhase(aConstruit)
		
		AunGagnant = verifierVictoire(getJoueurActif())
		
		if not(TourBonus):
			currentPlayerIndex = (currentPlayerIndex + 1) % playerArray.size()
		
		
func getJoueurActif() -> Player:
	return playerArray[currentPlayerIndex % playerCount ]

@abstract func getJoueursAdverses(joueur:Player) -> Array[Player]
@abstract func getJoueursOrdreAntihoraire(reference:Player) -> Array[Player]

@abstract func getEffectById(id:int) -> Effect

func verifierVictoire(joueur:Player) -> bool:
	return joueur.monumentCount == 5

func terminerPartie(gagnant:Player) -> void:
	# mise à jour des stat à envoie pour le BDD
	pass
func echangerCarte(j1:Player,c1:Establishment,j2:Player,c2:Establishment)-> void:
	
	pass
	
# Constructeur
func _init(gameId:int,timer:int,players:Array[Player]) -> void:
	timer = timer
	playerCount = players.size()
	playerArray = players
	gameId = gameId
	

#+Effect getEffectById(id)
func DicePhase() -> int:
	var resArray = lanceDe()
	
	# Monument Radio : pouvoir de relancer
	if getJoueurActif().monumentArray[Monument.MONUMENT_ID.Radio]:
		#RELANCER ?
		var relancer
		#relancer = INPUT
		if relancer:
			resArray = lanceDe()
			
	# Monument Parc Arctraction : douvle -> tour bonus
	if getJoueurActif().monumentArray[Monument.MONUMENT_ID.Parc]:
		if resArray[0] == resArray[1]:
			# TOUR BONUS
			pass
		pass
	
	var somme = resArray[0] + resArray[1]
	# Monument Port : resultat des >= 10, ajoutez +2.
	if getJoueurActif().monumentArray[Monument.MONUMENT_ID.Radio]:
		somme = somme + 2
		pass
	return somme

func lanceDe() -> Array[int]:
	var res
	res[0] = (randi()%6) + 1
	res[1] = 0 
	
	var intnombreDe = 1
	
	if getJoueurActif().monumentArray[Monument.MONUMENT_ID.Gare]:
		# intnombreDe = INPUT (1 ou 2)
		pass
	if intnombreDe == 2:
		res[1] == (randi()%6) +1
		
	return res

func EffectPhase(resDice) -> void:
	# ROUGE
	for joueur:Player in getJoueursOrdreAntihoraire(getJoueurActif()):
		joueur.activateEffect(Establishment.COULEUR.RED)
	# Bleu
	for joueur:Player in playerArray:
		joueur.activateEffect(Establishment.COULEUR.BLUE)
	#VERT
	getJoueurActif().activateEffect(Establishment.COULEUR.GREEN)
	#Violet
	getJoueurActif().activateEffect(Establishment.COULEUR.PURPLE)
	
	
		
#func lance
func skipPhase(aConstruit) -> void:
	var joueur = getJoueurActif()
	if not(aConstruit):
		if joueur.balance <=2:
			joueur.balance = joueur.balance + 2
		# Monument Radio : pouvoir de relancer
		if getJoueurActif().monumentArray[Monument.MONUMENT_ID.Aeroport]:
			joueur.balance = joueur.balance + 10
	
func buyPhase(card_id:int):
	pass
func buildPhase(Monument_id):
	pass
