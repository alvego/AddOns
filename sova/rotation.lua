-- Sova Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function Idle()
    if IsAttack() then 
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted() or CanExitVehicle()) then return end
    if (IsAttack() or InCombatLockdown()) then
        if TryHealing() then return end
        if TryProtect() then return end
        if TryBuffs() then return end
        TryTarget()
        
        if HasSpell("Звездопад") then
            Sova() 
        end
    end
end

------------------------------------------------------------------------------------------------------------------
local t = 0
function Sova()
    if t ~= 7 and Debug then print(t) end
    t = 0
    if not HasBuff("Облик лунного совуха") and DoSpell("Облик лунного совуха") then return end
    t = 1
    if UnitMana100("player") < 50 and DoSpell("Озарение", "player") then return end
    t = 2
    if UnitHealth("target") > 200000 and not HasDebuff("Волшебный огонь") and DoSpell("Волшебный огонь") then return end
    t = 3
    --if not HasDebuff("Земля и луна") and DoSpell("Гнев") then end
    if not HasMyDebuff("Рой насекомых", 1,"target") and DoSpell("Рой насекомых") then return end
    t = 4
    if not HasMyDebuff("Лунный огонь", 1,"target") and DoSpell("Лунный огонь") then return end
    t = 5
    if HasBuff("Лунное") and DoSpell("Звездный огонь") then return end
    t = 6
    if DoSpell("Гнев") then return end
    t = 7
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