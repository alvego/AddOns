-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffFF7D0ADruid|r loaded")
-- Binding
BINDING_HEADER_DRH = "Druid Rotation Helper"
BINDING_NAME_WRH_AUTOAOE = "Вкл/Выкл авто AOE"
------------------------------------------------------------------------------------------------------------------
if AutoAOE == nil then AutoAOE = true end
function AutoAOEToggle()
    AutoAOE = not AutoAOE
    echo("Авто АОЕ: " .. ( AutoAOE and "ON" or "OFF" ))
end
------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target)
  return UseSpell(spellName, target)
end
