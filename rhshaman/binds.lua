-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Binding
BINDING_HEADER_SRH = "Shaman Rotation Helper"
BINDING_NAME_SRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_SRH_AUTOAOE = "Вкл/Выкл авто AOE"
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

if AutoAOE == nil then AutoAOE = true end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON")
    else
        echo("Авто АОЕ: OFF")
    end
end


function IsAOE()
   return IsShift()
end

------------------------------------------------------------------------------------------------------------------
function IsBurst()
   return IsCtrl()
end

------------------------------------------------------------------------------------------------------------------

function IsMDD()
    return HasSpell("Бой двумя оружиями")
end

function IsRDD()
    return HasSpell("Гром и молния")
end

function IsHeal()
    return HasSpell("Быстрина")
end

------------------------------------------------------------------------------------------------------------------
local interruptSpell = "Пронизывающий ветер"
function TryInterrupt(target)
    if target == nil then target = "target" end
    if IsPvP() then return false end
    if not IsValidTarget(target) then return false end
    local channel = false

    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
    if not spell then
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    if not spell then return false end
    if not CanInterrupt then return false end
    local t = endTime/1000 - GetTime()
    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end

    if (channel or t < 0.8) and not notinterrupt and IsReadySpell(interruptSpell) and InRange(interruptSpell,target)
        and not HasBuff(nointerruptBuffs, 0.1, target) and CanMagicAttack(target) then
        if UseSpell(interruptSpell, target) then
            echo("Interrupt " .. spell .. " ("..target.." => " .. UnitName(target) .. ")")
            return true
        end
    end

    if (not channel and t < 1.8) and not HasTotem("Тотем заземления") and IsReadySpell("Тотем заземления")
        and IsHarmfulCast(spell) then

        if UseSpell("Тотем заземления") then
            echo("Тотем заземления " .. spell .. " (".. UnitName(target) .. ")")
            return true
        end
    end

    return false
end
------------------------------------------------------------------------------------------------------------------

function DoSpell(spell, target)
    return UseSpell(spell, target)
end
