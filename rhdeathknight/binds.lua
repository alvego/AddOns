-- Warrior Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffC79C6EWarrior|r loaded")
-- Binding
BINDING_HEADER_WRH = "DeathKnight Rotation Helper"
BINDING_NAME_WRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_WRH_AUTOTAUNT = "Авто Taunt"
BINDING_NAME_WRH_AUTOAOE = "Вкл/Выкл авто AOE"
------------------------------------------------------------------------------------------------------------------
local nointerruptBuffs = {"Мастер аур"}
if CanInterrupt == nil then CanInterrupt = true end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON")
    else
        echo("Interrupt: OFF")
    end
end

function TryInterrupt(pvp, melee)

    if not CanInterrupt then return false end

    local target = "target"
    local focus = "focus"

    local spell, left, duration, channel, nointerrupt = UnitIsCasting(target)
    if not spell then return nil end
    if left < (channel and 0.5 or 0.2) then  return  end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик

    local name = (UnitName(target)) or target

    if pvp and not tContains(InterruptList, spell) then return false end
    if pvp and tContains(HealList, spell) and (not IsValidTarget(target) or UnitHealth100(target) > 70) and (not IsValidTarget(focus) or UnitHealth100(focus) > 70) then return false end

    if not notinterrupt and not HasBuff(nointerruptBuffs, 0.1, target) and CanMagicAttack(target) then
        if (channel or left < 0.8) and InMelee(target) and DoSpell("Заморозка разума", target) then
            echo("Заморозка разума "..name)
            return true
        end
        if (not channel and left < 1.8) and DoSpell("Удушение", target) then
            echo("Удушение "..name)
            return true
        end
    end

    if CanAttack(target) and (channel or left < 0.8) and (UnitIsPlayer(target) or not IsInGroup()) and DoSpell("Хватка смерти", target) then
        echo("Хватка смерти"..name)
        return true
    end


    return false
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
local spellRunes = {
    ["Ледяные оковы"] = 010,
    ["Ледяное прикосновение"] = 010,
    ["Удар чумы"] = 001,
    ["Вскипание крови"] = 100,
    ["Кровавый удар"] = 100,
    ["Удар смерти"] = 011,
    ["Удар Плети"] = 011,
    ["Уничтожение"] = 011,
    ["Костяной щит"] = 001,
    ["Захват рун"] = 100,
    ["Мор"] = 100,
    ["Войско мертвых"] = 111,
    ["Смерть и разложение"] = 111,
    ["Власть крови"] = 100,
    ["Власть льда"] = 010,
    ["Власть нечестивости"] = 001,
    ["Врата смерти"] = 001,
    ["Зона антимагии"] = 001,
    ["Удушение"] = 100,
    ["Удар в сердце"] = 100,
}
------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target)
    local runes = spellRunes[spellName]
    if runes ~= nil and not HasRunes(runes) then return false end
    return UseSpell(spellName, target)
end
------------------------------------------------------------------------------------------------------------------

function HasRunes(runes, strong, time)
    local r = floor(runes / 100)
    local g = floor((runes - r * 100) / 10)
    local b = floor(runes - r * 100 - g * 10)
    local a = 0

    for i = 1, 6 do
        if IsRuneReady(i, time) then
            local t = select(1,GetRuneType(i))
            if t == 1 then r = r - 1 end
            if t == 2 then g = g - 1 end
            if t == 3 then b = b - 1 end
            if t == 4 then a = a + 1 end
        end
    end

    if r < 0 then r = 0 end
    if g < 0 then g = 0 end
    if b < 0 then b = 0 end
    if strong then a = 0 end
    if r + g + b - a <= 0 then return true end
    return false;
end
------------------------------------------------------------------------------------------------------------------
local function updateDamage(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, damage = ...
    if type:match("_DAMAGE") and destGUID == UnitGUID("player") then --SWING_DAMAGE
        TimerStart("Damage")
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateDamage)
