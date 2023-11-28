/**
 * Copyright © Mikusch, All rights reserved.
 * 
 * https://steamcommunity.com/profiles/76561198071478507
 */

enum ABILITY_STATE
{
	READY,
	ACTIVE,
	ON_COOLDOWN
}

class CAbility
{
	constructor(owner, name, overlay_material)
	{
		this.owner = owner
		this.name = name
		this.overlay_material = overlay_material
		this.state = ABILITY_STATE.READY
	}

	function Use()
	{
		if (state != ABILITY_STATE.READY)
			return false

		ability_start_time = Time()
		ability_end_time = duration != null ? ability_start_time + duration : null
		this.state = duration != null ? ABILITY_STATE.ACTIVE : ABILITY_STATE.ON_COOLDOWN

		return true
	}

	function Update()
	{
		UpdateOverlay()

		if (!IsOneTimeUse() && state == ABILITY_STATE.ON_COOLDOWN && GetNextAbilityUseTime() <= Time())
			this.state = ABILITY_STATE.READY

		if (state == ABILITY_STATE.ACTIVE && ability_end_time <= Time())
			ForceEnd()
	}

	function ForceEnd()
	{
		if ("OnEnd" in this)
			OnEnd()

		if ("Destroy" in this)
			Destroy()

		this.state = ABILITY_STATE.ON_COOLDOWN
	}

	function IsReady()
	{
		return state == ABILITY_STATE.READY
	}

	function IsActive()
	{
		return state == ABILITY_STATE.ACTIVE
	}

	function IsAllowedToUse()
	{
		return IsReady() && GetRoundState() != GR_STATE_PREROUND
	}

	function IsOneTimeUse()
	{
		return cooldown == null
	}

	function GetNextAbilityUseTime()
	{
		return ability_start_time + cooldown
	}

	function GetAbilityRechargePercentage()
	{
		if (IsReady())
			return 1.0

		if (IsOneTimeUse())
			return 0.0

		local percentage = 1.0 - (GetNextAbilityUseTime() - Time()) / cooldown
		return Clamp(percentage, 0.0, 1.0)
	}

	function UpdateOverlay()
	{
		if (overlay_material != null)
		{
			local overlay = overlay_material + (IsAllowedToUse() ? "_on" : "_off")
			if (owner.GetScriptOverlayMaterial() != overlay)
				owner.SetScriptOverlayMaterial(overlay)
		}
	}

	owner = null
	name = null
	overlay_material = null
	cooldown = null
	duration = null
	ability_start_time = null
	ability_end_time = null
	state = null
}

class CSpeedBoost extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "SPEED", "vgui/prophunt/ability_scout")
		this.cooldown = 30
		this.duration = 8
	}

	function Use()
	{
		if (!base.Use())
			return false

		owner.AddCond(TF_COND_SPEED_BOOST)
		return true
	}

	function OnEnd()
	{
		owner.RemoveCond(TF_COND_SPEED_BOOST)
	}
}

class CJarateBurst extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "JARATE", "vgui/prophunt/ability_sniper")
		this.cooldown = 20
	}

	function OnPostSpawn()
	{
		owner.AddCustomAttribute("applies snare effect", 0.65, -1)
	}

	function Use()
	{
		if (!base.Use())
			return false

		for (local i = 0; i < 10; i++)
		{
			local angle = 2.0 * PI * i / 10
			local jar_position = Vector(cos(angle), sin(angle), 0) 

			local jar = SpawnEntityFromTable("tf_projectile_jar", 
			{
				teamnum = owner.GetTeam(),
				origin = owner.GetCenter() + jar_position,
				angles = owner.GetAbsAngles()
			})
			jar_position.Norm()
			jar_position.z += 1.0
			jar.ApplyAbsVelocityImpulse(jar_position * 300.0)
			jar.ApplyLocalAngularVelocityImpulse(Vector(300.0, 0.0, 0.0))
			jar.SetOwner(owner)
			jar.ForcePurgeStrings()
		}

		return true
	}
}

class CBlastJump extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "JUMP", "vgui/prophunt/ability_soldier")
		this.cooldown = 30
	}

	function Use()
	{
		if (!base.Use())
			return false

		ToPHPlayer(owner).SetPropLock(false)
		ToPHPlayer(owner).CastSingleSpell(TF_SPELL_BLASTJUMP)
		return true
	}
}

class CSelfDestruct extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "EXPLODE", "vgui/prophunt/ability_demoman")
		this.cooldown = 45
		this.duration = 2
	}

	function Use()
	{
		if (!base.Use())
			return false

		owner.EmitSound(SND_ABILITY_DEMOMAN_USE)
		return true
	}

	function OnEnd()
	{
		local prev_takedamage = NetProps.GetPropInt(owner, "m_takedamage")
		NetProps.SetPropInt(owner, "m_takedamage", DAMAGE_EVENTS_ONLY)

		local player = ToPHPlayer(owner)
		player.has_killed_hunter = false

		// KABOOM!
		local bomb = SpawnEntityFromTable(PH_PROP_SELF_DESTRUCT_CLASSNAME,
		{
			targetname = PH_PROP_SELF_DESTRUCT_TARGETNAME,
			damage = 150.0,
			sound = "MVM.SentryBusterExplode",
			explode_particle = "fluidSmokeExpl_ring_mvm",
			origin = owner.GetOrigin(),
			teamnum = owner.GetTeam(),
			radius = 300.0
		})
		bomb.SetOwner(owner)
		bomb.ForcePurgeStrings()
		bomb.TakeDamage(1.0, DMG_GENERIC, owner)

		NetProps.SetPropInt(owner, "m_takedamage", prev_takedamage)

		if (!player.has_killed_hunter)
			owner.TakeDamageCustom(owner, owner, null, Vector(), owner.GetOrigin(), owner.GetHealth(), DMG_PREVENT_PHYSICS_FORCE | DMG_BLAST | DMG_ALWAYSGIB, TF_DMG_CUSTOM_SUICIDE)
	}
}

class COverheal extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "OVERHEAL", "vgui/prophunt/ability_medic")
		this.cooldown = 45
	}

	function Use()
	{
		if (!base.Use())
			return false

		ToPHPlayer(owner).CastSingleSpell(TF_SPELL_OVERHEAL)
		return true
	}
}


class CReflect extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "REFLECT", "vgui/prophunt/ability_heavyweapons")
		this.cooldown = 30
		this.duration = 5
	}

	function Use()
	{
		if (!base.Use())
			return false

		owner.EmitSound(SND_ABILITY_HEAVYWEAPONS_USE)
		owner.EmitSound(SND_ABILITY_HEAVYWEAPONS_LOOP)

		particle = SpawnEntityFromTable("trigger_particle",
		{
			particle_name = owner.GetTeam() == TF_TEAM_RED ? "electrocuted_red" : "electrocuted_blue",
			attachment_type = PATTACH_ABSORIGIN_FOLLOW,
			spawnflags = SF_TRIGGER_ALLOW_CLIENTS
		})
		particle.ForcePurgeStrings()
		EntFireByHandle(particle, "StartTouch", "!activator", -1, owner, owner)

		return true
	}

	function Destroy()
	{
		owner.StopSound(SND_ABILITY_HEAVYWEAPONS_LOOP)

		if (particle != null && particle.IsValid())
			particle.Destroy()
	}

	particle = null
}

class CGasBlast extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "GAS", "vgui/prophunt/ability_pyro")
		this.cooldown = 20
	}

	function Use()
	{
		if (!base.Use())
			return false

		local jar = SpawnEntityFromTable("tf_projectile_jar_gas", 
		{
			teamnum = owner.GetTeam(),
			origin = owner.GetCenter(),
			angles = owner.GetAbsAngles()
		})
		jar.SetOwner(owner)
		jar.ForcePurgeStrings()

		return true
	}

	function Update()
	{
		base.Update()

		foreach(cond in DEBUFF_CONDITIONS)
		{
			owner.RemoveCond(cond)
		}
	}
}

class CStealth extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "STEALTH", "vgui/prophunt/ability_spy")
		this.cooldown = 30
		this.duration = 8
	}

	function Use()
	{
		if (!base.Use())
			return false

		owner.EmitSound(SND_ABILITY_SPY_START)
		owner.AddCond(TF_COND_STEALTHED_USER_BUFF_FADING)

		owner.KeyValueFromInt("rendermode", kRenderTransAlpha)
		owner.KeyValueFromInt("renderamt", 64)

		return true
	}

	function OnEnd()
	{
		owner.RemoveCond(TF_COND_STEALTHED_USER_BUFF_FADING)
		owner.EmitSound("Player.Spy_UnCloak")
	}

	function Destroy()
	{
		owner.KeyValueFromInt("rendermode", kRenderNormal)
		owner.KeyValueFromInt("renderamt", 255)
	}
}

class CDecoyProp extends CAbility
{
	constructor(owner)
	{
		base.constructor(owner, "DECOY", "vgui/prophunt/ability_engineer")
		this.cooldown = 45
	}

	function IsAllowedToUse()
	{
		return base.IsAllowedToUse() && ToPHPlayer(owner).CanSpawnFakeProp()
	}

	function Use()
	{
		if (!base.Use())
			return false

		local decoy = ToPHPlayer(owner).CreateFakeProp(PH_DECOY_PROP_TARGETNAME)
		EmitSoundEx({ sound_name = SND_ABILITY_ENGINEER_USE, entity = decoy })
		
		return true
	}

	function Destroy()
	{
		for (local prop; prop = Entities.FindByName(prop, PH_DECOY_PROP_TARGETNAME);)
		{
			if (prop.GetOwner() != owner)
				continue
			
			prop.Destroy()
		}
	}
}