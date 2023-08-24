extends Area2D
# ============================================
# カード.
# ============================================
class_name Card

# --------------------------------------------
# const.
# --------------------------------------------
## ひっくり返る時間.
const TIME_ROTATE = 0.3
const TIME_VANISH = 0.5 # 消滅時間.

## カードID.
enum eId {
	NONE = 0,
	
	NASU = 1,
	TAKO = 2,
	BOX = 3,
	NYA = 4,
	MILK = 5,
	PUDDING = 6,
	XBOX = 7,
}

## 状態.
enum eState {
	BACK, # 裏向き.
	BACK_TO_FRONT, # 裏から表.
	FRONT, # 表向き.
	FRONT_TO_BACK, # 表から裏.
	VANISH, # 消滅.
}

# --------------------------------------------
# onready.
# --------------------------------------------
@onready var _back = $Back
@onready var _front = $Front
@onready var _white = $White
@onready var _label = $Label

# --------------------------------------------
# var.
# --------------------------------------------
## ID.
var _id = eId.NONE
## 位置.
var _pos_idx = 0
## 状態.
var _state = eState.BACK
## タイマー.
var _timer = 0.0
## 選択しているかどうか.
var _selected = false
## 点滅タイマー.
var _blink_timer = 0.0
## ディレイタイマー.
var _delay_timer = 0.0

# --------------------------------------------
# public functions.
# --------------------------------------------
## セットアップ.
func setup(pos:Vector2, idx:int, id:eId) -> void:
	position = pos
	_pos_idx = idx
	_id = id
	
	_front.texture = load("res://assets/images/card_%02d.png"%id)

## 消滅する.
func vanish() -> void:
	if _state == eState.VANISH:
		return
	_timer = 0
	_state = eState.VANISH
	
## 裏返す.
func flip_to_back(delay:float=0) -> void:
	if _state != eState.BACK:
		_timer = 0
		_state = eState.FRONT_TO_BACK
		_delay_timer = delay

## 表にする.
func flip_to_front(delay:float=0) -> void:
	if _state != eState.FRONT:
		_timer = 0
		_state = eState.BACK_TO_FRONT
		_delay_timer = delay
		_white.visible = false # 点滅を非表示.

# --------------------------------------------
# private functions.
# --------------------------------------------
## 開始.
func _ready() -> void:
	pass

## 更新.
func _process(delta: float) -> void:
	_update_debug()
	
	_blink_timer += delta
	
	if _delay_timer > 0.0:
		_delay_timer -= delta
		return
	
	var time_half = TIME_ROTATE / 2.0
	var time_total = TIME_ROTATE
	
	_timer += delta
	var rot_rate = 1.0
	var is_back = true
	match _state:
		eState.BACK:
			# 裏向き.
			is_back = true
			rot_rate = 1.0
			_update_back(delta)
		eState.BACK_TO_FRONT:
			# 裏 -> 表.
			if _timer < time_half:
				# 前半.
				is_back = true
				rot_rate = 1 - (_timer / time_half)
			elif _timer < time_total:
				# 後半.
				is_back = false
				rot_rate = (_timer - time_half) / time_half
			else:
				# 終了.
				is_back = false
				rot_rate = 1.0
				_state = eState.FRONT
		eState.FRONT:
			# 表向き.
			is_back = false
			rot_rate = 1.0
		eState.FRONT_TO_BACK:
			# 表 -> 裏.
			if _timer < time_half:
				# 前半.
				is_back = false
				rot_rate = 1 - (_timer / time_half)
			elif _timer < time_total:
				# 後半.
				is_back = true
				rot_rate = (_timer - time_half) / time_half
			else:
				# 終了.
				is_back = true
				rot_rate = 1.0
				_state = eState.BACK
		eState.VANISH:
			# 消滅.
			var rate = _timer / TIME_VANISH
			_front.scale = Vector2.ONE * (1 + rate)
			_front.modulate.a = 1 - rate
			# 以下の処理は行わない.
			if _timer >= TIME_VANISH:
				queue_free()
			return
	
	# フラグに対応した処理を行う.
	_back.visible = false
	_front.visible = false
	var spr:Sprite2D = _front
	if is_back:
		# 対象は裏のカード.
		spr = _back
	spr.visible = true
	spr.scale.x = 1.0 * sin(PI/2 * rot_rate)
	
func _update_back(delta:float) -> void:
	if _selected:
		_white.visible = true
		_white.modulate.a = 0.2 + 0.8 * abs(sin(_blink_timer * 2))
	else:
		if _white.modulate.a > 0:
			_white.modulate.a -= delta * 2
			if _white.modulate.a <= 0:
				_white.modulate.a = 0
				_white.visible = false

func _update_debug() -> void:
	_label.text = eState.keys()[_state]
# --------------------------------------------
# signals.
# --------------------------------------------
## マウスカーソルが入ってきた.
func _on_mouse_entered() -> void:
	_selected = true
	_blink_timer = PI/2/2

## マウスカーソルが出ていった.
func _on_mouse_exited() -> void:
	_selected = false

# --------------------------------------------
# properties.
# --------------------------------------------
## カードID.
var id:eId:
	get:
		return _id
## インデックス番号.
var idx:int:
	get:
		return _pos_idx
## 選択しているかどうか.
var selected:bool:
	get:
		if _state == eState.BACK:
			return _selected
		return false
## 裏向きかどうか.
var is_back:bool:
	get:
		return _state == eState.BACK
## 表向きかどうか.
var is_front:bool:
	get:
		return _state == eState.FRONT
