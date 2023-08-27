extends Area2D
# ============================================
# カード.
# ============================================
class_name Card

# --------------------------------------------
# const.
# --------------------------------------------
## 時間関連.
const TIME_ROTATE = 0.15 # ひっくり返る時間.
const TIME_VANISH = 0.5 # 消滅時間.
const TIME_SHAKE = 0.5 # 揺れ時間.

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
	BACK_TO_FRONT1, # 裏から表.
	BACK_TO_FRONT2,
	FRONT, # 表向き.
	FRONT_TO_BACK1, # 表から裏.
	FRONT_TO_BACK2,
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
## フレームカウンタ.
var _cnt = 0
## 選択しているかどうか.
var _selected = false
## 点滅タイマー.
var _blink_timer = 0.0
## ディレイタイマー.
var _delay_timer = 0.0
## 揺れ時間.
var _shake_timer = 0.0

# --------------------------------------------
# public functions.
# --------------------------------------------
## セットアップ.
func setup(pos:Vector2, pos_idx:int, card_id:eId) -> void:
	position = pos
	_pos_idx = pos_idx
	_id = card_id
	
	# 表のカード画像を読み込む.
	_front.texture = load("res://assets/images/card_%02d.png"%id)

## 揺れ開始.
func shake() -> void:
	_shake_timer = TIME_SHAKE

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
		_state = eState.FRONT_TO_BACK1
		_delay_timer = delay

## 表にする.
func flip_to_front(delay:float=0) -> void:
	if _state != eState.FRONT:
		_timer = 0
		_state = eState.BACK_TO_FRONT1
		_delay_timer = delay
		_white.visible = false # 点滅を非表示.

# --------------------------------------------
# private functions.
# --------------------------------------------
## 開始.
func _ready() -> void:
	pass

## 更新.
func _physics_process(delta: float) -> void:
	# フレームカウンタ更新.
	_cnt += 1
	
	# デバッグの更新.
	_update_debug()
	
	# 点滅タイマー更新.
	_blink_timer += delta
	
	if _delay_timer > 0.0:
		# 待ち処理.
		_delay_timer -= delta
		return
	
	# 揺れ更新.
	_update_shake(delta)
	
	_timer += delta
	var rot_rate = 1.0 # 回転の割合.
	var is_back_card = true # 裏向きかどうか.
	
	match _state:
		eState.BACK:
			# 裏向き.
			is_back_card = true
			rot_rate = 1.0
			# 選択カーソル更新.
			_update_blink_select(delta)
			
		eState.BACK_TO_FRONT1:
			# 裏 -> 表 (前半).
			is_back_card = true
			rot_rate = 1 - (_timer / TIME_ROTATE)
			if _timer >= TIME_ROTATE:
				# 後半へ続く.
				rot_rate = 0
				_timer = 0.0
				_state = eState.BACK_TO_FRONT2
		eState.BACK_TO_FRONT2:
			# 裏 -> 表 (後半).
			is_back_card = false
			rot_rate = _timer / TIME_ROTATE
			if _timer >= TIME_ROTATE:
				# 終了.
				is_back_card = false
				rot_rate = 1.0
				_state = eState.FRONT
			
		eState.FRONT:
			# 表向き.
			is_back_card = false
			rot_rate = 1.0
			
		eState.FRONT_TO_BACK1:
			# 表 -> 裏(前半).
			is_back_card = false
			rot_rate = 1 - (_timer / TIME_ROTATE)
			if _timer >= TIME_ROTATE:
				# 後半へ続く.
				rot_rate = 0
				_timer = 0.0
				_state = eState.FRONT_TO_BACK2
		eState.FRONT_TO_BACK2:
			# 表 -> 裏(後半).
			is_back_card = true
			rot_rate = _timer / TIME_ROTATE
			if _timer >= TIME_ROTATE:
				# 終了.
				is_back_card = true
				rot_rate = 1.0
				_state = eState.BACK
				
		eState.VANISH:
			# 消滅演出.
			var rate = Ease.cube_out(_timer / TIME_VANISH)
			var card_scale = 1 + rate
			_front.scale = Vector2.ONE * card_scale
			_front.modulate.a = 1 - rate
			if _timer >= TIME_VANISH:
				# 消える.
				queue_free()
			# 消滅はカードの更新を行わないのでここでreturnする.
			return
	
	# フラグに対応した回転処理を行う.
	_update_flip(is_back_card, rot_rate)
	
## 更新 > ひっくり返す.
func _update_flip(is_back_card:bool, rot_rate:float) -> void:
	# 表・裏のスプライトを非表示.
	_back.visible = false
	_front.visible = false
	
	# 回転するスプライト.
	var spr:Sprite2D = _front
	if is_back_card:
		# 対象は裏のカード.
		spr = _back
	# 表示するスプライトだけ表示する.
	spr.visible = true
	# sinカーブで回転.
	spr.scale.x = 1.0 * sin(PI/2 * rot_rate)	
	
## 更新 > 選択カーソル.
func _update_blink_select(delta:float) -> void:
	if _selected:
		# 選択していたら点滅する.
		_white.visible = true
		_white.modulate = Color.WHITE
		_white.modulate.a = 0.2 + 0.8 * abs(sin(_blink_timer * 2))
	else:
		# 選択していなかったらフェードアウトする.
		if _white.modulate.a > 0:
			_white.modulate.a -= delta * 2
			if _white.modulate.a <= 0:
				_white.modulate.a = 0
				_white.visible = false

## 更新 > 揺れ.
func _update_shake(delta:float) -> void:
	_shake_timer = max(_shake_timer-delta, 0.0) 
	var offset = Vector2.ZERO
	if _shake_timer > 0.0:
		# 揺れが有効.
		var rate = _shake_timer / TIME_SHAKE
		var mul = 1
		if _cnt%4 < 2:
			mul = -1
		offset.x = 4 * mul * rate
		offset.y = randf_range(-2, 2) * rate
	_front.offset = offset
	_back.offset = offset
	
## 更新 > デバッグ用.
func _update_debug() -> void:
	_label.text = eState.keys()[_state]

## print用の文字列を返す.	
func _to_string() -> String:
	return "[Card] id:%d idx:%d is_front:%d"%[id, idx, is_front]
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
