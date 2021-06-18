
class_name WeaponAbility
extends BaseAbility

# this is the temporary faux-json for data storage on weapon behaviours
var weapon = preload("res://src/technical/abilities/json_weapon_styles.gd")

# reference a string path held elsewhere (for simpler path changes)
const PROJECTILE_PATH = GlobalReferences.default_projectile
# reference for node 2d deletion script to attach to
# orbital projectile handlers
const NODE_2D_DELETION_HANDLER = GlobalReferences.node_2d_deletion
# minimum seconds between shots (introduced to prevent shots utilising
# a fixed rotation target sprite from firing before the rotation sprite
# has a chance to update)
const MINIMUM_SHOT_COOLDOWN = 0.1

var base_weapon_style = weapon.Style.FLAMETHROWER
var selected_weapon_style
var current_weapon_style

# damage dealt by a single instance of the attack
var base_damage: int = 1

# position instructions for spawning projectiles
var projectile_spawning_pattern
# intermission between shots
# additive per shot (so time diff between 1 and 2 is same as 3 and 4)
var spawn_delay_per_shot: float

# base vector heading for projectiles spawned
# spawn patterns will vary this in their own code
var shot_velocity: Vector2 = Vector2.ZERO
# projectiles travel this fast
var shot_flight_speed: int = 100
# projectile sprites are rotated per tick if set to anything other than 0
var shot_rotation: int = 0

# for projectile spawning
# get our position for spawn origin
var get_spawn_origin
# determine starting velocity to calculate from
var given_velocity

# number of projectiles fired
var projectile_count: int = 1
# variance for projectile spread
# initial value
var shot_spread: float = 0.15

# resource path of the projectile actors can spawn
onready var projectile_object = preload(PROJECTILE_PATH)
# resource path of the node 2d auto-deletion script for rotation
# handling technical parents generated by orbital projectiles
onready var node2d_deletion_script = preload(NODE_2D_DELETION_HANDLER)
# node references
onready var shot_spawn_delay_timer = $ShotDelayTimer
onready var minimum_cooldown_timer = $MinimumShotCooldown

###############################################################################


# TODO connect projectiles spawned by ability to owner of ability
# signal for expiry initially, include others later

# TODO set collision layers based on collision layers of spawner
#	GlobalReferences.CollisionLayers.PLAYER_PROJECTILE
#	GlobalReferences.CollisionLayers.ENEMY_PROJECTILE
##		projectile.set_collision_layer_bit(index)

# TODO - need to add these to projectile instances
#		DataType.BASE_DAMAGE				: 12,
##		DataType.PROJECTILE_FLIGHT_SPEED	: 250,
##		DataType.PROJECTILE_SPRITE_TYPE	: ProjectileSprite.MAGICAL,
##		DataType.PROJECTILE_SPRITE_ROTATE	: 0,
##		DataType.PROJECTILE_PARTICLES		: ProjectileParticles.NONE,
##		DataType.PROJECTILE_MOVE_PATTERN	: MovementBehaviour.DIRECT,
#
## TODO - need to add these to weapon ability nodes
##		DataType.AI_MIN_USE_RANGE			: GlobalVariables.RangeGroup.CLOSE,
##		DataType.AI_MAX_USE_RANGE			: GlobalVariables.RangeGroup.FAR,
##		DataType.SHOT_SURGE_EFFECT			: SpawnSurgeEffect.NONE,
##		DataType.SHOT_SOUND_EFFECT			: ShotSound.NONE,
#
## TODO - include this in spawn pattern logic
##		DataType.PROJECTILE_SPAWN_DELAY	: 0,
##		DataType.PROJECTILE_COUNT			: 1,
##		DataType.PROJECTILE_SHOT_SPREAD	: 0.05,
#
################################################################################
#
#
# Called when the node enters the scene tree for the first time.
func _ready():
	set_ability_type()
	set_new_weapon(base_weapon_style)
	set_new_cooldown_timer()
	set_minimum_cooldown_timer()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	cleanup_orbital_node_holders()
#
#
################################################################################


func set_ability_type():
	my_ability_type = AbilityType.WEAPON


func set_new_weapon(passed_weapon):
	set_weapon_style(passed_weapon)
	set_weapon_dependent_owner_variables()
#	set_new_cooldown_timer()
#	defunct comment line x3
#	is not called here because the relevant code
#	is included in set_activation_cooldown, the setter function for
#	activation_cooldown which IS set by the set_new_cooldown_timer()


# everything the weapon node needs to know about handling projectiles
# is included in the data returned with this function
# when changing weapon (e.g. via pickup) use this function
func set_weapon_style(new_weapon_style):
	# current_weapon_style should be set to the enum weapon.Style
	# pulls from weapon.STYLE_DATA and populates ability data dict
	var ability_data
	match new_weapon_style:
		weapon.Style.SPLIT_SHOT :
			ability_data = weapon.STYLE_DATA[weapon.Style.SPLIT_SHOT]
		weapon.Style.TRIPLE_BURST_SHOT :
			ability_data = weapon.STYLE_DATA[weapon.Style.TRIPLE_BURST_SHOT]
		weapon.Style.SNIPER_SHOT :
			ability_data = weapon.STYLE_DATA[weapon.Style.SNIPER_SHOT]
		weapon.Style.RAPID_SHOT :
			ability_data = weapon.STYLE_DATA[weapon.Style.RAPID_SHOT]
		weapon.Style.HEAVY_SHOT :
			ability_data = weapon.STYLE_DATA[weapon.Style.HEAVY_SHOT]
		weapon.Style.VORTEX_SHOT :
			ability_data = weapon.STYLE_DATA[weapon.Style.VORTEX_SHOT]
		
		# debugging and tesitng only for player
		# enemy and turret weapon styles
		
		# todo fix set_weapon_style
		# it should be modular/automatic, not a match statement
		
		weapon.Style.BASIC_SHOT :
			ability_data = weapon.STYLE_DATA[weapon.Style.BASIC_SHOT]
		
		weapon.Style.RADAR_SWEEP_SHOT :
			ability_data = weapon.STYLE_DATA[weapon.Style.RADAR_SWEEP_SHOT]
		
		weapon.Style.FLAMETHROWER :
			ability_data = weapon.STYLE_DATA[weapon.Style.FLAMETHROWER]
		
		weapon.Style.SCYTHE :
			ability_data = weapon.STYLE_DATA[weapon.Style.SCYTHE]
		
		weapon.Style.BOLT_LANCE :
			ability_data = weapon.STYLE_DATA[weapon.Style.BOLT_LANCE]
	
	# set the current weapon_style
	selected_weapon_style = new_weapon_style
	current_weapon_style = ability_data
#
#
func set_new_cooldown_timer():
	activation_cooldown =\
	current_weapon_style[weapon.DataType.SHOT_USE_COOLDOWN]
	activation_timer.stop()
	set_cooldown_timer()


func set_weapon_dependent_owner_variables():
	set_owner_targetting_sprites()


func set_owner_targetting_sprites(override = null):
	
	if override == null:
		var target_sprite_valid
		
		if current_weapon_style[weapon.DataType.SHOT_AIM_TYPE] in\
		[weapon.AimType.FIXED_ON_HOLD, weapon.AimType.SNIPER_AIM]:
			target_sprite_valid = false
		else:
			target_sprite_valid = true
	
		owner.can_rotate_target_sprites = target_sprite_valid
		owner.show_rotate_target_sprites = target_sprite_valid
	else:
		if override is bool:
			owner.can_rotate_target_sprites = override
			owner.show_rotate_target_sprites = true


func set_minimum_cooldown_timer():
	minimum_cooldown_timer.wait_time = MINIMUM_SHOT_COOLDOWN


#
################################################################################


# the weapon ability version of this function exclusively handles the
# stationary cooldown timer bonus to activation speed
func attempt_ability():
	.attempt_ability()
	# follow the parent class function and make sure timer is setup
	if is_timer_setup and not owner.is_moving:
		# get the normal ability timer
		var ability_timer_duration = activation_timer.wait_time
		# get the stationary bonus multiplier
		var stationary_bonus = current_weapon_style[weapon.DataType.SHOT_STATIONARY_BONUS]
		# calculate the wait time multiplied by stationary bonus
		var stationary_effective_timer =\
		 ability_timer_duration*(1-stationary_bonus)
		
		# if beneath the effective timer after applying the stationary bonus,
		# and the timer is still running,
		# activate the ability and stop/start the timer
		if activation_timer.time_left < stationary_effective_timer\
		and not activation_timer.is_stopped():
			activation_timer.stop()
			activation_timer.start()
			activate_ability()
	#

# activation function for weapon fire
func activate_ability():
	.activate_ability()
	if GlobalDebug.log_projectile_spawn_steps: ("activate_ability")
	call_projectile_spawn_pattern_function()


# okay this function works but it interferes with spawning projectiles
# so TODO make this only run if no projectile has been spawned recently
# TODO orbital handler is a local onready var when it should be parented, fix
func cleanup_orbital_node_holders():
	# as part of its function the orbital weapon pattern creates node2d
	# technical parents for the purposes of rotation around a central
	# rotating point - these are not cleaned by the projectile class
	# and thus must be cleaned elsewhere
	if current_weapon_style[weapon.DataType.PROJECTILE_MOVE_PATTERN]\
	 in [GlobalVariables.ProjectileMovement.ORBIT, \
	GlobalVariables.ProjectileMovement.ORBIT]:
		# we make sure owner is valid/has the valid node first
		if owner is Actor:
			# don't try to cleanup if currently shooting
			if not owner.is_firing:
				# everything we're trying to clean up is child of this node
				var cleanup_parent = owner.orbit_handler_node
				for orbit_node in cleanup_parent.get_children():
					# if the node has no children it is either new
					# (but if we're not firing it shouldn't be new)
					# or, what we want, it has had a child projectile removed
					if orbit_node.get_child_count() == 0:
						orbit_node.queue_free()


################################################################################
#

# this is a switchboard for the weapon spawn pattern functions
func call_projectile_spawn_pattern_function():
	if GlobalDebug.log_projectile_spawn_steps: ("call_projectile_spawn_pattern_function")
	# we do not process this function if minimum cooldown timer is
	# in action/started
	if  minimum_cooldown_timer.is_stopped():
		
		# projectiles are spawned travelling in the direction of last facing
		# additionally spawner velocity is added to the projectile
		var current_weapon_spawn_pattern = \
		current_weapon_style[weapon.DataType.PROJECTILE_SPAWN_PATTERN]
		
		# we some variables that are utilised by every spawn pattern
		# use our current weapon style to get the number of projectiles fired
		projectile_count = current_weapon_style[weapon.DataType.PROJECTILE_COUNT]
		# get spawn delay between projectiles
		spawn_delay_per_shot = current_weapon_style[weapon.DataType.PROJECTILE_SPAWN_DELAY]
			
		# calculate starting velocity to calculate from
		given_velocity = get_projectile_initial_velocity()
	
		match current_weapon_spawn_pattern:
			weapon.SpawnPattern.SPREAD:
				call_spawn_pattern_spread()
			weapon.SpawnPattern.SERIES:
				call_spawn_pattern_series()


func call_spawn_pattern_spread():
	if GlobalDebug.log_projectile_spawn_steps: ("call_spawn_pattern_spread")
	# TODO implement handling for 
#
#	# get the spread pattern rotation applied to velocity
	var projectile_spread_increment = (weapon.SPREAD_PATTERN_WIDTH)
##
	# initial velocity determined by the actor
	# specifically by the actor's 'firing_target'
	# for a player it is a vector toward their mouse position
	# (at the time they pressed the fire key)
	# for any AI it is the actor or entity they are aiming at
	# (after introducing some fake 'poor aim' and/or 'aiming delay')
	# this is now set in function before
	#var given_velocity = get_projectile_initial_velocity()
	
	# adjusted velocity is the velocity accounting for projectile spread
	var adjusted_velocity
	# this is to store the total rotation applied to projectile velocity
	var spread_adjustment
	# TODO rename this variable to be more representative
	# this variable is basically an additive to spawn_loop to get an
	# even distance between projectiles, it varies whether the
	# projectile count is odd or even
	var additional_spread
	
	# TODO account for projecitle size in spread
	
	var projectile_count_even = projectile_count % 2 == 0
	
	if GlobalDebug.projectile_spread_pattern: print("projectile count even = ", projectile_count_even)
	
	# while spawning projectiles  e are going to loop a number of times
	# equal to half the projectiles if even, or half-1 if odd
	# we are intentionally integer dividing, so please ignore errors
	#warning-ignore:integer_division
	#warning-ignore:integer_division
	var half_projectile_count =\
	projectile_count / 2 if projectile_count_even\
	else (projectile_count - 1) / 2 

	# on to the actual spawning of projectiles
	
	# get our position for spawn origin
	get_spawn_origin = owner.position
	
	# if an odd number of projectiles, spawn a center projectile
	# and set the additional spread to +1
	if not projectile_count_even:
		spawn_new_projectile(get_spawn_origin, given_velocity, 0)
		additional_spread = 1.0
	# else additional spread (for even # of projectiles) is +0.5
	else:
		additional_spread = 0.5
	if GlobalDebug.projectile_spread_pattern: print("additional spread value is ", additional_spread)
	if GlobalDebug.projectile_spread_pattern: print("projectile count is ", projectile_count)
	if GlobalDebug.projectile_spread_pattern: print("data type projectile count is ", current_weapon_style[weapon.DataType.PROJECTILE_COUNT])
	# then we loop to spawn any flanking projectiles
	if projectile_count > 1:
		# update starting velocity in case it has changed
		given_velocity = get_projectile_initial_velocity()
		# limited loop counting variable
		var spawn_loop = 0
		# bwgin the loop
		if GlobalDebug.projectile_spread_pattern: print("beginning spawn loop!")
		if GlobalDebug.projectile_spread_pattern: print("looping ", half_projectile_count, " times.")
		while spawn_loop < half_projectile_count:
			
			# get our position for spawn origin
			get_spawn_origin = owner.position
			if GlobalDebug.projectile_spread_pattern: print("loop count ", spawn_loop)
			# each loop we will adjust the velocity twice before creating
			# a new projectile with the adjusted velocity
			# the first will positively rotate the spread by the increment total
			# the second will negatively rotate the spread by the increment total			
			# spread gets wider each loop
			spread_adjustment =\
			projectile_spread_increment * (spawn_loop+additional_spread)
			# apply random variance to the fixed spread
			spread_adjustment += return_shot_rotation_from_variance()
			
			# update starting velocity in case it has changed
			given_velocity = get_projectile_initial_velocity()
			# rotate velocity by spread
			adjusted_velocity = given_velocity.rotated(spread_adjustment)
			# pass owner position for projectile spawn
			# pass the rotated velocity
			# pass the spread adjustment too, utilised for sprite rotation later
			spawn_new_projectile(get_spawn_origin, adjusted_velocity, spread_adjustment)
			
			# repeat the above with negative values
			spread_adjustment += return_shot_rotation_from_variance()
			adjusted_velocity = given_velocity.rotated(-spread_adjustment)
			spawn_new_projectile(get_spawn_origin, adjusted_velocity, -spread_adjustment)
			
			# increment the loop
			spawn_loop += 1
	
	end_spawn_pattern()


func call_spawn_pattern_series():
	if GlobalDebug.log_projectile_spawn_steps: ("call_spawn_pattern_series")
	set_owner_targetting_sprites(false)
	owner.show_sniper_line = current_weapon_style[weapon.DataType.USE_SNIPER_AIM_LINE]
	
	# adjusted velocity is the velocity accounting for projectile spread
	var adjusted_velocity
	# this is to store the total rotation applied to projectile velocity
	var spread_adjustment
	
	# update velocity
	given_velocity = get_projectile_initial_velocity()
	# don't change this if not free aim
	# bandaid to fix sniper retargeting
	var stored_velocity = given_velocity

	# on to the actual spawning of projectiles
	
	var total_projectiles_spawned = 0
	
	# do not proceed if the timer is already running
	# (that would mean we're waiting for a shot to fire)
	if not shot_spawn_delay_timer.is_stopped():
		return
	
	while total_projectiles_spawned < projectile_count:
		shot_spawn_delay_timer.wait_time = spawn_delay_per_shot
		shot_spawn_delay_timer.start()
		yield(shot_spawn_delay_timer, "timeout")
		spread_adjustment = return_shot_rotation_from_variance()
		
		# update starting velocity to calculate from if free aiming
		if current_weapon_style[weapon.DataType.SHOT_AIM_TYPE] == weapon.AimType.FREE_AIM:
			stored_velocity = get_projectile_initial_velocity()
		
		# get our position for spawn origin
		get_spawn_origin = owner.position
		adjusted_velocity = stored_velocity.rotated(-spread_adjustment)
		spawn_new_projectile(get_spawn_origin, adjusted_velocity, -spread_adjustment)
		total_projectiles_spawned += 1
	owner.show_sniper_line = false
	
	set_owner_targetting_sprites(true)
	
	end_spawn_pattern()


func end_spawn_pattern():
	if GlobalDebug.log_projectile_spawn_steps: ("end_spawn_pattern")
	minimum_cooldown_timer.start()


###############################################################################


func instance_new_projectile():
	if GlobalDebug.log_projectile_spawn_steps: ("instance_new_projectile")
	var new_projectile = projectile_object.instance()
	
	# set who spawned the projectile
	new_projectile.projectile_owner = self.owner

	# set the values by weapon style here
	# speed of the projectile
	new_projectile.projectile_speed =\
	 current_weapon_style[weapon.DataType.PROJECTILE_FLIGHT_SPEED]
	# check if actor is moving, if so add portion of their move speed to proj speed
	if owner.is_moving:
		var speed_inherit_multiplier =\
		 current_weapon_style[weapon.DataType.PROJECTILE_SPEED_INHERIT]
		new_projectile.projectile_speed +=\
		 (owner.movement_speed*speed_inherit_multiplier)
	
	# size of projectile
	new_projectile.projectile_set_size =\
	 current_weapon_style[weapon.DataType.PROJECTILE_SIZE]

	# projectile lifespan (by timer, before deletion)
	new_projectile.projectile_lifespan =\
	 current_weapon_style[weapon.DataType.PROJECTILE_MAX_LIFESPAN]
	# projectile max lifespan once offscreen (if more than this, set to this)
	new_projectile.offscreen_lifespan =\
	 current_weapon_style[weapon.DataType.PROJECTILE_OFFSCREEN_SPAN]
	# maximum range of projectile from origin
	new_projectile.maximum_range =\
	 current_weapon_style[weapon.DataType.PROJECTILE_MAX_RANGE]
	# maximum number of ticks projectile can be moving before deletion
	new_projectile.maximum_ticks_moving =\
	 current_weapon_style[weapon.DataType.PROJECTILE_MAX_MOVE_TICKS]
	
	# rotation of degrees per tick
	new_projectile.rotation_per_tick =\
	 current_weapon_style[weapon.DataType.PROJECTILE_SPRITE_ROTATE]
	
	# TODO change to be a sprite scaling function
	
	# this property is called on projectile to scale projectile size
	new_projectile.projectile_set_size =\
	 current_weapon_style[weapon.DataType.PROJECTILE_SIZE]
	
	# this determines the path of the projectile's sprite
	new_projectile.projectile_sprite_path =\
	 current_weapon_style[weapon.DataType.PROJECTILE_SPRITE_TYPE]
	# this determines the projectile's colour code
	new_projectile.projectile_colour_code =\
	 current_weapon_style[weapon.DataType.PROJECTILE_SPRITE_COLOUR]
	#
	# this establishes how the projectile moves once spawned
	# TODO movement behaviours could become projectile subclasses
	new_projectile.projectile_movement_behaviour =\
	 current_weapon_style[weapon.DataType.PROJECTILE_MOVE_PATTERN]

	# return the instanced projectile
	return new_projectile


# func for creating a new projectile and setting it on its way
func spawn_new_projectile(spawn_position, spawn_velocity, rotation_alteration):
	if GlobalDebug.log_projectile_spawn_steps: ("spawn_new_projectile")

	# call the function to instance a new projectile correctly
	# it applies all the related weapon style data dict values to
	# the newly created projectile
	var new_projectile = instance_new_projectile()

#
#	# if spread has been applied, affix a sprite change
	new_projectile.rotation_degrees = rotation_alteration*10
	
	# rotate projectile to look in direction it is heading
	new_projectile.look_at(spawn_velocity)
	# apply godot engine 90degree fix
#	new_projectile.rotation_degrees += 90

	new_projectile.position = spawn_position
	new_projectile.velocity = spawn_velocity
#
#	TODO - having problems with projectile rotation toward target, need
#	to fix that if I ever want to (re)introduce pointed projectiles
#	- for now just going to use circular projectiles
#
#	#new_projectile.rotation_degrees = 90
##	var offset = owner.position - owner.firing_target
#	var offset = owner.firing_target - owner.position
#	new_projectile.rotation -= offset.angle();
	
	var get_move_style = new_projectile.projectile_movement_behaviour
	if get_move_style == GlobalVariables.ProjectileMovement.DIRECT:
		# add projectile to the root viewport for now # TODO replace this
		var projectile_parent = get_tree().get_root()
		projectile_parent.add_child(new_projectile)
	elif get_move_style == GlobalVariables.ProjectileMovement.ORBIT:
		
		var projectile_parent = new_projectile.projectile_owner.orbit_handler_node
		var count_children = projectile_parent.get_child_count()
		var new_parent = Node2D.new()
		var spawn_spacing = weapon.ORBIT_PATTERN_ROTATION_SPACING
		new_parent.rotation_degrees = spawn_spacing * count_children
		new_parent.add_child(new_projectile)
		projectile_parent.add_child(new_parent)
		# now defunct script attachment to the node2d for cleanup
		# cleanup is now a function of weapon node
#		new_parent.set_script(node2d_deletion_script)
		
	elif get_move_style == GlobalVariables.ProjectileMovement.RADAR:
		
		var projectile_parent = new_projectile.projectile_owner.orbit_handler_node
		projectile_parent.add_child(new_projectile)


###############################################################################


func get_projectile_initial_velocity():
	if GlobalDebug.log_projectile_spawn_steps: ("get_projectile_initial_velocity")
	var firing_velocity =  Vector2(0,0)
	if owner is Actor:
		if current_weapon_style[weapon.DataType.SHOT_AIM_TYPE] == weapon.AimType.FIXED_ON_HOLD:
			firing_velocity = owner.firing_target.normalized()
		elif current_weapon_style[weapon.DataType.SHOT_AIM_TYPE] == weapon.AimType.FREE_AIM\
		or current_weapon_style[weapon.DataType.SHOT_AIM_TYPE] == weapon.AimType.SNIPER_AIM:
			firing_velocity = owner.current_mouse_target.normalized()
	else:
		if GlobalDebug.weapon_initial_velocity_check: print("initial velocity not set")
	# if it returns 0,0 there has been a problem
	return firing_velocity


# change projectile rotation_degree using weapon spread float
# apply spawn velocity as position.rotated(by this value)
# rotate proejctile (rotation_degrees) by this value * 10
func return_shot_rotation_from_variance():
	if GlobalDebug.log_projectile_spawn_steps: ("return_shot_rotation_from_variance")
	# get variance from weapon style data
	var new_shot_spread = \
	current_weapon_style[weapon.DataType.PROJECTILE_SHOT_VARIANCE]
	# return random value from range (0-variance to 0+variance)
	var rotation_degrees_randomisation = \
	GlobalFuncs.ReturnRandomRange(-new_shot_spread, new_shot_spread)
	return rotation_degrees_randomisation


###############################################################################
###############################################################################
#
# DEFUNCT FUNCTIONS BELOW HERE
#
## defunct, remove later
#func defunct_testing_of_call_spawn_pattern_spread():
#	# TODO implement handling for 
#	# use our current weapon style to get the number of projectiles fired
#	var get_projectile_count = \
#	current_weapon_style[weapon.DataType.PROJECTILE_COUNT]
##
##	# get the rotation applied to velocity for spread shots
#	var base_projectile_spread = weapon.SPREAD_PATTERN_WIDTH
#
#	var projectile_spread_increment = (weapon.SPREAD_PATTERN_WIDTH * 0.75)
###
##	# get our position for spawn origin
#	var get_spawn_origin = owner.position
#	# initial velocity determined by the actor
#	# specifically by the actor's 'firing_target'
#	# for a player it is a vector toward their mouse position
#	# (at the time they pressed the fire key)
#	# for any AI it is the actor or entity they are aiming at
#	# (after introducing some fake 'poor aim' and/or 'aiming delay')
#	var given_velocity = get_projectile_initial_velocity()
#	# adjusted velocity is the velocity accounting for projectile spread
#	var adjusted_velocity
#	# this is to store the total rotation applied to projectile velocity
#	var total_spread_increment_counter
#
#	spawn_new_projectile(get_spawn_origin, given_velocity)




###############################################################################

# unfinished function to compare weapon dps
func _calculate_weapon_dps():
	# code to print the entire style data values
	for wep in weapon.Style.size():
		for data in weapon.STYLE_DATA[wep]:
			var wep_data = str(weapon.STYLE_DATA[wep])
			var wep_value = str(weapon.STYLE_DATA[wep][data])
			print(wep_data + ": " + wep_value)
