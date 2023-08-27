# ===========================================
# 2次元配列クラス.
# ===========================================
class_name Array2

# -------------------------------------------
# const.
# -------------------------------------------
const DEFAULT = 0 # 初期値.
const INVALID = -1 # 無効な領域を指定したときの値.

# -------------------------------------------
# var.
# -------------------------------------------
var _pool = []
var _width = 0
var _height = 0

# -------------------------------------------
# public functions.
# -------------------------------------------
## 初期化.
func init(w:int, h:int) -> void:
	_width = w
	_height = h
	_pool.clear()
	for i in range(w*h):
		_pool.append(DEFAULT)

## 2次元を1次元のインデックスに変換する
func to_idx(i:int, j:int) -> int:
	if i < 0 or width <= i:
		return -1
	if j < 0 or height <= j:
		return -1
	return (j * width) + i

## 値を取得する.
func get_v(i:int, j:int) -> int:
	var idx = to_idx(i, j)
	if idx < 0:
		return INVALID
	
	return _pool[idx]

## 値を設定する.
func set_v(i:int, j:int, v:int) -> void:
	var idx = to_idx(i, j)
	if idx < 0:
		return
	
	_pool[idx] = v

## シャッフルする.
func shuffle() -> void:
	_pool.shuffle()
	
## 指定の値が存在する数を数える.
func count(v:int) -> int:
	var ret = 0
	for v2 in _pool:
		if v == v2:
			ret += 1
	return ret

## すべてを同じ値で埋める.
func fill(v:int) -> void:
	for idx in range(width*height):
		_pool[idx] = v

## すべてが初期値かどうか.
func check_all_empty() -> bool:
	dump()
	print("check_all_empty()", count(DEFAULT), "==", width * height)
	return count(DEFAULT) == width * height

func foreach(f:Callable) -> void:
	for j in range(height):
		for i in range(width):
			var v = get_v(i, j)
			f.call(i, j, v)

## デバッグ出力.
func dump() -> void:
	print("-----------------------------")
	print("[Array2] (w, h) = (%d, %d)"%[width, height])
	print("-----------------------------")
	for j in range(height):
		var s = ""
		for i in range(width):
			if i != 0:
				s += ", "
			s += "%d"%get_v(i, j)
		print(s)
	print("-----------------------------")
			

# -------------------------------------------
# private functions.
# -------------------------------------------
## 初期化.
func _init(w:int, h:int) -> void:
	init(w, h)
	
# -------------------------------------------
# properties.
# -------------------------------------------
var width:int = 0:
	get:
		return _width
var height:int = 0:
	get:
		return _height
