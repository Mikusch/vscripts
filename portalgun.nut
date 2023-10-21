// © Mikusch
// Created for the TF2Maps 72hr Jam 2023.

::MASK_SOLID_BRUSHONLY <- (Constants.FContents.CONTENTS_SOLID|Constants.FContents.CONTENTS_MOVEABLE|Constants.FContents.CONTENTS_WINDOW|Constants.FContents.CONTENTS_GRATE)

const PORTAL_BLUE = "blue"
const PORTAL_ORANGE = "orange"

const PORTAL_SOUND_SUCCESS = "Weapon_ShootingStar.Single"
PrecacheScriptSound(PORTAL_SOUND_SUCCESS)
const PORTAL_SOUND_FAILED = "Weapon_SniperRailgun.NonScoped"
PrecacheScriptSound(PORTAL_SOUND_FAILED)
const PORTAL_TELEPORT_SOUND = "Halloween.spell_teleport"
PrecacheScriptSound(PORTAL_TELEPORT_SOUND)
const PORTAL_MODEL = "models/effects/portalrift.mdl"
PrecacheModel(PORTAL_MODEL)

const RAD2DEG = 57.295779513

::MaxPlayers <- MaxClients().tointeger()
::PlayerManager <- Entities.FindByClassname(null, "tf_player_manager")

ClearGameEventCallbacks()

function PlayerThink()
{
	if (NetProps.GetPropInt(self, "m_lifeState") != 0)
		return -1

	local buttons = NetProps.GetPropInt(self, "m_nButtons")
	
	if (buttons & Constants.FButtons.IN_ATTACK || buttons & Constants.FButtons.IN_ATTACK2)
	{
		if (!self.GetScriptScope().held)
		{
			self.GetScriptScope().held = true

			if (buttons & Constants.FButtons.IN_ATTACK)
				ShootPortal(self, PORTAL_BLUE)
			else if (buttons & Constants.FButtons.IN_ATTACK2)
				ShootPortal(self, PORTAL_ORANGE)
		}
	}
	else
	{
		self.GetScriptScope().held = false
	}

	return -1
}

function PortalThink()
{
	if (self == null || !self.IsValid())
		return -1

	local entity = null
	while (entity = Entities.FindInSphere(entity, self.GetCenter(), 50))
	{
		if (entity == self)
			continue
		
		// We support only players right now
		if (!entity.IsPlayer())
			continue

		local other_portal = self.GetScriptScope().other_portal
        if (other_portal == null || !other_portal.IsValid())
            continue

        if (entity.GetScriptScope().last_teleport_time != null && Time() - entity.GetScriptScope().last_teleport_time < 0.5)
            continue

		local exit = other_portal.GetScriptScope().exit_point
		if (exit != null && exit.IsValid())
        {
			entity.SetAbsOrigin(exit.GetOrigin())
       	 	entity.SetAbsVelocity(exit.GetForwardVector() * 100)
			entity.SnapEyeAngles(exit.GetAbsAngles())
			
			entity.GetScriptScope().last_teleport_time = Time()

			other_portal.EmitSound(PORTAL_TELEPORT_SOUND)
		}
	}

	return -1
}

function ShootPortal(player, portal_type)
{
	local trace =
	{
		start = player.EyePosition(),
		end = player.EyePosition() + (player.EyeAngles().Forward() * 32768.0),
		ignore = player,
		mask = MASK_SOLID_BRUSHONLY
	}

	if (TraceLineEx(trace) && trace.hit)
	{
		// Only allow on flat surfaces
		if (!IsValidPortalNormal(trace.plane_normal.x) || !IsValidPortalNormal(trace.plane_normal.y) || !IsValidPortalNormal(trace.plane_normal.z))
		{
			player.EmitSound(PORTAL_SOUND_FAILED)
			return
		}

		player.EmitSound(PORTAL_SOUND_SUCCESS)

		local portal_name = "portal_" + portal_type

		// Destroy old portal if it exists
		local old_portal = player.GetScriptScope()[portal_name]
		if (old_portal != null && old_portal.IsValid())
			old_portal.Kill()

		local portal_angles = VectorAngles(trace.plane_normal)
		
        local portal = SpawnEntityFromTable("prop_dynamic",
        {
            targetname = portal_name,
            model = PORTAL_MODEL,
            origin = trace.endpos + trace.plane_normal,
            modelscale = 0.075,
            angles = portal_angles + QAngle(-90, 0, 0),
            disableshadows = true
        })

		local exit_point = SpawnEntityFromTable("info_target",
		{
			origin = trace.endpos + (trace.plane_normal * player.GetPlayerMaxs().z),
			angles = portal_angles
		})
		EntFireByHandle(exit_point, "SetParent", "!activator", -1, portal, null)

		portal.ValidateScriptScope()
		portal.GetScriptScope().exit_point <- exit_point
		portal.GetScriptScope().other_portal <- null
		portal.GetScriptScope().camera <- null

		local particle = SpawnEntityFromTable("info_particle_system",
		{
			effect_name = "eyeboss_doorway_vortex",
			start_active = 1,
			origin = portal.GetOrigin(),
			angles = portal_angles
		})
		EntFireByHandle(particle, "SetParent", "!activator", -1, portal, null)

        player.GetScriptScope()[portal_name] = portal
		AddThinkToEnt(portal, "PortalThink")

		local other_portal_name
		if (portal_type == PORTAL_BLUE)
			other_portal_name = "portal_" + PORTAL_ORANGE
		else
			other_portal_name = "portal_" + PORTAL_BLUE
		
		local other_portal = player.GetScriptScope()[other_portal_name]

		// Link the two portals
		if (other_portal != null && other_portal.IsValid())
		{
			portal.GetScriptScope().other_portal = other_portal
			other_portal.GetScriptScope().other_portal = portal
		}

		// Set up the portal camera
		if (other_portal != null && other_portal.IsValid())
		{
			CreateAndLinkCamera(portal, other_portal, portal_angles)

			// If the other portal does not have a camera yet, fix that!
			local other_camera = other_portal.GetScriptScope().camera
			if (other_camera == null || !other_camera.IsValid())
			{
				CreateAndLinkCamera(other_portal, portal, portal_angles)
			}
		}
	}
}

function CreateAndLinkCamera(source, target, angles)
{
	local camera = SpawnEntityFromTable("point_camera"
	{
		targetname = "camera_" + source.GetName(),
		origin = source.GetOrigin(),
		angles = angles,
		FOV = 90
	})

	local camera_link = SpawnEntityFromTable("info_camera_link",
	{
		target = target.GetName(),
		PointCamera = "camera_" + source.GetName()
	})

	EntFireByHandle(camera, "SetParent", "!activator", -1, source, null)
	EntFireByHandle(camera_link, "SetParent", "!activator", -1, camera, null)

	source.GetScriptScope().camera = camera
}

function IsValidPortalNormal(coord)
{
    return coord == -1 || coord == 0 || coord == 1
}

function VectorAngles(forward)
{
    local yaw, pitch
    if (forward.y == 0.0 && forward.x == 0.0)
    {
        yaw = 0.0
        if (forward.z > 0.0)
            pitch = 270.0
        else
            pitch = 90.0
    }
    else
    {
        yaw = atan2(forward.y, forward.x) * RAD2DEG
        if (yaw < 0.0)
            yaw += 360.0
        pitch = atan2(-forward.z, forward.Length2D()) * RAD2DEG
        if (pitch < 0.0)
            pitch += 360.0
    }
    return QAngle(pitch, yaw, 0.0)
}

function GetPlayerUserID(player)
{
    return NetProps.GetPropIntArray(PlayerManager, "m_iUserID", player.entindex())
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return
	
	if (params.team == Constants.ETFTeam.TEAM_UNASSIGNED)
	{
		player.ValidateScriptScope()
		player.GetScriptScope().held <- false
		player.GetScriptScope()["portal_" + PORTAL_BLUE] <- null
		player.GetScriptScope()["portal_" + PORTAL_ORANGE] <- null
		player.GetScriptScope().last_teleport_time <- 0.0
	}
}

for (local i = 1; i <= MaxPlayers; i++)
{
	local player = PlayerInstanceFromIndex(i)
	if (player == null)
		continue

	local params =
	{
		userid = GetPlayerUserID(player),
		team = Constants.ETFTeam.TEAM_UNASSIGNED
	}
	OnGameEvent_player_spawn(params)

	AddThinkToEnt(player, "PlayerThink")
}

__CollectGameEventCallbacks(this)
