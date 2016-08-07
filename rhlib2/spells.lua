-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
-- Время сетевой задержки
LagTime = 0
local lastUpdate = 0
local function UpdateLagTime()
    if GetTime() - lastUpdate < 30 then return end
    lastUpdate = GetTime()
    LagTime = tonumber((select(3, GetNetStats()) or 0)) / 1000
end
AttachUpdate(UpdateLagTime)
local sendTime = 0
local function CastLagTime(event, ...)
    local unit, spell = select(1,...)
    if spell and unit == "player" then
        if event == "UNIT_SPELLCAST_SENT" then
            sendTime = GetTime()
        end
        if event == "UNIT_SPELLCAST_START" then
            if not sendTime then return end
            LagTime = (GetTime() - sendTime) / 2
        end
    end
end
AttachEvent('UNIT_SPELLCAST_START', CastLagTime)
AttachEvent('UNIT_SPELLCAST_SENT', CastLagTime)
------------------------------------------------------------------------------------------------------------------
function StopCast(info)
    if not info then info = "?" end
    if Debug then chat("Stop Cast! ( ".. info .. " )") end
    oexecute("SpellStopCasting()")
end
------------------------------------------------------------------------------------------------------------------
local spellToIdList = {}
function GetSpellId(name, rank)
    spellGUID = name
    if rank then
        spellGUID = name .. rank
    end
    local result = spellToIdList[spellGUID]
    if nil == result then
        local link = GetSpellLink(name,rank)
        if not link then
            result = 0
        else
            result = 0 + link:match("spell:%d+"):match("%d+")
        end
        spellToIdList[spellGUID] = result
    end
    return result
end

------------------------------------------------------------------------------------------------------------------
function HasSpell(spellName)
    if GetSpellInfo(spellName) then return true end
    return false
end
------------------------------------------------------------------------------------------------------------------
local gcd_starttime, gcd_duration
local function updateGCD(_, start, dur, enable)
    if start > 0 and enable > 0 then
        if dur and dur > 0 and dur <= 1.5 then
            gcd_starttime = start
            gcd_duration = dur
        end
    end
end
hooksecurefunc("CooldownFrame_SetTimer", updateGCD)

function GetGCDLeft()
    if not gcd_starttime then return 0 end
    local t = GetTime() - gcd_starttime
    if  t  > gcd_duration then
        return 0
    end
    return gcd_duration - t
end

function InGCD()
    return GetGCDLeft() > LagTime
end

local abs = math.abs
function IsReady(left, checkGCD)
    if checkGCD == nil then checkGCD = false end
    if not checkGCD then
        local gcdLeft = GetGCDLeft()
        if (abs(left - gcdLeft) < 0.01) then return true end
    end
    if left > LagTime then return false end
    return true
end
------------------------------------------------------------------------------------------------------------------
-- Interact range - 40 yards
local interactSpells = {
    DRUID = "Целительное прикосновение",
    PALADIN = "Свет небес",
    SHAMAN = "Волна исцеления",
    PRIEST = "Малое исцеление"
}
local interactRangeSpell = interactSpells[GetClass()]

function InInteractRange(unit)
    -- need test and review
    if (unit == nil) then unit = "target" end
    if not UnitIsFriend("player", unit) then return false end
    if interactRangeSpell then return IsSpellInRange(interactRangeSpell, unit) == 1 end
    --UnitInRange("target")
    return DistanceTo and DistanceTo("player", unit) < 40
end
------------------------------------------------------------------------------------------------------------------
local meleeSpells = {
    DRUID = "Цапнуть",
    DEATHKNIGHT = "Удар чумы",
    PALADIN = "Щит праведности",
    SHAMAN = "Удар бури",
    WARRIOR = "Кровопускание"
}
local meleeSpell = meleeSpells[GetClass()]
function InMelee(target)
    if (target == nil) then target = "target" end
    if meleeSpell then return  (IsSpellInRange(meleeSpell, target) == 1) end
    return DistanceTo and DistanceTo("player", target) < 5
end
------------------------------------------------------------------------------------------------------------------

function IsReadySpell(name, checkGCD)
    local usable, nomana = IsUsableSpell(name)
    if not usable then return false end
    local left = GetSpellCooldownLeft(name)
    return IsSpellNotUsed(name, 0.5) and IsReady(left, checkGCD)
end

------------------------------------------------------------------------------------------------------------------
function GetSpellCooldownLeft(name)
    local start, duration, enabled = GetSpellCooldown(name);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
    return start + duration - GetTime()
end

------------------------------------------------------------------------------------------------------------------
function UseMount(mountName)
    if UnitIsCasting() then return false end
    if InGCD() then return false end
    if IsMounted() then return false end
    --[[if Debug then
        print(mountName)
    end]]
    omacro("/use " .. mountName)
    return true
end
------------------------------------------------------------------------------------------------------------------
function InRange(spell, target)
    if target == nil then target = "target" end
    if spell and IsSpellInRange(spell,target) == 0 then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------
-- using (nil if nothing casting)
-- local spell, left, duration, channel, nointerrupt = UnitIsCasting("unit")
function UnitIsCasting(unit)
    if not unit then unit = "player" end
    local channel = false
    -- name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")
    local spell, _, _, _, startTime, endTime, _, _, notinterrupt = UnitCastingInfo(unit)
    if spell == nil then
        --name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("unit")
        spell, _, _, _, startTime, endTime, _, nointerrupt = UnitChannelInfo(unit)
        channel = true
    end
    if spell == nil or not startTime or not endTime then return nil end
    local left = endTime * 0.001 - GetTime()
    local duration = (endTime - startTime) * 0.001
    if left < LagTime then return nil end
    --print(unit, spell, left, duration, channel, nointerrupt)
    return spell, left, duration, channel, nointerrupt
end
------------------------------------------------------------------------------------------------------------------
local InCast = {}

local function getCastInfo(spell)
	if not InCast[spell] then
		InCast[spell] = {StartTime = 0, LastCastTime = 0 }
	end
	return InCast[spell]
end

local function UpdateIsCast(event, ...)
    local unit, spell, rank, target = select(1,...)
    if spell and unit == "player" then
        local castInfo = getCastInfo(spell)
        if event == "UNIT_SPELLCAST_SUCCEEDED" and castInfo.StartTime > 0 then
            castInfo.LastCastTime = castInfo.StartTime
            return
        end
        if event == "UNIT_SPELLCAST_SENT" then
           castInfo.StartTime = GetTime()
        else
            castInfo.StartTime = 0
        end
    end
end
AttachEvent('UNIT_SPELLCAST_SENT', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_SUCCEEDED', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_FAILED', UpdateIsCast)

function GetSpellLastTime(spell)
    local castInfo = getCastInfo(spell)
    return castInfo.LastCastTime
end

function IsSpellNotUsed(spell, t)
    local last  = GetSpellLastTime(spell)
    return GetTime() - last >= t
end


function IsSpellInUse(spell)
    if not spell then return false end
    local castInfo = getCastInfo(spell)
    if (GetTime() - castInfo.StartTime <= LagTime) then return true end
    if IsCurrentSpell(spell) == 1 then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
CanTrySpellInfo = ""
CanTrySpellName = ""
function CanTrySpell(spell, target)
  CanTrySpellPrint = ""
  CanTrySpellInfo = ""
  CanTrySpellName = ""
  if not spell then CanTrySpellInfo = "!Spell" return false end
  local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spell)
  CanTrySpellName = name
  if not name then CanTrySpellInfo = "!Info " .. spell return false end
  if IsSpellInUse(name) then CanTrySpellInfo = "InUse " .. spell return false end
  local usable, nomana = IsUsableSpell(name)
  if usable ~= 1 then CanTrySpellInfo = "!Usable " .. spell return false end
  if nomana == 1 then CanTrySpellInfo = "NoMana " .. spell return false end
  local start, duration = GetSpellCooldown(name);
  if start and duration then
    local left = start + duration - GetTime()
    if left > LagTime / 2 then CanTrySpellInfo = "!Ready " .. spell return false end
  end
  if target == nil then return true end
  if UnitExists(target) ~= 1 then CanTrySpellInfo = "!UnitExists " .. target .. " ".. spell return false end
  if IsSpellInRange(name, target) == 0 then CanTrySpellInfo = "!InRange " .. target .. " ".. spell return false end
  if UnitInLos and UnitInLos(target) then CanTrySpellInfo = "UnitInLos " .. target .. " ".. spell return false end
  return true
end

local _spell = nil
local  _target = nil

local function updateSpellErrors(event, ...)
    TimerStart("CombatLog")
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, amount, info = ...
    if type:match("SPELL_CAST_FAILED") and sourceGUID == UnitGUID("player") then
        _spell = nil
        --  print(amount)
        if (amount == "Цель должна быть перед вами." or amount == "Цель вне поля зрения.") then
          FaceToTarget()
        end
        --[[if (amount == "Еще не готово.") or (amount == "Заклинание пока недоступно.")  then
          if Debug then print("Не готово", spellName , " GCD:", InGCD(), " left:", GetSpellCooldownLeft(spellName), " LagTime:", LagTime) end
        end]]
        --[[if (amount == "Эту цель атаковать нельзя.") then

        end]]
        if Debug then
          UIErrorsFrame:Clear()
          UIErrorsFrame:AddMessage(spellName .. ' - ' .. amount, 1.0, 0.2, 0.2);
        end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateSpellErrors)



function TrySpell()
  if InCombatLockdown() and TimerMore("CombatLog", 15) and TimerMore("CombatLogReset", 30) then
      CombatLogClearEntries()
      --chat("Reset CombatLog!")
      TimerStart("CombatLogReset")
  end
  if _spell ~= nil and CanTrySpell(_spell, _target) then
    local cast = "/cast "
    -- с учетом цели
    if _target then  cast = cast .."[@".. _target .."] " end
    -- пробуем скастовать
    --print(cast .. "!" .. CanTrySpellName .. '->' .. _spell)
    omacro(cast .. "!" .. CanTrySpellName)
    if SpellIsTargeting() then
          if _target then
            UnitWorldClick(_target)
          else
             local look = IsMouselooking()
              if look then
                  oexecute('TurnOrActionStop()')
              end
              oexecute('CameraOrSelectOrMoveStart()')
              oexecute('CameraOrSelectOrMoveStop()')
              if look then
                  oexecute('TurnOrActionStart()')
              end
          end
          oexecute('SpellStopTargeting()')
    end
    return true
  end
  --print(CanTrySpellInfo)
  _spell = nil
  _target = nil
  return false
end

function UseSpell(spell, target)
  if target and UnitExists(target) and UnitInLos and UnitInLos(target) then print("UnitInLos!") end
  if _spell == nil and CanTrySpell(spell, target) then
    _spell = spell
    _target = target
    return true
  end
  --if Debug and CanTrySpellInfo then print(CanTrySpellInfo) end
  if target and UnitExists(target) and UnitInLos and UnitInLos(target) then
    UIErrorsFrame:Clear()
    UIErrorsFrame:AddMessage("UnitInLos: " .. target, 1.0, 0.2, 0.2)
  end
  return false
end
