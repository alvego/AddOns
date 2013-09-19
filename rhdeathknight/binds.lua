-- Death Knight Rotation Helper by Timofeev Alexey
print("|cff0055ffRotation Helper|r|cffffe00a > |cff800000Death Knight|r loaded.")
-- Binding
BINDING_HEADER_RHDEATHKNIGHT = "Death Knight Rotation Helper"
BINDING_NAME_RHDEATHKNIGHT_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_RHDEATHKNIGHT_INTERRUPT = "Вкл/Выкл сбивание кастов"
------------------------------------------------------------------------------------------------------------------
if CanAOE == nil then CanAOE = true end

function AOEToggle()
    CanAOE = not CanAOE
    if CanAOE then
        echo("AOE: ON",true)
    else
        echo("AOE: OFF",true)
    end 
end

function IsAOE()
   if not CanAOE then return false end
   if IsShiftKeyDown() == 1 then return true end
   return (IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and Dotes(7) and Dotes(7, "focus"))
end

------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function InterruptToggle()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end 
end

------------------------------------------------------------------------------------------------------------------
function IsNeedTaunt()
    return  IsMouseButtonDown(5) == 1
end

------------------------------------------------------------------------------------------------------------------

local nointerruptBuffs = {"Мастер аур", "Дубовая кожа"}
local lichSpells = {"Превращение", "Сглаз", "Соблазн", "Страх", "Вой ужаса", "Контроль над разумом"}
local conrLichSpells = {"Изгнание зла", "Сковывание нежити"}
function TryInterrupt(target)
    if target == nil then target = "target" end
    if not IsValidTarget(target) then return false end
    local channel = false
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    
    if not spell then return false end

    if tContains(conrLichSpells, spell) then RunMacroText("/cancelaura Перерождение") end

    if IsPvP() and not InInterruptRedList(spell) then return false end
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end

    m = " -> " .. spell .. " ("..target..")"
    
    if not notinterrupt and not HasBuff(nointerruptBuffs, 0.1, target) and CanMagicAttack(target) then 
        if (channel or t < 0.8) and InMelee(target) and DoSpell("Заморозка разума", target) then 
            echo("Заморозка разума"..m)
            interruptTime = GetTime()
            return true 
        end
        if (not channel and t < 1.8) and HasRunes(100) and DoSpell("Удушение", target) then 
            echo("Удушение"..m)
            interruptTime = GetTime()
            return true 
        end
    end
    

    if HasSpell("Отгрызть") and IsReadySpell("Отгрызть") and CanAttack(target) and (channel or t < 0.8) then 
        if IsReadySpell("Прыжок") and InRange("Прыжок", target) then UseSpell("Прыжок", target) end
        RunMacroText("/cast [@" ..target.."] Прыжок")
        RunMacroText("/cast [@" ..target.."] Отгрызть")
        if not IsReadySpell("Отгрызть") then
            echo("Отгрызть"..m)
            interruptTime = GetTime()
            return false 
        end
    end

    if CanAttack(target) and (channel or t < 0.8) and UnitIsPlayer(target) and DoSpell("Хватка смерти", target) then 
        echo("Хватка смерти"..m)
        interruptTime = GetTime()
        return true 
    end

    if IsPvP() and IsHarmfulSpell(spell) and IsOneUnit("player", target .. "-target") and DoSpell("Антимагический панцирь") then 
        echo("Антимагический панцирь"..m)
        interruptTime = GetTime() + 5
        return true 
    end
    
    if HasSpell("Перерождение") and IsOneUnit("player",target .. "-target") and tContains(lichSpells, spell) and DoSpell("Перерождение") then 
        echo("Перерождение"..m)
        interruptTime = GetTime() + 2
        return true 
    end
end
------------------------------------------------------------------------------------------------------------------
local lichList = {
"Сон",
"Соблазн",
"Страх", 
"Вой ужаса", 
"Устрашающий крик", 
"Контроль над разумом", 
"Глубинный ужас", 
"Ментальный крик"
}

    
ExceptionControlList = { -- > 4
"Ошеломление", -- 20s
}

local freedomTime = 0
function UpdateAutoFreedom(event, ...)
    if GetTime() - freedomTime < 1.5 then return end
    if HasDebuff(lichList, 2, "player") then 
        if HasSpell("Перерождение") and IsReadySpell("Перерождение") then
            print("lich")
            DoCommand("lich") 
        else
            if not HasBuff("Перерождение") then  
                print("lich->freedom")
                DoCommand("freedom") 
            end
        end
        freedomTime = GetTime()
        return
    end 
    if HasDebuff(ControlList, 2, "player") and (not HasDebuff(ExceptionControlList) or IsAttack()) then 
        print("freedom")
        DoCommand("freedom") 
        freedomTime = GetTime()
        return
    end 
end
AttachUpdate(UpdateAutoFreedom, -1)
------------------------------------------------------------------------------------------------------------------
local physicDamage = {
    "Вихрь клинков", 
    "Гнев карателя",
}
local magicDamage = {
    "Стылая кровь",
    "Гнев карателя",
    "Призыв горгульи"
}
local checkedTargets = {"target", "focus", "arena1", "arena2", "mouseover"}
local defPhys = 0
local defMagic = 0;
function UpdateDefense()
    if GetTime() - defPhys < 5 then 
        DoSpell("Незыблемость льда")
        if Runes(2) > 0 and not HasBuff("Власть льда") then DoSpell("Власть льда") end
    end
    if GetTime() - defMagic < 5 then 
        if not not HasBuff("Зона антимагии") then DoSpell("Антимагический панцирь") end

        if HasSpell("Зона антимагии") and (IsSpellInUse("Антимагический панцирь") and not HasBuff("Антимагический панцирь")) then
            DoSpell("Зона антимагии")
        end
    end
end
AttachUpdate(UpdateDefense, -1)

function CheckDefense(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
    
    for i=1,#checkedTargets do
        local t = checkedTargets[i]
        if IsValidTarget(t) and UnitGUID(t) == sourceGUID and (IsOneUnit("player", t .. "-target") or InMelee(t)) then
            if tContains(physicDamage, spellName) then defPhys = GetTime() end
            if tContains(magicDamage, spellName) then defMagic = GetTime() end
            break
        end
    end

end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", CheckDefense)
------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target, runes)
    return UseSpell(spellName, target)
end
