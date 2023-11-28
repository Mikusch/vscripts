/**
 * Copyright © Mikusch, All rights reserved.
 * 
 * https://steamcommunity.com/profiles/76561198071478507
 */

ClearGameEventCallbacks()

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return
	
	// First joiners spawn in TEAM_UNASSIGNED
	if (params.team == TEAM_UNASSIGNED)
	{
		player.ValidateScriptScope()
		player.GetScriptScope().player <- CPropHuntPlayer(player)
		return
	}

	if (IsInWaitingForPlayers())
		return

	ToPHPlayer(player).OnSpawn(params)
	EntFireByHandle(player, "RunScriptCode", "ToPHPlayer(self).OnPostSpawn()", -1, null, null)
}

function OnGameEvent_post_inventory_application(params)
{
	if (IsInWaitingForPlayers())
		return

	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	if (player.GetTeam() == CONST.TEAM_PROPS)
	{
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (!startswith(wearable.GetClassname(), "tf_wearable") && wearable.GetClassname() != "tf_powerup_bottle")
				continue
			
			EntFireByHandle(wearable, "Kill", null, -1, null, null)
		}

		local size = NetProps.GetPropArraySize(player, "m_hMyWeapons")
		for (local i = 0; i < size; i++)
		{
			local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (weapon == null)
				continue
			
			EntFireByHandle(weapon, "Kill", null, -1, null, null)
		}
	}
}

function OnGameEvent_player_death(params)
{
	if (IsInWaitingForPlayers())
		return

	local victim = GetPlayerFromUserID(params.userid)
	if (victim == null)
		return

	if (params.death_flags & TF_DEATHFLAG_DEADRINGER)
		return

	local inflictor = EntIndexToHScript(params.inflictor_entindex)
	local attacker = GetPlayerFromUserID(params.attacker)
	local assister = GetPlayerFromUserID(params.assister)

	local player = ToPHPlayer(victim)
	player.ClearAbilityHUD()

	if (victim.GetTeam() == CONST.TEAM_PROPS)
	{
		player.SetPropLock(false, true)

		DispatchParticleEffect(FX_PROP_EXPLODE, victim.GetCenter(), victim.GetAbsAngles() + Vector())
		victim.EmitSound(SND_PROP_EXPLODE)

		if (attacker != null && attacker != victim)
			attacker.SetHealth(attacker.GetHealth() + victim.GetMaxHealth())

		if (assister != null)
			assister.SetHealth(assister.GetHealth() + victim.GetMaxHealth() / 2)

		if (victim.GetModelName() in breakable_models)
		{
			EntFireByHandle(victim, "CallScriptFunction", "ForcePlayerGib", -1, null, null)
		}
		else
		{
			EntFireByHandle(victim, "CallScriptFunction", "RemoveRagdoll", -1, null, null)
			CreatePropRagdoll(victim, attacker)
		}
	}
	else
	{
		if (inflictor != null && inflictor.GetClassname() == PH_PROP_SELF_DESTRUCT_CLASSNAME && inflictor.GetName() == PH_PROP_SELF_DESTRUCT_TARGETNAME)
		{
			local owner = inflictor.GetOwner()
			if (owner != null && owner == attacker)
				ToPHPlayer(owner).has_killed_hunter = true
		}
	}

	if (InSetup())
		return
	
	EntFireByHandle(worldspawn, "CallScriptFunction", "CheckTeamPlayerCount", -1, null, null)
}

function OnGameEvent_player_hurt(params)
{
	local victim = GetPlayerFromUserID("custom" in params && params.custom == TF_DMG_CUSTOM_RUNE_REFLECT ? params.attacker : params.userid)
	if (victim == null)
		return

	local player = ToPHPlayer(victim)
	if (player.ability != null && player.ability instanceof CReflect && player.ability.IsActive())
		victim.RemoveCond(TF_COND_RUNE_REFLECT)
}

function OnGameEvent_teamplay_round_start(params)
{
	SetGamemodeConvars()
	CreateMapEntities()
	BuildBreakablePropList()

	NetProps.SetPropInt(gamerules, "m_nGameType", 0)

	if (IsInWaitingForPlayers())
	{
		CollectValidProps()

		while (props.len() > 0)
		{
			local prop = props.pop()
			RecursiveRemoveChildrenFromArray(prop, props)
			prop.Destroy()
		}

		return
	}

	// Enables instant respawn
	for (local team = CONST.FIRST_GAME_TEAM; team < TF_TEAM_COUNT; team++)
	{
		NetProps.SetPropFloatArray(gamerules, "m_flNextRespawnWave", Time(), team)
	}

	local timer = Entities.FindByClassname(null, "team_round_timer")
	if (timer == null || timer.GetName().len() == 0)
	{
		printl("No named team_round_timer found! Creating fallback timer with default settings.")

		timer = SpawnEntityFromTable("team_round_timer",
		{
			targetname = PH_TIMER_DEFAULT_NAME,
			setup_length = PH_TIMER_SETUP_DEFAULT_LENGTH,
			timer_length = PH_TIMER_ROUND_DEFAULT_LENGTH,
			show_in_hud = 1,
			auto_countdown = 1,
			"OnSetupFinished#1": PH_TIMER_DEFAULT_NAME + ",CallScriptFunction,OnSetupFinished,0,-1",
			"OnFinished#1": PH_TIMER_DEFAULT_NAME + ",CallScriptFunction,OnRoundFinished,0,-1"
		})
	}
	else
	{
		EntFireByHandle(timer, "AddOutput", "OnSetupFinished " + timer.GetName() + ",CallScriptFunction,OnSetupFinished,0,-1", -1, null, null)
		EntFireByHandle(timer, "AddOutput", "OnFinished " + timer.GetName() + ",CallScriptFunction,OnRoundFinished,0,-1", -1, null, null)
	}

	Convars.SetValue("tf_stalematechangeclasstime", NetProps.GetPropInt(timer, "m_nSetupTimeLength"))

	CollectValidProps()

	local ratio = (MaxPlayers - GetNumPlayers()) / MaxPlayers
	local percentage = Max(PH_PROP_MAX_REMOVAL_PERCENTAGE * ratio, PH_PROP_MIN_REMOVAL_PERCENTAGE)

	for (local i = props.len() - 1; i >= 0; i--)
	{
		local prop = props[i]

		if (RandomFloat(0, 1) <= percentage)
		{
			props.remove(i)
			RecursiveRemoveChildrenFromArray(prop, props)
			prop.Destroy()
		}
		else if (prop.IsDestructible())
		{
			local health = Min(prop.GetBoundingMaxs().Length(), PH_PROP_MAX_HEALTH)
			prop.SetHealth(health)
			prop.SetMaxHealth(health)
			NetProps.SetPropInt(prop, "m_takedamage", DAMAGE_YES)
		}
	}
}

function OnGameEvent_player_team(params)
{
	if (IsInWaitingForPlayers() || InSetup())
		return

	if (params.disconnect)
	{
		local player = GetPlayerFromUserID(params.userid)
		if (player != null)
			ToPHPlayer(player).DestroyLockedProp()

		EntFireByHandle(worldspawn, "CallScriptFunction", "CheckTeamPlayerCount", -1, null, null)
	}
}

function OnGameEvent_teamplay_round_active(params)
{
	if (IsInWaitingForPlayers())
		return
	
	local timer = Entities.FindByClassname(null, "team_round_timer")
	if (timer != null)
		EntFireByHandle(timer, "Resume", null, -1, null, null)

	for (local i = 1; i <= MaxPlayers; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		if (player.GetTeam() != CONST.TEAM_PROPS)
			continue
		
		local ph_player = ToPHPlayer(player)
		ph_player.SetClassSpeed()
		ph_player.last_action_time = Time()
	}
}

function OnGameEvent_teamplay_round_win(params)
{
	Convars.SetValue("mp_forcecamera", false)

	for (local i = 1; i <= MaxPlayers; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		if (player.GetTeam() != CONST.TEAM_PROPS)
			continue

		NetProps.SetPropBool(player, "m_bGlowEnabled", true)

		local ph_player = ToPHPlayer(player)
		ph_player.StopDisguising()
		ph_player.SetPropLock(false)
	}

	foreach(i, prop in props)
	{
		prop.ValidateScriptScope()
		prop.GetScriptScope().fade_start_time <- Time()
		
		AddThinkToEnt(prop, "FadeOutThink")
	}
}

function OnGameEvent_npc_hurt(params)
{
	if (IsInWaitingForPlayers())
		return

	local npc = EntIndexToHScript(params.entindex)
	if (npc.IsDecoy() && params.health - params.damageamount <= 0)
	{
		NetProps.SetPropInt(npc, "m_takedamage", DAMAGE_EVENTS_ONLY)

		DispatchParticleEffect(FX_PROP_EXPLODE, npc.GetCenter(), npc.GetAbsAngles() + Vector())
		npc.EmitSound(SND_PROP_EXPLODE)

		DispatchParticleEffect(FX_DECOY_EXPLODE, npc.GetCenter(), npc.GetAbsAngles() + Vector())
		npc.EmitSound(SND_DECOY_EXPLODE)

		// Stun the foolish player that fell for it
		local attacker_player = GetPlayerFromUserID(params.attacker_player)
		if (attacker_player != null)
			StunPlayer(attacker_player, 3)

		if (npc.GetModelName() in breakable_models)
		{
			local gibs = SpawnEntityFromTable("prop_dynamic",
			{
				model = npc.GetModelName(),
				origin = npc.GetOrigin(),
				angles = npc.GetAbsAngles(),
				skin = npc.GetSkin()
			})
			gibs.ForcePurgeStrings()
			EntFireByHandle(gibs, "Break", null, -1, null, null)
		}
		else
		{
			CreatePropRagdoll(npc, attacker_player)
		}

		npc.Destroy()
	}
}

function OnGameEvent_player_say(params)
{
	if (IsInWaitingForPlayers())
		return

	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return
	
	if (player != GetListenServerHost() || !Convars.GetBool("sv_cheats"))
		return
	
	local text = strip(params.text)
	if (!startswith(text, PH_DEBUG_COMMAND))
		return
	
	local model = strip(text.slice(PH_DEBUG_COMMAND.len()))
	ToPHPlayer(player).HandleCommand_SetModel(model)
}

function OnScriptHook_OnTakeDamage(params)
{
	if (IsInWaitingForPlayers())
		return

	local entity = params.const_entity
	local inflictor = params.inflictor
	local attacker = params.attacker

	// Allow hunters to destroy disguisable props
	if (NetProps.GetPropInt(entity, "m_takedamage") == DAMAGE_YES && entity.GetHealth() - params.damage <= 0)
	{
		RagdollDisguisableEntitiesRecursively(entity, attacker)
	}

	// Knock ragdoll props around!
	if (attacker != null && entity.GetClassname() == "prop_physics" && entity.GetName() == PH_RAGDOLL_PROP_TARGETNAME)
	{
		local dir = entity.GetOrigin() - attacker.EyePosition()
		dir.Norm()

		if (params.damage_type & DMG_BLAST)
		{
			dir.z += 1.0
			dir.Norm()
		}

		entity.SetPhysVelocity(dir * 500.0)

		params.damage = 0
		params.early_out = true
		return
	}

	// Special bleed particles - only need to do this for decoy props, since locked props already pass on the damage
	if (entity.IsPlayer() && entity.GetTeam() == CONST.TEAM_PROPS || entity.IsDecoy())
	{
		DispatchParticleEffect(FX_PROP_BLEED, params.damage_position, entity.GetAbsAngles() + Vector())
	}

	if (entity.IsPlayer())
	{
		local player = ToPHPlayer(entity)
		if (player.ability != null && player.ability instanceof CReflect && player.ability.IsActive())
			entity.AddCondEx(TF_COND_RUNE_REFLECT, FrameTime(), null)
	}

	// Self-destruct bombs shouldn't launch the player
	if (inflictor != null && inflictor.GetClassname() == PH_PROP_SELF_DESTRUCT_CLASSNAME && inflictor.GetName() == PH_PROP_SELF_DESTRUCT_TARGETNAME && inflictor.GetOwner() == entity)
	{
		params.damage_type = params.damage_type | DMG_PREVENT_PHYSICS_FORCE
		return
	}

	// When damaging a locked prop, pass any damage to the owning player
	if (entity.IsLockedProp())
	{
		local owner = entity.GetOwner()
		if (owner != null && owner.IsPlayer() && ToPHPlayer(owner).locked_prop == entity)
		{
			owner.TakeDamageCustom(inflictor, attacker, params.weapon, params.damage_force, params.damage_position, params.damage, params.damage_type, params.damage_custom)
			params.damage = 0
			params.early_out = true
			return
		}
	}

	if (IsNoSelfDamageTime())
		return

	// Apply self-damage when hitting anything that is not a player or decoy
	if (!entity.IsPlayer() && !entity.IsDecoy())
	{
		// Projectiles already damage the player on deletion, don't do it again
		if (inflictor != null && startswith(inflictor.GetClassname(), "tf_projectile_"))
			return

		if (attacker != null && attacker.IsPlayer() && attacker.GetTeam() == CONST.TEAM_HUNTERS)
			attacker.TakeDamageCustom(params.weapon, entity, null, params.damage_force, params.damage_position, params.damage * PH_HUNTER_DAMAGE_MULTIPLIER, params.damage_type | DMG_PREVENT_PHYSICS_FORCE, params.damage_custom)
	}
	// Do NOT apply self-damage when hitting an enemy player with a projectile
	else if (attacker != null && attacker.IsPlayer() && attacker.GetTeam() != entity.GetTeam() && inflictor != null)
	{
		for (local i = projectiles.len() - 1; i >= 0; i--)
		{
			local projectile_entity = projectiles[i].entity

			// If we hit someone with a projectile, do not do self-damage
			if (startswith(inflictor.GetClassname(), "tf_projectile_"))
			{
				if (inflictor == projectile_entity)
				{
					projectiles.remove(i)
					break
				}
			}
			// Catch cases where the game sets inflictor as the weapon instead e.g. Sandman
			else if (NetProps.HasProp(projectile_entity, "m_hLauncher") && NetProps.GetPropEntity(projectile_entity, "m_hLauncher") == inflictor)
			{
				projectiles.remove(i)
				break
			}
		}
	}
}

__CollectGameEventCallbacks(this)