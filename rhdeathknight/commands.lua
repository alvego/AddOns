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
local stopTime = 0
SetCommand("stop", 
    function(target) 
        if target == nil then target = "target" end
        if InGCD() and IsPlayerCasting() then return end
        if HasDebuff("Ледяные оковы",7,target) then return end
        if Runes(2) > 0 and UseSpell("Ледяные оковы", target) then 
            stopTime = GetTime()
            return 
        end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanAttack(target) then return true end
        if GetTime() - stopTime < 0.1 then
            stopTime = 0
            return true
        end
        return false  
    end
)
------------------------------------------------------------------------------------------------------------------
-- Death Grip
local dgTime = 0
SetCommand("dg", 
    function(target) 
        if target == nil then target = "target" end
        if UseSpell("Хватка смерти", target) then 
            dgTime = GetTime()
            return 
        end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanMagicAttack(target) or not IsReadySpell("Хватка смерти") then return true end
        if GetTime() - dgTime < 0.1 then
            dgTime = 0
            return true
        end
        return false  
    end
)

------------------------------------------------------------------------------------------------------------------
local stunTime = 0
SetCommand("stun", 
    function(target) 
        if not IsReadySpell("Отгрызть") then return end
        if target == nil then target = "target" end
        RunMacroText("/petattack "..target)
        RunMacroText("/cast [@"..target.."] Отгрызть")
        RunMacroText("/cast [@"..target.."] Прыжок")
        if not IsReadySpell("Отгрызть") then 
            stunTime = GetTime()
            return 
        end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not HasSpell("Отгрызть") or not IsReadySpell("Отгрызть") or not CanAttack(target) or not CanControl(target) then return true end
        if GetTime() - stunTime < 0.1 then
            stunTime = 0
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
        --[[local mount = IsShiftKeyDown() and "Большой кодо Хмельного фестиваля" or "Конь смерти Акеруса"
        if IsFlyableArea() and not IsLeftControlKeyDown() then 
            mount = IsShiftKeyDown() and "Бронзовый дракон" or "Крылатый скакун Черного Клинка"
        end]]
        local mount = "Скакун Всадника без головы"
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then 
            tryMount = GetTime() 
            return
        end
    end, 
    function() 

        if tryMount > 0 and GetTime() - tryMount > 0.01 or (InCombatLockdown() or IsMounted() or CanExitVehicle()) then
            tryMount = 0    
            return  true
        end

        return false 
    end
)

------------------------------------------------------------------------------------------------------------------

local explodeTime = 0
SetCommand("explode", 
    function() 
        if IsPlayerCasting() and UnitMana("player") < 40 or not HasSpell("Отгрызть") or not HasSpell("Взрыв трупа") then return end
        RunMacroText("/cast [@pettarget] Прыжок")
        RunMacroText("/cast [@pet] Взрыв трупа")
        if IsPlayerCasting() then 
            explodeTime = GetTime()
            return 
        end
    end, 
    function() 
        if UnitMana("player") < 35 or not HasSpell("Отгрызть") or not HasSpell("Взрыв трупа") or not CanAttack(target) then return true end
        if GetTime() - explodeTime < 0.1 then
            explodeTime = 0
            return true
        end
        return false  
    end
)

------------------------------------------------------------------------------------------------------------------
local silenceTime = 0
SetCommand("silence", 
    function(target) 
        if target == nil then target = "target" end
        if Runes(1) > 0 and UseSpell("Удушение", target) then 
            silenceTime = GetTime()
            return 
        end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanMagicAttack(target) or HasBuff("Мастер аур", 0.1, target) then return true end
        if GetTime() - silenceTime < 0.1 then
            silenceTime = 0
            return true
        end
        return false  
    end
)

------------------------------------------------------------------------------------------------------------------

local armyTime = 0
SetCommand("army", 
    function() 
        if IsPlayerCasting() or not HasRunes(111) or not IsReadySpell("Войско мертвых") then return end
        RunMacroText("/cast Войско мертвых")
        if IsPlayerCasting() then 
            armyTime = GetTime()
            return 
        end
    end, 
    function() 
        if IsArena() or IsPlayerCasting() or not IsReadySpell("Войско мертвых") then return end
        if GetTime() - armyTime < 0.1 then
            armyTime = 0
            return true
        end
        return false  
    end
)
------------------------------------------------------------------------------------------------------------------