-- Sova Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function Idle()
    if IsAttack() then 
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted()) then return end
    if (IsAttack() or InCombatLockdown()) then
        if TryHealing() then return end
        if TryProtect() then return end
        if TryBuffs() then return end
        TryTarget()
        
        if HasSpell("Звездопад") then
            Tank() 
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function Tank()
    if not HasBuff("Облик лунного совуха") and DoSpell("Облик лунного совуха") then return end
    if UnitMana100("player") < 50 and DoSpell("Озарение") then return end
    if UnitHealth("target") > 200000 and not HasDebuff("Волшебный огонь") and DoSpell("Волшебный огонь") then return end
    -- if not HasDebuff("Земля и луна") and DoSpell("Гнев", target) then end
    if not HasMyDebuff("Рой насекомых", 1) and DoSpell("Рой насекомых") then return end
    if not HasMyDebuff("Лунный огонь", 1) and DoSpell("Лунный огонь") then return end
    if HasBuff("Лунное затмение") then DoSpell("Звездный огонь") return end
    if DoSpell("Гнев") then return end
end

------------------------------------------------------------------------------------------------------------------
function TryBuffs()
    if not HasBuff("дикой природы") and DoSpell("Знак дикой природы") then return end
end

------------------------------------------------------------------------------------------------------------------
function TryHealing()
    if UnitMana100() < 30 and UseItem("Рунический флакон с зельем маны") then return true end
end

------------------------------------------------------------------------------------------------------------------
function TryTarget()
    if not IsValidTarget("target") then
        local found = false
        local members = GetGroupUnits()
        for _,member in pairs(members) do 
            target = member .. "-target"
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and (CheckInteractDistance(target, 2) == 1)  then 
                found = true 
                RunMacroText("/startattack " .. target) 
            end
        end

        if not (CheckInteractDistance("target", 2) == 1) or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end

    end

    if  not IsValidTarget("target") then
        if GetNextTarget() ~= nil then
            RunMacroText("/startattack "..GetNextTarget())
            if not (CheckInteractDistance("target", 2) == 1) or not NextIsTarget() or not UnitCanAttack("player", "target") then
                RunMacroText("/cleartarget")
            end
            ClearNextTarget()
        end
    end

    if not IsValidTarget("target") then
        RunMacroText("/targetenemy [nodead]")
        
        if not IsAttack() and not (CheckInteractDistance("target", 2) == 1) or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end
    end

    if not IsValidTarget("target") or (IsAttack() and  not UnitCanAttack("player", "target")) then
        RunMacroText("/cleartarget")
    end
    
    if not IsValidTarget("focus") then
        RunMacroText("/clearfocus")
    end

    if IsAttack() and not InCombatLockdown() then RunMacroText("/startattack")  end
end

------------------------------------------------------------------------------------------------------------------
function TryProtect()
    if InCombatLockdown() then end
end