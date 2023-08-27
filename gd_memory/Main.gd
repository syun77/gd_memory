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

## カードをめくった後の待ち時間.
const TIMER_WAIT = 0.5

## 状態.
enum eState {
	START, # 開始.
	MAIN, # メイン.
	WAIT1, # めくった後の待ち時間.
	WAIT2,
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
## めくったカードのIDに対応する枚数.
var _front_cnts:Array[int] = []

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
		var pos = _grid_to_screen(i, j) # スクリーン座標.
		var idx = _grid_to_idx(i, j) # インデックス座標.
		var card = CARD_OBJ.instantiate() # カードインスタンス.
		_card_layer.add_child(card) # カードレイヤーに登録する.
		card.setup(pos, idx, v) # カードをセットアップ.
	)
	
	# 表のカード枚数計算用.
	_front_cnts.resize(Card.eId.size())
	_front_cnts.fill(0)

## 更新.
func _process(delta: float) -> void:
	# _stateに対応する更新処理を呼び出す.
	callv("_update_" + eState.keys()[_state], [delta])
	
	# デバッグの更新.
	_update_debug()

## 更新 > 開始.
func _update_START(_delta:float) -> void:
	_state = eState.MAIN
## 更新 > メイン.
func _update_MAIN(_delta:float) -> void:
	if _front_cards.size() >= 2:
		# カードを2枚めくった.
		_state = eState.WAIT1
		_timer = 0
		return
	
	# めくり判定.
	if Input.is_action_just_pressed("click"):
		for card in _card_layer.get_children():
			var c = card as Card
			if c.selected:
				# めくる.
				c.flip_to_front()
				_front_cards.append(c)
				break
	
# 更新 > めくった後の待ち時間.
func _update_WAIT1(_delta:float) -> void:
	for card in _front_cards:
		var c = card as Card
		if c.is_front == false:
			return # すべてが表向きになるまで待つ.

	# 表になっているカードの枚数を数える.
	_count_front_cards()
	
	# そろっていないカードを揺らす.
	_foreach_front_cards(false, func(card:Card): card.shake())
	
	print(_front_cnts)
	
	_state = eState.WAIT2

## 更新 > 待ち2.
func _update_WAIT2(delta:float) -> void:
	_timer += delta
	# 少し待つ.
	if _timer < TIMER_WAIT:
		return
	
	# めくったカードの処理.
	if _check_erase(true) == false:
		# 消せなかったのでカードをもとに戻す.
		for card in _front_cards:
			var c = card as Card
			c.flip_to_back()
			
	# めくったカード情報を消す.
	_front_cards.clear()
	_front_cnts.fill(0)
	
	# メインに戻る.
	_state = eState.MAIN
	_timer = 0

# 更新 > ゲームオーバー.
func _update_GAMEOVER(_delta:float) -> void:
	pass

# 更新 > ゲームクリア
func _update_GAMECLEAR(_delta:float) -> void:
	pass

## 表になっているカードの枚数を数える.
func _count_front_cards() -> void:
	# 0クリア.
	_front_cnts.fill(0)
	
	for card in _card_layer.get_children():
		var c = card as Card
		if c.is_front == false:
			continue # 対象カードは表のものだけ.
		# カウントアップ.
		_front_cnts[c.id] += 1

## 表のカードに対する処理を行う.
func _foreach_front_cards(is_match:bool, f:Callable) -> void:
	var match_list = [] # そろっているカード.
	var unmatch_list = [] # そろっていないカード.
	
	for idx in range(_front_cnts.size()):
		match _front_cnts[idx]:
			1: # 1枚だけ表向きならそろっていないとみなす.
				unmatch_list.append(idx)
			2: # 2枚表向きならそろっているとみなす.
				match_list.append(idx)
	
	var target = match_list # そろっているカード.
	if is_match == false:
		target = unmatch_list # そろっていないカードが対象.
	
	for card in _front_cards:
		if card.id in target:
			# 対象のカードなのでラムダ式を実行する.
			print(card)
			f.call(card)

## 消去チェック.
## @param is_erase 消去も同時に行うかどうか.
func _check_erase(is_erase:bool) -> bool:
	var ret = false # マッチしたカードがあるかどうか.
	
	var match_list = []
	for idx in range(_front_cnts.size()):
		if _front_cnts[idx] == 2:
			# 2枚表向きならそろっているとみなす.
			match_list.append(idx)
	
	for idx in range(_front_cnts.size()):
		if not idx in match_list:
			continue # マッチリストにいない.
		
		# マッチしたカードがある.
		ret = true
		
		# マッチしたカードを消す.
		for card in _front_cards:
			if card.id == idx:
				if is_erase:
					# 消去する.
					card.vanish()
	
	return ret

## 更新 > デバッグ.
func _update_debug() -> void:
	if Input.is_action_just_pressed("reset"):
		# やり直し.
		get_tree().change_scene_to_file("res://Main.tscn")
	
	if Input.is_action_just_pressed("abort"):
		# 終了.
		get_tree().quit()

## グリッド座標系をスクリーン座標系に変換する.
func _grid_to_screen(i:int, j:int) -> Vector2i:
	var v = Vector2i()
	v.x = OFS_X + (GRID_W * i)
	v.y = OFS_Y + (GRID_H * j)
	return v
	
## グリッド座標系をインデックス座標系に変換する.
func _grid_to_idx(i:int, j:int) -> int:
	return i + (GRID_CNT_W * j)
