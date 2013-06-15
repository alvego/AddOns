-- Druid Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--[[SetCommand("frostshock", 
    function() 
        if DoSpell("Ледяной шок", "target") then
            echo("Ледяной шок!", 1)
        end
    end, 
    function() 
        return not InCombatLockdown() or not CanControl("target") or HasDebuff("Ледяной шок", 0,1, "target") or not IsSpellNotUsed("Ледяной шок", 1) 
    end
)]]

------------------------------------------------------------------------------------------------------------------
--[[SetCommand("hex", 
    function() 
        if HasSpell("Природная стремительность") then 
            DoSpell("Природная стремительность") 
        end
        echo("Сглаз",1)
        if not IsPlayerCasting() then DoSpell("Сглаз", "target") end
    end, 
    function() 
        if not CanControl("target") or not IsSpellNotUsed("Сглаз", 1)  then return true end
        if not UnitIsPlayer("target") then
            local creatureType = UnitCreatureType("target")
            if creatureType ~= "Гуманоид" or creatureType ~= "Животное" then return true end
        end
        return false
    end
)]]
------------------------------------------------------------------------------------------------------------------
local freedomItem = nil
local freedomSpell = "Каждый за себя"
SetCommand("freedom", 
    function() 
        if HasSpell(freedomSpell) then
            DoSpell(freedomSpell)
            return
        end
        UseEquippedItem(freedomItem) 
    end, 
    function() 
        if IsPlayerCasting() then return true end
        if HasSpell(freedomSpell) and (not InGCD() and not IsReadySpell(freedomSpell)) then return true end
        if freedomItem == nil then
           freedomItem = (UnitFactionGroup("player") == "Horde" and "Медальон Орды" or "Медальон Альянса")
        end
        return not IsEquippedItem(freedomItem) or (not InGCD() and not IsReadyItem(freedomItem)) 
    end
)

------------------------------------------------------------------------------------------------------------------
local tryMount = false
SetCommand("mount", 
    function() 
        if InGCD() or IsPlayerCasting() then return end
        if (IsLeftControlKeyDown() or IsSwimming()) and not HasBuff("Хождение по воде", 1, "player") and DoSpell("Хождение по воде", "player") then 
            tryMount = true
            return 
        end
        if InCombatLockdown() or IsArena() or not PlayerInPlace() then
            DoSpell("Призрачный волк") 
            tryMount = true
            return 
        end
        if InCombatLockdown() or not IsOutdoors() then return end
        local mount = "Стремительный белый рысак"
        if IsFlyableArea() and not IsLeftControlKeyDown() then mount = "Черный дракон" end
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then tryMount = true return end
    end, 
    function() 
        if (HasBuff("Призрачный волк") or IsMounted() or CanExitVehicle()) then return true end
        if tryMount then
            tryMount = false
            return true
        end
        return false 
    end
)

------------------------------------------------------------------------------------------------------------------
-- TODO перенести в команды
function Mount()
    if GetShapeshiftForm() ~= 0 and not (IsFalling() or IsSwimming()) then RunMacroText("/cancelform") end
    
    if HasBuff("Облик кошки") and HasBuff("Крадущийся зверь") then
        RunMacroText("/cancelaura Крадущийся зверь")
        tryMount = true
        return
    end
    
    if InGCD() then return end
    
    
    if IsAltKeyDown() then
        UseMount("Тундровый мамонт путешественника")
        return
    end
    
    
    if IsSwimming() then
        UseMount("Водный облик")
        return
    end
    
    if InCombatLockdown() or IsAttack() or IsIndoors() or (IsFalling() and not IsFlyableArea() and not HasBuff("Облик кошки")) then 
        UseMount("Облик кошки")
        return 
    end

    if IsFlyableArea() and not IsControlKeyDown() then
--~         if not PlayerInPlace() then
            UseMount("Облик стремительной птицы")
            return
--~         end
--~         if IsOutdoors() then
--~             UseMount("Бронзовый дракон")
--~         return
--~         end
    end
        

    
    if not PlayerInPlace() then
        if IsControlKeyDown() then
            UseMount("Облик кошки")
            return
        end
        UseMount("Походный облик")
        return
    end
    
    if IsOutdoors() then
--~     UseMount("Бронированный бурый медведь")
        UseMount("Огромный белый кодо")
        return
    end
end    