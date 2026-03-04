@abstract  class_name Game
extends Node


var gameId:int
var timer:int
var playerCount:int
var currentPlayerIndex:int
var phase:GamePhase

func demarrerPartie() ->void:
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
	pass
