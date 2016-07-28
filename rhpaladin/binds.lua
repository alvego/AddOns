-- Paladin Rotation Helper by Timofeev Alexey & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |cffff4080Paladin|r loaded!")
-- Binding
BINDING_HEADER_PRH = "Paladin Rotation Helper"
BINDING_NAME_PRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_PRH_AUTOAGGRO = "Авто АГГРО"
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

function TryInterrupt(target)
    if not CanInterrupt then return false end
    if target == nil then target = "target" end
    --if not CanAttack(target) then return end
    local channel = false
    -- name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")
    local spell, _, _, _, startTime, endTime, _, _, notinterrupt = UnitCastingInfo(target)
    if not spell then
        --name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("unit")
        spell, _, _, _, startTime, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    if not spell then return nil end
    local s = startTime / 1000 -- время начала каста
    local c = GetTime() -- текущее время
    local e = endTime / 1000 -- время конца каста
    local t = e - c -- осталось до конца каста
    if t < (channel and 0.5 or 0.2) then  return  end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
    local name = UnitName(target)
    name = name or target
    local m = " -> " .. spell .. " ("..name..")"

    if not notinterrupt then

        if (channel or t < 0.8) and DoSpell("Молот правосудия", target) then
            print("Молот правосудия"..m)
            return true
        end

    end
    return false
end

------------------------------------------------------------------------------------------------------------------
if AutoAGGRO == nil then AutoAGGRO = true end

function AutoAGGROToggle()
    AutoAGGRO = not AutoAGGRO
    if AutoAGGRO then
        echo("АвтоАГГРО: ON")
    else
        echo("АвтоАГГРО: OFF")
    end
end

------------------------------------------------------------------------------------------------------------------
function IsAOE()
    if IsShiftKeyDown() == 1 then return true end
    return false
end

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
