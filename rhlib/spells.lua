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

    return GCDSpells[GetClass()]
end

function InGCD()
    local gcdStart = GetSpellCooldown(GetGCDSpellID());
    return (gcdStart and (gcdStart>0));
end

------------------------------------------------------------------------------------------------------------------
local function GetMeleeSpell()
    -- Use these spells to melee GCD
	local MeleeSpells = {
		DRUID = "Цапнуть",        
		DEATHKNIGHT = "Удар чумы", 
        PALADIN = "Щит праведности",
        SHAMAN = "Удар бури"
	}
    
    return MeleeSpells[GetClass()]
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
    if IsDebug() then
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
	local unit, spell = select(1,...)
	if spell and unit == "player" then
		if event == "UNIT_SPELLCAST_SENT" then
			InCast[spell] = GetTime()
		end
		if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" then
			InCast[spell] = nil
		end
	end
end
AttachEvent('UNIT_SPELLCAST_SENT', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_SUCCEEDED', UpdateIsCast)
AttachEvent('UNIT_SPELLCAST_FAILED', UpdateIsCast)
-- сброс при простое, не в бою, на всякий пожарный, как защита от залипания
local function UpdateCombatReset() 
	if not InCombatLockdown() and not IsPlayerCasting() and #InCast > 0 then  wipe(InCast) end 
end
AttachUpdate(UpdateCombatReset)
------------------------------------------------------------------------------------------------------------------

function UseSpell(spellName, target)
    if SpellIsTargeting() then return false end 
    
    if IsPlayerCasting() then return false end

    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    
    if not name or (name ~= spellName)  then
        if IsDebug() then print("UseSpell:Ошибка! Спел [".. spellName .. "] не найден!") end
        return false;
    end
    
    if not castTime or castTime < 0.5 then castTime = 0.5 end
    if InCast[spell] and (GetTime() - InCast[spell] <= castTime) then return false end
    
    if not InRange(name,target) then return false end  
    if IsReadySpell(spellName) then
        local cast = "/cast "
        if target ~= nil then cast = cast .."[target=".. target .."] "  end
        if cost and cost > 0 and UnitManaMax("player") > cost and UnitMana("player") <= cost then return false end
        RunMacroText(cast .. "!" .. spellName)
        if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end 
        local start, duration, enabled = GetSpellCooldown(spellName)
        if start > 0 and (GetTime() - start < 0.1) then  
            if Debug then
                print(spellName, cost, UnitMana("player"), target)
            end
            return true
        end
    end
    return false
end