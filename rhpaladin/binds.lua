-- Paladin Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |cffff4080Paladin|r loaded!")
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
