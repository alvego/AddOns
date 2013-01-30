-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
SetCommand("freedom", 
    function() return UseEquippedItem("Медальон Орды") end, 
    function() 
        local item = "Медальон Орды" 
        return IsPlayerCasting() or not IsEquippedItem(item) 
            or (not InGCD() and not IsReadyItem(item)) 
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
        if (not HasDebuff("Ледяные оковы",1,"target") and not HasDebuff("Сеть из ледяной ткани",1, "target")) then
            if UseItem("Сеть из ледяной ткани") or ( Runes(2) > 0 and UseSpell("Ледяные оковы", "target")) then 
                stopTarget = true
                return 
            end
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
