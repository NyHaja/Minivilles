@abstract  class_name Game
extends Node


var gameId:int
var timer:int
var playerCount:int
var currentPlayerIndex:int
var phase:Turn.GAMEPHASE :
	set(value):
		pass
	get:
		return tour.phaseActuelle
var tour :Turn
var lesJoueurs : Array[Player]
func demarrerPartie() ->void:
	#Lance Dé
	var AunGagnant = false
	
	while not(AunGagnant):
		var newtour = Turn.new(getJoueurActif())
		newtour.demarrer(newtour.joueurActif)
		AunGagnant = newtour.joueurActif.monument
		
		
func tourSuivant() -> void:
	pass
func getJoueurActif() -> Player:
	return lesJoueurs[currentPlayerIndex % playerCount ]

@abstract func getJoueursAdverses(joueur:Player) -> Array[Player]

@abstract func getJoueursOrdreAntihoraire(reference:Player) -> Array[Player]

func echangerCarte(j1:Player,c1:Establishment,j2:Player,c2:Establishment)-> void:
	
	pass
@abstract func getEffectById(id:int) -> Effect
@abstract func verifierVictoire(joueur:Player) -> bool

func terminerPartie(gagnant:Player) -> void:
	# mise à jour des stat à envoie pour le BDD
	pass

# Constructeur
func _init(timer:int,players:Array[Player]) -> void:
	timer = timer
	playerCount = players.size()
	
