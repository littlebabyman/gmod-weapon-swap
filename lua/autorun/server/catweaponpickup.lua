util.AddNetworkString("catpickup")

local enableweapon = CreateConVar("catpickup_weapons", "1", {FCVAR_REPLICATED+FCVAR_ARCHIVE}, "Enable picking up weapons manually.", 0, 1)
local enableitem = CreateConVar("catpickup_items", "1", {FCVAR_REPLICATED+FCVAR_ARCHIVE}, "Enable picking up other items manually.", 0, 1)
local weaponwipe = CreateConVar("catpickup_clearweapons", "0", {FCVAR_REPLICATED+FCVAR_ARCHIVE}, "Clear weapons dropped by NPCs and players.", 0)

hook.Add("OnEntityCreated", "CATManualPickup", function(ent)
    if (ent:IsWeapon() and enableweapon:GetBool()) or (!ent:IsWeapon() and enableitem:GetBool()) then
        ent.Spawnable = true
        timer.Simple(0, function()
            if !IsValid(ent) then return end
            if ent:IsWeapon() then ent.StoredAmmo = 0 end
            ent.Spawnable = false
        end)
    end
end)

hook.Add("PlayerDroppedWeapon", "CATManualPickup", function(ply, wep)
    wep.Spawnable = false
    if ply:IsPlayer() then
        wep.StoredAmmo = math.ceil(ply:GetAmmoCount(wep:GetPrimaryAmmoType()) * (ply:Alive() and 0.5 or 1))
        ply:RemoveAmmo(wep.StoredAmmo, wep:GetPrimaryAmmoType())
    else
        wep.StoredAmmo = wep:GetMaxClip1()
    end
    if weaponwipe:GetBool() then
        timer.Create("CATPickupWep" .. wep:EntIndex(), weaponwipe:GetInt() or 60, 1, function()
            if !IsValid(wep) or !timer.Exists("CATPickupWep" .. wep:EntIndex()) then return end
            wep:Remove()
            timer.Remove("CATPickupWep" .. wep:EntIndex())
        end)
    end
end)

hook.Add("PlayerCanPickupItem", "CATManualPickup", function(ply, item)
    if !enableitem:GetBool() then return end
    local used = !ply:KeyDown(IN_WALK) and ply:KeyDown(IN_USE) and !ply:KeyDownLast(IN_USE)
    if !used or ply.PickedUpItem then return item.Spawnable end
    ply.PickedUpItem = true
    timer.Simple(0, function() ply.PickedUpItem = false end)
end)

hook.Add("PlayerCanPickupWeapon", "CATManualPickup", function(ply, wep)
    if !enableweapon:GetBool() then return end
    local class = wep:GetClass()
    local haswep, getwep = ply:HasWeapon(class), ply:GetWeapon(class)
    if haswep and wep.StoredAmmo and wep.StoredAmmo > 0 then
        ply:GiveAmmo(wep.StoredAmmo, wep:GetPrimaryAmmoType(), false)
        wep.StoredAmmo = 0
    end
    local used = !ply:KeyDown(IN_WALK) and ply:KeyDown(IN_USE) and !ply:KeyDownLast(IN_USE)
    if !used or ply.PickedUpItem then return wep.Spawnable end
    local tr = {}
    tr.start = ply:EyePos()
    tr.endpos = wep:WorldSpaceCenter()
    tr.filter = {ply, wep}
    if util.TraceLine(tr).Hit then return end
    local isconsumable = IsValid(getwep) and (getwep:GetMaxClip1() < 0 and getwep:GetPrimaryAmmoType() != -1)
    if haswep and !isconsumable then
        if getwep == ply:GetActiveWeapon() and ply:GetPreviousWeapon():IsValid() then
            ply:SelectWeapon(ply:GetPreviousWeapon())
        end
        ply:DropWeapon(getwep)
        getwep:SetPos(wep:GetPos() + vector_up)
        getwep:SetAngles(wep:GetAngles())
        if IsValid(getwep:GetPhysicsObject()) then
            getwep:GetPhysicsObject():SetVelocityInstantaneous(vector_origin)
        else
            getwep:SetVelocity(-getwep:GetVelocity())
        end
        ply:DropObject()
    end
    if !haswep or !isconsumable then
        timer.Simple(0, function()
            if !IsValid(wep) then return end
            if wep:GetOwner() != ply then ply:PickupWeapon(wep) end
            ply:SelectWeapon(wep)
        end)
    end
    ply.PickedUpItem = true
    timer.Simple(0, function() ply.PickedUpItem = false end)
    -- return !(wep:GetMaxClip1() < 0 and wep:GetPrimaryAmmoType() != -1)
end)

hook.Add("WeaponEquip", "CATManualPickup", function(wep, ply)
    if timer.Exists("CATPickupWep" .. wep:EntIndex()) then timer.Remove("CATPickupWep" .. wep:EntIndex()) end
    if wep.StoredAmmo and wep.StoredAmmo > 0 then
        ply:GiveAmmo(wep.StoredAmmo, wep:GetPrimaryAmmoType(), true)
    end
    wep.Spawnable = false
end)

hook.Add("AllowPlayerPickup", "CATManualPickup", function(ply, ent)
    local walking = ply:KeyDown(IN_WALK)
    if (ent:IsWeapon() and enableweapon:GetBool()) then
        return walking
    end
    if (ent:GetClass():find("prop") == nil and enableitem:GetBool()) then
        return walking
    end
end)