-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffFF7D0ADruid 2|r loaded")
-- Binding
BINDING_HEADER_DRH = "Druid 2 Rotation Helper"
BINDING_NAME_DRH_AUTOTAUNT = "Авто Taunt"
BINDING_NAME_DRH_AUTOAOE = "Вкл/Выкл авто AOE"
BINDING_NAME_DRH_AUTOBERS = "Вкл/Выкл авто BERS"
BINDING_NAME_DRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
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
------------------------------------------------------------------------------------------------------------------
if AutoBers == nil then AutoBers = true end

function AutoBersToggle()
    AutoBers = not AutoBers
    if AutoBers then
        echo("Авто Bers: ON")
    else
        echo("Авто Bers: OFF")
    end
end

------------------------------------------------------------------------------------------------------------------
if AutoAOE == nil then AutoAOE = true end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON")
    else
        echo("Авто АОЕ: OFF")
    end
end
------------------------------------------------------------------------------------------------------------------
if AutoTaunt == nil then AutoTaunt = true end

function AutoTauntToggle()
    AutoTaunt = not AutoTaunt
    if AutoTaunt then
        echo("Авто Taunt: ON")
    else
        echo("Авто Taunt: OFF")
    end
end
------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target)
  return UseSpell(spellName, target)
end
------------------------------------------------------------------------------------------------------------------
local function updateDamage(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, damage = ...
    if type:match("SWING_DAMAGE") and destGUID == UnitGUID("player") then --SWING_DAMAGE
        TimerStart("Damage")
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateDamage)
------------------------------------------------------------------------------------------------------------------
