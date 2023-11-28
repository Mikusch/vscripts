/**
 * Copyright © Mikusch, All rights reserved.
 * 
 * https://steamcommunity.com/profiles/76561198071478507
 */

EntFire("tf_gamerules", "SetRedTeamGoalString", "Find a hiding spot and prevent BLU from eliminating your team!")
EntFire("tf_gamerules", "SetBlueTeamGoalString", "Find and eliminate RED!")

::worldspawn <- Entities.FindByClassname(null, "worldspawn")
AddThinkToEnt(worldspawn, "WorldThink")
NetProps.SetPropInt(worldspawn, "m_takedamage", DAMAGE_EVENTS_ONLY)
::gamerules <- Entities.FindByClassname(null, "tf_gamerules")
::MaxPlayers <- MaxClients()

::props <- []
::projectiles <- []
::game_text <- null
::env_hudhint <- null

class CPropHuntPlayer
{
	constructor(player)
	{
		this.player = player

		AddThinkToEnt(player, "PlayerThink")
	}

	function ClearAbilityHUD()
	{
		ShowText("", PH_HUD_CHAN_ABILITY_BAR)
		ShowText("", PH_HUD_CHAN_ABILITY_NAME)
		player.SetScriptOverlayMaterial("")
	}

	function OnSpawn(params)
	{
		if (ability != null && "Destroy" in ability)
			ability.Destroy()

		ability = null
		last_action_time = Time()

		StopDisguising()
		ClearDisguise()
		ClearAbilityHUD()
		SetPropLock(false, true)

		NetProps.SetPropBool(player, "m_bGlowEnabled", false)

		if (params.team == CONST.TEAM_PROPS)
		{
			// Assign ability for current class
			ability = GetAbility()
			played_bell = true

			player.AddHudHideFlags(HIDEHUD_BUILDING_STATUS | HIDEHUD_PIPES_AND_CHARGE | HIDEHUD_CLOAK_AND_FEIGN | HIDEHUD_METAL)

			EntFireByHandle(player, "RunScriptCode", "self.SetForcedTauntCam(1)", 0.1, null, null)
			EntFireByHandle(player, "DisableShadow", null, -1, null, null)

			for (local i = MAX_VIEWMODELS - 1; i >= 0; i--)
			{
				local viewmodel = NetProps.GetPropEntityArray(player, "m_hViewModel", i)
				if (viewmodel != null)
					viewmodel.Destroy()
			}
		}
	}

	function OnPostSpawn()
	{
		player.SetHealth(player.GetMaxHealth())

		if (player.GetTeam() == CONST.TEAM_PROPS)
		{
			if (ability != null && "OnPostSpawn" in ability)
				ability.OnPostSpawn()

			if (GetRoundState() != GR_STATE_PREROUND)
				SetClassSpeed()

			local valid_props = []

			foreach(i, prop in props)
			{
				if (IsValidDisguiseTarget(prop) && prop.GetBoundingMaxs().Length() <= 100)
					valid_props.push(prop)
			}

			// Spawn in as a random medium-sized prop
			if (valid_props.len() > 0)
			{
				disguise_target = valid_props[RandomInt(0, valid_props.len() - 1)]
				disguise_finish_time = Time()
			}
		}
		else if (player.GetTeam() == CONST.TEAM_HUNTERS)
		{
			player.AddCustomAttribute("reduced_healing_from_medics", PH_MEDIC_HEALTING_MULTIPLIER, -1)
			player.AddCustomAttribute("engy sentry fire rate increased", 1.0 / PH_SENTRY_FIRING_SPEED_MULTIPLIER, -1)
		}
	}

	function SetClassSpeed()
	{
		if (player.GetPlayerClass() == TF_CLASS_SCOUT)
			return

		local factor = 300 / NetProps.GetPropFloat(player, "m_flMaxspeed")
		if (factor > 1)
			player.AddCustomAttribute("move speed bonus", factor, -1)
		else if (factor < 1)
			player.AddCustomAttribute("move speed penalty", factor, -1)
	}

	function ClearDisguise()
	{
		player.SetCustomModel("")
		player.SetCustomModelOffset(Vector())
		player.ClearCustomModelRotation()
		player.SetCustomModelRotates(true)
		NetProps.SetPropBool(player, "m_bForcedSkin", false)
	}

	function IsValidDisguiseTarget(entity)
	{
		return entity != null && entity.IsValid()
			&& (props.find(entity) != null || entity.IsValidForDisguise())
			&& entity != disguise_target
			&& (IsDisguising() || player.GetModelName() != entity.GetModelName() || player.GetEffectiveSkin() != entity.GetEffectiveSkin())
			&& (disguise_target == null || disguise_target.GetModelName() != entity.GetModelName() || disguise_target.GetEffectiveSkin() != entity.GetEffectiveSkin())
	}

	function IsDisguising()
	{
		return disguise_finish_time != null
	}

	function BeginDisguising(target)
	{
		// If we're already disguised as this prop, but have a disguise in progress, cancel it
		if (target.GetModelName() == player.GetModelName() && target.GetEffectiveSkin() == player.GetEffectiveSkin())
		{
			StopDisguising()
			return
		}

		disguise_effect = SpawnEntityFromTable("trigger_particle",
		{
			particle_name = player.GetTeam() == TF_TEAM_RED ? "spy_start_disguise_red" : "spy_start_disguise_blue",
			attachment_type = PATTACH_ABSORIGIN_FOLLOW,
			spawnflags = SF_TRIGGER_ALLOW_CLIENTS
		})
		disguise_effect.ForcePurgeStrings()
		EntFireByHandle(disguise_effect, "StartTouch", "!activator", -1, player, player)

		player.EmitSound("Player.Spy_Disguise")

		disguise_target = target
		disguise_finish_time = Time() + PH_PROP_DISGUISE_TIME
	}

	function StopDisguising()
	{
		if (!IsDisguising())
			return
		
		disguise_target = null
		disguise_finish_time = null

		if (disguise_effect != null && disguise_effect.IsValid())
		{
			disguise_effect.Destroy()
			EntFireByHandle(player, "DispatchEffect", "ParticleEffectStop", -1, null, null)
		}
	}

	function CompleteDisguise()
	{
		if (!IsDisguising())
			return

		if (disguise_target != null && disguise_target.IsValid())
		{
			ClearDisguise()

			local model = disguise_target.GetModelName()

			config = model in configs ? configs[model] : null

			player.SetCustomModel(model)

			if (config != null)
			{
				if (config.offset != null)
					player.SetCustomModelOffset(config.offset)

				if (config.rotation != null)
					player.SetCustomModelRotation(config.rotation)
			}

			NetProps.SetPropInt(player, "m_bloodColor", DONT_BLEED)
			NetProps.SetPropBool(player, "m_bForcedSkin", true)
			NetProps.SetPropInt(player, "m_nForcedSkin", disguise_target.GetEffectiveSkin())

			local size = disguise_target.GetBoundingMaxs().Length()

			// Keep the ratio of health to max health the same when the player switches props
			local desired_maxhealth = (config != null && config.health != null) ? config.health : size

			player.AddCustomAttribute("voice pitch scale", Clamp(100.0 / size, 0.5, 2.0), -1)

			// Heavy has increased prop health
			if (player.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS)
				desired_maxhealth *= 2

			desired_maxhealth = Min(desired_maxhealth, PH_PROP_MAX_HEALTH)

			if (player.GetMaxHealth() != desired_maxhealth)
			{
				local percentage = player.GetHealth().tofloat() / player.GetMaxHealth().tofloat()
				player.RemoveCustomAttribute("hidden maxhealth non buffed")
				player.AddCustomAttribute("hidden maxhealth non buffed", desired_maxhealth - player.GetMaxHealth(), -1)

				player.SetHealth(Clamp(player.GetMaxHealth() * percentage, 1, PH_PROP_MAX_HEALTH))
			}

			if (developer() == 1)
			{
				ClientPrint(player, HUD_PRINTTALK, "[DEBUG] You have disguised as " + model)
			}
		}

		// Must be the last call! Clear out any values.
		StopDisguising()
	}

	function UseAbility()
	{
		if (ability == null)
			return false

		if (!ability.IsAllowedToUse())
			return false

		// Abilities can fail to activate
		if (!ability.Use())
			return false

		played_bell = false
		return true
	}

	function AbilityThink()
	{
		if (this.ability == null)
			return

		if (ability.IsAllowedToUse() && !played_bell)
		{
			played_bell = true
			EmitSoundEx({ sound_name = "TFPlayer.ReCharged", entity = player, filter_type = RECIPIENT_FILTER_SINGLE_PLAYER })
		}

		ability.Update()
	}

	function CreateFakeProp(targetname)
	{
		local origin = player.GetOrigin()
		local angles = player.GetAbsAngles()
		local team = player.GetTeam()

		if (config != null)
		{
			if (config.offset != null)
				origin += config.offset
			
			if (config.rotation != null)
				angles = config.rotation
		}

		local prop = Entities.CreateByClassname(PH_FAKE_PROP_CLASSNAME)
		prop.KeyValueFromString("targetname", targetname)
		prop.KeyValueFromInt("body", NetProps.GetPropInt(player, "m_nBody"))
		prop.SetAbsOrigin(origin)
		prop.SetAbsAngles(angles)
		prop.SetSkin(player.GetEffectiveSkin())
		prop.SetTeam(player.GetTeam())
		prop.SetHealth(player.GetHealth())
		prop.SetMaxHealth(player.GetMaxHealth())
		prop.SetModel(player.GetModelName())
		prop.SetSequence(player.GetSequence())
		prop.SetPlaybackRate(player.GetPlaybackRate())
		prop.SetCycle(player.GetCycle())
		prop.SetOwner(player)
		prop.AddEffects(EF_NOSHADOW)
		prop.SetSolid(SOLID_VPHYSICS)
		prop.AddFlag(FL_NOTARGET)
		prop.ForcePurgeStrings()

		NetProps.SetPropInt(prop, "m_takedamage", DAMAGE_YES)
		NetProps.SetPropInt(prop, "m_bloodColor", DONT_BLEED)

		AddThinkToEnt(prop, "AnimThink")

		local train_name = "ph_locked_prop_train_" + player.entindex()
		local tracktrain = SpawnEntityFromTable("func_tracktrain",
		{
			targetname = train_name,
			origin = origin + Vector(0, 0, prop.GetBoundingMaxs().z - prop.GetBoundingMins().z),
			angles = angles,
			model = "models/empty.mdl",
			rendermode = kRenderNone,
			teamnum = team
		})
		tracktrain.ForcePurgeStrings()
		EntFireByHandle(tracktrain, "SetParent", "!activator", -1, prop, null)

		prop.ValidateScriptScope()
		prop.GetScriptScope().train <- tracktrain

		local team_train_watcher = SpawnEntityFromTable("team_train_watcher",
		{
			train = train_name,
			origin = origin,
			angles = angles,
			teamnum = team,
			start_node = PH_DUMMY_PATH_TRACK_TARGETNAME,
			goal_node = PH_DUMMY_PATH_TRACK_TARGETNAME
		})
		team_train_watcher.ForcePurgeStrings()
		EntFireByHandle(team_train_watcher, "SetParent", "!activator", -1, prop, null)
		EntFireByHandle(team_train_watcher, "Enable", null, -1, null, null)

		return prop
	}

	function PropThink()
	{
		if (!player.IsAlive())
			return -1
		
		if (IsDisguising() && disguise_finish_time <= Time())
			CompleteDisguise()

		if (ability != null)
		{
			local percentage = ability.GetAbilityRechargePercentage()

			local message = CreateProgressBar(percentage, PH_ABILITY_BAR_LENGTH)
			ShowText(message, PH_HUD_CHAN_ABILITY_BAR, PH_HUD_POS_X, PH_HUD_POS_Y + 0.01)

			message = RepeatString(" ", PH_ABILITY_BAR_LENGTH - ability.name.len() - 1) + ability.name
			ShowText(message, PH_HUD_CHAN_ABILITY_NAME, PH_HUD_POS_X, PH_HUD_POS_Y + 0.04)
		}

		if (InSetup() && env_hudhint != null && env_hudhint.IsValid())
			EntFireByHandle(env_hudhint, "ShowHudHint", "!activator", -1, player, null)

		local buttons = NetProps.GetPropInt(player, "m_nButtons")

		// mp_idledealmethod and mp_idlemaxtime are not on the allowlist
		local button_forced = NetProps.GetPropInt(player, "m_afButtonForced")
		if (in_grenade1)
			NetProps.SetPropInt(player, "m_afButtonForced", button_forced &~ IN_GRENADE1)
		else
			NetProps.SetPropInt(player, "m_afButtonForced", button_forced | IN_GRENADE1)
		in_grenade1 = !in_grenade1

		if (GetRoundState() != GR_STATE_TEAM_WIN)
		{
			local trace =
			{
				start = player.EyePosition(),
				end = player.EyePosition() + (player.EyeAngles().Forward() * PH_PROP_SELECT_RANGE),
				ignore = player,
				mask = CONST.MASK_SOLID
			}

			if (!locked)
			{
				if (TraceLineEx(trace) && trace.hit && "enthit" in trace && IsValidDisguiseTarget(trace.enthit))
				{
					ClientPrint(player, HUD_PRINTCENTER, "Press 'PRIMARY ATTACK' to disguise!")
					
					// +attack: Disguise
					if (IsButtonToggled(buttons, IN_ATTACK))
						BeginDisguising(trace.enthit)
				}
				else
				{
					ClientPrint(player, HUD_PRINTCENTER, "")
				}
			}
		}

		// Movement keys: Undo prop lock
		if (locked && (IsButtonToggled(buttons, IN_JUMP) || IsButtonToggled(buttons, IN_FORWARD) || IsButtonToggled(buttons, IN_BACK) || IsButtonToggled(buttons, IN_MOVELEFT) || IsButtonToggled(buttons, IN_MOVERIGHT)))
			SetPropLock(false)

		if (buttons & IN_JUMP || buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT)
			last_action_time = Time()

		// Auto-lock after some time
		if (CanPropLock() && last_action_time != null && Time() - last_action_time >= 3.0)
			SetPropLock(true)

		// +attack2: Toggle prop lock
		if (IsButtonToggled(buttons, IN_ATTACK2) && !IsDisguising())
		{
			if (locked)
			{
				SetPropLock(false)
			}
			else if (CanPropLock())
			{
				SetPropLock(true)
			}
			else
			{
				EmitSoundEx({ sound_name = "Player.UseDeny", entity = player, filter_type = RECIPIENT_FILTER_SINGLE_PLAYER })
			}
		}

		// ++use_action_slot_item: Use ability
		if (player.IsUsingActionSlot())
		{
			if (!using_action_slot)
			{
				using_action_slot = true
				last_action_time = Time()

				if (!UseAbility())
					EmitSoundEx({ sound_name = "Player.UseDeny", entity = player, filter_type = RECIPIENT_FILTER_SINGLE_PLAYER })
			}
		}
		else
		{
			using_action_slot = false
		}

		// +reload: Toggle third person
		if (IsButtonToggled(buttons, IN_RELOAD))
		{
			player.SetForcedTauntCam(NetProps.GetPropInt(player, "m_nForceTauntCam") == 0 ? 1 : 0)

			// Fade out the prop while in third person (at least 1 HU)
			if (locked_prop != null && locked_prop.IsValid())
				NetProps.SetPropFloat(locked_prop, "m_fadeMaxDist", NetProps.GetPropInt(player, "m_nForceTauntCam") == 0 ? 1.0 : 0.0)
		}
		
		AbilityThink()

		old_buttons = buttons
		return -1
	}

	function IsButtonToggled(buttons, button)
	{
		return !(old_buttons & button) && buttons & button
	}

	function ShowText(message, channel, x = PH_HUD_POS_X, y = PH_HUD_POS_Y)
	{
		if (game_text == null || !game_text.IsValid())
			return

		game_text.GetScriptScope().queue.append({ message = message, channel = channel, x = x, y = y })
		EntFireByHandle(game_text, "Display", null, -1, player, null)
	}

	function CanPropLock()
	{
		if (locked)
			return false

		if (next_lock_time > Time())
			return false

		if (GetRoundState() == GR_STATE_TEAM_WIN || GetRoundState() == GR_STATE_PREROUND)
			return false

		ToggleSolidFlagsForTrigger("trigger_hurt", true)
		ToggleSolidFlagsForTrigger("func_croc", true)

		local trace =
		{
			start = player.GetOrigin(),
			end = player.GetOrigin() - Vector(0, 0, 32768),
			ignore = player,
			mask = (CONST.MASK_PLAYERSOLID ^ CONTENTS_MONSTER)
		}
		TraceLineEx(trace)

		ToggleSolidFlagsForTrigger("trigger_hurt", false)
		ToggleSolidFlagsForTrigger("func_croc", false)

		// Don't allow prop locking over trigger_hurt or too far above the ground
		if (trace.hit && ("enthit" in trace && trace.enthit.GetClassname() == "trigger_hurt" || (trace.startpos - trace.endpos).Length() > PH_PROP_MAX_LOCK_HEIGHT))
			return false

		return CanSpawnFakeProp()
	}

	function CanSpawnFakeProp()
	{
		local prop = SpawnEntityFromTable("prop_dynamic", { model = player.GetModelName(), origin = player.GetOrigin(), angles = player.GetAbsAngles() })
		local origin = prop.GetOrigin()
		local mins = prop.GetBoundingMinsOriented() + origin
		local maxs = prop.GetBoundingMaxsOriented() + origin
		prop.ForcePurgeStrings()
		prop.Destroy()

		// Check if we would trap a player with our prop
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local target = PlayerInstanceFromIndex(i)
			if (target == null)
				continue
			
			if (target == player)
				continue
			
			if (!target.IsAlive())
				continue
			
			local target_origin = target.GetOrigin()
			local target_mins = target_origin + target.GetPlayerMins()
			local target_maxs = target_origin + target.GetPlayerMaxs()

			if ((target_mins.x > maxs.x) || (target_maxs.x < mins.x))
				continue
			
			if ((target_mins.y > maxs.y) || (target_maxs.y < mins.y))
				continue
			
			if ((target_mins.z > maxs.z) || (target_maxs.z < mins.z))
				continue
			
			return false
		}

		return true
	}

	function GetAbility()
	{
		switch (player.GetPlayerClass())
		{
			case TF_CLASS_SCOUT:
				return CSpeedBoost(player)
			case TF_CLASS_SNIPER:
				return CJarateBurst(player)
			case TF_CLASS_SOLDIER:
				return CBlastJump(player)
			case TF_CLASS_DEMOMAN:
				return CSelfDestruct(player)
			case TF_CLASS_MEDIC:
				return COverheal(player)
			case TF_CLASS_HEAVYWEAPONS:
				return CReflect(player)
			case TF_CLASS_PYRO:
				return CGasBlast(player)
			case TF_CLASS_SPY:
				return CStealth(player)
			case TF_CLASS_ENGINEER:
				return CDecoyProp(player)
			default:
				return CDecoyProp(player)
		}
	}

	function UpdateObservers(old, new)
	{
		for (local i = 1; i <= MaxPlayers; i++)
		{
			local other = PlayerInstanceFromIndex(i)
			if (other == null)
				continue

			if (other == player)
				continue

			if (NetProps.GetPropEntity(other, "m_hObserverTarget") != old)
				continue

			NetProps.SetPropEntity(other, "m_hObserverTarget", new)
		}
	}

	function SetPropLock(locked, silent = false)
	{
		if (this.locked == locked)
			return

		if (!silent)
		{
			player.SetMoveType(locked ? MOVETYPE_NONE : MOVETYPE_WALK, MOVECOLLIDE_DEFAULT)

			if (locked)
				EmitSoundEx({ sound_name = SND_PROPLOCK_ENABLE, channel = CHAN_STATIC, delay = -0.235, entity = player, filter_type = RECIPIENT_FILTER_SINGLE_PLAYER })
			else
				EmitSoundEx({ sound_name = SND_PROPLOCK_DISABLE, channel = CHAN_STATIC, entity = player, filter_type = RECIPIENT_FILTER_SINGLE_PLAYER })
		}

		local effect = SpawnEntityFromTable("trigger_particle",
		{
			particle_name = "xms_icicle_impact_dryice",
			attachment_type = PATTACH_ABSORIGIN_FOLLOW,
			spawnflags = SF_TRIGGER_ALLOW_CLIENTS
		})
		EntFireByHandle(effect, "StartTouch", "!activator", -1, player, player)
		EntFireByHandle(effect, "Kill", null, -1, null, null)

		if (locked)
		{
			player.AddFlag(FL_NOTARGET)
			player.DisableDraw()
			player.SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			player.AddCond(TF_COND_IMMUNE_TO_PUSHBACK)

			// Create a separate entity for proper collisions
			locked_prop = CreateFakeProp(PH_LOCKED_PROP_TARGETNAME)
			NetProps.SetPropFloat(locked_prop, "m_fadeMaxDist", NetProps.GetPropInt(player, "m_nForceTauntCam") == 0 ? 1.0 : 0.0)

			UpdateObservers(player, locked_prop.GetScriptScope().train)

			ClientPrint(player, HUD_PRINTCENTER, "Prop lock engaged!")

			next_lock_time = Time() + 0.5
		}
		else
		{
			player.RemoveFlag(FL_NOTARGET)
			player.EnableDraw()
			player.SetCollisionGroup(COLLISION_GROUP_PLAYER)
			player.RemoveCond(TF_COND_IMMUNE_TO_PUSHBACK)

			UpdateObservers(locked_prop.GetScriptScope().train, player)

			DestroyLockedProp()
		}

		player.SetCustomModelRotates(!locked)

		this.locked = locked
		last_action_time = Time()
	}

	function DestroyLockedProp()
	{
		if (locked_prop != null && locked_prop.IsValid())
		{
			AddThinkToEnt(locked_prop, null)
			locked_prop.Destroy()
		}
	}

	function CastSingleSpell(index)
	{
		local spellbook = SpawnEntityFromTable("tf_weapon_spellbook", { origin = player.GetOrigin(), teamnum = player.GetTeam() })
		NetProps.SetPropInt(spellbook, "m_iSelectedSpellIndex", index)
		NetProps.SetPropInt(spellbook, "m_iSpellCharges", 1)
		spellbook.SetOwner(player)
		player.Weapon_Equip(spellbook)
		NetProps.SetPropFloat(spellbook, "m_flNextPrimaryAttack", Time())
		spellbook.PrimaryAttack()
		AddThinkToEnt(spellbook, "SpellbookThink")
	}

	// !setmodel <model>
	function HandleCommand_SetModel(model)
	{
		ClearDisguise()
		SetPropLock(false)

		local prop = SpawnEntityFromTable("prop_dynamic", { model = model, origin = player.GetOrigin(), angles = player.GetAbsAngles() })
		EntFireByHandle(prop, "Kill", null, -1, null, null)

		disguise_target = prop
		disguise_finish_time = Time()
	}

	player = null

	ability_meter_text = null
	ability_name_text = null
	config = null

	old_buttons = 0
	last_action_time = null
	using_action_slot = false
	in_grenade1 = false
	locked = false
	next_lock_time = 0.0
	locked_prop = null
	has_killed_hunter = false

	disguise_effect = null
	disguise_target = null
	disguise_finish_time = null

	ability = null
	played_bell = false
}

::ForcePlayerGib <- function()
{
	local ragdoll = NetProps.GetPropEntity(self, "m_hRagdoll")
	if (ragdoll != null)
		NetProps.SetPropBool(ragdoll, "m_bGib", true)
}

::RemoveRagdoll <- function()
{
	local ragdoll = NetProps.GetPropEntity(self, "m_hRagdoll")
	if (ragdoll != null)
		ragdoll.Kill()
}

::OnSetupFinished <- function()
{
	for (local i = 1; i <= MaxPlayers; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		NetProps.SetPropBool(player, "m_bAllowInstantSpawn", false)

		if (!player.IsAlive() && player.GetTeam() > TEAM_SPECTATOR)
			player.ForceRespawn()
	}

	// Disables instant respawn
	for (local team = CONST.FIRST_GAME_TEAM; team < TF_TEAM_COUNT; team++)
	{
		NetProps.SetPropFloatArray(gamerules, "m_flNextRespawnWave", FLT_MAX, team)
	}

	NetProps.SetPropInt(gamerules, "m_iRoundState", GR_STATE_STALEMATE)

	for (local respawnroom; respawnroom = Entities.FindByClassname(respawnroom, "func_respawnroom");)
	{
		respawnroom.Destroy()
	}

	EmitSoundEx({ sound_name = SND_ROUND_START[RandomInt(0, SND_ROUND_START.len() - 1)], channel = CHAN_VOICE2, filter_type = RECIPIENT_FILTER_TEAM, filter_param = CONST.TEAM_PROPS })

	// Players may have left before the round even started
	CheckTeamPlayerCount()
}

::OnRoundFinished <- function()
{
	// Timer end always means the hiders won!
	SetWinningTeam(CONST.TEAM_PROPS)
}

::GetNumPlayers <- function()
{
	local count = 0

	for (local i = 1; i <= MaxPlayers; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (player.GetTeam() <= TEAM_SPECTATOR)
			continue

		count++
	}

	return count
}

::CheckTeamPlayerCount <- function()
{
	if (GetRoundState() == GR_STATE_TEAM_WIN || GetRoundState() == GR_STATE_GAME_OVER)
		return

	local team_player_counts = {}
	local all_dead = true

	for (local team = CONST.FIRST_GAME_TEAM; team < TF_TEAM_COUNT; team++)
	{
		team_player_counts[team] <- GetAlivePlayerCountForTeam(team)
		
		if (team_player_counts[team] > 0)
			all_dead = false
	}

	if (all_dead)
	{
		SetWinningTeam(TEAM_UNASSIGNED)
		return
	}

	foreach(team, count in team_player_counts)
	{
		if (count > 0)
			continue
		
		local opposing_team = GetOpposingTeam(team)
		if (opposing_team == null)
			continue
		
		SetWinningTeam(opposing_team)
		return
	}
}

::WorldThink <- function()
{
	for (local i = props.len() - 1; i >= 0; i--)
	{
		if (!props[i].IsValid())
			props.remove(i)
	}

	for (local rune; rune = Entities.FindByClassname(rune, "item_powerup_rune");)
	{
		rune.Kill()
	}

	if (IsNoSelfDamageTime())
		return
	
	for (local i = projectiles.len() - 1; i >= 0; i--)
	{
		local projectile = projectiles[i]

		if (projectile.entity.IsValid())
		{
			projectile.origin = projectile.entity.GetOrigin()

			// Explosive projectiles will remove themselves on contact with the world,
			// others will delay their removal after impact and set their movetype to MOVETYPE_NONE
			if (projectile.entity.GetMoveType() != MOVETYPE_NONE)
			{
				// CTFGrenadePipebombProjectile uses 'm_bTouched' to determine if it hit a surface
				if (!NetProps.HasProp(projectile.entity, "m_bTouched") || !NetProps.GetPropBool(projectile.entity, "m_bTouched"))
					continue
			}
		}
		
		if (projectile.classname in PROJECTILE_CLASSNAME_TO_DAMAGE && projectile.owner != null)
		{
			projectile.owner.TakeDamageEx(projectile.entity, worldspawn, null, Vector(), projectile.origin, PROJECTILE_CLASSNAME_TO_DAMAGE[projectile.classname] * PH_HUNTER_DAMAGE_MULTIPLIER, DMG_GENERIC | DMG_PREVENT_PHYSICS_FORCE)
		}
		else
		{
			printf("You forgot to specify projectile damage for %s!\n", projectile.classname)
		}

		projectiles.remove(i)
	}

	for (local projectile; projectile = Entities.FindByClassname(projectile, "tf_projectile_*");)
	{
		// Use unused EFlag to only process projectiles once
		if (projectile.GetTeam() != CONST.TEAM_HUNTERS || projectile.IsEFlagSet(EFL_NO_ROTORWASH_PUSH))
			continue
		
		projectile.SetEFlags(EFL_NO_ROTORWASH_PUSH)

		// Exclude certain weapons from self-damage
		local launcher = NetProps.GetPropEntity(projectile, "m_hLauncher")
		if (launcher != null && (GetItemDefIndex(launcher) == TF_DEFINDEX_ROCKET_JUMPER || GetItemDefIndex(launcher) == TF_DEFINDEX_STICKY_JUMPER))
			continue

		projectiles.push({ entity = projectile, owner = GetProjectileOwner(projectile), classname = projectile.GetClassname(), origin = projectile.GetOrigin() })
	}

	for (local flamethrower; flamethrower = Entities.FindByClassname(flamethrower, "tf_weapon_flamethrower");)
	{
		if (flamethrower.GetScriptThinkFunc() == "FlameThrowerThink")
			continue
		
		AddThinkToEnt(flamethrower, "FlameThrowerThink")
	}

	for (local minigun; minigun = Entities.FindByClassname(minigun, "tf_weapon_minigun");)
	{
		if (minigun.GetScriptThinkFunc() == "MinigunThink")
			continue
		
		local def_index = GetItemDefIndex(minigun)
		if (def_index != TF_DEFINDEX_HUO_LONG_HEATER && def_index != TF_DEFINDEX_HUO_LONG_HEATER_GENUINE)
			continue
		
		AddThinkToEnt(minigun, "MinigunThink")
	}

	return -1
}

::PlayerThink <- function()
{
	if (IsInWaitingForPlayers())
		return
	
	if (self.GetTeam() == CONST.TEAM_PROPS)
		return ToPHPlayer(self).PropThink()
	
	return -1
}

::FlameThrowerThink <- function()
{
	if (IsNoSelfDamageTime())
		return -1

	if (NetProps.GetPropInt(self, "m_iWeaponState") == FT_STATE_FIRING)
	{
		local owner = self.GetOwner()
		if (owner != null && owner.IsPlayer())
		{
			owner.TakeDamageEx(self, worldspawn, null, Vector(), owner.GetOrigin(), 1.0, DMG_BURN | DMG_PREVENT_PHYSICS_FORCE)
		}
	}

	return -1
}

::MinigunThink <- function()
{
	if (IsNoSelfDamageTime())
		return -1
	
	if (NetProps.GetPropInt(self, "m_iWeaponState") > AC_STATE_STARTFIRING)
	{
		local owner = self.GetOwner()
		if (owner != null && owner.IsPlayer())
		{
			local trigger = SpawnEntityFromTable("trigger_ignite"
			{
				burn_duration = 8,
				damage_percent_per_second = (5 / owner.GetMaxHealth()) * 100,
				spawnflags = SF_TRIGGER_ALLOW_CLIENTS
			})
			trigger.ForcePurgeStrings()
			EntFireByHandle(trigger, "StartTouch", "!activator", -1, owner, owner)
			EntFireByHandle(trigger, "Kill", null, -1, null, null)
		}
	}

	return 0.5
}

::SpellbookThink <- function()
{
	// Keep this spellbook around until it is no longer thinking
	if (self.IsEFlagSet(EFL_NO_THINK_FUNCTION))
		self.Destroy()
	
	return -1
}

::FadeOutThink <- function()
{
	if (!self.IsValid())
		return

	// Is asleep or reached its maximum lifetime?
	if (self.GetCollisionGroup() != COLLISION_GROUP_DEBRIS && self.GetScriptScope().fade_start_time > Time())
		return

	self.KeyValueFromInt("rendermode", kRenderTransTexture)

	local alpha = (NetProps.GetPropInt(self, "m_clrRender") >> 24) & 0xFF
	local speed = Max(1, 256 * FrameTime())

	alpha = ApproachValue(0, alpha, speed)
	self.KeyValueFromInt("renderamt", alpha)

	if (alpha == 0)
		self.Destroy()
	
	return -1
}

::AnimThink <- function()
{
	if (self.IsSequenceFinished())
		self.ResetSequence(self.GetSequence())

	self.StudioFrameAdvance()

	return -1
}

::CreatePropRagdoll <- function(target, attacker)
{
	local model = target.GetModelName()
	local origin = target.GetOrigin()
	local angles = target.GetAbsAngles()

	local config = model in configs ? configs[model] : null
	if (config != null)
	{
		if (config.offset != null)
			origin += config.offset
			
		if (config.rotation != null)
			angles = config.rotation
	}

	local ragdoll = SpawnEntityFromTable("prop_physics_override",
	{
		targetname = PH_RAGDOLL_PROP_TARGETNAME,
		model = model,
		origin = origin,
		angles = angles,
		skin = target.GetEffectiveSkin(),
		overridescript = "mass,1000"
	})
	ragdoll.SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	ragdoll.ForcePurgeStrings()

	if (attacker != null)
	{
		local dir = target.GetOrigin() - attacker.EyePosition()
		dir.Norm()
		ragdoll.SetPhysVelocity(dir * 800.0)
	}

	ragdoll.ValidateScriptScope()
	ragdoll.GetScriptScope().fade_start_time <- Time() + 10.0

	AddThinkToEnt(ragdoll, "FadeOutThink")
}

::RagdollDisguisableEntitiesRecursively <- function(entity, attacker)
{
	if (entity.IsValidForDisguise() && entity.IsDestructible())
	{
		if (entity.GetModelName() in breakable_models)
			EntFireByHandle(entity, "Break", null, -1, null, null)
		else
			CreatePropRagdoll(entity, attacker)
	}

	for (local child = entity.FirstMoveChild(); child != null; child = child.NextMovePeer())
	{
		RagdollDisguisableEntitiesRecursively(child, attacker)
	}
}

::ToggleSolidFlagsForTrigger <- function(classname, add)
{
	for (local trigger; trigger = Entities.FindByClassname(trigger, classname);)
	{
		if (add)
			trigger.AddSolidFlags(FSOLID_NOT_SOLID)
		else
			trigger.RemoveSolidFlags(FSOLID_NOT_SOLID)
	}
}

::CreateProgressBar <- function(progress, parts)
{
	local filled = floor(progress * parts)
	local empty = parts - filled

	local message = ""
	message += RepeatString("▰", filled)
	message += RepeatString("▱", empty)
	return message
}

::GetOpposingTeam <- function(team)
{
	if (team == CONST.TEAM_PROPS)
		return CONST.TEAM_HUNTERS
	else if (team == CONST.TEAM_HUNTERS)
		return CONST.TEAM_PROPS

	return null
}

::GetProjectileOwner <- function(projectile)
{
	local owner = projectile.GetOwner()
	if (owner != null && owner.IsPlayer())
		return owner
	
	local launcher = NetProps.GetPropEntity(projectile, "m_hLauncher")
	if (launcher != null)
	{
		owner = launcher.GetOwner()
		if (owner != null)
			return owner
	}

	return null
}

::StunPlayer <- function(player, duration)
{
	local trigger = SpawnEntityFromTable("trigger_stun",
	{
		stun_type = 1,
		stun_effects = true,
		stun_duration = duration,
		spawnflags = SF_TRIGGER_ALLOW_CLIENTS,
		startdisabled = false
	})
	EntFireByHandle(trigger, "EndTouch", null, -1, player, player)
	EntFireByHandle(trigger, "Kill", null, -1, null, null)
}

::IsNoSelfDamageTime <- function()
{
	return IsInWaitingForPlayers() || InSetup() || GetRoundState() == GR_STATE_TEAM_WIN
}

::CollectValidProps <- function()
{
	props.clear()

	for (local entity = Entities.First(); entity != null; entity = Entities.Next(entity))
	{
		if (!entity.IsValidForDisguise())
			continue

		// Some entities such as items are valid for disguise but we don't consider them as valid "props"
		if (!startswith(entity.GetClassname(), "prop_"))
			continue

		local parent = NetProps.GetPropEntity(entity, "m_hMoveParent")
		if (parent != null && parent.GetClassname() in PERSIST_PARENT_CLASSNAMES)
			continue

		if (startswith(entity.GetName(), PH_PROP_PERSIST_TARGETNAME))
			continue
		
		props.push(entity)
	}
}

::IsValidPropClassname <- function(classname)
{
	return startswith(classname, "prop_") || startswith(classname, "obj_") || startswith(classname, "item_")
}

::SetGamemodeConvars <- function()
{
	Convars.SetValue("tf_weapon_criticals", false)
	Convars.SetValue("mp_disable_respawn_times", true)
	Convars.SetValue("mp_show_voice_icons", false)
	Convars.SetValue("mp_autoteambalance", false)
	Convars.SetValue("mp_scrambleteams_auto", false)
	Convars.SetValue("mp_forceautoteam", true)
	Convars.SetValue("mp_forcecamera", true)
	Convars.SetValue("sv_gravity", 500)
}

::CreateMapEntities <- function()
{
	game_text = SpawnEntityFromTable("game_text",
	{
		color = Vector(255, 255, 255),
		holdtime = FLT_MAX,
		fadein = 0,
		fadeout = 0
	})
	game_text.ValidateScriptScope()
	local scope = game_text.GetScriptScope()
	scope.queue <- []
	scope.InputDisplay <- InputDisplay
	scope.inputdisplay <- InputDisplay

	env_hudhint = SpawnEntityFromTable("env_hudhint", { message = "%+attack% DISGUISE %+attack2% LOCK ROTATION %+use_action_slot_item% USE ABILITY %+reload% TOGGLE CAMERA" })

	SpawnEntityFromTable("path_track", { targetname = PH_DUMMY_PATH_TRACK_TARGETNAME })
}

::GetAlivePlayerCountForTeam <- function(team)
{
	local count = 0

	for (local i = 1; i <= MaxPlayers; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		if (!player.IsAlive())
			continue

		if (player.GetTeam() != team)
			continue
		
		count++
	}

	return count
}

::InSetup <- function()
{
	return NetProps.GetPropBool(gamerules, "m_bInSetup")
}

::SetWinningTeam <- function(team, force_map_reset = true, switch_teams = true)
{
	local win = SpawnEntityFromTable("game_round_win", { teamnum = team, force_map_reset = force_map_reset, switch_teams = switch_teams })
	EntFireByHandle(win, "RoundWin", null, -1, null, null)
	EntFireByHandle(win, "Kill", null, -1, null, null)
}

::InputDisplay <- function()
{
	local params = queue.remove(0)
	self.KeyValueFromString("message", params.message)
	self.KeyValueFromInt("channel", params.channel)
	self.KeyValueFromFloat("x", params.x)
	self.KeyValueFromFloat("y", params.y)
	return true
}

::GetItemDefIndex <- function(item)
{
	return NetProps.GetPropInt(item, "m_AttributeManager.m_Item.m_iItemDefinitionIndex")
}

::ToPHPlayer <- function(player)
{
	return player.GetScriptScope().player
}

::RecursiveRemoveChildrenFromArray <- function(entity, arr)
{
	for (local child = entity.FirstMoveChild(); child != null; child = child.NextMovePeer())
	{
		local i = arr.find(child)
		if (i != null)
			arr.remove(i)
		
		RecursiveRemoveChildrenFromArray(child, arr)
	}
}

::ApproachValue <- function(target, value, speed)
{
	local delta = target - value

	if (delta > speed)
		value += speed
	else if (delta < -speed)
		value -= speed
	else
		value = target

	return value
}

::Min <- function(a, b)
{
	return (a <= b) ? a : b
}

::Max <- function(a, b)
{
	return (a >= b) ? a : b
}

::Clamp <- function(val, min, max)
{
	return Min(Max(val, min), max)
}

::RepeatString <- function(string, num)
{
	local result = ""
	for (local i = 0; i < num; i++)
	{
		result += string
	}
	return result
}

::CBaseEntity_IsAlive <- function()
{
	return NetProps.GetPropInt(this, "m_lifeState") == LIFE_ALIVE
}

::CBaseEntity_GetEffectiveSkin <- function()
{
	return NetProps.HasProp(this, "m_bForcedSkin") && NetProps.GetPropBool(this, "m_bForcedSkin") ? NetProps.GetPropInt(this, "m_nForcedSkin") : GetSkin()
}

::CBaseEntity_ForcePurgeStrings <- function()
{
	NetProps.SetPropBool(this, "m_bForcePurgeFixedupStrings", true)
}

::CBaseEntity_AddEffects <- function(effects)
{
	NetProps.SetPropInt(this, "m_fEffects", NetProps.GetPropInt(this, "m_fEffects") | effects)
}

::CBaseEntity_IsValidForDisguise <- function()
{
	return this != worldspawn
		&& IsValidPropClassname(GetClassname())
		&& !startswith(GetModelName(), "*")
		&& GetName() != PH_PROP_NODISGUISE_TARGETNAME
		&& GetSolid() != SOLID_NONE
}

::CBaseEntity_IsDestructible <- function()
{
	return startswith(GetClassname(), "prop_") && !startswith(GetName(), PH_PROP_PERSIST_TARGETNAME)
}

::CBaseEntity_IsLockedProp <- function()
{
	return GetClassname() == PH_FAKE_PROP_CLASSNAME && GetName() == PH_LOCKED_PROP_TARGETNAME
}

::CBaseEntity_IsDecoy <- function()
{
	return GetClassname() == PH_FAKE_PROP_CLASSNAME && GetName() == PH_DECOY_PROP_TARGETNAME
}

local entity_classes = []
foreach (key, value in getroottable())
{
	if (typeof(value) == "class" && "AddEFlags" in value)
		entity_classes.append(value)
}

foreach (key, value in this)
{
	if (typeof(value) == "function" && startswith(key, "CBaseEntity_"))
	{
		local func_name = key.slice(12)
		foreach (entity_class in entity_classes)
			entity_class[func_name] <- value
		delete this[key]
	}
}