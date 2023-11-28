if ("breakable_models" in ROOT)
	return

::models_to_test_arr <- {}
::models_to_test_tbl <- []
::breakable_models <- {}

::breakable_manager <- SpawnEntityFromTable("move_rope", {})
::breakable_current_index <- -1
::breakable_current_model <- null

::BuildBreakablePropList <- function()
{
	if (!breakable_manager.IsValid() || breakable_manager.GetScriptThinkFunc() == "BreakableManagerThink")
		return

	models_to_test_arr.clear()
	models_to_test_tbl.clear()

	for (local entity = Entities.First(); entity != null; entity = Entities.Next(entity))
	{
		if (!entity.IsValidForDisguise())
			continue

		local model = entity.GetModelName()
		if (model in models_to_test_arr)
			continue

		models_to_test_arr[model] <- true
		models_to_test_tbl.push(model)
	}

	AddThinkToEnt(breakable_manager, "BreakableManagerThink")
}

::BreakableManagerThink <- function()
{
	if (++breakable_current_index >= models_to_test_tbl.len())
	{
		printf("=== %d Breakable Props ===\n", breakable_models.len())
		foreach (model, v in breakable_models)
			printf("\t%s\n", model)

		self.Destroy()
		return
	}

	local model = models_to_test_tbl[breakable_current_index]

	local breakable = SpawnEntityFromTable("physics_cannister",
	{
		origin = Vector(16383, 16383, 16383),
		model = "models/props_farm/wooden_barrel.mdl" // model needs physics or it will crash
	})
	breakable.ForcePurgeStrings()
	NetProps.SetPropInt(breakable, "m_nModelIndex", GetModelIndex(model))

	breakable_current_model = model
	EntFire("prop_physics", "AddOutput", "classname _prop_physics", -1)
	EntFireByHandle(breakable, "Explode", null, -1, null, null)
	EntFire("prop_physics", "CallScriptFunction", "CheckBreakablePropGib", -1)
	EntFire("_prop_physics", "AddOutput", "classname prop_physics", -1)
}

::CheckBreakablePropGib <- function()
{
	if (!(breakable_current_model in breakable_models))
		breakable_models[breakable_current_model] <- true
	
	self.Destroy()
}