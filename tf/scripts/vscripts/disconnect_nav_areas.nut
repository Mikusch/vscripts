// © Mikusch
// Created for pl_spineyard, a payload map featured in Scream Fortress XV. 

const FLT_MAX = 0x7F7FFFFF
const STEP_HEIGHT = 18

DebugDrawClear()

CTFNavArea.ComputePortal <- function(to, dir)
{
	local center = Vector()
	local nwCorner = GetCorner(Constants.ENavCornerType.NORTH_WEST)
	local seCorner = GetCorner(Constants.ENavCornerType.SOUTH_EAST)
	local to_nwCorner = to.GetCorner(Constants.ENavCornerType.NORTH_WEST)
	local to_seCorner = to.GetCorner(Constants.ENavCornerType.SOUTH_EAST)

	if (dir == Constants.ENavDirType.NORTH || dir == Constants.ENavDirType.SOUTH)
	{
		if (dir == Constants.ENavDirType.NORTH)
			center.y = nwCorner.y
		else
			center.y = seCorner.y

		local left = (nwCorner.x > to_nwCorner.x) ? nwCorner.x : to_nwCorner.x
		local right = (seCorner.x < to_seCorner.x) ? seCorner.x : to_seCorner.x

		if (left < nwCorner.x)
			left = nwCorner.x
		else if (left > seCorner.x)
			left = seCorner.x

		if (right < nwCorner.x)
			right = nwCorner.x
		else if (right > seCorner.x)
			right = seCorner.x

		center.x = (left + right) * 0.5
	}
	else
	{
		if (dir == Constants.ENavDirType.WEST)
			center.x = nwCorner.x
		else
			center.x = seCorner.x

		local top = (nwCorner.y > to_nwCorner.y) ? nwCorner.y : to_nwCorner.y
		local bottom = (seCorner.y < to_seCorner.y) ? seCorner.y : to_seCorner.y

		if (top < nwCorner.y)
			top = nwCorner.y
		else if (top > seCorner.y)
			top = seCorner.y

		if (bottom < nwCorner.y)
			bottom = nwCorner.y
		else if (bottom > seCorner.y)
			bottom = seCorner.y

		center.y = (top + bottom) * 0.5
	}

	center.z = GetZ(center)
	return center
}

CTFNavArea.GetClosestPointOnArea <- function(pos)
{
	local close = Vector()
	local nwCorner = GetCorner(Constants.ENavCornerType.NORTH_WEST)
	local seCorner = GetCorner(Constants.ENavCornerType.SOUTH_EAST)
	close.x = (pos.x - nwCorner.x >= 0) ? pos.x : nwCorner.x
	close.x = (close.x - seCorner.x >= 0) ? seCorner.x : close.x
	close.y = (pos.y - nwCorner.y >= 0) ? pos.y : nwCorner.y
	close.y = (close.y - seCorner.y >= 0) ? seCorner.y : close.y
	close.z = GetZ(close)
	return close
}

function DisconnectAreas()
{
	local areas = {}
	NavMesh.GetAllAreas(areas)

	foreach (i, area in areas)
	{
		local center = area.GetCenter()
		for (local dir = 0; dir < Constants.ENavDirType.NUM_DIRECTIONS; dir++)
		{
			local adjacentAreas = {}
			area.GetAdjacentAreas(dir, adjacentAreas)

			foreach (j, adjacentArea in adjacentAreas)
			{
				local pos = area.ComputePortal(adjacentArea, dir)
				local from = pos + Vector()
				local to = pos + Vector()
				from.z = area.GetZ(from)
				to.z = adjacentArea.GetZ(to)

				to = adjacentArea.GetClosestPointOnArea(to)

				if ((to.z - from.z) > STEP_HEIGHT)
				{
					area.DebugDrawFilled(0, 255, 0, 32, 60, true, 0)
					adjacentArea.DebugDrawFilled(255, 0, 0, 32, 60, true, 0)
					DebugDrawLine(from, to, 255, 255, 255, true, 60)

					area.Disconnect(adjacentArea)
					printl("Disconnected area #" + area.GetID() + " from area #" + adjacentArea.GetID())
				}
			}
		}
	}
}

newthread(DisconnectAreas.bindenv(this)).call()