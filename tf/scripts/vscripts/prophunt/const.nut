/**
 * Copyright © Mikusch, All rights reserved.
 * 
 * https://steamcommunity.com/profiles/76561198071478507
 */

// Prop Hunt constants
const PH_FAKE_PROP_CLASSNAME = "base_boss"
const PH_DECOY_PROP_TARGETNAME = "ph_decoy_prop"
const PH_LOCKED_PROP_TARGETNAME = "ph_locked_prop"
const PH_RAGDOLL_PROP_TARGETNAME = "ph_ragdoll_prop"
const PH_PROP_PERSIST_TARGETNAME = "ph_prop_persist"
const PH_PROP_SELF_DESTRUCT_CLASSNAME = "tf_generic_bomb"
const PH_PROP_SELF_DESTRUCT_TARGETNAME = "ph_suicide_bomb"
const PH_PROP_NODISGUISE_TARGETNAME = "ph_prop_no_disguise"
const PH_DUMMY_PATH_TRACK_TARGETNAME = "ph_dummy_node"
const PH_DEBUG_COMMAND = "!setmodel"
const PH_ABILITY_BAR_LENGTH = 10

const PH_HUD_CHAN_ABILITY_BAR = 2
const PH_HUD_CHAN_ABILITY_NAME = 3
const PH_HUD_POS_X = 0.867
const PH_HUD_POS_Y = 0.885

CONST.TEAM_PROPS <- TF_TEAM_RED
CONST.TEAM_HUNTERS <- TF_TEAM_BLUE

// Prop Hunt settings
const PH_TIMER_DEFAULT_NAME = "ph_timer"
const PH_TIMER_SETUP_DEFAULT_LENGTH = 45
const PH_TIMER_ROUND_DEFAULT_LENGTH = 210

const PH_PROP_MAX_LOCK_HEIGHT = 512.0
const PH_PROP_MIN_REMOVAL_PERCENTAGE = 0.1
const PH_PROP_MAX_REMOVAL_PERCENTAGE = 0.5
const PH_PROP_DISGUISE_TIME = 2.0
const PH_PROP_SELECT_RANGE = 200.0
const PH_PROP_MAX_HEALTH = 300
const PH_HUNTER_DAMAGE_MULTIPLIER = 0.35
const PH_MEDIC_HEALTING_MULTIPLIER = 0.25
const PH_SENTRY_FIRING_SPEED_MULTIPLIER = 0.25

// Math constants
const FLT_MAX = 0x7F7FFFFF

// TF constants
const DAMAGE_NO = 0
const DAMAGE_EVENTS_ONLY = 1
const DAMAGE_YES = 2

const CHAN_STATIC = 6
const CHAN_VOICE2 = 7

const TF_SPELL_OVERHEAL = 2
const TF_SPELL_BLASTJUMP = 4

const LIFE_ALIVE = 0
const DONT_BLEED = 0
const MAX_VIEWMODELS = 2
const FT_STATE_FIRING = 2
const AC_STATE_STARTFIRING = 1
const PATTACH_ABSORIGIN_FOLLOW = 1
const SF_TRIGGER_ALLOW_CLIENTS = 0x01
const TF_DEATHFLAG_DEADRINGER = 32

const TF_DEFINDEX_HUO_LONG_HEATER = 811
const TF_DEFINDEX_HUO_LONG_HEATER_GENUINE = 832
const TF_DEFINDEX_ROCKET_JUMPER = 237
const TF_DEFINDEX_STICKY_JUMPER = 265

CONST.FIRST_GAME_TEAM <- (TEAM_SPECTATOR + 1)
CONST.MASK_SOLID <- (CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_WINDOW | CONTENTS_MONSTER | CONTENTS_GRATE)
CONST.MASK_PLAYERSOLID <- (CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_PLAYERCLIP | CONTENTS_WINDOW | CONTENTS_MONSTER | CONTENTS_GRATE)

const SND_PROPLOCK_ENABLE = "weapons/icicle_freeze_victim_01.wav"
PrecacheSound(SND_PROPLOCK_ENABLE)
const SND_PROPLOCK_DISABLE = "weapons/icicle_melt_01.wav"
PrecacheSound(SND_PROPLOCK_DISABLE)
const SND_PROP_EXPLODE = "Halloween.Merasmus_Hiding_Explode"
PrecacheScriptSound(SND_PROP_EXPLODE)
const SND_DECOY_EXPLODE = "Game.HappyBirthdayNoiseMaker"
PrecacheScriptSound(SND_DECOY_EXPLODE)
const FX_PROP_EXPLODE = "merasmus_object_spawn"
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = FX_PROP_EXPLODE })
const FX_PROP_BLEED = "merasmus_blood"
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = FX_PROP_BLEED })
const FX_DECOY_EXPLODE = "bday_confetti"
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = FX_DECOY_EXPLODE })

const SND_ABILITY_DEMOMAN_USE = "MVM.SentryBusterSpin"
PrecacheScriptSound(SND_ABILITY_DEMOMAN_USE)
const SND_ABILITY_HEAVYWEAPONS_USE = "Powerup.PickUpReflect"
PrecacheScriptSound(SND_ABILITY_HEAVYWEAPONS_USE)
const SND_ABILITY_HEAVYWEAPONS_LOOP = "Ambient.NucleusElectricity"
PrecacheScriptSound(SND_ABILITY_HEAVYWEAPONS_LOOP)
const SND_ABILITY_SPY_START = "Halloween.spell_stealth"
PrecacheScriptSound(SND_ABILITY_SPY_START)
const SND_ABILITY_ENGINEER_USE = ")ui/item_mtp_drop.wav"
PrecacheSound(SND_ABILITY_ENGINEER_USE)

::DEBUFF_CONDITIONS <-
[
	TF_COND_BURNING,
	TF_COND_URINE,
	TF_COND_BLEEDING,
	TF_COND_MAD_MILK,
	TF_COND_GAS
]

::SND_ROUND_START <-
[
	"vo/mvm_wave_start10.mp3",
	"vo/mvm_wave_start11.mp3"
]
foreach (i, sound in SND_ROUND_START)
	PrecacheSound(sound)

::PERSIST_PARENT_CLASSNAMES <-
{
	func_door = true,
	func_door_rotating = true,
	func_tracktrain = true
}

::PROJECTILE_CLASSNAME_TO_DAMAGE <-
{
	tf_projectile_arrow				= 50,
	tf_projectile_ball_ornament		= Convars.GetFloat("sv_proj_stunball_damage"),
	tf_projectile_balloffire		= 75,
	tf_projectile_cleaver			= 40,
	tf_projectile_energy_ball		= 90,
	tf_projectile_energy_ring		= 20,
	tf_projectile_flare				= 30,
	tf_projectile_healing_bolt		= 40,
	tf_projectile_jar				= 0 ,
	tf_projectile_jar_gas			= 0,
	tf_projectile_mechanicalarmorb	= 10,
	tf_projectile_pipe				= 100,
	tf_projectile_pipe_remote		= 120,
	tf_projectile_rocket			= 90,
	tf_projectile_sentryrocket		= 100,
	tf_projectile_stun_ball			= Convars.GetFloat("sv_proj_stunball_damage"),
	tf_projectile_syringe			= 10
}