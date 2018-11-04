-- Death Knight Helper 2 by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |cff800000Death Knight|r 2 loaded.")
-- Binding
BINDING_HEADER_WRH = "DeathKnight Rotation Helper 2"
BINDING_NAME_WRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_WRH_AUTOTAUNT = "Авто Taunt"
BINDING_NAME_WRH_AUTOAOE = "Вкл/Выкл авто AOE"
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
------------------------------------------------------------------------------------------------------------------
