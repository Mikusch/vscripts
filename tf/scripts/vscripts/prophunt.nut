/**
 * Copyright © Mikusch, All rights reserved.
 * 
 * https://steamcommunity.com/profiles/76561198071478507
 */

const PH_VERSION = "1.4.1"

::CONST <- getconsttable()
CONST.setdelegate({ _newslot = @(k, v) compilestring("const " + k + "=" + (typeof(v) == "string" ? ("\"" + v + "\"") : v))() })

::ROOT <- getroottable()
if (!("ConstantNamingConvention" in ROOT))
{
	foreach (a, b in Constants)
		foreach (k, v in b)
			if (v == null)
				ROOT[k] <- 0
			else
				ROOT[k] <- v
}

if (!("PropHuntLoaded" in ROOT))
{
	if (developer() == 0)
		PropHuntLoaded <- true

	IncludeScript("prophunt/const", ROOT)
	IncludeScript("prophunt/main", ROOT)
	IncludeScript("prophunt/breakable_detector", ROOT)
	IncludeScript("prophunt/ability", ROOT)
	IncludeScript("prophunt/config", ROOT)
	IncludeScript("prophunt/events", ROOT)
	
	for (local i = 1; i <= MaxPlayers; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.ValidateScriptScope()
		player.GetScriptScope().player <- CPropHuntPlayer(player)
	}
}