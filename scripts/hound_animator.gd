extends Node
class_name HoundAnimator
## Plays the hound's animations based on what the MonsterAI parent is doing.
## Animations in the pack: Idle, Walk, Run, Attack, Attack2, Death, Hit, Howl.

@export var animation_player_path: NodePath

var _monster: MonsterAI
var _anim: AnimationPlayer
var _last_state := -1
var _busy_until := 0.0


func _ready() -> void:
	_monster = get_parent() as MonsterAI
	_anim = get_node_or_null(animation_player_path) as AnimationPlayer
	if _monster == null or _anim == null:
		push_warning("HoundAnimator: needs a MonsterAI parent and an AnimationPlayer.")
		set_process(false)
		return
	for looping in ["Idle", "Walk", "Run"]:
		if _anim.has_animation(looping):
			_anim.get_animation(looping).loop_mode = Animation.LOOP_LINEAR
	_monster.attacked_target.connect(_on_attacked)
	_anim.play("Idle")


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _busy_until:
		return # an attack or howl is playing
	if _monster.is_stunned():
		if _anim.current_animation != "Hit":
			_anim.play("Hit", 0.1)
		return
	# Howl once when the hunt starts.
	if _monster.state == MonsterAI.State.CHASE and _last_state != MonsterAI.State.CHASE:
		_last_state = _monster.state
		_play_once("Howl")
		return
	_last_state = _monster.state
	var speed := Vector2(_monster.velocity.x, _monster.velocity.z).length()
	var wanted := "Idle"
	if _monster.state == MonsterAI.State.CHASE and speed > 0.5:
		wanted = "Run"
	elif speed > 0.3:
		wanted = "Walk"
	if _anim.current_animation != wanted:
		_anim.play(wanted, 0.2)


func _play_once(animation_name: String) -> void:
	if not _anim.has_animation(animation_name):
		return
	_anim.play(animation_name, 0.1)
	_busy_until = Time.get_ticks_msec() / 1000.0 + _anim.get_animation(animation_name).length


func _on_attacked(_target: Node, _damage: float, _dir: Vector3, _force: float) -> void:
	_play_once("Attack")
