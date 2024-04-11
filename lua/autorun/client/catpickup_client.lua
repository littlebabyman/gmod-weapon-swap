AddCSLuaFile()

hook.Add("PopulateToolMenu", "CATManualPickup", function()
	spawnmenu.AddToolMenuOption("Options", "Chen's Addons", "catmanualpickup", "Manual Pickup & Swap", "", "", function(panel)
		panel:CheckBox("Manually pick up weapons", "catpickup_weapons")
		panel:CheckBox("Manually pick up ammo and items", "catpickup_items")
		panel:NumSlider("Weapon auto-clear time", "catpickup_clearweapons", 0, 600, 1)
		panel:ControlHelp("Automatically clear dropped weapons after # seconds. 0 to not clear.")
	end)
end)

hook.Add("Tick", "CATManualPickup", function()
	-- print("hi")
end)