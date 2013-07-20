-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local holyShieldTime  =  0
local steathClass = {"ROGUE", "DRUID"}
function Idle()
    if IsAttack() then 
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted() or  CanExitVehicle()) then return end
    if IsMouseButtonDown(3) and TryTaunt("mouseover") then return end

    for _,t in pairs(TARGETS) do
        if UnitIsPlayer(t) and tContains(steathClass, GetClass(t)) and not InRange("Покаяние", t) and not HasDebuff("Длань возмездия", 1, t) and DoSpell("Длань возмездия", t) then return end
    end
    
    if (IsAttack() or InCombatLockdown()) then
        if CanInterrupt then
            for _,t in pairs(TARGETS) do
                if TryInterrupt(t) then return end
            end 
        end
                
        if AutoAGGRO and InGroup() and InCombat(1) then
            for _,target in pairs(TARGETS) do
                if IsValidTarget(target) and UnitAffectingCombat(target) and TryTaunt(target) then return end
            end
        end
        
        -- Священная жертва
        if InCombatLockdown() and HasSpell("Щит мстителя") and InGroup() and CalculateHP("player") > 70 then
            local lowhpmembers = 0
            for _,target in pairs(UNITS) do if CalculateHP(target) <= 50 then lowhpmembers = lowhpmembers + 1 end end
            if lowhpmembers > 2 and DoSpell("Священная жертва") then return end
        end
        
        if TryHealing() then return end
        if TryProtect() then return end
        if TryBuffs() then return end
        TryTarget()
        
        if (IsControlKeyDown() == 1) and IsValidTarget("target") and DoSpell("Гнев карателя") then return end
        
        if HasSpell("Щит мстителя") then
            Tank() 
        else 
            Retribution()
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function Tank()
    local target = "target"
    -- пытаемся сдиспелить с себя каку не чаще чем раз в 2 сек
    if IsSpellNotUsed("Очищение" , 2) and TryDispel("player") then return end
    if not IsAttack() and not CanAttack(target) then return end
    if not (UnitAffectingCombat(target) or IsAttack()) then return end
    if DoSpell("Щит мстителя", target) then return end
    if IsAOE() then
        if UnitMana100("player") > 50 and InMelee(target) and DoSpell("Освящение", target) then return end
        if (UnitCreatureType(target) == "Нежить") and UnitMana100("player") > 60 and InMelee(target) and DoSpell("Гнев небес", target) then return end
    end
    if UnitHealth100(target) < 20 and DoSpell("Молот гнева", target) then return end
    if DoSpell("Молот праведника", target) then return end
    if UnitMana100("player") > 55 and DoSpell("Правосудие света", target) then return end
    if UnitMana100("player") <= 55 and DoSpell("Правосудие мудрости", target) then return end
    if DoSpell("Щит праведности", target) then return end
end

------------------------------------------------------------------------------------------------------------------
local redDispelList = { 
    "Превращение", 
    "Глубокая заморозка", 
    "Огненный шок", 
    "Покаяние", 
    "Молот правосудия",
    "Замедление",
    "Эффект ледяной ловушки",
    "Эффект замораживающей стрелы",
    "Удушение",
    "Антимагия - немота",
    "Безмолвие",
    "Волшебный поток",
    "Вой ужаса",
    "Ментальный крик",
    "Успокаивающий поцелуй"
}

local rootDispelList = {
    "Ледяной шок", 
    "Оковы земли", 
    "Заморозка",
    "Удар грома",
    "Ледяная стрела", 
    "Ночной кошмар",
    "Ледяные оковы",
    "Обморожение",
    "Кольцо льда",
    "Стрела ледяного огня",
    "Холод",
    "Окоченение",
    "Конус холода",
    "Разрушенная преграда",
    "Замедление",
    "Удержание",
    "Гнев деревьев",
    "Обездвиживающее поле",
    "Леденящий взгляд",
    "Хватка земли"
}

local function IsFinishHim(target) return CanAttack(target) and UnitHealth100(target) < 35 end 
local totems = { "Тотем оков земли", "Тотем прилива маны", "Тотем заземления" }
function Retribution()
    local target = "target"

    if not IsFinishHim(target) and UnitMana100("player") > 10 and IsReadySpell("Очищение") and IsSpellNotUsed("Очищение", 5) then
        for _,u in pairs(IUNITS) do
            if CanHeal(u) and HasDebuff(redDispelList, 2, u) and TryDispel(u) then return end
        end
    end

    if UnitHealth100("player") < 50 and UseItem("Камень здоровья из Скверны") then return end
    if UnitMana100("player") < 20 and not HasBuff("Печать мудрости") and DoSpell("Печать мудрости") then return end
    if UnitMana100("player") > 70 then RunMacroText("/cancelaura Печать мудрости") end
    if IsPvP() then
        for _,t in pairs(TARGETS) do
            if CanAttack(t) and (UnitCreatureType(t) == "Нежить" or UnitCreatureType(t) == "Демон") 
                and not HasDebuff("Изгнание зла", 0.1, t) and DoSpell("Изгнание зла",t) then return end
        end
    end
    if IsReadySpell("Длань возмездия") then
        for _,t in pairs(TARGETS) do
            if CanAttack(t) and tContains(totems, UnitName(t)) and DoSpell("Длань возмездия",t) then return end
        end
    end
    if not IsAttack() and not CanAttack(target) then return end
    if not (UnitAffectingCombat(target) or IsAttack()) then return end
    if InMelee(target) and HasBuff("Гнев карателя") and UseEquippedItem("Знак превосходства")then return end
    if IsShiftKeyDown() == 1 and DoSpell("Освящение") then return end
    if UnitHealth100(target) < 20 and DoSpell("Молот гнева", target) then return end
    if CanMagicAttack(target) then
        if UseEquippedItem("Чешуйчатые рукавицы разгневанного гладиатора")then return end
        if HasBuff("Искусство войны") and DoSpell("Экзорцизм", target) then return end   
        if DoSpell(IsAltKeyDown() and "Правосудие справедливости" or "Правосудие мудрости", target) then return end
    end
    if CanAttack(tagret) and UnitMana100("player") > 20 and not InMelee(target) and HasDebuff(rootDispelList, 1, "player") and TryDispel("player") then return end
    if InMelee(target) and DoSpell("Божественная буря") then return end
    if DoSpell("Удар воина Света", target) then return end
    if IsEquippedItem("Обломок треснувших ворот Цитадели") and DoSpell("Щит праведности", target) then return end
    if (UnitCreatureType(target) == "Нежить") and UnitMana100("player") > 40 and InMelee(target) and DoSpell("Гнев небес") then return end    
    if UnitMana100("player") < 50 and DoSpell("Святая клятва") then return end
    if (IsPvP() or (UnitThreat("player") == 3 and UnitHealth100("player") < 95)) and (GetTime() - holyShieldTime > 10) then
        local hasShield = false
        for _,u in pairs(UNITS) do
            if HasMyBuff("Священный щит", 0.1, u) then 
                hasShield = true
                break
            end
        end
       if not hasShield and DoSpell("Священный щит","player") then holyShieldTime = GetTime() return end 
    end
       
    if not IsFinishHim(target) and UnitMana100("player") > 40 and IsReadySpell("Очищение") then
        for _,u in pairs(IUNITS) do
            if TryDispel(u) then return end
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function TryBuffs()
        if HasSpell("Удар воина Света") then
        -- if not InCombatLockdown() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
            if HasBuff("Праведное неистовство") and RunMacroText("/cancelaura Праведное неистовство") then return end
            if not HasBuff("Печать") and DoSpell("Печать праведности") then return end
            if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
                if not HasBuff("Боевой крик")
                    and not HasBuff("благословение могущества") and DoSpell("Великое благословение могущества","player") then return end
                if ((HasBuff("благословение могущества") and not HasMyBuff("благословение могущества")) or HasBuff("Боевой крик")) 
                    and not HasBuff("благословение королей") and DoSpell("Великое благословение королей","player") then return end
            end
        else
            if not HasBuff("Благословение") and DoSpell("Великое благословение неприкосновенности","player") then return end
            if not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
            if HasSpell("Печать мщения") and not HasBuff("Печать мщения") and DoSpell("Печать мщения") then return end
            if HasSpell("Печать порчи") and not HasBuff("Печать порчи") and DoSpell("Печать порчи") then return end
            if not HasBuff("Священный щит") and DoSpell("Священный щит","player") then return end
            if not HasBuff("Святая клятва") and DoSpell("Святая клятва") then return end
            if not HasBuff("Щит небес",0.8) and DoSpell("Щит небес") then return end
            return false
        end 
end

------------------------------------------------------------------------------------------------------------------
function TryHealing()
    if not IsArena() and InCombatLockdown() then
        if CalculateHP("player") < 35 and UseHealPotion() then return true end
        if UnitMana100() < 10 and UseItem("Рунический флакон с зельем маны") then return true end
    end
    if InCombatLockdown() or IsArena() then
        local unitWithShield
        for i=1,#UNITS do 
            if HasMyBuff("Священный щит",1,UNITS[i]) then unitWithShield = UNITS[i] end 
        end 
        local members, membersHP = GetHealingMembers(IUNITS)
        local u = members[1]
        local h = membersHP[u]
        if ((not unitWithShield and h < 80) or (not HasBuff("Священный щит",1,u) and h < 40 and (GetTime() - holyShieldTime > 3))) and DoSpell("Священный щит",u) then
            holyShieldTime = GetTime() 
            return 
        end
        if h < 20 and DoSpell("Возложение рук",u) then return end
        if h < 100 and HasBuff("Искусство войны") and (not IsFinishHim("target") and not IsReadySpell("Экзорцизм") or h < 70 ) and DoSpell("Вспышка Света",u) then return end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
end

function TryTarget()
    if not IsValidTarget("target") then
        local found = false
        local members = GetGroupUnits()
        for _,member in pairs(members) do 
            target = member .. "-target"
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target) and (not IsPvP() or UnitIsPlayer(target))  then 
                found = true 
                RunMacroText("/startattack " .. target) 
            end
        end

        if not ActualDistance("target") or not UnitCanAttack("player", "target") or (IsPvP() and not UnitIsPlayer("target")) then
            RunMacroText("/cleartarget")
        end

    end

    if  not IsValidTarget("target") then
        if GetNextTarget() ~= nil then
            RunMacroText("/startattack "..GetNextTarget())
            if not ActualDistance("target") or not NextIsTarget() or not UnitCanAttack("player", "target") or (IsPvP() and not UnitIsPlayer("target")) then
                RunMacroText("/cleartarget")
            end
            ClearNextTarget()
        end
    end

    if not IsValidTarget("target") then
        if IsPvP() then
            RunMacroText("/targetenemyplayer [nodead]")
        else
            RunMacroText("/targetenemy [nodead]")
        end
        if not IsAttack() and not ActualDistance("target") or not UnitCanAttack("player", "target") or (IsPvP() and not UnitIsPlayer("target")) then
            RunMacroText("/cleartarget")
        end
    end

    if not IsValidTarget("target") or (IsAttack() and  not UnitCanAttack("player", "target")) then
        RunMacroText("/cleartarget")
    end
    
    if not IsValidTarget("focus") then
        RunMacroText("/clearfocus")
    end

    for _,t in pairs(TARGETS) do
        if IsValidTarget(t) and (UnitCreatureType(t) == "Нежить" or UnitCreatureType(t) == "Демон") and not IsOneUnit("focus",t) then
            RunMacroText("/focus " .. t)
            return
        end
    end
       
    if IsArena() and IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
        if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
        if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
    end
    
    if IsAttack() or InCombatLockdown() then RunMacroText("/startattack")  end
end

------------------------------------------------------------------------------------------------------------------
local tryShieldTime = 0
function TryProtect()
    if InCombatLockdown() then
        if (UnitHealth100() < 90 and not (HasBuff("Крепнущая броня"))) then
            if UseEquippedItem("Клятва Эйтригга") then return true end
        end
        
        if HasSpell("Щит мстителя") and UnitHealth100() < 80 and DoSpell("Святая клятва") then return end
        
        if (UnitHealth100() < 50 and not (HasBuff("Затвердевшая кожа"))) then
            if UseEquippedItem("Проржавевший костяной ключ") then return true end
        end
        
        -- if HasSpell("Удар воина Света") and (UnitHealth100() < 50) and DoSpell("Священная жертва") then return end
        
        if GetTime() - tryShieldTime > 5 then 
        
            if HasSpell("Удар воина Света") and (UnitHealth100() < 20) then 
                if DoSpell("Божественный щит") then 
                    tryShieldTime = GetTime()
                    return true 
                end
                if IsReadySpell("Божественный щит") then return false end
            end
            
            if not IsPvP() and (UnitHealth100() < 15) and DoSpell("Божественная защита") then 
                tryShieldTime = GetTime()
                return true 
            end   
        end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
local InterruptTime = 0
function TryInterrupt(target)
    if (GetTime() - InterruptTime < 1) then return false end 
    
    if target == nil then target = "target" end
    
    if not IsValidTarget(target) then return false end

    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
    end
    
    if not spell then return false end
    
    if IsPvP() and not (IsFinishHim(target) and InInterruptRedList(spell)) then return false end

    local time = endTime/1000 - GetTime()
    if time < 0.1 or time > 1.8 then 
        return false 
    end
    m = " -> " .. spell .. " ("..target..")"
    
    if not notinterrupt then 
        if HasSpell("Удар воина Света") and CanControl(target) and DoSpell("Покаяние", target) then 
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

------------------------------------------------------------------------------------------------------------------
local TauntTime = 0
function TryTaunt(target)
 if (GetTime() - TauntTime < 1.5) then return false end
 if not CanAttack(target) then return false end
 if UnitIsPlayer(target) then return false end
 
 local tt = UnitName(target .. "-target")
 if not UnitExists(tt) then return false end
 
 if IsOneUnit("player", tt) then return false end
 -- Снимаем только с игроков, причем только с тех, которые не в черном списке
 local status = false
 for _,u in pairs(UNITS) do
    if not IsOneUnit("player", u) and not IsIgnored(u) and UnitThreat(u,target) == 3 then 
        status = true 
        break
    end
 end
 if not status then return false end
 
 if DoSpell("Длань возмездия", target) then 
     TauntTime = GetTime()
     -- chat("Длань возмездия на " .. UnitName(target))
     return true  
 end

 if not IsReadySpell("Длань возмездия") and IsInteractUnit(tt) and DoSpell("Праведная защита", tt) then 
     TauntTime = GetTime()
     -- chat("Праведная защита на " .. UnitName(tt))
     return true  
 end
 return false
end