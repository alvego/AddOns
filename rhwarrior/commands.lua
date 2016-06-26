-- Warrior Rotation Helper by Timofeev Alexey
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
-- // /run if IsReadySpell("s") and СanMagicAttack("target") then DoCommand("spell", "s", "target") end
SetCommand("spell", 
    function(spell, target) 
        if DoSpell(spell, target) then
            echo(spell.."!",1)
        end
    end, 
    function(spell, target) 
        if not HasSpell(spell) then
            chat(spell .. " - нет спела!")
            return true
        end
        if not InRange(spell, target) then
            chat(spell .. " - неверная дистанция!")
            return true
        end
        if not IsSpellNotUsed(spell, 1)  then
            chat(spell .. " - успешно сработало!")
            return true
        end
        return false
    end
)

------------------------------------------------------------------------------------------------------------------
local tryMount = 0
SetCommand("mount", 
    function() 
        if InGCD() or InCombatLockdown() or IsMounted() or CanExitVehicle() or IsPlayerCasting() or not IsOutdoors() or not PlayerInPlace() then
            tryMount = GetTime() 
            return
        end
        --local mount = (IsFlyableArea() and not IsShiftKeyDown()) and "Стремительный сиреневый грифон" or "Стремительный игреневый конь"
        --local mount = not IsShiftKeyDown() and "Непобедимый" or (IsFlyableArea() and "Прогулочная ракета X-53" or "Анжинерский чоппер")
        local mount = "Большая ракета любви"
        --[[if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end]]
        if UseMount(mount) then 
            tryMount = GetTime() 
            return
        end
    end, 
    function() 

        if tryMount > 0 and GetTime() - tryMount > 0.01 then
            tryMount = 0    
            return  true
        end

        return false 
    end
)
------------------------------------------------------------------------------------------------------------------