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
SetCommand("dg", 
   function() return DoSpell("Хватка смерти") end, 
   function() return not InGCD() and not IsReadySpell("Хватка смерти") end
)

------------------------------------------------------------------------------------------------------------------
local stopTarget = false
SetCommand("stop", 
    function() 
        if InGCD() and IsPlayerCasting() then return end
        if HasDebuff("Ледяные оковы",6,"target") then return end
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
local tryMount = false
SetCommand("mount", 
    function() 
        if (IsLeftControlKeyDown() or IsSwimming()) 
            and not HasBuff("Льдистый путь", 1, "player") and DoSpell("Льдистый путь") then 
            tryMount = true
            return 
        end
        if IsEquippedItemType("Удочка") and DoSpell("Рыбная ловля") then
            tryMount = true
            return 
        end
        if InGCD() or IsPlayerCasting() or InCombatLockdown() or not IsOutdoors() or not PlayerInPlace() then return false end
        local mount = IsShiftKeyDown() and "Конь смерти Акеруса" or "Механоцикл"
        if IsFlyableArea() and not IsLeftControlKeyDown() then 
            mount = IsShiftKeyDown() and "Турбоветролет" or "Голова Мимирона"
        end
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then 
            tryMount = true 
            return 
        end
    end, 
    function() 
        if (InCombatLockdown() or IsMounted() or CanExitVehicle()) then return true end
        if tryMount then
            tryMount = false
            return true
        end
        return false 
    end
)

------------------------------------------------------------------------------------------------------------------
