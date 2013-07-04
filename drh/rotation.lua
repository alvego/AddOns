-- Druid Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function Idle()
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    --if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff({"Пища", "Питье", "Походный облик", "Облик стремительной птицы", "Водный облик"})) then return end
    -- чтоб контроли не сбивать
    --if not CanControl("target") then RunMacroText("/stopattack") end

    if IsHeal() then
        HealRotation()
        return
    end
end

------------------------------------------------------------------------------------------------------------------
function CanHeal(t)
    return InInteractRange(t) and InRange("Омоложение", t) and IsVisible(t)
end

------------------------------------------------------------------------------------------------------------------
function HealRotation()
    if IsAttack() then
        if HasSpell("Буйный рост") then
            if GetShapeshiftForm() ~= 5 and UseMount("Древо Жизни") then return end
        else
            if GetShapeshiftForm() ~= 0 then RunMacroText("/cancelform") end
        end
    end
    
    if not (IsAttack() or InCombatLockdown()) then return end
    
    DoSpell("Покровительство Природы")
end


