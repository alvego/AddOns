-- Rotation Helper Library by Alex Tim
------------------------------------------------------------------------------------------------------------------
local moveBackward = false
local moveBackwardStart = function() moveBackward = true end
hooksecurefunc("MoveBackwardStart", moveBackwardStart);
local moveBackwardStop = function() moveBackward = false end
hooksecurefunc("MoveBackwardStop", moveBackwardStop);

local moving = false
local moveStart = function() moving = true end
hooksecurefunc("MoveBackwardStart", moveStart);
hooksecurefunc("MoveForwardStart", moveStart);
hooksecurefunc("StrafeLeftStart", moveStart);
hooksecurefunc("StrafeRightStart", moveStart);
hooksecurefunc("JumpOrAscendStart", moveStart);
local moveStop = function() moving = false end
hooksecurefunc("MoveBackwardStop", moveStop);
hooksecurefunc("MoveForwardStop", moveStop);
hooksecurefunc("StrafeLeftStop", moveStop);
hooksecurefunc("StrafeRightStop", moveStop);
hooksecurefunc("AscendStop", moveStop);

function PayerIsRooted()
  if IsSwimming() or IsMounted() or CanExitVehicle() then return false end
  if moving and HasDebuff(RootList, 0.5, "player") then return true end
  local speed = GetUnitSpeed("player")
  if speed == 0 then return false end
  if speed < (moveBackward and 4.5 or 7) then
    print(speed)
    if not TimerStarted('PayerIsRooted') then TimerStart('PayerIsRooted') end
  else
    if TimerStarted('PayerIsRooted') then TimerReset('PayerIsRooted') end
  end
  return TimerStarted('PayerIsRooted') and TimerMore('PayerIsRooted', 1)
end

------------------------------------------------------------------------------------------------------------------
local inDuel = false
local function startDuel()
    inDuel = true
end
hooksecurefunc("StartDuel", startDuel);

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
    if not UnitCanAttack("player", t) then
        IsValidTargetInfo = "Невозможно атаковать"
        return false
    end
    if UnitIsDeadOrGhost(t) and not HasBuff("Притвориться мертвым", 0.1, t) then
        IsValidTargetInfo = "Цель дохлая"
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
IsInteractUnitInfo = ""
function IsInteractUnit(t)
    if t == nil then t = "player" end
    if not InInteractRange(t) then
        IsInteractUnitInfo = "Не в радиусе взаимодействия"
        return false
    end
    if UnitIsDeadOrGhost(t) then
    	IsInteractUnitInfo = "Труп " .. t
    	return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
local talentTab = {}
local talentIdx = {}
function HasTalent(name)
  if not name then return 0 end
  if not talentTab[name] then
    local numTabs = GetNumTalentTabs();
    for t=1, numTabs do
        local numTalents = GetNumTalents(t);
        for i=1, numTalents do
            nameTalent, icon, tier, column, currRank, maxRank= GetTalentInfo(t,i);
            if name == nameTalent then
              talentTab[name] = t
              talentIdx[name] = i
            end
        end
    end
    if not talentTab[name] then
      chat("Неверное имя таланта " .. name)
      return 0;
    end
  end

	local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(talentTab[name], talentIdx[name])
	return nameTalent and currRank or 0
end
------------------------------------------------------------------------------------------------------------------
--[[function Stance(...)
  local s = GetShapeshiftForm()
    for i = 1, select('#', ...) do
        if s == select(i, ...) then return true end
    end
    return false
end]]
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
    return UnitThreatSituation(u, t) or 0
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
function UnitLostHP(unit)
    local hp = UnitHealth(unit)
    local maxhp = UnitHealthMax(unit)
    local lost = maxhp - hp
    return lost
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
    return inInstance ~= nil and (instanceType =="arena" or instanceType =="pvp")
end
------------------------------------------------------------------------------------------------------------------
function PlayerInPlace()
    return (GetUnitSpeed("player") == 0) and not IsFalling()
end

------------------------------------------------------------------------------------------------------------------
function PlayerFacingTarget(unit, angle) -- angle 1 .. 90, default 90
    if not UnitExists(unit) or IsOneUnit("player",unit) then return false end
    local x, y = UnitPosition(unit)
    local yawAngle = PlayerFacingAngleToPoint(x, y)
    if not angle then angle = 90 end
    return yawAngle > -angle and yawAngle < angle
end
------------------------------------------------------------------------------------------------------------------
function PlayerFacingAngleToPoint(x, y) -- angle 1 .. 90, default 90
    if not x or not y then return 0 end
    local facing = GetPlayerFacing()
    local x0,y0 = UnitPosition("player")
    local yawAngle = atan2(y0 - y, x0 - x) - deg(facing)
    if yawAngle < 0 then yawAngle = yawAngle + 360 end
    return yawAngle - 180
end
------------------------------------------------------------------------------------------------------------------
local moveUp = false
local moveUpStart = function() moveUp = true end
hooksecurefunc("JumpOrAscendStart", moveUpStart);
local moveUpStop = function() moveUp = false end
hooksecurefunc("AscendStop", moveUpStop);

function MoveUpStart()
  if moveUp then return end
  MoveDownStop()
  oexecute('JumpOrAscendStart()')
end

function MoveUpStop()
  if not moveUp then return end
  oexecute('AscendStop()')
end

local moveDown = false
local moveDownStart = function() moveDown = true end
hooksecurefunc("SitStandOrDescendStart", moveDownStart);
local moveDownStop = function() moveDown = false end
hooksecurefunc("DescendStop", moveDownStop);

function MoveDownStart()
  if moveDown then return end
  MoveUpStop()
  oexecute('SitStandOrDescendStart()')
end

function MoveDownStop()
  if not moveDown then return end
  oexecute('DescendStop()')
end

function MoveZStop()
  MoveDownStop()
  MoveUpStop()
end
------------------------------------------------------------------------------------------------------------------
local turnRight = false
local turnRightStart = function() turnRight = true end
hooksecurefunc("TurnRightStart", turnRightStart);
local turnRightStop = function() turnRight = false end
hooksecurefunc("TurnRightStop", turnRightStop);

local turnLeft = false
local turnLeftStart = function() turnLeft = true end
hooksecurefunc("TurnLeftStart", turnLeftStart);
local turnLeftStop = function() turnLeft = false end
hooksecurefunc("TurnLeftStop", turnLeftStop);

function RotateRightStart()
  if turnRight then return end
  RotateLeftStop()
  oexecute('TurnRightStart()')
end

function RotateRightStop()
  if not turnRight then return end
  oexecute('TurnRightStop()')
end

function RotateLeftStart()
  RotateRightStop()
  if turnLeft then return end
  oexecute('TurnLeftStart()')
end

function RotateLeftStop()
  if not turnLeft then return end
  oexecute('TurnLeftStop()')
end

function RotateStop()
  RotateLeftStop()
  RotateRightStop()
end

------------------------------------------------------------------------------------------------------------------
function MoveStop()
  RotateStop()
  RunForwardStop()
  MoveZStop()
end
------------------------------------------------------------------------------------------------------------------

local moveForward = false
local moveForwardStart = function() moveForward = true end
hooksecurefunc("MoveForwardStart", moveForwardStart);
local moveForwardStop = function() moveForward = false end
hooksecurefunc("MoveForwardStop", moveForwardStop);

function RunForwardStart()
  if moveForward then return end
  oexecute('MoveForwardStart()')
end

function RunForwardStop()
  if not moveForward then return end
  --print('RunForwardStop')
  oexecute('MoveForwardStop()')
end
------------------------------------------------------------------------------------------------------------------
function Intersection(ax1,ay1,ax2,ay2,bx1,by1,bx2,by2)
   local v1 = (bx2-bx1)*(ay1-by1)-(by2-by1)*(ax1-bx1)
   local v2 = (bx2-bx1)*(ay2-by1)-(by2-by1)*(ax2-bx1)
   local v3 = (ax2-ax1)*(by1-ay1)-(ay2-ay1)*(bx1-ax1)
   local v4 = (ax2-ax1)*(by2-ay1)-(ay2-ay1)*(bx2-ax1)
   return (v1*v2 < 0) and (v3*v4 < 0);
end
------------------------------------------------------------------------------------------------------------------
function removeLoops(points)
  if #points < 4 then return end
  local xn, yn = unpack(points[#points])
  local _xn, _yn = unpack(points[#points-1])
  local _xi, _yi = unpack(points[#points-2])
  local cross
  for i = #points-3, 1, -1 do
    local xi, yi, zi = unpack(points[i])
    if Intersection(xn, yn, _xn, _yn, xi, yi, _xi, _yi)  then
      cross = i
      break
    end
    _xi = xi
    _yi = yi
  end
  if not cross then return end
  local loop_start = cross + 1
  local loop_end = #points - 1
  for i = loop_start, loop_end do
    tremove(points, loop_start)
  end
end

------------------------------------------------------------------------------------------------------------------
function clearFollowPoints(unit)
    SendAddonMessage('rhlib2', format("clearFollow!", x, y, z), "WHISPER", unit)
end
------------------------------------------------------------------------------------------------------------------
function sendFollowAttack(unit)
    SendAddonMessage('rhlib2', format("followAttack!", x, y, z), "WHISPER", unit)
end
------------------------------------------------------------------------------------------------------------------
local lx, ly, lz, lf
function sendFollowPoint(unit, x, y, z)
    local msg = format("followPoint:%.0f,%.0f,%.0f", x, y, z)
    --print(msg)
    SendAddonMessage('rhlib2', msg , "WHISPER", unit)
    lx, ly, lz = x,y,z
    lf = GetPlayerFacing()
end
------------------------------------------------------------------------------------------------------------------
local followPoints = {}
local function receiveFollowPoint(type, prefix, message, channel, sender)
  if prefix ~= 'rhlib2' then return end
  if channel ~= 'WHISPER' then return end
  if IsOneUnit(sender, "player") then return end
  if message:match("clearFollow!") then
    wipe(followPoints)
    if not PlayerInPlace() then
      RunForwardStart()
      RunForwardStop()
    end
    return
  end
  if message:match("followAttack!") then
    TryAttack()
    return
  end
  if message:match("followPoint:") then
    local point = {}
    gsub(message, "-?%d+", function(i) tinsert(point, tonumber(i)) end)
    tinsert(followPoints, point)
    --print("point: ", unpack(point))
    removeLoops(followPoints)
    return
  end
end
AttachEvent('CHAT_MSG_ADDON', receiveFollowPoint)
------------------------------------------------------------------------------------------------------------------
function GoToMeUnit(unit)
  local x, y, z = UnitPosition("player")
  if lx and ly and lz then
    local dist = (IsFlying() and 30 or ((abs(lf - GetPlayerFacing()) > 0.5) and 2 or 10))
    if PointToPontDistance(x, y, z, lx, ly, lz) > dist then
      --print(dist)
      sendFollowPoint(unit, x, y, z)
    end
  else
    sendFollowPoint(unit, x, y, z)
  end
end
------------------------------------------------------------------------------------------------------------------
if not AutoFollowUnit then AutoFollowUnit = nil end
local function updateFollow()
  if AutoFollowUnit and UnitExists(AutoFollowUnit) then GoToMeUnit(AutoFollowUnit) end
  if Paused then return end
  if UnitIsCasting('player') then return end
  if #followPoints < 1 then return end
  local _x, _y, _z =  unpack(followPoints[1])
  local x, y, z = UnitPosition("player")
  local dist = PointToPontDistance(x, y, z, _x, _y, _z)
  -- if (dist < 6 and dist > 4) and not (IsFlying() or IsSwimming() or IsFalling()) then
  --   MoveUpStart()
  --   MoveUpStop()
  -- end
  if (dist < 3) then
    tremove(followPoints, 1)
    updateFollow()
    return
  end
  --if PlayerInPlace() then
    MovePlayer(_x, _y, _z)
  --end
  if PlayerInPlace() then
    -- if not (IsFlying() or IsSwimming() or IsFalling()) then
    --   MoveUpStart()
    --   MoveUpStop()
    -- end
    tremove(followPoints, 1)
    updateFollow()
  end
end
AttachUpdate(updateFollow)
------------------------------------------------------------------------------------------------------------------
function PointToPontDistance(x1, y1, z1, x2, y2, z2)
  if not (x1 and y1 and z1 and x2 and y2 and z2) then return 0 end
  local dx = x1 - x2
  local dy = y1 - y2
  local dz = z1 - z2
  return sqrt( dx * dx + dy * dy + dz * dz )
end
------------------------------------------------------------------------------------------------------------------
function InCombatMode()
    if IsValidTarget("target") then
      TimerStart('CombatTarget')
    end
    if InCombatLockdown() then
      TimerStart('CombatLock')
    end
    if IsAttack() or (TimerLess('CombatLock', 0.01) and TimerLess('CombatTarget', 3)) then
      TimerStart('InCombatMode')
      return true
    end
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
------------------------------------------------------------------------------------------------------------------
function CantAttack()
  local attack = IsAttack()
  if not CanAttack("target") then
    if CanAttackInfo then chat('!attack: ' .. CanAttackInfo ) end
    return true
  end
  local autoAttack = IsCurrentSpell("Автоматическая атака")
  if not attack and not UnitAffectingCombat("target") then -- TODO: Не бить в сапы и имуны, писать почему не бьем
    chat('!attack: !combat target' )
    if autoAttack then
      chat('attack: stop!')
      oexecute("StopAttack()")
    end
    return true
  end
  if not autoAttack then
      chat('attack: start!')
      oexecute("StartAttack()")
  end
  FaceToTarget("target")
  return false
end
------------------------------------------------------------------------------------------------------------------
function TryTarget(attack, focus)
  local validTarget = IsValidTarget("target")
  if IsArena() and validTarget and IsValidTarget("focus") then
    switchFocusTarget()
    return
  end
  local pvp = IsPvP()
  local _currentGUID = nil
  local _uid = nil
  local _uid2 = nil
  local _face = false
  local _dist = 100
  local _combat = false
  UpdateObjects()
  UpdateTargets()
  if validTarget then
    _currentGUID = UnitGUID("target")
    _uid2 = "target"
  end
  local look = IsMouselooking()
  for i = 1, #TARGETS do
    local uid = TARGETS[i]
    repeat -- для имитации continue
      if not IsValidTarget(uid) then break end
      local combat = UnitAffectingCombat(uid)
      -- уже есть кто-то в бою
      if _currentGUID and _currentGUID == UnitGUID(uid) then break end
      if _combat and not combat then break end
      -- автоматически выбераем только цели в бою
      if not attack and not combat then break end
      -- не будет лута
      if (UnitIsTapped(uid)) and (not UnitIsTappedByPlayer(uid)) then break end
      -- Призванный юнит
      if UnitIsPossessed(uid) then break end
      -- в pvp выбираем только игроков
      if pvp and not UnitIsPlayer(uid) then break end
      -- только актуальные цели
      local face = PlayerFacingTarget(uid, look and 45 or 90)
      -- если смотрим, то только впереди
      if look and not face then break end
      local dist = DistanceTo("player", uid)
      if _face and not face and dist > 8 then break end
      if dist > _dist then break end
      if _uid then _uid2 = _uid end
      _uid = uid
      _combat = combat
      _face = face
      _dist = dist
    until true
  end
  if focus and _uid2 then oexecute("FocusUnit('".. _uid2 .."')") end
  if _uid then oexecute("TargetUnit('".. _uid .."')") end
end
------------------------------------------------------------------------------------------------------------------
function switchFocusTarget()
  if UnitExists("target") and not UnitExists("focus") then
      omacro("/focus")
      omacro("/cleartarget")
      return
  end
  if UnitExists("focus") and not UnitExists("target") then
    omacro("/target focus")
    omacro("/clearfocus")
    return
  end
  omacro("/target focus")
  omacro("/targetlasttarget")
  omacro("/focus")
  omacro("/targetlasttarget")
end
