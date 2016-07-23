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
function spellCastErrorMonitoring(event, ...)
  local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, agrs12, agrs13,agrs14 = select(1, ...)
  if sourceGUID == playerGUID and spellName then
    local err = agrs12
    if err then
      UIErrorsFrame:Clear()
      UIErrorsFrame:AddMessage(spellName .. ' - ' .. err, 1.0, 0.2, 0.2);
    end
  end
end
AttachEvent('SPELL_CAST_FAILED', CastLagTime)

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

------------------------------------------------------------------------------------------------------------------
function InInteractRange(unit)
    -- need test and review
    if (unit == nil) then unit = "target" end
    if not IsInteractUnit(unit) then return false end
    return IsItemInRange(34471, unit) == 1
end
------------------------------------------------------------------------------------------------------------------
function InMelee(target)
    if (target == nil) then target = "target" end
    return IsItemInRange(37727, target) == 1
end

------------------------------------------------------------------------------------------------------------------

function IsReadySpell(name)
    local usable, nomana = IsUsableSpell(name)
    if not usable then return false end
    local left = GetSpellCooldownLeft(name)
    if left > LagTime then return false end
    return true
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
    if IsPlayerCasting() then return false end
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
function IsPlayerCasting()
    local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo("player")
    if spell == nil then
        spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo("player")
    end
    if not spell or not endTime then return false end
    local res = ((endTime/1000 - GetTime()) < LagTime)
    if res then return false end
    return true
end
------------------------------------------------------------------------------------------------------------------
function UseSpell(spellName, target)
    local dump = false --spellName == "Целительный ливень"
    -- Не пытаемся что либо прожимать во время каста
    if IsPlayerCasting() then
        if dump then print("Кастим, не можем прожать", spellName) end
        return false
    end
    local manual = (target == false);

    if target == nil then target = "target" end

    if dump then print("Пытаемся прожать", spellName, "на", target  or "...") end

    if SpellIsTargeting() then
        -- Не мешаем выбрать область для спела (нажат вручную)
        if dump then print("Ждем выбор цели, не можем прожать", spellName) end
        return false
    end
    -- Проверяем на наличе спела в спелбуке
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    if not name then
        if Debug then error("Спел [".. spellName .. "] не найден!") end
        return false;
    end
    -- проверяем, что этот спел не используется сейчас
    if IsCurrentSpell(spellName) then
        if dump then print("Уже прожали, не можем больше прожать", spellName) end
        return false
    end

    -- проверяем что цель в зоне досягаемости
    if not manual and not InRange(spellName, target) then
        if dump then print(target," - Цель вне зоны досягаемости, не можем прожать", spellName) end
        return false
    end

    -- Проверяем что все готово
    if not IsReadySpell(spellName) then
        if dump then print("Не готово, не можем прожать", spellName) end
        return false
    end
    -- собираем команду
    local cast = "/cast "
    -- с учетом цели
    if target then cast = cast .."[@".. target .."] "  end
    -- проверяем, хватает ли нам маны
    if cost and cost > 0 and (UnitPower("player", powerType) or 0) <= cost then
        if dump then print("Не достаточно маны, не можем прожать", spellName) end
        return false
    end
      -- пробуем скастовать
    --if Debug then print("Жмем", cast .. "!" .. spellName) end
    omacro(cast .. "!" .. spellName)
    -- если нужно выбрать область - кидаем на текущий mouseover
    if SpellIsTargeting() then
          if manual then
             local look = IsMouselooking()
              if look then
                  oexecute('TurnOrActionStop()')
              end
              oexecute('CameraOrSelectOrMoveStart()')
              oexecute('CameraOrSelectOrMoveStop()')
              if look then
                  oexecute('TurnOrActionStart()')
              end
          else
              UnitWorldClick(target)
          end
          oexecute('SpellStopTargeting()')
    end

    if dump then print("Спел вроде прожался", spellName) end

    if Debug then
        local name = UnitName(target)
        name = name or target
        chat(spellName .. " -> ".. name, 0.4,0.4,0.4)
    end
    return true
end
