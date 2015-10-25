-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Время сетевой задержки 
LagTime = 0
local lastUpdate = 0
local function UpdateLagTime()
    if GetTime() - lastUpdate < 30 then return end
    lastUpdate = GetTime() 
    LagTime = tonumber(select(3, GetNetStats()) / 1000)  * 1.5

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
            LagTime = GetTime() - sendTime
        end
    end
end
AttachEvent('UNIT_SPELLCAST_START', CastLagTime)
AttachEvent('UNIT_SPELLCAST_SENT', CastLagTime)

------------------------------------------------------------------------------------------------------------------
function IsCasting(unit)
    if not unit then unit = 'player' end
    local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
    if spell == nil then
        spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
    end
    if not spell or not endTime then return false end
    if ((endTime * 0.001 - GetTime()) < LagTime) then return nil end
    return spell, rank, displayName, icon, startTime, endTime
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
    local spell = GetSpellInfo(spellName)
    return (spell == spellName)
end
------------------------------------------------------------------------------------------------------------------
-- Use these spells to detect GCD
local GCDSpells = {
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
GCDSpellID = GCDSpells[GetClass()]

function InGCD()
    local left = GetSpellCooldownLeft(GCDSpellID)
    return (left > LagTime)
end
------------------------------------------------------------------------------------------------------------------
-- Interact range - 40 yards
local interactSpells = {
    DRUID = "Целительное прикосновение",
    PALADIN = "Свет небес",
    SHAMAN = "Волна исцеления",
    PRIEST = "Малое исцеление"
}
InteractRangeSpell = interactSpells[GetClass()]

function InInteractRange(unit)
    -- need test and review
    if (unit == nil) then unit = "target" end
    if not IsInteractUnit(unit) then return false end
    if spell then return IsSpellInRange(InteractRangeSpell,unit) == 1 end
    if IsArena() then return true end
    return InDistance("player", unit, 40)
end
------------------------------------------------------------------------------------------------------------------
local meleeSpells = {
    DRUID = "Цапнуть",        
    DEATHKNIGHT = "Удар чумы", 
    PALADIN = "Щит праведности",
    SHAMAN = "Удар бури",
    WARRIOR = "Кровопускание"
}
MeleeSpell = meleeSpells[GetClass()]
function InMelee(target)
    if (target == nil) then target = "target" end
    return (IsSpellInRange(MeleeSpell,target) == 1)
end

------------------------------------------------------------------------------------------------------------------
function SpellCastTime(spell)
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spell)
    if not name then return 0 end
    return castTime / 1000
end

------------------------------------------------------------------------------------------------------------------
function IsReadySpell(name)
    local usable, nomana = IsUsableSpell(name)
    if not usable then return false end
    local left = GetSpellCooldownLeft(name)
    if left > LagTime then return false end
    local spellName, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(name)
    if cost and cost > 0 and not(powerType == -2 and UnitHealth("player") > cost*2 or UnitPower("player", powerType) >= cost) then return false end
    return IsSpellNotUsed(name, 0.5)
end

------------------------------------------------------------------------------------------------------------------
function GetSpellCooldownLeft(name)
    local start, duration, enabled = GetSpellCooldown(name);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    return left
end

------------------------------------------------------------------------------------------------------------------
function InRange(spell, target) 
    if target == nil then target = "target" end
    if spell and IsSpellInRange(spell,target) == 0 then return false end 
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
local function checkTargetInErrList(target, list)
    if not target then target = "target" end
    if target == "player" then return true end
    if not UnitExists(target) then return false end
    local t = list[UnitGUID(target)]
    if t and GetTime() - t < 1.2 then return false end
    return true;
end

local notVisible = {}
--~ Цель в поле зрения.
function IsVisible(target)
    return checkTargetInErrList(target, notVisible)
end

local notInView = {}
-- передо мной
function IsInView(target)
    return checkTargetInErrList(target, notInView)
end

local notBehind = {}
-- за спиной цели
function IsBehind(target)
    return checkTargetInErrList(target, notBehind)
end

local function UpdateTargetPosition(event, ...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, agrs12, agrs13,agrs14 = select(1, ...)
    if sourceGUID == UnitGUID("player") and (event:match("^SPELL_CAST") and spellID and spellName)  then
        local err = agrs12
        local cast = getCastInfo(spellName)
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
------------------------------------------------------------------------------------------------------------------
function UseSpell(spellName, target)

end