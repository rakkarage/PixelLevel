var energy := 0
var energyPerTurn := 10

func current() -> int:
	return energy

func add(e := energyPerTurn) -> void:
	energy += e

func subtract(cost: int) -> void:
	energy -= cost
