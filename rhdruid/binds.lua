-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffFF7D0ADruid|r loaded")
-- Binding
BINDING_HEADER_DRH = "Druid Rotation Helper"
BINDING_NAME_DRH_AUTOHEAL = "Вкл/Выкл авто лечение"
BINDING_NAME_DRH_AUTODISPEL = "Вкл/Выкл авто диспел"
------------------------------------------------------------------------------------------------------------------
if AutoHeal == nil then AutoHeal = true end
function ToggleAutoHeal()
    AutoHeal = not AutoHeal
    echo("Авто Heal: " .. ( AutoHeal and "ON" or "OFF" ))
end
------------------------------------------------------------------------------------------------------------------
if AutoDispel == nil then AutoDispel = true end
function ToggleAutoDispel()
    AutoDispel = not AutoDispel
    echo("Авто Dispel: " .. ( AutoDispel and "ON" or "OFF" ))
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
