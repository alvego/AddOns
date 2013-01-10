-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local LagTime = 0
local sendTime = 0
local function UpdateLag(event, ...)
    local unit, spell = select(1,...)
    if spell and unit == "player" then
        if event == "UNIT_SPELLCAST_SENT" then
            sendTime = GetTime()
        end
        if event == "UNIT_SPELLCAST_START" then
            if not sendTime then return end
            LagTime = GetTime() - sendTime
        end
    end
end
AttachEvent('UNIT_SPELLCAST_START', UpdateLag)
AttachEvent('UNIT_SPELLCAST_SENT', UpdateLag)
-- Время сетевой задержки 
function GetLagTime()
    return LagTime
end

------------------------------------------------------------------------------------------------------------------
function IsPlayerCasting()
    local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo("player")
    if spell == nil then
        spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo("player")
    end
    if not spell or not endTime then return false end
    local res = ((endTime/1000 - GetTime()) < GetLagTime())
    if res then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------
function GetSpellId(name, rank)
    local link = GetSpellLink(name,rank)
    if not link then return nil end
    return 0 + link:match("spell:%d+"):match("%d+")
end

------------------------------------------------------------------------------------------------------------------
function HasSpell(spellName)
    local spell = GetSpellInfo(spellName)
    return spell == spellName
end

------------------------------------------------------------------------------------------------------------------
local function GetGCDSpellID()
    -- Use these spells to detect GCD
	local spells = {
		PALADIN = 635,       -- Holy Light I [OK]
		PRIEST = 1243,       -- Power Word: Fortitude I
		SHAMAN = 8071,       -- Rockbiter I
		WARRIOR = 772,       -- Rend I (only from level 4) [OK]
		DRUID = 5176,        -- Wrath I
		MAGE = 168,          -- Frost Armor I
		WARLOCK = 687,       -- Demon Skin I
		ROGUE = 1752,        -- Sinister Strike I
		HUNTER = 1978,       -- Serpent Sting I (only from level 4)
		DEATHKNIGHT = 45902, -- Blood Strike I
	}
    return spells[GetClass()]
end

function InGCD()
    local gcdStart = GetSpellCooldown(GetGCDSpellID());
    return (gcdStart and (gcdStart>0));
end
------------------------------------------------------------------------------------------------------------------
-- Interact range - 40 yards
local function GetInteractRangeSpell()
	local spells = {
		DRUID = "Целительное прикосновение",
        PALADIN = "Свет небес",
        SHAMAN = "Волна исцеления",
        PRIEST = "Малое исцеление"
	}
    return spells[GetClass()]
end

function InInteractRange(unit)
    -- need test and review
    if (unit == nil) then unit = "target" end
    if not IsInteractUnit(unit) then return false end
    local spell = GetInteractRangeSpell()
    if spell then return IsSpellInRange(spell,unit) == 1 end
    if IsArena() then return true end
    return InDistance("player", unit, 40)
end
------------------------------------------------------------------------------------------------------------------
local function GetMeleeSpell()
    -- Use these spells to melee
	local spells = {
		DRUID = "Цапнуть",        
		DEATHKNIGHT = "Удар чумы", 
        PALADIN = "Щит праведности",
        SHAMAN = "Удар бури"
	}
    return spells[GetClass()]
end

function InMelee(target)
    if (target == nil) then target = "target" end
    return (IsSpellInRange(GetMeleeSpell(),target) == 1)
end

------------------------------------------------------------------------------------------------------------------
function SpellCastTime(spell)
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spell)
    if not name then return 0 end
    return castTime / 1000
end

------------------------------------------------------------------------------------------------------------------
--~ local GCDSpellList = {}
function IsReadySpell(name)
    local usable, nomana = IsUsableSpell(name)
    if not usable then return false end
    local left = GetSpellCooldownLeft(name)
    local spellName, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(name)
--~     local leftGCD = GetSpellCooldownLeft(GetGCDSpellID())
--~     
--~     if InGCD() and tContains(GCDSpellList,name) then
--~         return false
--~     end
--~     
--~     if InGCD() and (left == leftGCD) then
--~         if not tContains(GCDSpellList,name) then 
--~             tinsert(GCDSpellList, name)
--~         end
--~     end
    
    if left > 0 then return false end
    
    if cost and cost > 0 and not(UnitPower("player", powerType) >= cost) then return false end
    
    return true
end

------------------------------------------------------------------------------------------------------------------
function GetSpellCooldownLeft(name)
    local start, duration, enabled = GetSpellCooldown(name);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
--~     if duration < 1 then 
--~         print(name, duration)
--~         duration = 1.4 
--~     end
    local left = start + duration - GetTime()
    return left
end

------------------------------------------------------------------------------------------------------------------
function UseMount(mountName)
    if IsPlayerCasting() then return false end
    if InGCD() then return false end
    if IsMounted()then return false end
    if Debug then
        print(mountName)
    end
    RunMacroText("/use "..mountName)
    return true
end

------------------------------------------------------------------------------------------------------------------
function InRange(spell, target) 
    if target == nil then target = "target" end
    if spell and IsSpellInRange(spell,target) == 0 then return false end 
    return true    
end

------------------------------------------------------------------------------------------------------------------
local InCast = {}
local function UpdateIsCast(event, ...)
	local unit, spell, rank, target = select(1,...)
	if spell and unit == "player" then
        local cast = InCast[spell] or {}
        if event == "UNIT_SPELLCAST_SENT" then
            cast.StartTime = GetTime()
            cast.TargetName = target
        else
            cast.StartTime = 0
        end
        InCast[spell] = cast
    end
end
AttachEvent('UNIT_SPELLCAST_SENT', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_SUCCEEDED', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_FAILED', UpdateIsCast)
-- сброс при простое, не в бою, на всякий пожарный, как защита от залипания
local function UpdateCombatReset() 
	if not InCombatLockdown() and not IsPlayerCasting() and #InCast > 0 then  wipe(InCast) end 
end
--AttachUpdate(UpdateCombatReset)

------------------------------------------------------------------------------------------------------------------
--~ Цель вне поля зрения.
local function checkTargetInErrList(target, list)
    if not target or target == "player"  then return true end
    if not UnitExists(target) then return false end
    local t = list[UnitGUID(target)]
    if t and GetTime() - t < 1.2 then return false end
    return true;
end

local notVisible = {}
function IsVisible(target)
    return checkTargetInErrList(target, notVisible)
end

-- не передо мной
local notInView = {}
function IsInView(target)
    return checkTargetInErrList(target, notInView)
end


-- не за спиной цели
local notBehind = {}
function IsBehind(target)
    return checkTargetInErrList(target, notBehind)
end


local function UpdateTargetPosition(event, ...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, agrs12, agrs13,agrs14 = select(1, ...)
    if sourceGUID == UnitGUID("player") and (event:match("^SPELL_CAST") and spellID and spellName)  then
        local err = agrs12
        local cast = InCast[spellName] or {}
        local guid = cast.TargetGUID or nil
        if err and guid then
            if err == "Цель вне поля зрения." then
                notVisible[guid] = GetTime()
            end
            if err == "Цель должна быть перед вами." then
                notInView[guid] = GetTime() 
            end
            if err == "Вы должны находиться позади цели." then 
                notBehind[guid] = GetTime() 
            end
        end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateTargetPosition)
---------------------------------------
local badSpellTarget = {}
function UseSpell(spellName, target)
    -- Не мешаем выбрать облась для спела (нажат вручную)
    if SpellIsTargeting() then return false end 
    -- Не пытаемся что либо прожимать во время каста
    if IsPlayerCasting() then return false end
    -- Проверяем на наличе спела в спелбуке
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    if not name or (name ~= spellName)  then
        if Debug then print("UseSpell:Ошибка! Спел [".. spellName .. "] не найден!") end
        return false;
    end
    -- чтоб не залипало, ставим минимальный интервал
    if not castTime or castTime < 0.5 then castTime = 0.5 end
    -- проверяем, что этот спел не используется сейчас
    if InCast[spellName] and InCast[spellName].StartTime and (GetTime() - InCast[spellName].StartTime <= castTime) then return false end
    -- проверяем, что цель подходящая для этого спела
    local badTargets =  badSpellTarget[spellName] or {}
    if UnitExists(target) and badTargets[UnitGUID(target)] and (GetTime() - badTargets[UnitGUID(target)] < 10) then return false end
    -- проверяем что цель в зоне досягаемости
    if not InRange(spellName, target) then return false end  
    -- Проверяем что все готово
    if IsReadySpell(spellName) then
        -- собираем команду
        local cast = "/cast "
        -- с учетом цели
        if target ~= nil then cast = cast .."[target=".. target .."] "  end
        -- проверяем, хвататет ли нам маны
        if cost and cost > 0 and UnitManaMax("player") > cost and UnitMana("player") <= cost then return false end
        -- пробуем скастовать
        RunMacroText(cast .. "!" .. spellName)
        -- если нужно выбрать область - кидаем на текущий mouseover
        if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end 
        -- проверка на успешное начало кд
        local start, duration, enabled = GetSpellCooldown(spellName)
        if start > 0 and (GetTime() - start < 0.01) then
            -- данные о кастах
            local cast = InCast[spellName] or {}
            if UnitExists(target) then 
                -- проверяем цель на соответсвие реальной
                if cast.TargetName and cast.TargetName ~= UnitName(target) then 
                    RunMacroText("/stopcasting") 
                    --chat("bad target", target, spellName)
                    badTargets[UnitGUID(target)] = GetTime()
                    badSpellTarget[spellName] = badTargets
                else
                    cast.Target = target
                    cast.TargetName = UnitName(target)
                    cast.TargetGUID = UnitGUID(target)
                end
            end
            InCast[spellName] = cast
            if Debug then
                print(spellName, cost, UnitMana("player"), target)
            end
            return true
        end
    end
    return false
end