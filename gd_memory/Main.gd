extends Node2D

# ---------------------------------------------
# const.
# ---------------------------------------------
const OFS_X = 128
const OFS_Y = 128
const GRID_W = 80
const GRID_H = 100
const GRID_CNT_W = 4
const GRID_CNT_H = 4

# ---------------------------------------------
# preload.
# ---------------------------------------------
const CARD_OBJ = preload("res://src/Card.tscn")

# ---------------------------------------------
# onready
# ---------------------------------------------
@onready var _card_layer = $CardLayer
@onready var _ui_layer = $UILayer

# ---------------------------------------------
# var.
# ---------------------------------------------
var _array2 = Array2.new(GRID_CNT_W, GRID_CNT_H)

# ---------------------------------------------
# private functions.
# ---------------------------------------------
## 開始.
func _ready() -> void:
	for j in range(GRID_CNT_H):
		for i in range(GRID_CNT_W):
			_array2.set_v(i, j, j+1)
	_array2.shuffle()
	_array2.dump()
	
	_array2.foreach(func(i, j, v):
		var pos = _grid_to_screen(i, j)
		var idx = _grid_to_idx(i, j)
		var card = CARD_OBJ.instantiate()
		_card_layer.add_child(card)
		card.setup(pos, idx, v)
		card.flip_to_front(idx * 0.1)
	)
	
func _process(delta: float) -> void:
	_update_debug()

func _update_debug() -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().change_scene_to_file("res://Main.tscn")

func _grid_to_screen(i:int, j:int) -> Vector2i:
	var v = Vector2i()
	v.x = OFS_X + (GRID_W * i)
	v.y = OFS_Y + (GRID_H * j)
	return v
func _grid_to_idx(i:int, j:int) -> int:
	return i + (GRID_W * j)
