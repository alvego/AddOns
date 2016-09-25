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
local sendTime = nil
local function CastLagTime(event, ...)
    local unit, spell = select(1,...)
    if spell and unit == "player" then
        if event == "UNIT_SPELLCAST_SENT" then
            sendTime = GetTime()
        else
            if not sendTime then return end
            LagTime = (GetTime() - sendTime) / 2
            sendTime = nil
        end
    end
end
AttachEvent('UNIT_SPELLCAST_SENT', CastLagTime)
AttachEvent('UNIT_SPELLCAST_START', CastLagTime)
AttachEvent('UNIT_SPELLCAST_SUCCEEDED', CastLagTime)
AttachEvent('UNIT_SPELLCAST_FAILED', CastLagTime)

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
function GetGCDLeft()
    return GetSpellCooldownLeft(61304)
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
        end
        if event == "UNIT_SPELLCAST_SENT" then
           castInfo.StartTime = GetTime()
           TimerStart('InCast')
        else
            castInfo.StartTime = 0
            TimerReset('InCast')
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
FaceSpells = FaceSpells or {}
local function updateSpellErrors(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, amount, info = ...
    if type:match("SPELL_CAST_FAILED") and sourceGUID == UnitGUID("player") then
        --  print(amount)
        if (amount == "Цель должна быть перед вами.") then
          if FaceSpells[spellName] == nil then
            FaceSpells[spellName] = true
          end
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

------------------------------------------------------------------------------------------------------------------
local _m = ''
local spellDebug = false
local function falseBecause(m, spell, icon, target)
  if m == "Не готов" then return false end -- ignore
  if m == "Уже используется" then return false end -- ignore
  if spellDebug and  _m ~= m then
    _m = m
    local s = '|T'.. (icon and icon or 'Interface\\Icons\\INV_Misc_Coin_02') ..':16|t '
    if spell then
      s = s .. '|cff71d5ff[' .. spell .. ']|r '
    end
    if m and m ~= spell then
      s = s .. '|cffff5555<' .. m .. '>|r '
    end
    if target then
      s = s .. '|cffcccccc->|r ' .. (UnitIsEnemy("player", target) and '|cffff0000' or '|cff00ff00') .. UnitName(target) .. '|r'
    end
    print(s)
  end
  return false
end

function UseSpell(spell, target)


  --if TimerStarted("InCast") then return falseBecause("В процессе каста") end
  if UnitIsCasting("player") then return falseBecause("В процессе каста") end
  if not spell then return falseBecause("Отсутсвует", spell) end
  local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spell)
  if not name then return falseBecause("Нет в книге заклинаний", spell) end
  if IsSpellInUse(name) then return falseBecause("Уже используется", name, icon) end

  local usable, nomana = IsUsableSpell(name)
  if usable ~= 1 then return falseBecause("Недоступен", name, icon) end
  if nomana == 1 then return falseBecause("Нужно больше маны", name, icon) end

  local start, duration = GetSpellCooldown(name);
  if start and duration then
    local left = start + duration - GetTime()
    if left > LagTime then return falseBecause("Не готов", name, icon)  end --LagTime --falseBecause("Спелл не готов " .. spell)
  end

  if target ~= nil then
    if UnitExists(target) ~= 1 then return falseBecause("Цель не существует", name, icon, target) end
    if IsSpellInRange(name, target) == 0 then return falseBecause("Цель не в зоне действия", name, icon, target) end
    if UnitInLos and UnitInLos(target) then echo("UnitInLos!") return falseBecause("Цель в лосе", name, icon, target) end
    if FaceSpells[name] ~= nil and not PlayerFacingTarget(target) then
      FaceToTarget(target)
      return falseBecause("Мы не смотрим на цель", name, icon, target)
    end
  end



  local cast = "/cast "
  -- с учетом цели
  if target then  cast = cast .."[@".. target .."] " end
  -- пробуем скастовать

  falseBecause(name, name, icon, target)
  omacro(cast .. "!" .. name)
  --print(cast .. "!" .. name)
  if SpellIsTargeting() then
        if target then
          UnitWorldClick(target)
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
