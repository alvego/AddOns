-- Paladin Rotation Helper 2 by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |cffff4080Paladin|r 2 loaded!")
-- Binding
BINDING_HEADER_PRH = "Paladin Rotation Helper 2"
BINDING_NAME_PRH_AUTOTAUNT = "Авто Taunt"
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
if not AggroIgnored then AggroIgnored = {} end
------------------------------------------------------------------------------------------------------------------
function InForbearance(unit)
    if unit == nil then unit = "player" end
    return ((GetTime() - GetSpellLastTime("Гнев карателя") < 30) or HasDebuff("Воздержанность", 0.01, unit))
end
------------------------------------------------------------------------------------------------------------------
local forbearanceSpells = {"Гнев карателя", "Божественный щит", "Возложение рук", "Божественная защита", "Длань защиты"}
function DoSpell(spellName, target)

    if tContains(forbearanceSpells, spellName) and InForbearance(target) then return false end

    return UseSpell(spellName, target)
end
