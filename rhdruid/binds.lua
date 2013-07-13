-- Druid Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_DRH = "Druid Rotation Helper"
BINDING_NAME_DRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_DRH_AUTO_AOE = "Авто AOE"
print("Druid Rotation Helper loaded")
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
if AutoAOE == nil then AutoAOE = true end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON",true)
    else
        echo("Авто АОЕ: OFF",true)
    end 
end
------------------------------------------------------------------------------------------------------------------
local role = 3 
function IsTank() return (role == 1) end
function IsDD() return (role == 2) end
function IsHeal() return (role == 3) end

local roleNames =  {"Танк", "ДД", "Хил"}
function RoleName() return roleNames[role] end
function Role(r)
    role = r
    Notify(RoleName())
end

function RoleTank() Role(1) end
function RoleDD() Role(2) end
function RoleHeal() Role(3) end

local function UpdateRole(event, ...)
    if HasSpell("Буйный рост") or HasBuff("Древо Жизни") then 
        RoleHeal() 
    else
        if HasBuff("Облик лютого медведя") then 
            RoleTank() 
        else
            RoleDD()
        end
    end
end    
AttachEvent("PLAYER_ENTERING_WORLD", UpdateRole)
AttachEvent("ACTIVE_TALENT_GROUP_CHANGED", UpdateRole)

------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target, mana)
    return UseSpell(spell, target, mana)
end
