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

local nointerruptBuffs = {"Мастер аур", "Дубовая кожа"}
local sheepSpell = {"Превращение", "Сглаз"}
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
    
    if CanAttack(target) and (channel or t < 0.8) and UnitIsPlayer(target) and DoSpell("Хватка смерти", target) then 
        echo("Хватка смерти"..m)
        interruptTime = GetTime()
        return true 
    end

    if GetUnitName("player") == GetUnitName(target .. "-target") and DoSpell("Антимагический панцирь") then 
        echo("Антимагический панцирь"..m)
        interruptTime = GetTime() + 5
        return true 
    end
    
    if HasSpell("Перерождение") and tContains(sheepSpell, spell) and DoSpell("Перерождение") then 
        echo("Перерождение"..m)
        interruptTime = GetTime() + 2
        return true 
    end
end
------------------------------------------------------------------------------------------------------------------
function UpdateAutoFreedom(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel = select(1, ...)
    if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)
        and err and err:match("Действие невозможно")  
        and (HasDebuff(ControlList, 3.8, "player") or not IsPvP()) then DoCommand("freedom") end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateAutoFreedom)

------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target, runes)
    return UseSpell(spellName, target)
end
