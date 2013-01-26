-- Sova Rotation Helper by Timofeev Alexey & Co
------------------------------------------------------------------------------------------------------------------
-- Binding
BINDING_HEADER_SOVA = "Sova Rotation Helper"
BINDING_NAME_SOVA_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_SOVA_AUTOAGGRO = "Авто АГГРО"

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
    return IsValidTarget("target") and InMelee("target") and TryEach(TARGETS, function(t)
        return IsValidTarget(t) and InMelee(t) and not IsOneUnit("target", t)
    end)
end

------------------------------------------------------------------------------------------------------------------
--[[-- dispel
if DispelBlacklist == nil then DispelBlacklist = {} end
if DispelWhitelist == nil then DispelWhitelist = {} end
local dispelSpell = "Очищение"
local dispelTypes = {"Poison", "Disease", "Magic"}
function TryDispel(unit)
    if not IsReadySpell(dispelSpell) or InGCD() or not CanHeal(unit) or HasDebuff("Нестабильное колдовство", 0.1, unit) then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) 
                and (tContains(DispelWhitelist, name) or tContains(dispelTypes, debuffType) and not tContains(DispelBlacklist, name)) then
                if DoSpell(dispelSpell, unit) then 
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

        if type:match("^SPELL_CAST") and unit and err and err == "Нечего рассеивать." then
            for i = 1, 40 do
                local name, _, _, _, debuffType = UnitDebuff(unit, i,true) 
                if name and tContains(dispelTypes, debuffType)
                    and not tContains(DispelWhitelist, name)
                    and not tContains(DispelBlacklist, name) then
                    tinsert(DispelBlacklist, name)
                end
            end
        end
        
        if type == "SPELL_DISPEL" and not tContains(DispelWhitelist, dispel) then
            tinsert(DispelWhitelist, dispel)
        end
    end
end    

AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateDispelLists)]]

------------------------------------------------------------------------------------------------------------------

function DoSpell(spellName, target)
    return UseSpell(spellName, target)
end
