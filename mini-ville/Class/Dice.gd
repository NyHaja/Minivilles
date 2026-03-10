extends Node
class_name  Dice


var nombreDe : int
var resultat : Array[int]
var aRelance : bool # ???

func lancer(intnombreDe) -> Array[int]:
	var res
	res[0] = randi()%7
	res[1] = 0 
	if intnombreDe == 2:
		res[1] == randi()%7
		
	resultat = res
	
	return res
	

func getSomme() ->int:
	return resultat[0] + resultat[1]
	
func estDouble() ->bool:
	return resultat[0] == resultat[1]

func getResultat():
	return resultat
	
# +void setNombreDe(int n)  ## Set quoi le premier dé ou le deuxiememe 
# +int getNombreDe()		## pareil
