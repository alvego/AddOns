-- Rotation Helper Library by Timofeev Alexey
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
function GetUnits()
    local units = {
        "player", 
        "target", 
        "focus" 
    }
    local members = GetGroupUnits()
    for i = 1, #members, 1 do 
        tinsert(units, members[i])
        tinsert(units, members[i] .."pet")
    end
    tinsert(units, "mouseover")
    realUnits = {}
    for i = 1, #units, 1 do 
        local u = units[i]
        if not TryEach(realUnits, function(t) return IsOneUnit(t, u) end) 
            and InInteractRange(u) then table.insert(realUnits, u) end
    end
    return realUnits
end

------------------------------------------------------------------------------------------------------------------
function GetGroupUnits()
    local units = {"player"}
    if not InGroup() then return units end
    local group = InRaid() and {name = "raid", size = 40} or {name = "party", size = 4}
    for i = 0, group.size do 
        local u = group.name..i
        if UnitExists(u) and UnitName(u) ~= nil 
            and not TryEach(units, function(unit) return IsOneUnit(unit, u) end) then
            tinsert(units, u)
        end
    end
    return units
end

------------------------------------------------------------------------------------------------------------------
function GetTargets()
    local units = {
        "target",
        "focus"
    }
    if IsArena() then
        for i = 1, 5 do 
             tinsert(units, "arena" .. i)
        end
    end
    for i = 1, 4 do 
         tinsert(units, "boss" .. i)
    end
    local members = GetGroupUnits()
    for i = 1, #members do 
         tinsert(units, members[i] .."-target")
         tinsert(units, members[i] .."pet-target")
    end
    tinsert(units, "mouseover")
    realUnits = {}
    for i = 1, #units do 
        local u = units[i]
        if not TryEach(realUnits, function(t) return IsOneUnit(t, u) end) 
            and IsValidTarget(u) 
            and (IsArena() 
                or CheckInteractDistance(u, 1) 
                or IsOneUnit("player", u .. '-target')) then 
            tinsert(realUnits, u) 
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
    return TryEach(units, 
        function(u) return UnitExists(u) and UnitIsPlayer(u) and tContains(classes, GetClass(u)) end
    ) 
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
