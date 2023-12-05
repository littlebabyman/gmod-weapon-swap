util.AddNetworkString("catpickup")

hook.Add("OnEntityCreated", "CATManualPickup", function(ent)
    if ent:IsWeapon() then ent.Spawnable = true timer.Simple(0, function() if !IsValid(ent) then return end ent.StoredAmmo = 0 ent.Spawnable = false end) end
end)

hook.Add("PlayerDroppedWeapon", "CATManualPickup", function(ply, wep)
    wep.Spawnable = false
    if ply:IsPlayer() then
        wep.StoredAmmo = math.ceil(ply:GetAmmoCount(wep:GetPrimaryAmmoType()) * (ply:Alive() and 0.5 or 1))
        ply:RemoveAmmo(wep.StoredAmmo, wep:GetPrimaryAmmoType())
    else
        wep.StoredAmmo = wep:GetMaxClip1()
    end
end)

hook.Add("PlayerCanPickupWeapon", "CATManualPickup", function(ply, wep)
    local class = wep:GetClass()
    local haswep, getwep = ply:HasWeapon(class), ply:GetWeapon(class)
    if haswep and wep.StoredAmmo and wep.StoredAmmo > 0 then
        ply:GiveAmmo(wep.StoredAmmo, wep:GetPrimaryAmmoType(), false)
        wep.StoredAmmo = 0
    end
    local used = ply:KeyPressed(IN_USE)
    if !used or ply.PickedUpWeapon then return wep.Spawnable end
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
        DropEntityIfHeld(getwep)
    end
    if !haswep or !isconsumable then
        timer.Simple(0, function()
            if !IsValid(wep) then return end
            if wep:GetOwner() != ply then ply:PickupWeapon(wep) end
            ply:SelectWeapon(wep)
        end)
    end
    ply.PickedUpWeapon = true
    timer.Simple(0, function() ply.PickedUpWeapon = false end)
    -- return !(wep:GetMaxClip1() < 0 and wep:GetPrimaryAmmoType() != -1)
end)

hook.Add("WeaponEquip", "CATManualPickup", function(wep, ply)
    if wep.StoredAmmo and wep.StoredAmmo > 0 then
        ply:GiveAmmo(wep.StoredAmmo, wep:GetPrimaryAmmoType(), true)
    end
    wep.Spawnable = false
end)