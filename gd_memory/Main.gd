extends Node2D

var _array2 = Array2.new(4, 4)

func _ready() -> void:
	for j in range(4):
		for i in range(4):
			_array2.set_v(i, j, j+1)
	_array2.shuffle()
	
	_array2.dump()
