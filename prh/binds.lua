-- Paladin Rotation Helper by Timofeev Alexey & Co
------------------------------------------------------------------------------------------------------------------
-- Binding
BINDING_HEADER_PRH = "Paladin Rotation Helper"
BINDING_NAME_PRH_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_PRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_PRH_AUTOAGGRO = "Авто АГГРО"
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
if AutoAGGRO == nil then AutoAGGRO = true end

function AutoAGGROToggle()
    AutoAGGRO = not AutoAGGRO
    if AutoAGGRO then
        echo("АвтоАГГРО: ON",true)
    else
        echo("АвтоАГГРО: OFF",true)
    end 
end

------------------------------------------------------------------------------------------------------------------
function IsAOE()
   if IsShiftKeyDown() == 1 then return true end
   return (IsValidTarget("target") and InMelee("target")
    and IsValidTarget("focus") and InMelee("focus")
    and not IsOneUnit("target", "focus"))
end

------------------------------------------------------------------------------------------------------------------
if DispelBlacklist == nil then DispelBlacklist = {} end
if DispelWhitelist == nil then DispelWhitelist = {} end
local dispelTime = GetTime()
local dispelSpell = "Очищение"
local dispelType = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true}
function TryDispel(unit)
    if GetTime() - dispelTime < 2 then return false end
    if not IsReadySpell(dispelSpell) or InGCD() then return false end
    if not CanHeal(unit) then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) 
                and (DispelWhitelist[name] or dispelType[debuffType] and not DispelBlacklist[name]) then
                if DoSpell(dispelSpell, unit) then 
                    dispelTime = GetTime()
                    ret = true 
                end
            end
        end
    end
    return ret
end

local function UpdateDispelLists(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel = select(1, ...)
    local unit = GetLastSpellTarget(dispelSpell)
    if sourceGUID == UnitGUID("player")
        and spellId and spellName and spellName == dispelSpell then
        
        if type:match("^SPELL_CAST") 
            and unit and GetTime() - dispelTime < 1
            and err and err == "Нечего рассеивать." then
            for i = 1, 40 do
                local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
                if name and dispelType[debuffType] then
                    DispelBlacklist[name] = true
                end
            end
        end
        
        if type == "SPELL_DISPEL" and dispel then
            DispelWhitelist[dispel] = true
            --print("Рассеян", dispel)
        end
    end
end    

AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateDispelLists)

------------------------------------------------------------------------------------------------------------------
local ForbearanceTime = 0
function InForbearance(unit)
    if unit == nil then unit = "player" end
    return ((GetTime() - ForbearanceTime < 30) or HasDebuff("Воздержанность", 0.01, unit))
end

local function UpdateForbearanceTime(event, ...)
    local unit, spell = select(1, ...)
    if unit == "player" and spell == "Гнев карателя" then 
        ForbearanceTime = GetTime() 
    end
end
AttachEvent("UNIT_SPELLCAST_SUCCEEDED", UpdateForbearanceTime)

------------------------------------------------------------------------------------------------------------------

function DoSpell(spellName, target)
    if tContains({"Гнев карателя", "Божественный щит", "Возложение рук", "Божественная защита", "Длань защиты"}, spellName) and InForbearance(target) then return false end
    return UseSpell(spellName, target)
end
