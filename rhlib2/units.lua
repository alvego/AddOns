-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Возвращает список членов группы отсортированных по приоритету исцеления
local members = {}
local membersHP = {}
local protBuffsList = {"Ледяная глыба", "Божественный щит", "Превращение", "Щит земли", "Частица Света"}
local dangerousType = {"worldboss", "rareelite", "elite"}
local function compareMembers(u1, u2) 
    return membersHP[u1] < membersHP[u2]
end
function GetHealingMembers(units)
    local myHP = UnitHealth100("player")
    if #members > 0 and UpdateInterval == 0 then
        return members, membersHP
    end
    wipe(members)
    wipe(membersHP)
    if units == nil then units = UNITS end
    for _,u in pairs(units) do
        if CanHeal(u) then 
             local h =  CalculateHP(u)
            if IsFriend(u) then 
                if UnitAffectingCombat(u) and h > 99 then h = h - 1 end
                h = h  - ((100 - h) * 1.15) 
            end
            if UnitIsPet(u) then
                if UnitAffectingCombat("player") then 
                    h = h * 1.5
                end
            else
                local status = 0
                for _,t in pairs(TARGETS) do
                    if tContains(dangerousType, UnitClassification(t)) then 
                        local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", t)
                        if state ~= nil and state > status then status = state end
                    end
                end
                h = h - 2 * status
                if HasBuff(protBuffsList, 1, u) then h = h + 5 end
                if not IsArena() and myHP < 50 and not IsOneUnit("player", u) and not (UnitThreat(u) == 3) then h = h + 30 end
            end
            tinsert(members, u)
            membersHP[u] = h
        end
    end
    table.sort(members, compareMembers)  
    for _,u in pairs(members) do
        if UnitHealth100(u) == 100 then membersHP[u] = 100 end
    end
    return members, membersHP
end
------------------------------------------------------------------------------------------------------------------
-- friend list
function IsFriend(unit)
    if IsOneUnit(unit, "player") then return true end
    if not IsInteractUnit(unit) or not UnitIsPlayer(unit) then return false end
    local numberOfFriends, onlineFriends = GetNumFriends()
    local unitName, isFriend = UnitName(unit), false
    for friendIndex = 1, numberOfFriends do
        local name, level, class, area, connected, status, note = GetFriendInfo(friendIndex);
        if name and name == unitName then isFriend = true end
    end
    return isFriend
end

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
local units = {}
local realUnits = {}
function GetUnits()
	wipe(units)
	tinsert(units, "target")
	tinsert(units, "focus")
	local members = GetGroupUnits()
	for i = 1, #members, 1 do 
		tinsert(units, members[i])
		tinsert(units, members[i] .."pet")
	end
	tinsert(units, "mouseover")
	wipe(realUnits)
    for i = 1, #units do 
        local u = units[i]
        local exists = false
        for _,t in pairs(realUnits) do 
			exists = IsOneUnit(t, u)
			if exists then break end 
		end
        if not exists and InInteractRange(u) then 
			tinsert(realUnits, u) 
		end
    end
    return realUnits
end

------------------------------------------------------------------------------------------------------------------
local groupUnits  = {}
function GetGroupUnits()
	wipe(groupUnits)
	tinsert(groupUnits, "player")
    if not InGroup() then return groupUnits end
    local name = "party"
    local size = MAX_PARTY_MEMBERS
    if InRaid() then
		name = "raid"
		size = MAX_RAID_MEMBERS
    end
    for i = 0, size do 
		tinsert(groupUnits, name..i)
    end
    return groupUnits
end

------------------------------------------------------------------------------------------------------------------
local targets = {}
local realTargets = {}
function GetTargets()
	wipe(targets)
	tinsert(targets, "target")
	tinsert(targets, "focus")
	if IsArena() then
		for i = 1, 5 do 
			 tinsert(targets, "arena" .. i)
		end
	end
	for i = 1, 4 do 
		 tinsert(targets, "boss" .. i)
	end
	local members = GetGroupUnits()
	for i = 1, #members do 
		 tinsert(targets, members[i] .."-target")
		 tinsert(targets, members[i] .."pet-target")
	end
	tinsert(targets, "mouseover")
	wipe(realTargets)
    for i = 1, #targets do 
        local u = targets[i]
        
        local exists = false
        
        for _,t in pairs(realTargets) do 
			exists = IsOneUnit(t, u) 
			if exists then break end 
		end
        
        if not exists and IsValidTarget(u) and (IsArena() or CheckInteractDistance(u, 1) 
                or IsOneUnit("player", u .. '-target')) then 
            tinsert(realTargets, u) 
        end
        
    end
    return realTargets
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

------------------------------------------------------------------------------------------------------------------
function IsInteractUnit(t)
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
function CanHeal(t)
    return InInteractRange(t) and not HasDebuff("Смерч", 0.1, t) and IsVisible(t)
end 
------------------------------------------------------------------------------------------------------------------
function GetClass(target)
    if not target then target = "player" end
    local _, class = UnitClass(target)
    return class
end

------------------------------------------------------------------------------------------------------------------
function HasClass(units, classes)
	for _,u in pairs(units) do
		if UnitExists(u) and UnitIsPlayer(u) and (type(classes) == 'table' and tContains(classes, GetClass(u)) or classes == GetClass(u)) then return true end
	end
    return false
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
local HealComm = LibStub("LibHealComm-4.1")

function UnitGetIncomingHeals(target, s)
    if not target then 
        target = "player" 
    end
    if not s then 
        s = 4
        if UnitThreatAlert(target) == 3 then s = 2 end
        if UnitHealth100(target) < 40 then return 0 end
    end
    return HealComm:GetHealAmount(UnitGUID(target), HealComm.ALL_HEALS, GetTime() + s) or 0
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
    if UnitThreatAlert(unit) == 3 then lost = lost * 1.5 end
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
