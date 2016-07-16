-- Hunter Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Binding
BINDING_HEADER_HRH = "Hunter Rotation Helper"
BINDING_NAME_HRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end
end
------------------------------------------------------------------------------------------------------------------


function IsAOE()
   return (IsShiftKeyDown() == 1)
end

------------------------------------------------------------------------------------------------------------------
local interruptSpell = "Встречный выстрел"
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
        and not HasBuff(nointerruptBuffs, 0.1, target) and CanMagicAttack(target) then -- Magic?
        if HasSpell(interruptSpell) and  UseSpell(interruptSpell, target) then
            echo("Interrupt " .. spell .. " ("..target.." => " .. UnitName(target) .. ")")
            return true
        end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------

function DoSpell(spell, target)
    return UseSpell(spell, target)
end
