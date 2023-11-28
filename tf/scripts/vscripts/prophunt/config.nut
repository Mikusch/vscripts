/**
 * Copyright © Mikusch, All rights reserved.
 * 
 * https://steamcommunity.com/profiles/76561198071478507
 */

::configs <- {}

class PropConfig
{
	constructor(health = null, offset = null, rotation = null)
	{
		this.health = health
		this.offset = offset
		this.rotation = rotation
	}

	health = null
	offset = null
	rotation = null
}

// model <- PropConfig(health, offset, rotation)
// Pass 'null' or leave property empty to use the default
configs["models/props_hydro/barricade_open.mdl"] <- PropConfig(null, Vector(95, 0 ,0), QAngle())
configs["models/props_gameplay/barbell.mdl"] <- PropConfig(null, Vector(0, 0, 8))
configs["models/props_farm/pallet001.mdl"] <- PropConfig(null, Vector(0, 0, 5))
configs["models/props_farm/metal_pile.mdl"] <- PropConfig(null, Vector(0, 0, 17))
configs["models/props_2fort/roof_metal002.mdl"] <- PropConfig(null, Vector(0, 0, 65))
configs["models/props_farm/wood_pile.mdl"] <- PropConfig(null, Vector(0, 0, 14))
configs["models/props_christmas/candydrop_large.mdl"] <- PropConfig(null, Vector(0, 0, 20))
configs["models/props_farm/gibs/wooden_barrel_break02.mdl"] <- PropConfig(null, Vector(0, 0, 30))
configs["models/props_2fort/hose001.mdl"] <- PropConfig(null, Vector(0, 0, 25))
configs["models/props_lights/lamp001.mdl"] <- PropConfig(null, Vector(0, 0, 25))
configs["models/props_spytech/wall_clock.mdl"] <- PropConfig(null, Vector(0, 0, 16))
configs["models/props_island/island_large_electrical_box.mdl"] <- PropConfig(null, Vector(0, 0, 56))
configs["models/props_mall/recompile/wall_clock_noglass.mdl"] <- PropConfig(null, Vector(0, 0, 16))
configs["models/props_trainyard/bomb_cart_red.mdl"] <- PropConfig(null, Vector(0, 0, 26))
configs["models/props_c17/cashregister01a.mdl"] <- PropConfig(null, Vector(0, 0, 12))
configs["models/props_2fort/lunchbag.mdl"] <- PropConfig(null, Vector(0, 0, 9.5))
configs["models/props_manor/vase_01.mdl"] <- PropConfig(null, Vector(0, 0, 32))
configs["models/props_powerhouse/powerhouse_blind01.mdl"] <- PropConfig(null, Vector(0, 0, 42))
configs["models/props_powerhouse/powerhouse_blind02.mdl"] <- PropConfig(null, Vector(0, 0, 42))
configs["models/props_mall/recompile/modelrocket003_size2.mdl"] <- PropConfig(null, Vector(0, 0, 25))
configs["models/props_well_xmas/workbench_table.mdl"] <- PropConfig(null, Vector(0, -32, 0), QAngle())
configs["models/props_farm/wooden_barrel.mdl"] <- PropConfig(null, Vector(0, 0, 30))
configs["models/props_gameplay/bottle001.mdl"] <- PropConfig(null, Vector(0, 0, 10))
configs["models/props_hydro/road_bumper01.mdl"] <- PropConfig(null, Vector(0, 0, 12))
configs["models/props_island/mannco_case_large.mdl"] <- PropConfig(null, Vector(0, 0, 23))
configs["models/props_island/mannco_case_small.mdl"] <- PropConfig(null, Vector(0, 0, 23))
configs["models/props_trainyard/train_billboard001_sm.mdl"] <- PropConfig(null, Vector(0, 0, 38))
configs["models/props_granary/grain_machinery_set1.mdl"] <- PropConfig(null, Vector(0, 0, 185))
configs["models/props_granary/grain_machinery_set2.mdl"] <- PropConfig(null, Vector(0, 0, 100))
configs["models/props_swamp/chainsaw.mdl"] <- PropConfig(null, Vector(0, 0, 10))
configs["models/props_atom_smash/stainlessdoor003_l.mdl"] <- PropConfig(null, Vector(0, -28, 0), QAngle(0, 90, 0))
configs["models/props_atom_smash/stainlessdoor003_r.mdl"] <- PropConfig(null, Vector(0, 28, 0), QAngle(0, 90, 0))
configs["models/props_gameplay/towel_rack.mdl"] <- PropConfig(null, Vector(0, 0, 32))
configs["models/props_spytech/vent.mdl"] <- PropConfig(null, Vector(0, 0, 12))
configs["models/props_2fort/wastebasket01.mdl"] <- PropConfig(null, Vector(0, 0, 31))
configs["models/props_2fort/corrugated_metal005.mdl"] <- PropConfig(null, Vector(0, 0, 64))
configs["models/player/items/pyro/fireman_helmet.mdl"] <- PropConfig(null, Vector(0, 0, -72))
configs["models/player/items/demo/top_hat.mdl"] <- PropConfig(null, Vector(0, 0, -72))
configs["models/player/items/engineer/cave_hat.mdl"] <- PropConfig(null, Vector(0, 0, -71))