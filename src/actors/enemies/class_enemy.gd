
class_name Enemy
extends Actor

signal enemy_defeated # DEBUGGER ISSUE, UNUSED

const ENEMY_TYPE_BASE_MOVEMENT_SPEED = 150
var BASE_AGGRESSION_TIMER_WAIT_TIME = 3.0

export var enemy_life: int = 35
export var enemy_aggression_modifier: float = 1.0

var current_mouse_target
var firing_target
#
var show_sniper_line = true

var sprite_rescale_x = 0.75
var sprite_rescale_y = 0.75

# used for handling attack minimum range conflict edge case
var approach_flag = false
# used for handling idle state
var is_offscreen = false

var invert_squish = false
var horizontal_squish = Vector2(1.05, 0.95)
var vertical_squish = Vector2(0.95, 1.05)
var squish_randomness_cap = 0.05
var squish_duration  = 0.5

var lifebar_visibility_wait_time = 2.0
var offscreen_activity_time = 2.0

var is_firing = false

onready var enemy_hitbox = $CollisionShape2D

onready var enemy_sprite = $SpriteHolder/TestSprite
onready var target_line = $AbilityHolder/WeaponAbility/TargetLine
onready var squish_tween = $SpriteHolder/TestSprite/SquishingTween

onready var orbit_handler_node = $OrbitalProjectileHolder

onready var damage_immunity_timer = $SpriteHolder/TestSprite/DamageImmunityTimer

onready var debug_lifebar = $Lifebar
onready var damaged_recently_timer = $Lifebar/LifebarTimer

onready var offscreen_timer = $OffscreenTimer
onready var aggression_timer = $AggressionTimer

onready var shot_audio1 = $EnemyShots/Shot1
onready var shot_audio2 = $EnemyShots/Shot2
onready var shot_audio3 = $EnemyShots/Shot3
onready var shot_audio4 = $EnemyShots/Shot4
onready var shot_audio5 = $EnemyShots/Shot5

onready var damaged_audio1 = $EnemyOtherAudio/Damaged1
onready var damaged_audio2 = $EnemyOtherAudio/Damaged2
onready var damaged_audio3 = $EnemyOtherAudio/Damaged3

onready var death_particles = $DeathEffect
onready var death_timer = $DeathEffect/DeathTimer

# stat PERCEPTION --
# stat PERCEPTION --
	# multiplies the initial detection radii
	# multiplies the additional size of additional detection radii
	# can be negative

# stat AGGRESSION --
	# how long does damage cause them to keep active (minimum)
		# 10x float for timer
	# how close do they move to target
		# float multiply close distance border
	# how long do they take to lose attention once off screen
		# 10x float for timer
	# how long do they pursue during second stage searching
		# 5x float for timer

var gamestat_reaction_speed = 20

# stat REACTION_SPEED --
	# how long additional time on top of weapon cooldown? (value/100)
	# initial cooldown multiplied by float of reaction speed
	# how many times per second the enemy can change state

onready var weapon_node = $AbilityHolder/WeaponAbility
onready var detection_scan = $DetectionHandler
onready var state_manager = $StateManager

###############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("enemies")
	set_enemy_stats()
	set_squish_randomness()
	start_squish_tween()
	set_lifebar()
	set_behaviour_timers()
#	set_initial_state(State.IDLE)
	set_parent_spawn_handler()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if velocity != Vector2.ZERO:
		squish_tween.playback_speed = 2.0
	else:
		squish_tween.playback_speed = 0.5
	if is_active:
	#	_process_check_state()
	#	_process_call_state_behaviour(delta)
		var _discard_value = move_and_slide(velocity.normalized() * movement_speed)
	#	detection_scan.player
#		if state_manager.current_state != null:
#			$DebugStateLabel.text = str(state_manager.current_state)
	else:
		state_manager.set_new_state(StateManager.State.IDLE)


###############################################################################


func set_squish_randomness():
	var random_squish =\
	 GlobalFuncs.ReturnRandomRange(\
	 -squish_randomness_cap, squish_randomness_cap)
	
	if random_squish < 0.03 and random_squish > 0:
		random_squish += 0.03
	elif random_squish < 0 and random_squish > -0.03:
		random_squish -= 0.03
	
	horizontal_squish = Vector2(\
	sprite_rescale_x - random_squish, sprite_rescale_y + random_squish)
	vertical_squish = Vector2(\
	sprite_rescale_x + random_squish, sprite_rescale_y - random_squish)
	squish_duration += random_squish


func set_behaviour_timers():
	offscreen_timer.wait_time = offscreen_activity_time
	var aggression_timer_if_damaged =\
	BASE_AGGRESSION_TIMER_WAIT_TIME * enemy_aggression_modifier
	# higher aggression modifier adds more aggression wait time to pursue
	aggression_timer.wait_time = aggression_timer_if_damaged


func set_enemy_stats():
	movement_speed = ENEMY_TYPE_BASE_MOVEMENT_SPEED


func set_parent_spawn_handler():
	var myParent = get_parent()
	if myParent != null:
		yield(myParent, "ready")
		if myParent is WaveSpawnHandler:
			var _discard_value = connect("enemy_defeated", myParent, "check_enemy_count")


func set_lifebar():
	debug_lifebar.visible = false
	debug_lifebar.max_value = enemy_life#
	damaged_recently_timer.wait_time = lifebar_visibility_wait_time
	update_lifebar()


###############################################################################


func _on_DetectionHandler_body_changed_detection_radius(body, is_entering_radius, range_group):
#	print(body, is_entering_radius, range_group)
	if is_active and body is Player\
	 and range_group == GlobalVariables.RangeGroup.NEAR:
		if is_entering_radius:
#			state_manager
			state_manager.set_new_state(StateManager.State.HUNTING)
			detection_scan.current_target = body
		if not is_entering_radius\
	 	 and not range_group in\
		 [GlobalVariables.RangeGroup.MELEE, GlobalVariables.RangeGroup.CLOSE]\
		 and aggression_timer.is_stopped():
			state_manager.set_new_state(StateManager.State.SEARCHING)
#			state_manager.state_node_searching.start_timer()
#			.search_state_first_phase.start()
			detection_scan.current_target = null


func _on_OffscreenNotifier_screen_exited():
# implemented ham-fisted fix of the laggy initial state behaviour implementation
# implemented offscreen force of idle state
#	current_state = State.IDLE
	start_offscreen_timer()
	is_offscreen = true

func _on_OffscreenNotifier_screen_entered():
	is_offscreen = false


func _on_OffscreenTimer_timeout():
	if is_offscreen and aggression_timer.is_stopped():
		state_manager.set_new_state(StateManager.State.IDLE)
		velocity = Vector2.ZERO


func _on_SquishingTween_tween_all_completed():
	invert_squish = !invert_squish
	start_squish_tween()


func _on_Enemy_damaged(damage_taken, damager):
	if damage_immunity_timer.is_stopped():
		damage_immunity_timer.start_immunity()
		enemy_life -= damage_taken
		debug_lifebar.visible = true
		aggression_timer.start()
#		if not state_manager.current_state in\
#		[StateManager.State.HUNTING, StateManager.State.ATTACK]:
#			state_manager.set_new_state(StateManager.State.HUNTING)
#			detection_scan.current_target = damager
		detection_scan._on_Range_Near_body_entered(damager)
		get_damaged_sound_and_play()
		update_lifebar()


func _on_LifebarTimer_timeout():
	debug_lifebar.visible = false


func _on_DeathTimer_timeout():
	queue_free()


func _on_State_Hunting_approach_distance(is_at_maximum_approach):
	approach_flag = is_at_maximum_approach


###############################################################################


func start_offscreen_timer():
	if offscreen_timer.is_stopped():
		# check if not in tree and if it isn't, wait until it is
		if !offscreen_timer.is_inside_tree():
			yield(offscreen_timer, "tree_entered")
		offscreen_timer.start()
	else:
		offscreen_timer.stop()
		offscreen_timer.start()


func start_squish_tween():
	var start_scale = horizontal_squish if invert_squish else vertical_squish
	var end_scale = vertical_squish if invert_squish else horizontal_squish
	squish_tween.interpolate_property(enemy_sprite, "scale",\
	 start_scale, end_scale, squish_duration,\
	 Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	squish_tween.start()


###############################################################################


func move_toward_given_position(self_position, target_position):
#	var velocity = Vector2.ZERO
	velocity = -(self_position - target_position)


func update_lifebar():
	debug_lifebar.value = enemy_life
	damaged_recently_timer.start()
	if enemy_life <= 0:
		enemy_died()


func enemy_died():
	is_active = false
	# hide target line in case it was active at time of death
	target_line.visible = false
#	enemy_hitbox.disabled = true
	enemy_hitbox.set_deferred("disabled", true)
	set_collision_layer_bit(GlobalVariables.CollisionLayers.ENEMY_BODY, false)
	
	detection_scan.disable_all_collision_radii()
	
	debug_lifebar.visible = false
	enemy_sprite.visible = false
	death_particles.emitting = true
	get_damaged_sound_and_play()
	death_timer.start()


func get_shot_sound_and_play():
	var audio_array_shot = [\
	shot_audio1, shot_audio2, shot_audio3, shot_audio4, shot_audio5]
	if GlobalDebug.ENEMY_SE_ENABLED:
		GlobalFuncs.shuffle_audio_and_play(audio_array_shot)


func get_damaged_sound_and_play():
	var audio_array_damaged = [\
	damaged_audio1, damaged_audio2, damaged_audio3]
	if GlobalDebug.ENEMY_SE_ENABLED:
		GlobalFuncs.shuffle_audio_and_play(audio_array_damaged)

##############################################################################


# for removing debugger complaints
func voidfunc():
	emit_signal("enemy_defeated")
