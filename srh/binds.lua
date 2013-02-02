-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Binding
BINDING_HEADER_SRH = "Shaman Rotation Helper"
BINDING_NAME_SRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_SRH_AUTOAOE = "Вкл/Выкл авто AOE"
BINDING_NAME_SRH_TOTEMS = "Автоматически ставить тотемы"
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end 
end
------------------------------------------------------------------------------------------------------------------

if AutoAOE == nil then AutoAOE = true end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON",true)
    else
        echo("Авто АОЕ: OFF",true)
    end 
end


function IsAOE()
   return (IsShiftKeyDown() == 1) 
    or (AutoAOE and IsValidTarget("target") and IsValidTarget("focus") 
        and not IsOneUnit("target", "focus") 
        and UnitAffectingCombat("focus") and UnitAffectingCombat("target"))
end

------------------------------------------------------------------------------------------------------------------
local AutoTotems = true
function CanAutoTotems()
    return AutoTotems
end

function Totems()
    AutoTotems = not AutoTotems
    if AutoTotems then
        echo("AutoTotems: ON",true)
    else
        echo("AutoTotems: OFF",true)
    end 
end


function IsMDD()
    return HasSpell("Бой двумя оружиями")
end

function IsRDD()
    return HasSpell("Гром и молния")
end

function IsHeal()
    return HasSpell("Быстрина")
end

function RoleName()
    if IsMDD() then return "МДД" end
    if IsRDD() then return "РДД" end
    return "Хил"
end

function RoleDD()
    Role = 1
    Notify(RoleName())
end

function RoleHeal()
    Role = 2
    Notify(RoleName())
end

------------------------------------------------------------------------------------------------------------------
local resList = {}
local resSpell = "Дух предков"
function CanRes(t)
    if InCombatLockdown() then return false end
    if not (UnitExists(t)
        and UnitIsPlayer(t)
        and not UnitIsAFK(t)
        and not UnitIsFeignDeath(t)
        and not UnitIsEnemy("player",t)
        and UnitIsDead(t)
        and not UnitIsGhost(t)
        and UnitIsConnected(t)
        and IsVisible(t)
        and InRange(resSpell, t)
        and (not resList[UnitGUID(t)] or (GetTime() - resList[UnitGUID(t)]) > 5)
    ) then return false end
    return true
end

function TryRes(t)
    if not CanRes(t) then return false end
    if DoSpell(resSpell, t) then
        Notify(resSpell .. " на " .. UnitName(t))
        resList[UnitGUID(t)] = GetTime()
        return true
    end
    return false
end

function UpdateCanRes(event, ...)
    local unit, spell = select(1,...)
    if spell and spell == resSpell and unit == "player" then
        local u = GetLastSpellTarget(resSpell)
        resList[UnitGUID(u)] = GetTime() + 60
        Notify("Успешно применил "..resSpell .. " на " .. u)
    end
end
AttachEvent("UNIT_SPELLCAST_SUCCEEDED", UpdateCanRes)

local function UpdateResCast(elapsed)
    if (CanHeal(resUnit) and UnitCastingInfo("player") == resSpell)  then RunMacroText("/stopcasting") end
end
AttachUpdate(UpdateResCast, 900)


------------------------------------------------------------------------------------------------------------------
-- dispel
if DispelBlackList == nil then DispelBlackList = {} end
if DispelWhiteList == nil then DispelWhiteList = {} end
function IsDispelTotemNeed(units)
    return TryEach(units, function(unit) 
        local ret = false
        for i = 1, 40 do
            if not ret then
                local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
                if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) 
                    and tContains({"Poison", "Disease"}, debuffType) and tContains(DispelWhiteList, name) then
                    ret = true 
                end
            end
        end
        return ret
    end)
end

local dispelSpell = "Очищение духа"
local dispelTypes = {"Poison", "Disease", "Curse"}
function TryDispel(unit)
    if not HasSpell(dispelSpell) or not IsReadySpell(dispelSpell) or InGCD() or not CanHeal(unit) then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) 
                and (tContains(DispelWhiteList, name) or tContains(dispelTypes, debuffType) and not tContains(DispelBlackList, name)) then
                if not (UnitMana100("player") < 50 and HasTotem("Тотем очищения") and tContains({"Poison", "Disease"}, debuffType)) and DoSpell(dispelSpell, unit) then 
                    ret = true 
                end
            end
        end
    end
    return ret
end

local function UpdateDispelLists(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel = select(1, ...)
    local unit = GetLastSpellTarget(dispelSpell)
    
    if type:match("^SPELL_CAST") and sourceGUID == UnitGUID("player") 
        and spellId and spellName and spellName == dispelSpell
        and unit and err and err == "Нечего рассеивать." then
        for i = 1, 40 do
            local name, _, _, _, debuffType = UnitDebuff(unit, i,true) 
            if name and tContains(dispelTypes, debuffType) 
                and not tContains(DispelWhiteList, name)
                and not tContains(DispelBlackList, name) then
                tinsert(DispelBlackList, name)
            end
        end
    end
        
    if type == "SPELL_DISPEL" and (sourceGUID == UnitGUID("player") or sourceName == "Тотем очищения") 
        and dispel and not tContains(DispelWhiteList, dispel) then
        tinsert(DispelWhiteList, dispel)
    end
end    

AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateDispelLists)

------------------------------------------------------------------------------------------------------------------
-- steal
if StealBlackList == nil then StealBlackList = {} end
if StealWhiteList == nil then StealWhiteList = {} end
local stealSpell = "Развеивание магии"
local stealTypes = {"Magic"}
function TrySteal(target)
    if not HasSpell(stealSpell) or not IsReadySpell(stealSpell) or InGCD() or not CanMagicAttack(target) then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitBuff(target, i) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) 
                and (tContains(StealWhiteList, name) 
                or tContains(stealTypes, debuffType) and not tContains(StealBlackList, name)) then
                if DoSpell(stealSpell, target) then 
                    ret = true 
                end
            end
        end
    end
    return ret
end

local function UpdateStealLists(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, steal = select(1, ...)
    local target = GetLastSpellTarget(stealSpell)
    if sourceGUID == UnitGUID("player")
        and spellId and spellName and spellName == stealSpell then

        if type:match("^SPELL_CAST") 
            and target and err and err == "Нечего рассеивать." then
            for i = 1, 40 do
                local name, _, _, _, debuffType = UnitBuff(target, i,true) 
                if name and tContains(stealTypes, debuffType) 
                    and not tContains(StealWhiteList, name)
                    and not tContains(StealBlackList, name) then
                    tinsert(StealBlackList, name)
                end
            end
        end
        
        if type == "SPELL_DISPEL" and not tContains(StealWhiteList, steal) then
            tinsert(StealWhiteList, steal)
        end
    end
end    

AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateStealLists)
------------------------------------------------------------------------------------------------------------------
if InterruptWhiteList == nil then InterruptWhiteList = {} end
if InterruptBlackList == nil then InterruptBlackList = {} end
local interruptSpell = "Пронизывающий ветер"
local interruptedSpell = nil
function TryInterrupt(target, hp)
    if target == nil then target = "target" end
    if not IsValidTarget(target) then return false end
    local channel = false
    local canBreak = not hp or hp > 60
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    
    if not spell then return false end
    
    
    --if tContains(InterruptBlackList, spell) then return false end
    
    if not CanInterrupt and not InInterruptRedList(spell) then return false end
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end

    if (channel or t < 0.8) and not notinterrupt and IsReadySpell(interruptSpell) and InRange(interruptSpell,target) 
        and not HasBuff({"Мастер аур"}, 0.1, target) and CanMagicAttack(target) then
        if canBreak and UnitCastingInfo("player") ~= nil then RunMacroText("/stopcasting") end
        if UseSpell(interruptSpell, target) then 
            interruptedSpell = spell 
            echo("Interrupt " .. spell .. " ("..target.." => " .. UnitName(target) .. ")")
            return true 
        end
    end
     
    if (not channel and t < 1.8) and not HasTotem("Тотем заземления") and IsReadySpell("Тотем заземления") 
        and IsHarmfulCast(spell) then
        if canBreak and UnitCastingInfo("player") ~= nil then RunMacroText("/stopcasting") end
        if UseSpell("Тотем заземления") then 
            print("Тотем заземления " .. spell .. " (".. UnitName(target) .. ")")
            return true 
        end
    end
    
    return false    
end

local function UpdateInterruptErr(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, arg13 = select(1, ...)
    if sourceGUID == UnitGUID("player")
        and spellId and spellName and spellName == interruptSpell then
        if type:match("^SPELL_CAST") then
            local target = GetLastSpellTarget(interruptSpell)
            if target and err and type(err) == "string" and interruptedSpell then
                local utype = GetUnitType(target)
                local spells = InterruptBlackList[utype] or {}
                local info = interruptedSpell + '|' + err
                if not tContains(spells, info) then
                    tinsert(spells, info)
                end
                InterruptBlackList[utype] = spells
            end
        end
    end
end    
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateInterruptErr)

function UpdateInterruptWhiteList(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, args12, interruptedSpell = select(1, ...)
    if type == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player") and spellId and spellName and spellName == interruptSpell then 
        local target = GetLastSpellTarget(interruptSpell)
        if target then
            local utype = GetUnitType(target)
            local spells = InterruptWhiteList[utype] or {}
            if not tContains(spells, interruptedSpell) then
                tinsert(spells, interruptedSpell)
            end
            InterruptWhiteList[utype] = spells
        end
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateInterruptWhiteList)

------------------------------------------------------------------------------------------------------------------
function UpdateAutoFreedom(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel = select(1, ...)
    if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)
        and err and err:match("Действие невозможно")  
        and HasDebuff(ControlList, 3.8, "player") 
        and TryEach(UNITS, function(u) return CanHeal(u) and CalculateHP(u) < 40 end) then 
        DoCommand("freedom") 
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateAutoFreedom)
------------------------------------------------------------------------------------------------------------------

function DoSpell(spell, target)
    return UseSpell(spell, target)
end
