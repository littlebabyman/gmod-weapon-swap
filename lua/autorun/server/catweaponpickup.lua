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
    if ply:HasWeapon(wep:GetClass()) and wep.StoredAmmo and wep.StoredAmmo > 0 then
        ply:GiveAmmo(wep.StoredAmmo, wep:GetPrimaryAmmoType(), true)
        wep.StoredAmmo = 0
    end
    return !(ply:HasWeapon(wep:GetClass()) and !(wep:GetMaxClip1() < 0 and wep:GetPrimaryAmmoType() != -1) or (!wep.Spawnable))
end)

hook.Add("WeaponEquip", "CATManualPickup", function(wep, ply)
    if wep.StoredAmmo and wep.StoredAmmo > 0 then
        ply:GiveAmmo(wep.StoredAmmo, wep:GetPrimaryAmmoType(), true)
    end
    wep.Spawnable = false
end)

hook.Add("AllowPlayerPickup", "CATManualPickup", function(ply, ent)
    return ent:IsWeapon() and ent.Spawnable
end)

hook.Add("KeyPress", "CATManualPickup", function(ply, key)
    if SERVER and key == IN_USE then
        local ent = ply:GetUseEntity()
        if ent:IsWeapon() and ent:GetPhysicsObject():IsAsleep() then
            local wep = ply:GetWeapon(ent:GetClass())
            local isconsumable = IsValid(wep) and (wep:GetMaxClip1() < 0 and wep:GetPrimaryAmmoType() != -1)
            if ply:HasWeapon(ent:GetClass()) and !isconsumable then
                if wep == ply:GetActiveWeapon() and ply:GetPreviousWeapon():IsValid() then
                    ply:SelectWeapon(ply:GetPreviousWeapon())
                end
                ply:DropWeapon(wep)
                wep:SetPos(ent:GetPos() + vector_up)
                wep:SetAngles(ent:GetAngles())
                wep:GetPhysicsObject():SetVelocityInstantaneous(vector_origin)
                DropEntityIfHeld(wep)
            end
            ply:PickupWeapon(ent, isconsumable)
            if !isconsumable then
                ply:SelectWeapon(ent)
            end
        end
    end
end)