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
    if not HasMyDebuff("Рой насекомых", 1,"target") and DoSpell("Рой насекомых","target") then return end
    if not HasMyDebuff("Лунный огонь", 1,"target") and DoSpell("Лунный огонь","target") then return end
    if HasBuff("Лунное", 0.1, "player") and DoSpell("Звездный огонь","target") then return end
    if not HasBuff("Лунное", 0.1, "player") and DoSpell("Гнев","target") then return end
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
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
end

function TryTarget(useFocus)
    if useFocus == nil then useFocus = true end
    if not IsValidTarget("target") then
        local found = false
        local members = GetGroupUnits()
        for _,member in pairs(members) do 
            target = member .. "-target"
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target)  then 
                found = true 
                RunMacroText("/startattack " .. target) 
            end
        end

        if not ActualDistance("target") or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end

    end

    if  not IsValidTarget("target") then
        if GetNextTarget() ~= nil then
            RunMacroText("/startattack "..GetNextTarget())
            if not ActualDistance("target") or not NextIsTarget() or not UnitCanAttack("player", "target") then
                RunMacroText("/cleartarget")
            end
            ClearNextTarget()
        end
    end

    if not IsValidTarget("target") then
        RunMacroText("/targetenemy [nodead]")
        
        if not IsAttack() and not ActualDistance("target") or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end
    end

    if not IsValidTarget("target") or (IsAttack() and  not UnitCanAttack("player", "target")) then
        RunMacroText("/cleartarget")
    end
   
    if not IsArena() then
        if useFocus and not IsValidTarget("focus") then
            local found = false
            for _,target in pairs(TARGETS) do 
                if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target) and not IsOneUnit("target", target) then 
                    found = true 
                    RunMacroText("/focus " .. target) 
                end
            end
        end

        if useFocus and not IsValidTarget("focus") or IsOneUnit("target", "focus") or not ActualDistance("focus") then
            RunMacroText("/clearfocus")
        end
    else
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
            if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
        end
    end
    

end

------------------------------------------------------------------------------------------------------------------
function TryProtect()
    if InCombatLockdown() then end
end