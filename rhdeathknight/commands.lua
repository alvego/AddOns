-- DK Rotation Helper by Timofeev Alexey
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
        if freedomItem == nil then
           freedomItem = (UnitFactionGroup("player") == "Horde" and "Медальон Орды" or "Медальон Альянса")
        end
        if HasSpell(freedomSpell) and (not InGCD() and not IsReadySpell(freedomSpell)) then return true else return false end
        return not IsEquippedItem(freedomItem) or (not InGCD() and not IsReadyItem(freedomItem)) 
    end
)

------------------------------------------------------------------------------------------------------------------

SetCommand("lich", 
    function() 
        if DoSpell("Перерождение") then
            echo("Перерождение!",1)
        end
    end, 
    function() 
        return not HasSpell("Перерождение") or  HasBuff("Перерождение", 1, "player") or not IsSpellNotUsed("Перерождение", 1) 
    end
)

------------------------------------------------------------------------------------------------------------------
local stopTarget = false
SetCommand("stop", 
    function() 
        if InGCD() and IsPlayerCasting() then return end
        if HasDebuff("Ледяные оковы",7,"target") then return end
        if Runes(2) > 0 and UseSpell("Ледяные оковы", "target") then 
            stopTarget = true
            return 
        end
    end, 
    function() 
        if not CanAttack("target") then return true end
        if stopTarget then
            stopTarget = false
            return true
        end
        return false  
    end
)

------------------------------------------------------------------------------------------------------------------
local stopFocus = false
SetCommand("stopFocus", 
    function() 
        if InGCD() and IsPlayerCasting() then return end
        if HasDebuff("Ледяные оковы",7,"focus") then return end
        if Runes(2) > 0 and UseSpell("Ледяные оковы", "focus") then 
            stopFocus = true
            return 
        end
    end, 
    function() 
        if not CanAttack("focus") then return true end
        if stopFocus then
            stopFocus = false
            return true
        end
        return false  
    end
)
------------------------------------------------------------------------------------------------------------------
local tryMount = 0
SetCommand("mount", 
    function() 
        if (IsLeftControlKeyDown() or IsSwimming()) 
            and not HasBuff("Льдистый путь", 1, "player") and DoSpell("Льдистый путь") then 
            tryMount = GetTime()
            return
        end
        if IsEquippedItemType("Удочка") and DoSpell("Рыбная ловля") then
            tryMount = GetTime()
            return
        end
        if InGCD() or IsPlayerCasting() or InCombatLockdown() or not IsOutdoors() or not PlayerInPlace() then return end
        local mount = IsShiftKeyDown() and "Большой кодо Хмельного фестиваля" or "Стремительный баран Хмельного фестиваля"
        if IsFlyableArea() and not IsLeftControlKeyDown() then 
            mount = IsShiftKeyDown() and "Синий дракон" or "Бронзовый дракон"
        end
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then 
            tryMount = GetTime() 
            return
        end
    end, 
    function() 

        if GetTime() - tryMount < 0.01 or (InCombatLockdown() or IsMounted() or CanExitVehicle()) then
            tryMount = 0    
            return  true
        end

        return false 
    end
)

------------------------------------------------------------------------------------------------------------------
