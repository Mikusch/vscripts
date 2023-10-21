// © Mikusch
// Created for pl_spineyard, a payload map featured in Scream Fortress XV.

const DAMAGE_EVENTS_ONLY = 1
const MOBSTER_DEATH_SOUND = "Halloween.skeleton_break"

PrecacheScriptSound(MOBSTER_DEATH_SOUND)

ClearGameEventCallbacks()

function OnPostSpawn()
{
	AddThinkToEnt(self, "UpdateMobsters")
}

function UpdateMobsters()
{
	if (!("nextbots" in getroottable()))
		return
	
	// Remove any invalids
	nextbots = nextbots.filter(function(index, nextbot) {
		return nextbot != null && nextbot.IsValid()
	})

	foreach (nextbot in nextbots)
		nextbot.GetScriptScope().nextbot.Update()

	return -1
}

function OnGameEvent_npc_hurt(params)
{
	if (!("nextbots" in getroottable()))
		return
	
	local npc = EntIndexToHScript(params.entindex)
	if (nextbots.find(npc) != null && params.health - params.damageamount <= 0)
	{
		// Prevent death
		NetProps.SetPropInt(npc, "m_takedamage", DAMAGE_EVENTS_ONLY)

		// Spawn fancy gibs instead of just disappearing
		local gibs = SpawnEntityFromTable("prop_dynamic",
		{
			model = npc.GetModelName(),
			origin = npc.GetOrigin(),
			angles = npc.GetAbsAngles(),
			skin = npc.GetSkin()
		})
		EntFireByHandle(gibs, "Break", null, -1, null, null)

		local attacker_player = GetPlayerFromUserID(params.attacker_player)
		if (attacker_player != null)
		{
			SendGlobalGameEvent("halloween_skeleton_killed", { player = attacker_player })
		}

		npc.EmitSound(MOBSTER_DEATH_SOUND)

		if (IsUsingSpells())
		{
			npc.GetScriptScope().nextbot.DropSpell()
		}

		local index = nextbots.find(npc)
		if (index != null)
			nextbots.remove(index)
		
		// Actually remove NPC
		npc.Kill()
	}
}

// Round restart
function OnGameEvent_scorestats_accumulated_update(params)
{
	if (!("nextbots" in getroottable()))
		return
	
	nextbots.clear()
}

function OnScriptHook_OnTakeDamage(params)
{
	if (!("nextbots" in getroottable()))
		return;
	
	local victim = params.const_entity
	if (nextbots.find(victim) != null)
	{
		// Avoid miniguns and sentry guns shredding us!
		if (params.weapon != null && params.weapon.GetClassname() == "tf_weapon_minigun")
			params.damage *= 0.6
		else if (params.inflictor != null && params.inflictor.GetClassname() == "obj_sentrygun")
			params.damage *= 0.5
	}
}

__CollectGameEventCallbacks(this)