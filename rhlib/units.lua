-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Возвращает список членов группы отсортированных по приоритету исцеления
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
function IsValidTarget(target)
    if target == nil then target = "target" end
    if not UnitExists(target) then return false end
    if IsIgnored(target) then return false end
    if UnitIsDeadOrGhost(target) then return false end
    if UnitIsEnemy("player",target) and UnitCanAttack("player", target) then return true end 
    if (UnitInParty(target) or UnitInRaid(target)) then return false end 
    return UnitCanAttack("player", target)
end

------------------------------------------------------------------------------------------------------------------
function IsInteractUnit(t)
    if not UnitExists(t) then return false end
    if IsIgnored(t) then return false end
    if IsValidTarget(t) then return false end
    if UnitIsDeadOrGhost(t) then return false end
    if UnitIsCharmed(t) then return false end
    return not UnitIsEnemy("player",t)
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
	for i = 1, #units do
        local u = units[i]
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
    return UnitExists(unit) and not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack("player", unit));
end

------------------------------------------------------------------------------------------------------------------
function UnitIsPet(unit)
    return UnitExists(unit) and not UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit);
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
function CalculateHP(t)
  return 100 * UnitHP(t) / UnitHealthMax(t)
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
