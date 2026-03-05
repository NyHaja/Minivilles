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
func demarrerPartie() ->void:
	#Lance Dé
	pass
func tourSuivant() -> void:
	pass
@abstract func getJoueurActif() -> Player

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
	
