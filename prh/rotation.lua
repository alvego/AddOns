-- Paladin Rotation Helper by Timofeev Alexey
SetCommand("free", 
   function() return DoSpell("Длань свободы") end, 
   function() return HasBuff("Длань свободы") or (not InGCD() and not IsReadySpell("Длань свободы"))  end
)

SetCommand("freedom", 
   function() return DoSpell("Каждый за себя") end, 
   function() return not InGCD() and not IsReadySpell("Каждый за себя")  end
)
SetCommand("repentance", 
   function() return DoSpell("Покаяние") end, 
   function() return (not InGCD() and not IsReadySpell("Покаяние")) or not CanControl()   end
)

SetCommand("stun", 
   function() return DoSpell("Молот правосудия") end, 
   function() return (not InGCD() and not IsReadySpell("Молот правосудия")) or not CanControl() and not HasBuff("Незыблемость льда", 0.1 , "target") end
)

SetCommand("frepentance", 
   function() return DoSpell("Покаяние","focus") end, 
   function() return (not InGCD() and not IsReadySpell("Покаяние")) or not CanControl("focus") end
)

SetCommand("fstun", 
   function() return DoSpell("Молот правосудия","focus") end, 
   function() return (not InGCD() and not IsReadySpell("Молот правосудия")) or not CanControl("focus") and not HasBuff("Незыблемость льда", 0.1, "focus")  end
)

SetCommand("sv", 
   function() return DoSpell("Длань защиты","Ириха") end, 
   function() return not InForbearance("Ириха") and not InGCD() and not IsReadySpell("Длань защиты") end
)

SetCommand("hp", 
   function() return DoSpell("Печать Света") end, 
   function() return not InGCD() and HasBuff("Печать Света")  end
)

SetCommand("dd", 
   function() return DoSpell("Печать праведности") end, 
   function() return not InGCD() and HasBuff("Печать праведности")  end
)

SetCommand("cl", 
   function() end, 
   function() return not InGCD() and DoSpell("Очищение","Ириха") end
)

function Tank()
    if not (IsValidTarget("target") and (UnitAffectingCombat("target") or IsAttack()))  then return end
    if DoSpell("Щит мстителя") then return end
    if IsAOE() then
        if UnitMana100() > 50 and InMelee() and DoSpell("Освящение") then return end
        if (UnitCreatureType("target") == "Нежить") and UnitMana100() > 60 and InMelee() and DoSpell("Гнев небес") then return end
    end
    if UnitHealth100("target") < 20 and DoSpell("Молот гнева") then return end
    if DoSpell("Молот праведника") then return end
    if UnitMana100() > 55 and DoSpell("Правосудие света") then return end
    if UnitMana100() <= 55 and DoSpell("Правосудие мудрости") then return end
    if DoSpell("Щит праведности") then return end
end

function Retribution()
    if IsArena() then
        local redDispelList = {
            "Превращение"
            -- "Покаяние",
            -- "Глубокая заморозка",
            -- "Молот правосудия",
            -- "Замораживающая ловушка",
            --"Смерч"
        }
        if IsReadySpell("Очищение") and TryEach(GetUnitNames(),
            function(u) return CanHeal(u) and IsVisible(u) and HasDebuff(redDispelList, 2, u) and DoSpell("Очищение", u) end
        ) then return end
    end
    if InMelee() and HasBuff("Гнев карателя") and UseItem("Знак превосходства")then return end
    if UnitMana("player") < 1000 and not HasBuff("Печать мудрости") and DoSpell("Печать мудрости") then return end
    if UnitMana100("player") > 70 then RunMacroText("/cancelaura Печать мудрости") end
    if IsValidTarget("mouseover") and (UnitCreatureType("mouseover") == "Нежить" or UnitCreatureType("mouseover") == "Демон") 
        and not HasDebuff("Изгнание зла", 0.5, "mouseover") and DoSpell("Изгнание зла","mouseover") then return end
    if IsValidTarget("mouseover") and (UnitName("mouseover") == "Тотем оков земли") and DoSpell("Длань возмездия", "mouseover") then return end
    if not (IsValidTarget("target") and (UnitAffectingCombat("target") or IsAttack()))  then return end
    
    if HasDebuff("Огненный шок", 1, "player") and DoSpell("Очищение",player) then return end
    
    if IsShiftKeyDown() == 1 and DoSpell("Освящение") then return end
    
    if UnitHealth100("target") < 20 and DoSpell("Молот гнева") then return end
    if CanMagicAttack() then
        if HasBuff("Искусство войны") and DoSpell("Экзорцизм") then return end      
        if IsAltKeyDown() then
            if DoSpell("Правосудие справедливости") then return end
        else
            if UnitMana100() < 60 then DoSpell("Правосудие мудрости") else DoSpell("Правосудие света") end
        end
    end
    
    if InMelee() and DoSpell("Божественная буря") then return end
    if DoSpell("Удар воина Света") then return end
    if (UnitCreatureType("target") == "Нежить") and UnitMana100() > 40 and InMelee() and DoSpell("Гнев небес") then return end    
    if UnitMana100() < 50 and DoSpell("Святая клятва") then return end
    if not TryEach(GetUnitNames(), function(u) return HasMyBuff("Священный щит", 0.1, u) end) and DoSpell("Священный щит","player") then return end
    -- Dispel
    if IsArena() then
        if IsReadySpell("Очищение") and TryEach(GetUnitNames(), 
            function(u) return CanHeal(u) and IsVisible(u) and HasDebuff({"Magic", "Disease", "Poison"}, 3, u) and DoSpell("Очищение", u) end
        ) then return end
    else
        if IsReadySpell("Очищение") and HasDebuff({"Magic", "Disease", "Poison"}, 3, "player") and DoSpell("Очищение", "player") then return end
    end
    
end

local StartCombatTime = 0
function Idle()
    if not InCombatLockdown() then
        StartCombatTime = GetTime()
    end
    if (IsAttack() or InCombatLockdown()) then
        local harmTarget = GetHarmTarget()
        local units = GetPartyOrRaidMembers()
        if CanUseInterrupt() and TryEach(harmTarget, TryInterrupt) then return end
        if IsMouseButtonDown(3) and TryTaunt("mouseover") then return end
        if GetAutoAGGRO() and InGroup() and ((GetTime() - StartCombatTime > 1)) then
            if (GetTime() - StartCombatTime < 3) and TryEach(units, function(unit) 
                if IsInteractTarget(unit) and  UnitThreat(unit) > 1 and not IsOneUnit("player", unit) and DoSpell("Длань спасения",unit) then 
                    echo("Длань спасения " .. unit) 
                    return true
                end
                return false
            end) then return end
            if TryEach(harmTarget, function(target) return IsValidTarget(target) and UnitAffectingCombat(target) and TryTaunt(target) end) then return end
        end
        -- Священная жертва
        if InCombatLockdown() and HasSpell("Щит мстителя") and InGroup() and CalculateHP("player") > 70 then
            local lowhpmembers = 0
            for _,target in pairs(units) do if CalculateHP(target) <= 50 then lowhpmembers = lowhpmembers + 1 end end
            if lowhpmembers > 2 and DoSpell("Священная жертва") then return end
        end
        
        if TryHealing() then return end
        if TryProtect() then return end
        if TryBuffs() then return end
        TryTarget()
        
        if (IsControlKeyDown() == 1) and IsValidTarget("target") and DoSpell("Гнев карателя") then return end
        
        if HasSpell("Щит мстителя") then
            if TryDispell("player") then return end
            Tank() 
        else 
            Retribution()
        end
    end
end

function TryBuffs()
        if HasSpell("Удар воина Света") then
            if HasBuff("Праведное неистовство") and RunMacroText("/cancelaura Праведное неистовство") then return end
            if not HasBuff("Печать") and DoSpell("Печать праведности") then return end
            if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
                if not HasBuff("Боевой крик")
                    and not HasBuff("благословение могущества") and DoSpell("Великое благословение могущества","player") then return end
                if ((HasBuff("благословение могущества") and not HasMyBuff("благословение могущества")) or HasBuff("Боевой крик")) 
                    and not HasBuff("благословение королей") and DoSpell("Великое благословение королей","player") then return end
            end
        else
            if not FindAura("Благословение") and DoSpell("Великое благословение неприкосновенности","player") then return end
            if not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
            if not HasBuff("Печать мщения") and DoSpell("Печать мщения") then return end
            if not HasBuff("Священный щит") and DoSpell("Священный щит","player") then return end
            if not HasBuff("Святая клятва") and DoSpell("Святая клятва") then return end
            if not HasBuff("Щит небес",0.8) and DoSpell("Щит небес") then return end
            return false
        end 
end

function CanHeal(t)
    if IsInteractTarget(t) 
        and InRange("Вспышка света", t)
        and IsVisible(t)
    then return true end 
    return false
end 

local HolyShieldTime  =  0
function TryHealing()
    if IsArena() then
        local members, units = {}, GetUnitNames()
        for i=1,#units do
            local u = units[i]
            if CanHeal(u) then table.insert(members, { Unit = u, HP = CalculateHP(u), Lost = UnitLostHP(u) } ) end
        end
        table.sort(members, function(x,y) return x.HP < y.HP end)
        local unitWithShield = nil
        for i=1,#units do 
            if HasMyBuff("Священный щит",1,units[i]) then unitWithShield = units[i] end 
        end 
        if #members > 0 then 
            local u, h, l = members[1].Unit, members[1].HP, members[1].Lost
            if ((not unitWithShield and h < 80) or (not HasBuff("Священный щит",1,u) and h < 40 and (GetTime() - HolyShieldTime > 3))) and DoSpell("Священный щит",u) then
                HolyShieldTime = GetTime() 
                return 
            end
            if h < 20 and DoSpell("Возложение рук",u) then return end
            if h < 70 and HasBuff("Искусство войны") and (not IsReadySpell("Экзорцизм") or h < 40) and DoSpell("Вспышка Света",u) then return end
        end
    else
        local h = CalculateHP("player")
        if InCombatLockdown() then
            -- if h < 40 and not HasBuff("Печать Света") and DoSpell("Печать Света") then return end
            -- if h > 80 and not HasBuff("Печать праведности") and DoSpell("Печать праведности") then return end
            -- if h < 50 and HasBuff("Искусство войны") and EquipItemByName("Манускрипт правосудия гневного гладиатора") and DoSpell("Вспышка Света") and EquipItemByName("Манускрипт стойкости гневного гладиатора") then return end
            if h < 35 and UseHealPotion() then return true end
            if h < 30 and DoSpell("Возложение рук") then return true end
            if h < 80 and HasBuff("Искусство войны") and (not IsReadySpell("Экзорцизм") or h < 40) then DoSpell("Вспышка Света") return end
            if UnitMana100() < 10 and UseItem("Рунический флакон с зельем маны") then return true end
        end
    end
    return false
end


function TryTarget()
    if not IsValidTarget("target") then
        local found = false
        local members = GetPartyOrRaidMembers()
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
    
    if IsArena() and IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
        if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
        if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
    end
    
end

function TryProtect()
    if InCombatLockdown() then
        if (UnitHealth100() < 90 and not (HasBuff("Крепнущая броня"))) then
            if UseEquippedItem("Клятва Эйтригга") then return true end
        end
        
        if HasSpell("Щит мстителя") and UnitHealth100() < 80 and DoSpell("Святая клятва") then return end
        
        if (UnitHealth100() < 50 and not (HasBuff("Затвердевшая кожа"))) then
            if UseEquippedItem("Проржавевший костяной ключ") then return true end
        end
        if HasSpell("Удар воина Света") and (UnitHealth100() < 20) and DoSpell("Божественный щит") then return true end
        if (UnitHealth100() < 15) and DoSpell("Божественная защита") then return true end   
        end
    return false;
end

local InterruptTime = 0
function TryInterrupt(target)
    if (GetTime() - InterruptTime < 1) or IsArena() then return false end
    if target == nil then target = "target" end
    
    if not IsValidTarget(target) then return false end
    
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
    end
    
    if not spell then return false end
   
    local time = endTime/1000 - GetTime()

    if time < 0.1 or time > 2 then 
        return false 
    end
    m = " -> " .. spell .. " ("..target..")"
    
    if not notinterrupt then 
        if CanControl(target) and DoSpell("Покаяние", target) then 
            echo("Покаяние"..m)
            InterruptTime = GetTime()
            return true 
        end
        if CanControl(target) and not HasBuff("Незыблемость льда", 0.1 , target) and DoSpell("Молот правосудия", target) then 
            echo("Молот правосудия"..m)
            InterruptTime = GetTime()
            return true 
        end
    end
    
    return false    
end

local TauntTime = 0
function TryTaunt(target)
 if not IsValidTarget(target) then return false end
 if UnitIsPlayer(target) then return false end
 if UnitThreat("player",target) == 3 then return false end
 if (GetTime() - TauntTime < 1.5) then return false end
 local tt = UnitName(target .. "-target")
 if not UnitExists(tt) then return false end
 if IsOneUnit("player", tt) then return false end
 
 if DoSpell("Длань возмездия", target) then 
     TauntTime = GetTime()
     -- chat("Длань возмездия на " .. UnitName(target))
     return true  
 end

 if IsInteractTarget(tt) and DoSpell("Праведная защита", tt) then 
     TauntTime = GetTime()
     -- chat("Праведная защита на " .. UnitName(tt))
     return true  
 end
 return false
end