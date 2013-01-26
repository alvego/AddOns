-- Sova
------------------------------------------------------------------------------------------------------------------
function Idle()
    if IsAttack() then 
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted()) then return end
        if TryHealing() then return end
        if TryProtect() then return end
        if TryBuffs() then return end
        TryTarget()
        if HasSpell("Звездопад") then
            Sova() 
        else 
            return
        end
end

------------------------------------------------------------------------------------------------------------------
function Sova()
local target = "target"
    if not HasBuff("Облик лунного совуха") and DoSpell("Облик лунного совуха") then return end
    if UnitMana100("player") < 50 and DoSpell("Озарение") then return end
    if not HasDebuff("Волшебный огонь") and DoSpell("Волшебный огонь", target) then return end
    if not HasDebuff("Земля и луна") and DoSpell("Гнев", target) then end
    if not HasMyDebuff("Рой насекомых", 0.3) and DoSpell("Рой насекомых", target) then return end
    if not HasMyDebuff("Лунный огонь", 0.3) and DoSpell("Лунный огонь", target) then return end
    if HasMyBuff("Лунное затмение") and DoSpell("Звездный огонь", target) then return end
    if not HasMyBuff("Лунное затмение") and DoSpell("Гнев", target) then return end
end

------------------------------------------------------------------------------------------------------------------
function TryBuffs()
            if not HasBuff("дикой природы") and DoSpell("Знак дикой природы") then return end
end
------------------------------------------------------------------------------------------------------------------
function TryHealing()
    
        -- if UnitMana100() < 10 and UseItem("Рунический флакон с зельем маны") then return true end

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
    TryEach(TARGETS, function(t)
        if IsValidTarget(t) and (UnitCreatureType(t) == "Нежить" or UnitCreatureType(t) == "Демон") and IsOneUnit("focus",t) then
            RunMacroText("/focus " .. t)
            return true
        end
        return false
    end)
    
    
    if IsArena() and IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
        if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
        if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
    end
    
    if IsAttack() and not InCombatLockdown() then RunMacroText("/startattack")  end
end

------------------------------------------------------------------------------------------------------------------
function TryProtect()
    if InCombatLockdown() then
        if (UnitHealth100() < 40) and DoSpell("Дубовая кожа") then return true end
        end
    return false
end