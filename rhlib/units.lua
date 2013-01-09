-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- unit filted start
local IgnoredNames = {}

function Ignore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then 
        Notify(target .. " not exists")
        return 
    end
    IgnoredNames[n] = true
    Notify("Ignore " .. n)
end

function IsIgnored(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil or not IgnoredNames[n] then return false end
    -- Notify(n .. " in ignore list")
    return true
end

function NotIgnore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n then 
        IgnoredNames[n] = false
        Notify("Not ignore " .. n)
    end
end

function NotIgnoreAll()
    wipe(IgnoredNames)
    Notify("Not ignore all")
end
-- unit filted start end

------------------------------------------------------------------------------------------------------------------
function GetUnitNames()
    local units = {"player", "target", "focus" }
    local members = GetPartyOrRaidMembers()
    for i = 1, #members, 1 do 
        table.insert(units, members[i])
        table.insert(units, members[i] .."pet")
    end
    table.insert(units, "mouseover")
    realUnits = {}
    for i = 1, #units, 1 do 
        local u = units[i]
        local exists = false
        for j = 1, #realUnits, 1 do
            if UnitName(u) and IsOneUnit(realUnits[j], u) then exists = true end
        end
        local d = CheckDistance(u, "player")
        if not exists and ((not d or d < 40) or IsArena()) then table.insert(realUnits, u) end
    end
    return realUnits
end

------------------------------------------------------------------------------------------------------------------
function GetPartyOrRaidMembers()
    local members = {}
    local group = "party"
    if GetNumRaidMembers() > 0 then group = "raid" end
    for i = 1, 40, 1 do 
        if UnitExists(group..i) and UnitName(group..i) ~= nil then table.insert(members, group..i) end
    end
--~     table.sort(members, function(u1, u1) return (UnitThreatSituation(u1) > UnitThreatSituation(u2)) end)
    return members
end

------------------------------------------------------------------------------------------------------------------
function GetHarmTarget()
    local units = {"target","mouseover","focus","arena1","arena2","arena3","arena4","arena5","bos1","bos2","bos3","bos4"}
    local members = GetPartyOrRaidMembers()
    for i = 1, #members, 1 do 
         table.insert(units, members[i] .."-target")
    end
    realUnits = {}
    for i = 1, #units, 1 do 
        local u = units[i]
        local exists = false
        for j = 1, #realUnits, 1 do
            if IsOneUnit(realUnits[j], u) then exists = true end
        end
        if not exists and IsValidTarget(u) and (IsArena() or CheckInteractDistance(u, 1)) then 
			table.insert(realUnits, u) 
		end
    end
    return realUnits
end

------------------------------------------------------------------------------------------------------------------
function IsValidTarget(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then return false end
    if IsIgnored(target) then return false end
    if UnitIsDeadOrGhost(target) then return false end
    if UnitIsEnemy("player",target) and UnitCanAttack("player", target) then return true end 
    if (UnitInParty(target) or UnitInRaid(target)) then return false end 
    return UnitCanAttack("player", target)
end

function IsInteractTarget(t)
    if IsValidTarget(t) then return false end
    if UnitExists(t) 
        and not IsIgnored(t) 
        and not UnitIsCharmed(t)
        and not UnitIsDeadOrGhost(t) 
        and not UnitIsEnemy("player",t)
        and UnitIsConnected(t)
    then return true end 
    return false
end

------------------------------------------------------------------------------------------------------------------
function BlizzName(unit)
    if not unit or not UnitExists(unit) then return nil end
    local guid = UnitGUID(unit)
    local blizz = nil
    local members = GetUnitNames()
    for i=1,#members do 
        if not blizz and UnitGUID(members[i]) == guid then return members[i] end
    end
    local targets = GetHarmTarget()
    for i=1,#targets do 
        if not blizz and UnitGUID(targets[i]) == guid then return targets[i] end
    end
    return blizz
end

------------------------------------------------------------------------------------------------------------------
function GetClass(target)
    if not target then target = "player" end
    local _, class = UnitClass(target)
    return class
end

------------------------------------------------------------------------------------------------------------------
function HasClass(units, classes) 
    local ret = false
    for _,u in pairs(units) do 
        if UnitExists(u) and UnitIsPlayer(u) and tContains(classes, GetClass(u)) then 
            ret = true 
        end 
    end
    return ret 
end

------------------------------------------------------------------------------------------------------------------
function GetUnitType(target)
    if not target then target = "target" end
    local unitType = UnitName(target)
    if UnitIsPlayer(target) then
        unitType = GetClass(target)
    end
    if UnitIsPet(target) then
        unitType ='PET'
    end
    return unitType
end

------------------------------------------------------------------------------------------------------------------
function UnitIsNPC(unit)
    return not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack("player", unit));
end

------------------------------------------------------------------------------------------------------------------
function UnitIsPet(unit)
    return not UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit);
end

------------------------------------------------------------------------------------------------------------------
function IsOneUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return false end
    return UnitGUID(unit1) == UnitGUID(unit2)
end

------------------------------------------------------------------------------------------------------------------
function UnitThreat(u, t)
    local threat = UnitThreatSituation(u, t)
    if threat == nil then threat = 0 end
    return threat
end

------------------------------------------------------------------------------------------------------------------
function UnitThreatAlert(u)
    local threat, target = UnitThreat(u), format("%s-target", u)
    if UnitAffectingCombat(target) 
        and UnitIsPlayer(target) 
        and IsValidTarget(target) 
        and IsOneUnit(u, target .. "-target") then threat = 3 end
    return threat
end

------------------------------------------------------------------------------------------------------------------
function UnitHealth100(target)
    if target == nil then target = "player" end
    return UnitHealth(target) * 100 / UnitHealthMax(target)
end

------------------------------------------------------------------------------------------------------------------
function UnitMana100(target)
    if target == nil then target = "player" end
    return UnitMana(target) * 100 / UnitManaMax(target)
end

------------------------------------------------------------------------------------------------------------------
local HealComm = LibStub("LibHealComm-4.0")
function UnitGetIncomingHeals(target, s)
    if not target then 
        target = "player" 
    end
    if not s then 
        if UnitHealth100(target) < 10 then return 0 end
        s = 4
        if UnitThreatSituation(target) == 3 then s = 2 end
    end
    return HealComm:GetHealAmount(UnitGUID(target), HealComm.CASTED_HEALS, GetTime() + s) or 0
end

------------------------------------------------------------------------------------------------------------------
function CalculateHP(t)
  return 100 * UnitHP(t) / UnitHealthMax(t)
end

------------------------------------------------------------------------------------------------------------------
function UnitLostHP(unit)
    local hp = UnitHP(unit)
    local maxhp = UnitHealthMax(unit)
    local lost = maxhp - hp
    if UnitThreat(unit) == 3 then lost = lost * 1.2 end
    return lost
end

------------------------------------------------------------------------------------------------------------------
function UnitHP(t)
  local incomingheals = UnitGetIncomingHeals(t)
  local hp = UnitHealth(t) + incomingheals
  if hp > UnitHealthMax(t) then hp = UnitHealthMax(t) end
  return hp
end

------------------------------------------------------------------------------------------------------------------
function InGroup()
    return (InRaid() or InParty())
end

------------------------------------------------------------------------------------------------------------------
function InRaid()
    return (GetNumRaidMembers() > 0)
end

------------------------------------------------------------------------------------------------------------------
function InParty()
    return (GetNumPartyMembers() > 0)
end

------------------------------------------------------------------------------------------------------------------
function IsBattleground()
    local inInstance, instanceType = IsInInstance()
    return (inInstance ~= nil and instanceType =="pvp")
end

------------------------------------------------------------------------------------------------------------------
function IsArena()
    local inInstance, instanceType = IsInInstance()
    return (inInstance ~= nil and instanceType =="arena")
end

------------------------------------------------------------------------------------------------------------------
function IsPvP()
    return (IsBattleground() or IsArena() or (IsValidTarget("target") and UnitIsPlayer("target")))
end

------------------------------------------------------------------------------------------------------------------
-- не за спиной цели
local notBehindTarget = 0
function IsNotBehindTarget()
    return GetTime() - notBehindTarget < 1
end

--~ Цель вне поля зрения.
local notVisible = {}
function IsVisible(target)
    if not target or target == "player"  then return true end
    if not UnitIsVisible(target) then return false end
    local t = notVisible[target]
    if t and GetTime() - t < 1 then return false end
    return true;
end

local function UpdateTargetPosition(event, ...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, agrs12, agrs13,agrs14 = select(1, ...)
    if sourceGUID == UnitGUID("player") and (event:match("^SPELL_CAST") and spellID and spellName)  then
        local err = agrs12
        if err then
            if err == "Цель вне поля зрения." then
                local partyName = BlizzName(lastTarget)
                if partyName then
                    notVisible[partyName] = GetTime()
                end
            end
            if err == "Вы должны находиться позади цели." then notBehindTarget = GetTime() end
        end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateTargetPosition)
------------------------------------------------------------------------------------------------------------------