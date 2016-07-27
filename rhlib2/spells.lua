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
local InCast = {}
local function getCastInfo(spell)
	if not InCast[spell] then
		InCast[spell] = {}
	end
	return InCast[spell]
end
local function UpdateIsCast(event, ...)
    local unit, spell, rank, target = select(1,...)
    if spell and unit == "player" then
        local castInfo = getCastInfo(spell)
        if event == "UNIT_SPELLCAST_SUCCEEDED"
            and castInfo.StartTime and castInfo.StartTime > 0 then
            castInfo.LastCastTime = castInfo.StartTime
        end
        if event == "UNIT_SPELLCAST_SENT" then
            castInfo.StartTime = GetTime()
            castInfo.TargetName = target
        else
            castInfo.StartTime = 0
        end
    end
end
AttachEvent('UNIT_SPELLCAST_SENT', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_SUCCEEDED', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_FAILED', UpdateIsCast)

function GetLastSpellTarget(spell)
    local castInfo = getCastInfo(spell)
    return (castInfo.Target and castInfo.TargetGUID and UnitExists(castInfo.Target) and UnitGUID(castInfo.Target) == castInfo.TargetGUID) and castInfo.Target or nil
end

function GetSpellLastTime(spell)
    local castInfo = getCastInfo(spell)
    return castInfo.LastCastTime or 0
end

function IsSpellNotUsed(spell, t)
    local last  = GetSpellLastTime(spell)
    return GetTime() - last >= t
end

function IsSpellInUse(spellName)
    if not spellName or not InCast[spellName] or not InCast[spellName].StartTime then return false end
    local start = InCast[spellName].StartTime
    if (GetTime() - start <= 0.5) then return true end
    if IsReadySpell(spellName) then InCast[spellName].StartTime = 0 end
    return false
end
------------------------------------------------------------------------------------------------------------------
local badSpellTarget = {}
local inCastSpells = {"Трепка", "Рунический удар", "Удар героя", "Рассекающий удар", "Гиперскоростное ускорение", "Нарукавная зажигательная ракетница"} -- TODO: Нужно уточнить и дополнить.
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
    local IsBusy = IsSpellInUse(spellName)
    if IsBusy then
        if dump then print("Уже прожали, SPELL_SENT пошел, не можем больше прожать", spellName) end
        return false
    end
     -- проверяем, что не кастится другой спел
     for s,_ in pairs(InCast) do
		if not IsBusy and not tContains(inCastSpells, s) and IsSpellInUse(s) then
            if dump then print("Уже прожали " .. s .. ", ждем окончания, пока не можем больше прожать", spellName) end
            IsBusy = true
        end
     end
    if IsBusy then return false end
    -- проверяем, что цель подходящая для этого спела
    if  not manual and UnitExists(target) and badSpellTarget[spellName] then
        local badTargetTime = badSpellTarget[spellName][UnitGUID(target)]
        if badTargetTime and (GetTime() - badTargetTime < 10) then
            if dump then
                print(target, "- Цель не подходящая, не можем прожать", spellName)
            end
            return false
        end
    end

    if not manual and UnitInLos and target and UnitExists(target) and UnitInLos(t) then
        if dump then print("Не можем больше прожать, цель за препятствием", spellName) end
        return false
    end

    -- проверяем что цель в зоне досягаемости
    if not manual and not InRange(spellName, target) then
        if dump then print(target," - Цель вне зоны досягаемости, не можем прожать", spellName) end
        return false
    end

    -- Проверяем что все готово
    if not IsReadySpell(spellName) then
        if dump then print("Не готово, не можем прожать", spellName , "GCD:", InGCD(), "left:", GetSpellCooldownLeft(spellName), "LagTime:", LagTime) end
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

    if not manual and UnitExists(target) then
        -- данные о кастах
        local castInfo = getCastInfo(spellName)
        castInfo.Target = target
        castInfo.TargetName = UnitName(target)
        castInfo.TargetGUID = UnitGUID(target)
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

    -- данные о кастах
    local castInfo = getCastInfo(spellName)
    -- проверка на успешное начало кд
    if castInfo.StartTime and (GetTime() - castInfo.StartTime < 0.01) then
        if not manual and UnitExists(target) then
            -- проверяем цель на соответствие реальной
            if castInfo.TargetName and castInfo.TargetName ~= "" and castInfo.TargetName ~= UnitName(target) then
                if dump then print("Цели не совпали", spellName) end
                StopCast("Цели не совпали")
                --chat("bad target", target, spellName)
                if nil == badSpellTarget[spellName] then
		                badSpellTarget[spellName] = {}
                end
                local badTargets = badSpellTarget[spellName]
                badTargets[UnitGUID(target)] = GetTime()
                castInfo.Target = nil
                castInfo.TargetName = nil
                castInfo.TargetGUID = nil
            end
         end
         if dump then print("Спел вроде прожался", spellName) end

         if Debug then
             local name = UnitName(target)
             name = name or target
             chat(spellName .. " -> ".. name, 0.4,0.4,0.4)
         end
        return true
    end
    if dump then print("SPELL_CAST - не произошел для", spellName) end
    return false
end
