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
if IsValidTarget("target") and InMelee() and (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) then DoCommand("spell", "Мор") end
------------------------------------------------------------------------------------------------------------------
local morTime = 0
SetCommand("mor", 
    function() 
        if not HasRunes(100) then DoSpell("Кровоотвод") end
        if DoSpell("Мор") then 
            morTime = GetTime()
            return 
        end
    end, 
    function() 
        if not IsValidTarget("target") or not InMelee() or not (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) then return true end
        if GetTime() - morTime < 0.1 then
            stopTime = 0
            return true
        end
        return false  
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("silence", 
    function(target) 
        local spell = "Удушение"
        if not HasRunes(100) then DoSpell("Кровоотвод") end
        if DoSpell(spell, target) then
            echo(spell.."!",1)
        end
    end, 
    function(target) 
        if not CanMagicAttack(target) or HasBuff("Мастер аур", 0.1, target) then return true end
        local spell = "Удушение"
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
local stopTime = 0
local stopImmune = {"Длань свободы", "Отражение заклинания"}
SetCommand("stop", 
    function(target) 
        if target == nil then target = "target" end
        if InGCD() and IsPlayerCasting() then return end
        if HasDebuff("Ледяные оковы",7,target) then return end
        if DoSpell("Ледяные оковы", target) then 
            stopTime = GetTime()
            return 
        end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanAttack(target) or HasBuff(stopImmune, 0.1, target) then return true end
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
        if DoSpell("Хватка смерти", target) then 
            dgTime = GetTime()
            return 
        end
    end, 
    function(target) 
        if target == nil then target = "target" end
        if not CanAttack(target)  or HasBuff("Отражение заклинания", 0.1, target) or not IsReadySpell("Хватка смерти") then return true end
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
        if DoSpell("Отгрызть", target) then 
            stunTime = GetTime()
            return 
        end
        DoSpell("Прыжок", target)
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
        if InGCD() or InCombatLockdown() or IsMounted() or CanExitVehicle() or IsPlayerCasting() or not IsOutdoors() or not PlayerInPlace() then
            tryMount = GetTime() 
            return
        end
        --local mount = (IsFlyableArea() and not IsShiftKeyDown()) and "Крылатый скакун Черного Клинка" or "Конь смерти Акеруса"
        local mount = (IsFlyableArea() and not IsShiftKeyDown()) and "Прогулочная ракета X-53" or "Анжинерский чоппер"
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
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

local explodeTime = 0
SetCommand("explode", 
    function() 
        if IsPlayerCasting() and UnitMana("player") < 40 or not HasSpell("Отгрызть") or not HasSpell("Взрыв трупа") then return end
        --DoSpell("Прыжок", "pet-target")
        RunMacroText("/petpassive")
        RunMacroText("/petstay")
        if DoSpell("Взрыв трупа", "pet") then 
            explodeTime = GetTime()
            return 
        end
    end, 
    function() 
        if IsPlayerCasting() or UnitMana("player") < 35 or not HasSpell("Отгрызть") or not HasSpell("Взрыв трупа") or not CanAttack(target) then return true end
        if GetTime() - explodeTime < 0.1 then
            explodeTime = 0
            return true
        end
        return false  
    end
)

