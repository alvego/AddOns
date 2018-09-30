-- Warrior Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cff0080bfMage|r loaded")
-- Binding
BINDING_HEADER_WRH = "Mage Rotation Helper"
BINDING_NAME_WRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON")
    else
        echo("Interrupt: OFF")
    end
end

local nointerruptBuffs = {"Мастер аур"}
function TryInterrupt()
    if not CanInterrupt then return false end
    local target = "target"
    local focus = "focus"
    local spell, left, duration, channel, nointerrupt = UnitIsCasting(target)
    if not spell then return nil end
    if left < (channel and 0.5 or 0.2) then  return  end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
    local name = (UnitName(target)) or target
    local pvp = IsPvP()
    if pvp and not tContains(InterruptList, spell) then return false end
    if pvp and tContains(HealList, spell) and (not IsValidTarget(focus) or UnitHealth100(focus) > 50) then return false end
    if not notinterrupt and not HasBuff(nointerruptBuffs, 0.1, target) then
        if (channel or left < 0.8) and InMelee(target) and DoSpell("Антимагия", target) then
            echo("Антимагия "..name)
            return true
        end
    end
    return false
end
-----------------------------------------------------------------------------------------------------------------
local function updateDamage(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, damage = ...
    if type:match("_DAMAGE") and destGUID == UnitGUID("player") then --SWING_DAMAGE
        TimerStart("Damage")
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateDamage)
------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target)
  return UseSpell(spellName, target)
end
