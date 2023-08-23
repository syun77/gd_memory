extends Node2D

# ---------------------------------------------
# const.
# ---------------------------------------------
## 配置するカードの左上座標.
const OFS_X = 128
const OFS_Y = 128
## 配置間隔.
const GRID_W = 80
const GRID_H = 100
## 配置枚数.
const GRID_CNT_W = 4
const GRID_CNT_H = 4

## 状態.
enum eState {
	START, # 開始.
	MAIN, # メイン.
	WAIT, # めくった後の待ち時間.
	GAMEOVER, # ゲームオーバー.
	GAMECLEAR, # ゲームクリア.
}

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
## 状態.
var _state = eState.START
## タイマー.
var _timer = 0.0
## カードの配置情報.
var _array2 = Array2.new(GRID_CNT_W, GRID_CNT_H)
## めくったカードのリスト.
var _front_cards:Array[Card] = []

# ---------------------------------------------
# private functions.
# ---------------------------------------------
## 開始.
func _ready() -> void:
	## 配置情報を作成.
	for j in range(GRID_CNT_H):
		for i in range(GRID_CNT_W):
			_array2.set_v(i, j, j+1)
	## 配情報をシャッフルする.
	_array2.shuffle()
	## デバッグ出力.
	_array2.dump()
	
	## カードを生成.
	_array2.foreach(func(i, j, v):
		var pos = _grid_to_screen(i, j)
		var idx = _grid_to_idx(i, j)
		var card = CARD_OBJ.instantiate()
		_card_layer.add_child(card)
		card.setup(pos, idx, v)
		#card.flip_to_front(idx * 0.1)
	)

## 更新.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("click"):
		for card in _card_layer.get_children():
			var c = card as Card
			if c.selected:
				# めくる.
				c.flip_to_front()
				_front_cards.append(c)
				break
	if Input.is_action_just_pressed("ui_accept"):
		for card in _front_cards:
			var c = card as Card
			c.flip_to_back()
	
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
	return i + (GRID_CNT_W * j)
