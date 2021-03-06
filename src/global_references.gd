extends Node

###############################################################################

# paths to various resources handled by multiple scenes
# the default weapon projectile modified by weapon style data
const default_projectile = "res://src/entities/projectile.tscn"
# node for deletion of instances created by orbital proj spawn pattern
const node_2d_deletion = "res://src/technical/node2d_deletion_handler.gd"
# technical modifiers
# technical modifier for time slow ability
const modifier_time_slow = "res://src/technical/modifiers/modifier_time_slow.tscn"
# graphical effects
# particle that travels across the screen at a rotating offset
const windy_leaf_particle = "res://src/effect/level_windy_leaf_particle.tscn"
# particles for nodes affected by the player's time slow bubble
const time_slow_particles = "res://src/effect/time_slowed_effect.tscn"
# the time slow bubble ability scene
const time_slow_bubble = "res://src/effect/TimeBubbleZone.tscn"
# the poo bomb ability scene
const poo_bomb = "res://src/technical/abilities/weapon_object_poo_bomb.tscn"
# creep zone ground effect scene
const creep_ground = "res://src/effect/ground_effect_creep_area.tscn"

# paths to various enemy scenes
const enemy_basic_snake = "res://src/actors/enemies/base_enemy.tscn"
const enemy_croc_sniper = "res://src/actors/enemies/enemy_crocodile_totem_sniper.tscn"
const enemy_wind_scyther = "res://src/actors/enemies/enemy_flying_wind_scyther.tscn"
const enemy_creep_giraffe = "res://src/actors/enemies/enemy_giraffe_blood_creep.tscn"
const enemy_elite_snake = "res://src/actors/enemies/enemy_red_snake_elite.tscn"
const enemy_wolverine_tank = "res://src/actors/enemies/enemy_wolverine_tank.tscn"

###############################################################################

# paths to sprite graphics for collectables and ui cooldown radial
const sprite_weapon_split_shot = "res://art/icons/lorc-gameicons_striking_arrows.png"
const sprite_weapon_triple_burst_shot = "res://art/icons/lorc-gameicons_bullets.png"
const sprite_weapon_sniper_shot = "res://art/icons/lorc-gameicons_sniper.png"
const sprite_weapon_rapid_shot = "res://art/icons/lorc-gameicons_missile_swarm.png"
const sprite_weapon_heavy_shot = "res://art/icons/lorc-gameicons_comet_spark.png"
const sprite_weapon_vortex_shot = "res://art/icons/lorc-gameicons_orbital.png"
const sprite_weapon_wind_scythe = "res://art/icons/lorc-gameicons_whirlpool_shuriken.png"
const sprite_weapon_bolt_lance = "res://art/icons/lorc-gameicons_lightning_frequency.png"

# paths to greyscale sprite graphics for ui cooldown radial
const sprite_weapon_split_shot_greyscale = "res://art/icons/lorc-gameicons_striking_arrows_greyscale.png"
const sprite_weapon_triple_burst_shot_greyscale = "res://art/icons/lorc-gameicons_bullets_greyscale.png"
const sprite_weapon_sniper_shot_greyscale = "res://art/icons/lorc-gameicons_sniper_greyscale.png"
const sprite_weapon_rapid_shot_greyscale = "res://art/icons/lorc-gameicons_missile_swarm_greyscale.png"
const sprite_weapon_heavy_shot_greyscale = "res://art/icons/lorc-gameicons_comet_spark_greyscale.png"
const sprite_weapon_vortex_shot_greyscale = "res://art/icons/lorc-gameicons_orbital_greyscale.png"
const sprite_weapon_wind_scythe_greyscale = "res://art/icons/lorc-gameicons_whirlpool_shuriken_greyscale.png"
const sprite_weapon_bolt_lance_greyscale = "res://art/icons/lorc-gameicons_lightning_frequency_greyscale.png"

# paths to projectile graphics
const sprite_projectile_split_shot = "res://art/projectile/kenney_simplespace/meteor_squareLarge.png"
const sprite_projectile_triple_burst_shot = "res://art/projectile/kenney_simplespace/meteor_squareDetailedLarge.png"
const sprite_projectile_sniper_shot = "res://art/projectile/kenney_simplespace/station_B.png"
const sprite_projectile_rapid_shot = "res://art/projectile/kenney_simplespace/star_tiny.png"
const sprite_projectile_heavy_shot = "res://art/projectile/kenney_simplespace/meteor_detailedLarge.png"
const sprite_projectile_vortex_shot = "res://art/projectile/kenney_simplespace/meteor_large.png"
const sprite_projectile_smoke = "res://art/projectile/kenney_smokeparticleassets/PNG/Black smoke/blackSmoke00.png"
const sprite_projectile_fire_cloud = "res://art/projectile/kenney_particlePack_1.1/flame_02.png"
const sprite_projectile_scythe = "res://art/kenney_particle1.1/twirl_01.png"
const sprite_projectile_bolt_lance = "res://art/projectile/kenney_particlePack_1.1/trace_05.png"

#

const state_emote_roaming = "res://art/icons/kenney_emotespack/PNG/Vector/Style 1/emote_question.png"
const state_emote_searching = "res://art/icons/kenney_emotespack/PNG/Vector/Style 1/emote_alert.png"
const state_emote_hunting = "res://art/icons/kenney_emotespack/PNG/Vector/Style 1/emote_anger.png"

###############################################################################

# string references for descriptions
# descriptions for weapon types
const DESC_SPLIT_SHOT =\
"Fires 3 projectiles in a split pattern."
const DESC_TRIPLE_BURST_SHOT =\
"Fires 3 projectiles in a series pattern."
const DESC_SNIPER_SHOT =\
"Fires a single high speed powerful projectile."
const DESC_RAPID_SHOT =\
"Fires single projectiles as rapidly as possible."
const DESC_HEAVY_SHOT =\
"Fires a large slow shot that deals high damage."
const DESC_VORTEX_SHOT =\
"Fires shots that stop and orbit the attacker"

const DESC_NONE =\
"Invalid description string"

###############################################################################
