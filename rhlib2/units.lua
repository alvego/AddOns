-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local inDuel = false
local startDuel = StartDuel
function StartDuel()
    inDuel = true
    startDuel()
end

function InDuel()
    return inDuel
end
local function DuelUpdate(event)
   inDuel = (event == 'DUEL_REQUESTED' and true or false)
end
AttachEvent('DUEL_REQUESTED', DuelUpdate)
AttachEvent('DUEL_FINISHED', DuelUpdate)
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
        for j = 1, #realUnits do
        exists = IsOneUnit(realUnits[j], u)
			if exists then break end
		end
        if not exists and IsInteractUnit(u) then
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
    if not IsInGroup() then return groupUnits end
    local name = "party"
    local size = MAX_PARTY_MEMBERS
	if IsInRaid() then
		name = "raid"
		size = MAX_RAID_MEMBERS
    end
    for i = 0, size do
		tinsert(groupUnits, name..i)
    end
    return groupUnits
end
------------------------------------------------------------------------------------------------------------------
-- /run DоCommand("cl", GetSameGroupUnit("mouseover"))
function GetSameGroupUnit(unit)
    local group = GetGroupUnits()
    for i = 1, #group do
        if IsOneUnit(unit, group[i]) then return group[i] end
    end
    return unit
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
        for j = 1, #realTargets do
 			exists = IsOneUnit(realTargets[j], u)
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
IsValidTargetInfo = ""
function IsValidTarget(t)
    IsValidTargetInfo = ""
    if t == nil then t = "target" end
    if not UnitName(t) then
        IsValidTargetInfo = "Нет цели"
        return false
    end
    if UnitIsDeadOrGhost(t) and not HasBuff("Притвориться мертвым", 0.1,t) then
        IsValidTargetInfo = "Цель дохлая"
        return false
    end

    if not UnitCanAttack("player", t) then
        IsValidTargetInfo = "Невозможно атаковать"
        return false
    end

    if UnitInLos and UnitInLos(t) then
        IsValidTargetInfo = "В лосе"
        return false
    end

    return true
end

------------------------------------------------------------------------------------------------------------------
IsInteractUnitInfo = ""
function IsInteractUnit(t)
    if t == nil then t = "player" end
    if not UnitExists(t) then
    	IsInteractUnitInfo = "Нет юнита " .. t
    	return false
    end
    if UnitIsDeadOrGhost(t) and not HasBuff("Притвориться мертвым", 0.1, t)  then
    	IsInteractUnitInfo = "Труп или призрак " .. t
    	return false
    end
    if UnitCanAttack("player", t) then
        IsValidTargetInfo = "Можно атаковать"
        return false
    end
    if UnitIsCharmed(t) then
    	IsInteractUnitInfo = "Околдован " .. t
    	return false
    end
    if UnitIsEnemy("player",t) then
    	IsInteractUnitInfo = "Враждебен "  .. t
    	return false
    end

    if UnitInLos and UnitInLos(t) then
        IsInteractUnitInfo = "Вне поля зрения"
        return false
    end

    if not InInteractRange(t) then
        IsInteractUnitInfo = "Не в радиусе взаимодействия"
        return false
    end

    return true
end

------------------------------------------------------------------------------------------------------------------
function GetClass(target)
    if not target then target = "player" end
    local _, class = UnitClass(target)
    return class
end
------------------------------------------------------------------------------------------------------------------
function UnitIsNPC(unit)
    return UnitExists(unit) and not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack("player", unit));
end

------------------------------------------------------------------------------------------------------------------
function UnitIsPet(unit)
    return UnitExists(unit) and not UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit);
end

------------------------------------------------------------------------------------------------------------------
function IsOneUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return false end
    return unit1 == unit2 or UnitGUID(unit1) == UnitGUID(unit2)
end

------------------------------------------------------------------------------------------------------------------
function UnitThreat(u, t)
    if not UnitIsPlayer(u) then return 0 end
    local threat = UnitThreatSituation(u, t)
    if threat == nil then threat = 0 end
    return threat
end

------------------------------------------------------------------------------------------------------------------
function UnitHealth100(target)
    if target == nil then target = "player" end
    return UnitHP(target) * 100 / UnitHealthMax(target)
end

------------------------------------------------------------------------------------------------------------------
function UnitMana100(target)
    if target == nil then target = "player" end
    return UnitMana(target) * 100 / UnitManaMax(target)
end

------------------------------------------------------------------------------------------------------------------
function UnitLostHP(unit)
    local hp = UnitHP(unit)
    local maxhp = UnitHealthMax(unit)
    local lost = maxhp - hp
    return lost
end

------------------------------------------------------------------------------------------------------------------
function UnitHP(unit)
  local hp = UnitHealth(unit) + (UnitGetIncomingHeals(unit) or 0)
  if hp > UnitHealthMax(unit) then hp = UnitHealthMax(unit) end
  return hp
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
    if InDuel() then return true end
    if IsValidTarget("target") and UnitIsPlayer("target") then return true end
    local inInstance, instanceType = IsInInstance()
    return (inInstance ~= nil and (instanceType =="arena" or instanceType =="pvp")) or (IsValidTarget("target") and UnitIsPlayer("target"))
end
------------------------------------------------------------------------------------------------------------------
function PlayerInPlace()
    return (GetUnitSpeed("player") == 0) and not IsFalling()
end

------------------------------------------------------------------------------------------------------------------
function PlayerFacingTarget(unit)
    if not UnitExists(unit) or IsOneUnit("player",unit) then return false end
    local facing = GetPlayerFacing()
    local x1,y1 = UnitPosition("player")
    local x2,y2 = UnitPosition(unit)
    local yawAngle = atan2(y1 - y2, x1 - x2) - deg(facing)
    if yawAngle < 0 then yawAngle = yawAngle + 360 end
    return yawAngle > 90 and yawAngle < 270
end
------------------------------------------------------------------------------------------------------------------
function InCombatMode()
    if IsValidTarget("target") then
      TimerStart('CombatTarget')
    end
    if InCombatLockdown() then
      TimerStart('CombatLock')
    end
    if IsAttack() then
      return true
    end
    if TimerLess('CombatLock', 1) and TimerLess('CombatTarget', 3) then return true end
    return false
end
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
function IsInGroup()
    return (IsInRaid() or IsInParty())
end

------------------------------------------------------------------------------------------------------------------
function IsInRaid()
    return (GetNumRaidMembers() > 0)
end

------------------------------------------------------------------------------------------------------------------
function IsInParty()
    return (GetNumPartyMembers() > 0)
end
