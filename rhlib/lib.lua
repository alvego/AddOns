-- Rotation Helper Library by Timofeev Alexey
SetCVar("cameraDistanceMax", 50)
SetCVar("cameraDistanceMaxFactor", 3.4)
local frame=CreateFrame("Frame",nil,UIParent)
-- attach events
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_SENT")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")


if HarmfulCastingSpell == nil then HarmfulCastingSpell = {} end

SetMapToCurrentZone() 
local LagTime = 0
local sendTime = 0
function onEvent(self, event, ...)
    if event:match("^UNIT_SPELLCAST") then
        local unit, spell = select(1,...)
        if spell and unit == "player" then
            if event == "UNIT_SPELLCAST_START" then
                if not sendTime then return end
                LagTime = GetTime() - sendTime
            end
            if event == "UNIT_SPELLCAST_SENT" then
                sendTime = GetTime()
            end
        end
        return
    end
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, agrs12, agrs13,agrs14 = select(1, ...)
        if type:match("SPELL_DAMAGE") then
            if spellName and agrs12 > 0 then
                local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId) 
                if castTime > 0 then
                    HarmfulCastingSpell[spellName] = true
                end
            end
        end
    end
end
frame:SetScript("OnEvent", onEvent)


function IsHarmfulCast(spellName)
    return HarmfulCastingSpell[spellName]
end

function GetLagTime()
    return LagTime
end

function GetSpellId(name, rank)
    local link = GetSpellLink(name,rank)
    if not link then return nil end
    return 0 + link:match("spell:%d+"):match("%d+")
end

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

function IsBattleField()
    return (GetBattlefieldInstanceRunTime() > 0)
end

function IsArena()
    return (UnitName("arena1") or UnitName("arena2") or UnitName("arena3")  or UnitName("arena4") or UnitName("arena5"))
end

function IsPvP()
    return (IsBattleField() or IsArena() or (IsValidTarget("target") and UnitIsPlayer("target")))
end

function GetClass(target)
    if not target then target = "player" end
    local _, class = UnitClass(target)
    return class
end

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

function UnitIsNPC(unit)
    return not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack("player", unit));
end

function UnitIsPet(unit)
    return not UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit);
end 


function HasSpell(spellName)
    local spell = GetSpellInfo(spellName)
    return spell == spellName
end

function UseHealPotion()
    local potions = { 
    "Камень здоровья из Скверны",
    "Великий камень здоровья",
    "Рунический флакон с лечебным зельем",
    "Бездонный флакон с лечебным зельем",
    }
    local ret = false
    for name,value in pairs(potions) do 
        if not ret and UseItem(value) then ret = true end
    end
    return ret
end


IgnoredNames = {}

function Ignore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then 
        Notify(target .. " not exists")
        return 
    end
    IgnoredNames[n] = true
    Notify("Ignore " .. n)
end

function IsIgnored(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil or not IgnoredNames[n] then return false end
    -- Notify(n .. " in ignore list")
    return true
end

function NotIgnore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n then 
        IgnoredNames[n] = false
        Notify("Not ignore " .. n)
    end
end

function NotIgnoreAll()
    wipe(IgnoredNames)
    Notify("Not ignore all")
end

function IsValidTarget(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then return false end
    if IsIgnored(target) then return false end
    if UnitIsDeadOrGhost(target) then return false end
    if UnitIsEnemy("player",target) and UnitCanAttack("player", target) then return true end 
    if (UnitInParty(target) or UnitInRaid(target)) then return false end 
    return UnitCanAttack("player", target)
end

function IsInteractTarget(t)
    if UnitExists(t) 
        and not IsIgnored(t) 
        and not UnitIsCharmed(t)
        and not UnitIsDeadOrGhost(t) 
        and not UnitIsEnemy("player",t)
        and UnitIsConnected(t)
    then return true end 
    return false
end

local HealComm = LibStub("LibHealComm-4.0")
function UnitGetIncomingHeals(target, s)
    if not target then 
        target = "player" 
    end
    if not s then 
        if UnitHealth100(target) < 10 then return 0 end
        s = 4
        if UnitThreatSituation(target) == 3 then s = 2 end
    end
    return HealComm:GetHealAmount(UnitGUID(target), HealComm.CASTED_HEALS, GetTime() + s) or 0
end

function CalculateHP(t)
  return 100 * UnitHP(t) / UnitHealthMax(t)
end

function UnitHP(t)
  local incomingheals = UnitGetIncomingHeals(t)
  local hp = UnitHealth(t) + incomingheals
  if hp > UnitHealthMax(t) then hp = UnitHealthMax(t) end
  return hp
end

function InGroup()
    return (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0)
end

function GetUnitNames()
    local units = {"player", "target", "focus" }
    local members = GetPartyOrRaidMembers()
    for i = 1, #members, 1 do 
        table.insert(units, members[i])
        table.insert(units, members[i] .."pet")
    end
    table.insert(units, "mouseover")
    realUnits = {}
    for i = 1, #units, 1 do 
        local u = units[i]
        local exists = false
        for j = 1, #realUnits, 1 do
            if UnitName(u) and IsOneUnit(realUnits[j], u) then exists = true end
        end
        if not exists then table.insert(realUnits, u) end
    end
    return realUnits
end

function GetPartyOrRaidMembers()
    local members = {}
    local group = "party"
    if GetNumRaidMembers() > 0 then group = "raid" end
    for i = 1, 40, 1 do 
        if UnitExists(group..i) and UnitName(group..i) ~= nil then table.insert(members, group..i) end
    end
--~     table.sort(members, function(u1, u1) return (UnitThreatSituation(u1) > UnitThreatSituation(u2)) end)
    return members
end


function GetHarmTarget()
    local units = {"target","mouseover","focus","targetlastenemy","arena1","arena2","arena3","arena4","arena5","bos1","bos2","bos3","bos4"}
    local members = GetPartyOrRaidMembers()
    for i = 1, #members, 1 do 
         table.insert(units, members[i] .."-target")
    end
    realUnits = {}
    for i = 1, #units, 1 do 
        local u = units[i]
        local exists = false
        for j = 1, #realUnits, 1 do
            if IsOneUnit(realUnits[j], u) then exists = true end
        end
        if not exists and IsValidTarget(u) then table.insert(realUnits, u) end
    end
    return realUnits
end


function tContainsKey(table, key)
    for name,value in pairs(table) do 
        if key == name then return true end
    end
    return false
end


function IsReadySlot(slot)
    local itemID = GetInventoryItemID("player",slot)
    if not itemID or (IsItemInRange(itemID, "target") == 0) then return false end
    if not IsReadyItem(itemID) then return false end
    return true
end


function UseSlot(slot)
    if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end  
    if IsPlayerCasting() then return false end
    if not IsReadySlot(slot) then return false end
    RunMacroText("/use " .. slot) 
    return true
end

function HasDebuff(debuff, last, target)
    if debuff == nil then return false end
    if target == nil then target = "target" end
    if last == nil then last = 0.1 end
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, debuff) 
    if name == nil then return false end;
    return (expirationTime - GetTime() >= last or expirationTime == 0)
end

function HasBuff(buff, last, target)
    if buff == nil then return false end
    if target == nil then target = "player" end
    if last == nil then last = 0.1 end
    local name, _, _, _, _, _, Expires = UnitBuff(target, buff)
    if name == nil then return false end;
    return (Expires - GetTime() >= last or Expires == 0)
end

function GetBuffStack(aura, target)
    if aura == nil then return false end
    if target == nil then target = "player" end
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(target, aura) 
    if not name or unitCaster ~= "player" or not count then return 0 end;
    return count
end

function GetDebuffTime(aura, target)
    if aura == nil then return false end
    if target == nil then target = "player" end
    local name, _, _, count, _, _, Expires  = UnitDebuff(target, aura) 
    if not name then return 0 end
    if expirationTime == 0 then return 10 end
    local left =  expirationTime - GetTime()
    if left < 0 then left = 0 end
    return left
end

function GetDebuffStack(aura, target)
    if aura == nil then return false end
    if target == nil then target = "target" end
    local name, _, _, count, _, _, Expires  = UnitDebuff(target, aura) 
    if not name or not count then return 0 end;
    return count
end


function GetMyDebuffTime(debuff, target)
    if debuff == nil then return false end
    if target == nil then target = "target" end
    local i = 1
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
    local result = false
        while (i <= 40) and not result do
        if name and strlower(name):match(strlower(debuff)) and (unitCaster == "player")then 
            result = true
        end
        i = i + 1
        if not result then
            name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
        end
    end
    if not result then return 0 end
    if expirationTime == 0 then return 10 end
    local left =  expirationTime - GetTime()
    if left < 0 then left = 0 end
    return left
end



function FindAura(aura, target)
    if aura == nil then return nil end
    if target == nil then target = "player" end
    local i = 1
    local name  = UnitAura(target, i)
    local result = false
    while (i <= 40) and not result  do
        if name and strlower(name):match(strlower(aura)) then result = name end
        i = i + 1
        if not result then name = UnitAura(target, i) end
    end
    return result
end

function HasMyBuff(buff, last, target)
    if buff == nil then return false end
    if target == nil then target = "player" end
    if last == nil then last = 0.1 end
    local i = 0
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(target, i)
    local result = false
    while (i <= 40) and not result do
        if name and strlower(name):match(strlower(buff)) and (unitCaster == nil or unitCaster == "player") then 
            result = true
        end
        i = i + 1
        if not result then
            name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(target, i)
        end
    end
    if not result then return false end
    return (expirationTime - GetTime() >= last or expirationTime == 0)
end

function HasMyDebuff(debuff, last, target)
    if debuff == nil then return false end
    if target == nil then target = "target" end
    if last == nil then last = 0.1 end
    local i = 0
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
    local result = false
    while (i <= 40) and not result do
        if name and strlower(name):match(strlower(debuff)) and (unitCaster == "player") then 
            result = true
        end
        i = i + 1
        if not result then
            name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
        end
    end
    if not result then return false end
    return (expirationTime - GetTime() >= last or expirationTime == 0)
end

function GetUtilityTooltips()
    if ( not RH_Tooltip1 ) then
        for idxTip = 1,2 do
            local ttname = "RH_Tooltip"..idxTip
            local tt = CreateFrame("GameTooltip", ttname)
            tt:SetOwner(UIParent, "ANCHOR_NONE")
            tt.left = {}
            tt.right = {}
            -- Most of the tooltip lines share the same text widget,
            -- But we need to query the third one for cooldown info
            for i = 1, 30 do
                tt.left[i] = tt:CreateFontString()
                tt.left[i]:SetFontObject(GameFontNormal)
                if i < 5 then
                    tt.right[i] = tt:CreateFontString()
                    tt.right[i]:SetFontObject(GameFontNormal)
                    tt:AddFontStrings(tt.left[i], tt.right[i])
                else
                    tt:AddFontStrings(tt.left[i], tt.right[4])
                end
            end 
         end
    end
    local tt1,tt2 = RH_Tooltip1, RH_Tooltip2
    
    tt1:ClearLines()
    tt2:ClearLines()
    return tt1,tt2
end

--~ using: TempEnchantName = DetermineTempEnchantFromTooltip(16 or 17)
function DetermineTempEnchantFromTooltip(i_invID)
    local tt1,tt2 = GetUtilityTooltips()
    
    tt1:SetInventoryItem("player", i_invID)
    local n,h = tt1:GetItem()

    tt2:SetHyperlink(h)
    
    -- Look for green lines present in tt1 that are missing from tt2
    local nLines1, nLines2 = tt1:NumLines(), tt2:NumLines()
    local i1, i2 = 1,1
    while ( i1 <= nLines1 ) do
        local txt1 = tt1.left[i1]
        if ( txt1:GetTextColor() ~= 0 ) then
            i1 = i1 + 1
        elseif ( i2 <= nLines2 ) then
            local txt2 = tt2.left[i2]
            if ( txt2:GetTextColor() ~= 0 ) then
                i2 = i2 + 1
            elseif (txt1:GetText() == txt2:GetText()) then
                i1 = i1 + 1
                i2 = i2 + 1
            else
                break
            end
        else
            break
        end
    end
    if ( i1 <= nLines1 ) then
        local line = tt1.left[i1]:GetText()
        local paren = line:find("[(]")
        if ( paren ) then
            line = line:sub(1,paren-2)
        end
        return line
    end    
end

function Runes(slot)
    local c = 0
    if slot == 1 then
       if IsRuneReady(1) then c = c + 1 end
       if IsRuneReady(2) then c = c + 1 end
    elseif slot == 2 then
        if IsRuneReady(5) then c = c + 1 end
        if IsRuneReady(6) then c = c + 1 end
    elseif slot == 3 then
        if IsRuneReady(3) then c = c + 1 end
        if IsRuneReady(4) then c = c + 1 end
    end
    return c;
end

function NoRunes(t)
    if (t == nil) then t = 1.6 end
    if GetRuneCooldownLeft(1) < t then return false end
    if GetRuneCooldownLeft(2) < t then return false end
    if GetRuneCooldownLeft(3) < t then return false end
    if GetRuneCooldownLeft(4) < t then return false end
    if GetRuneCooldownLeft(5) < t then return false end
    if GetRuneCooldownLeft(6) < t then return false end
    return true
end

function IsRuneReady(id)
    local left = GetRuneCooldownLeft(id)
    if left == 0 then return true end
    return false;
end


function GetRuneCooldownLeft(id)
    local start, duration, enabled = GetRuneCooldown(id);
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    if left < 0 then left = 0 end
    return left;
end


function GetItemCooldownLeft(name)
    local start, duration = GetItemCooldown(name);
    if not start then return 0 end
    if not duration or duration < 1.45 then duration = 1.45  end
    local left = start + duration - GetTime()
    if left < 0.01 then 
        return 0
    end
    return left
end

function IsReadyItem(name)
   local usable = IsUsableItem(name) 
   if not usable then return true end
   local left = GetItemCooldownLeft(name)
   return (left < 0.01)
end


function UseItem(itemName)
    if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end  
    if IsPlayerCasting() then return false end
    if not IsEquippedItem(itemName) and not IsUsableItem(itemName) then return false end
    if not IsReadyItem(itemName) then return false end
    RunMacroText("/use " .. itemName)
    return true
end

function UseEquippedItem(item)
    if IsEquippedItem(item) and UseItem(item) then return true end
    return false
end

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

  
  
  
  
function HasTotem(name, last)
--[[Где (1) Это Огненный 
(2) = Земляной
(3) = Водный
(4) = Воздух]]
    if not last then last = 0.01 end
    
    local n = tonumber(name)
    if n ~= nil then
        local _, totemName, startTime, duration = GetTotemInfo(n)
        if totemName and startTime and (startTime+duration-GetTime() > last) then return totemName end
        return false
    end
    
    for index=1,4 do
        local _, totemName, startTime, duration = GetTotemInfo(index)
        if totemName and strlower(totemName):match(strlower(name)) and startTime and (startTime+duration-GetTime() > last) then return true end
    end
    return false
end

function TotemCount()
    local n = 0
    for index=1,4 do
        local _, totemName, startTime, duration = GetTotemInfo(index)
        if totemName and startTime and (startTime+duration-GetTime() > 0.01) then n = n + 1 end
    end
    return n
end

function GetGCDSpellID()
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

function GetMeleeSpell()
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

function SpellCastTime(spell)
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spell)
    if not name then return 0 end
    return castTime / 1000
end

function IsOneUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return false end
    return UnitGUID(unit1) == UnitGUID(unit2)
end

function UnitThreat(u, t)
    local threat = UnitThreatSituation(u, t)
    if threat == nil then threat = 0 end
    return threat
end


function UnitHealth100(target)
    if target == nil then target = "player" end
    return UnitHealth(target) * 100 / UnitHealthMax(target)
end

function UnitMana100(target)
    if target == nil then target = "player" end
    return UnitMana(target) * 100 / UnitManaMax(target)
end

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


function CheckDistanceCoord(unit, x2, y2)
    local mapFileName, textureHeight, textureWidth = GetMapInfo()
    if not mapFileName then return nil end
    local x1,y1 = GetYardCoords(unit)
    if x1 == 0 or y1 == 0 or x2 == 0 or y2 == 0 then return nil end
    local dx = (x1-x2)
    local dy = (y1-y2)
    return sqrt( dx^2 + dy^2 )
end


function CheckDistance(unit1,unit2)
  local x2,y2 = GetYardCoords(unit2)
  return CheckDistanceCoord(unit1, x2,y2)
end

function InRange(spell, target) 
    if target == nil then target = "target" end
    if spell and IsSpellInRange(spell,target) == 0 then return false end 
    return true    
end

function UseSpell(spellName, target)
    if SpellIsTargeting() then return false end 
     
    if IsPlayerCasting() then return false end

    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    
    if not name or (name ~= spellName)  then
        if IsDebug() then print("UseSpell:Ошибка! Спел [".. spellName .. "] не найден!") end
        return false;
    end
    
    
    if not InRange(name,target) then return false end  
    if IsReadySpell(spellName) then
        
        local cast = "/cast "
        if target ~= nil then cast = cast .."[target=".. target .."] "  end
        if cost and cost > 0 and UnitManaMax("player") > cost and UnitMana("player") <= cost then return false end
        if IsDebug() then
            -- print(spellName, cost, UnitMana("player"), target)
        end
        
        RunMacroText(cast .. "!" .. spellName)
        if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end 

        return true
    end
    return false
end


-------------------------------------------------------------------------------
-- Debug & Notification Frame
-------------------------------------------------------------------------------
-- Update Debug Frame
NotifyFrame = nil
function NotifyFrame_OnUpdate()
        if (NotifyFrameTime < GetTime() - 5) then
                local alpha = NotifyFrame:GetAlpha()
                if (alpha ~= 0) then NotifyFrame:SetAlpha(alpha - .02) end
                if (aplha == 0) then NotifyFrame:Hide() end
        end
end

-- Debug messages.
function Notify(message)
        NotifyFrame.text:SetText(message)
        NotifyFrame:SetAlpha(1)
        NotifyFrame:Show()
        NotifyFrameTime = GetTime()
end

-- Debug Notification Frame
NotifyFrame = CreateFrame('Frame')
NotifyFrame:ClearAllPoints()
NotifyFrame:SetHeight(300)
NotifyFrame:SetWidth(300)
NotifyFrame:SetScript('OnUpdate', NotifyFrame_OnUpdate)
NotifyFrame:Hide()
NotifyFrame.text = NotifyFrame:CreateFontString(nil, 'BACKGROUND', 'PVPInfoTextFont')
NotifyFrame.text:SetAllPoints()
NotifyFrame:SetPoint('CENTER', 0, 200)
NotifyFrameTime = 0


function echo(msg, cls)
    if (cls ~= nil) then UIErrorsFrame:Clear() end
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end


function chat(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.5, 0.5);
end



function buy(name,q) 
    local c = 0
    for i=0,3 do 
        local numberOfFreeSlots = GetContainerNumFreeSlots(i);
        if numberOfFreeSlots then c = c + numberOfFreeSlots end
    end
    if c < 1 then return end
    if q == nil then q = 255 end
    for i=1,100 do 
        if name == GetMerchantItemInfo(i) then
            local s = c*GetMerchantItemMaxStack(i) 
            if q > s then q = s end
            BuyMerchantItem(i,q)
        end 
    end
end

function sell(name) 
    if not name then name = "" end
    for bag = 0,4,1 do for slot = 1, GetContainerNumSlots(bag), 1 do local item = GetContainerItemLink(bag,slot); if item and string.find(item,name) then UseContainerItem(bag,slot) end; end;end
end




function printtable(t, indent)

  indent = indent or 0;

  local keys = {};

  for k in pairs(t) do
    keys[#keys+1] = k;
    table.sort(keys, function(a, b)
      local ta, tb = type(a), type(b);
      if (ta ~= tb) then
        return ta < tb;
      else
        return a < b;
      end
    end);
  end

  print(string.rep('  ', indent)..'{');
  indent = indent + 1;
  for k, v in pairs(t) do

    local key = k;
    if (type(key) == 'string') then
      if not (string.match(key, '^[A-Za-z_][0-9A-Za-z_]*$')) then
        key = "['"..key.."']";
      end
    elseif (type(key) == 'number') then
      key = "["..key.."]";
    end

    if (type(v) == 'table') then
      if (next(v)) then
        print(format("%s%s =", string.rep('  ', indent), tostring(key)));
        printtable(v, indent);
      else
        print(format("%s%s = {},", string.rep('  ', indent), tostring(key)));
      end 
    elseif (type(v) == 'string') then
      print(format("%s%s = %s,", string.rep('  ', indent), tostring(key), "'"..v.."'"));
    else
      print(format("%s%s = %s,", string.rep('  ', indent), tostring(key), tostring(v)));
    end
  end
  indent = indent - 1;
  print(string.rep('  ', indent)..'}');
end