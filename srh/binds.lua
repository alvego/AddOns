-- Shaman Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_SRH = "Shaman Rotation Helper"
BINDING_NAME_SRH_OFF = "Выкл ротацию"
BINDING_NAME_SRH_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_SRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_SRH_AUTOAOE = "Вкл/Выкл авто AOE"
BINDING_NAME_SRH_LISTMODE = "Вкл/Выкл WhiteList"
BINDING_NAME_SRH_TOTEMS = "Автоматически ставить тотемы"

-- addon main frame
local frame=CreateFrame("Frame",nil,UIParent)
print("Shaman Rotation Helper loaded")
-- protected lock test
RunMacroText("/cleartarget")
-- attach events
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
frame:RegisterEvent("UNIT_SPELLCAST_SENT")

local LastUpdate = 0
local UpdateInterval = 0.0001

local resList = {}
local NextTarget = nil
local NextGUID = nil
local AutoTotems = true

if Paused == nil then Paused = false end
if Debug == nil then Debug = false end
if CanInterrupt == nil then CanInterrupt = true end
if AutoAOE == nil then AutoAOE = true end

if DispelWhiteList == nil then DispelWhiteList = {} end
if DispelBlackList == nil then DispelBlackList = {} end

if StealWhiteList == nil then StealWhiteList = {} end
if StealBlackList == nil then StealBlackList = {} end

if InterruptWhiteList == nil then InterruptWhiteList = {} end
if InterruptBlackList == nil then InterruptBlackList = {} end

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


function CanUseInterrupt()
    return CanInterrupt
end


function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end 
end


function GetNextTarget()
    return NextTarget
end

function ClearNextTarget()
    NextTarget = nil
    NextGUID = nil
end


function NextIsTarget(target)
    if not target then target = "target" end
    return (UnitGUID("target") == NextGUID)
end

    
function AutoRotationOff()
    Paused = true
    RunMacroText("/stopattack")
    RunMacroText("/stopcasting")
    wipe(resList)
    echo("Авто ротация: OFF",true)
end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON",true)
    else
        echo("Авто АОЕ: OFF",true)
    end 
end

function CanAutoAOE()
    return AutoAOE
end 

function DebugToggle()
    Debug = not Debug
    if Debug then
         SetCVar("scriptErrors", 1)
        echo("Режим отладки: ON",true)
    else
         SetCVar("scriptErrors", 0)
        echo("Режим отладки: OFF",true)
    end 
end

function IsDebug()
    return Debug
end    

function IsAttack()
    return (IsMouseButtonDown(4) == 1)
end

function IsAOE()
   return (IsShiftKeyDown() == 1) or (CanAutoAOE() and IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and UnitAffectingCombat("focus") and UnitAffectingCombat("target"))
end

local resSpell = nil
local resUnit = nil
function CanRes(t)
    if not (UnitExists(t)
        and UnitIsPlayer(t)
        and not UnitIsAFK(t)
        and not UnitIsFeignDeath(t)
        and not UnitIsEnemy("player",t)
        and UnitIsDead(t)
        and not UnitIsGhost(t)
        and UnitIsConnected(t)
        and IsVisible(t)
        and InRange("Дух предков", t)
        and (not resList[UnitName(t)] or (GetTime() - resList[UnitName(t)]) > 60)
    ) then return false end
    return true
end

function TryRes(t)
    local spell = "Дух предков"
    if InCombatLockdown() then
        return false
    end
    if not CanRes(t) then return false end
  
    if DoSpell(spell, t) then
        resUnit = UnitName(t)
        resSpell = spell
        Notify(spell .. " " .. resUnit .. "(" ..t ..")")
        return true
    end
    return false
end

function IsHealCast(spell)
    if not spell then return false end
    local healCasts = {"Малая волна исцеления", "Волна исцеления", "Цепное исцеление"}
    local result = false
    for name,value in pairs(healCasts) do 
        if value == spell then result = true end
    end
    return result
end

local lastHealCastTarget = nil
function GetLastHealCastTarget()
    return lastHealCastTarget
end

local lastTarget = nil


local whiteListMode = false
function ListModeToggle()
    whiteListMode = not whiteListMode
    if whiteListMode then 
        echo("Режим WhiteList: ON",true)
    else
        echo("Режим WhiteList: OFF",true)
    end
end



local stealTime = GetTime()
local stealTarget = nil
local stealTargetGUID = nil
local stealFailList = {}
function TrySteal(target)
    local t = 5
    if not PlayerInPlace() then t = 2 end  
    if (stealTarget and GetTime() - stealTime < t) then return end 
    if target == nil then target = "target" end
    if not IsValidTarget(target) then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, _, _, expirationTime, _, isStealable = UnitBuff(target, i) 
            if name and (expirationTime - GetTime() >= 3) and (not stealFailList[name] or (GetTime() - stealFailList[name] > 30)) then
                local positiveTry = 0
                if StealWhiteList[name] then positiveTry = StealWhiteList[name] end
                local negativeTry = 0
                if StealBlackList[name] then negativeTry = StealBlackList[name] end
                --if positiveTry > 0 then negativeTry = 0 end
                if (not whiteListMode or positiveTry > 5) and  (negativeTry < 5) then
                    if DoSpell("Развеивание магии", target) then 
                        stealTarget = target
                        stealTargetGUID = UnitGUID(target)
                        --local uName = UnitName(target) 
                        --echo(format("Steal: Пробуем развеять %s c %s", name , uName))
                        stealTime = GetTime()
                        ret = true 
                    end
                end
            end
        end
    end
    return ret
end

local dispelTime = GetTime()
local dispelTarget = nil
local dispelTargetGUID = nil
local dispelFailList = {}
function TryDispel(target)
    local t = 5
    if not PlayerInPlace() then t = 2 end  
    if dispelTarget and (GetTime() - dispelTime < t) then return end 
    if target == nil then target = "player" end
    if not IsInteractTarget(target) then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime = UnitDebuff(target, i,true)
            if name and debuffType and (expirationTime - GetTime() >= 3) and (not dispelFailList[name] or (GetTime() - dispelFailList[name] > 30)) then
                local allowTypes = {}
                local spell = "Оздоровление"
                -- Болезнь
                allowTypes["Disease"] = true
                -- Яд
                allowTypes["Poison"] = true
                if (allowTypes[debuffType]) then
                    if HasTotem("Тотем очищения") then 
                        return false 
                    else
                        local positiveTry = 0
                        if DispelWhiteList[name] then positiveTry = DispelWhiteList[name] end
                        if not IsPvP() and positiveTry > 0 and CanUseInterrupt() and IsHeal() and InGroup() and not HasTotem("Тотем очищения") and DoSpell("Тотем очищения") then return false end
                    end 
                end
                if HasSpell("Очищение духа") then 
                    spell = "Очищение духа"
                    -- Проклятие
                    allowTypes["Curse"] = true
                end
                local positiveTry = 0
                if DispelWhiteList[name] then positiveTry = DispelWhiteList[name] end
                local negativeTry = 0
                if DispelBlackList[name] then negativeTry = DispelBlackList[name] end
                --if positiveTry > 0 then negativeTry = 0 end
                if allowTypes[debuffType] and (not whiteListMode or positiveTry > 5) and  (negativeTry < 5) then
                    if DoSpell(spell, target) then
                        dispelTarget = target
                        dispelTargetGUID = UnitGUID(target)
                        --local uName = UnitName(target) 
                        --echo(format("Dispel: Пробуем развеять %s c %s", name , uName))
                        dispelTime = GetTime()
                        ret = true 
                    end
                end
            end
        end
    end
    return ret
end

local InterruptTime = 0
local InterruptKey = nil
local InterruptGUID = nil
function TryInterrupt(target)
    if InterruptTime and (GetTime() - InterruptTime < 0.5) then return false end
    if target == nil then target = "target" end
    
    if not IsValidTarget(target) then return false end
    
    local channel = false
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    
    if not spell then return false end
    if not CanUseInterrupt() and not InInterruptRedList(spell) then return false end
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end
    if not channel and t > 0.7 then return false end
    local name = GetUnitType(target) .. '|' ..  spell
    
    local positiveTry = 0
    if InterruptWhiteList[name] then positiveTry = InterruptWhiteList[name] end
    local negativeTry = 0
    if InterruptBlackList[name] then negativeTry = InterruptBlackList[name] end
    --if positiveTry > 0 then negativeTry = 0 end
    if not ((not whiteListMode or positiveTry > 5) and (negativeTry < 5)) and not InInterruptRedList(spell) then return false end
    
    if not notinterrupt and IsReadySpell("Пронизывающий ветер") and InRange("Пронизывающий ветер",target) and not HasBuff({"Мастер аур"}, 0.1, target) and CanMagicAttack(target) then
        if UnitCastingInfo("player") ~= nil then RunMacroText("/stopcasting") end
        if UseSpell("Пронизывающий ветер", target) then 
            --echo("Interrupt " .. spell .. " ("..target.." => " .. UnitName(target) .. ")")
            InterruptTime = GetTime()
            if not(UnitIsPlayer(target) or UnitIsPet(target)) then 
                InterruptKey = name
                InterruptGUID = UnitGUID(target)
            end
            return true 
        end
    end
    
    if not channel and not HasTotem("Тотем заземления") and IsReadySpell("Тотем заземления") 
        and IsHarmfulCast(spell) and IsOneUnit(target .. "-target", "player") and InRange("Пронизывающий ветер",target)  then
        if UnitCastingInfo("player") ~= nil then RunMacroText("/stopcasting") end
        if UseSpell("Тотем заземления") then 
            echo("Interrupt " .. spell .. " ("..target.." => " .. UnitName(target) .. ")")
            InterruptTime = GetTime()
            return true 
        end
    end
    
    return false    
end

function onUpdate(frame, elapsed)
    
    if ApplyCommands() then return end
 
    if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
    if (CanHeal(resUnit) and (UnitCastingInfo("player") == "Дух предков"))  then RunMacroText("/stopcasting") end
    
    if InterruptKey and InterruptGUID and GetTime() - InterruptTime > 1 and not InterruptWhiteList[InterruptKey] then 
        local try = 0
        if InterruptBlackList[InterruptKey] then try = InterruptBlackList[InterruptKey] end
        if try < 100 then try = try + 1 end
        InterruptBlackList[InterruptKey] = try
        InterruptKey = nil
        InterruptGUID = nil
    end
    
    LastUpdate = LastUpdate + elapsed
    if LastUpdate < UpdateInterval then return end
    LastUpdate = 0
    
    if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") or not UnitPlayerControlled("player") then return end
    if Paused then 
        return 
    end
    
    Idle()
end
frame:SetScript("OnUpdate", onUpdate)

function onEvent(self, event, ...)

    if event:match("^UNIT_SPELLCAST") then
        local unit, spell = select(1,...)
--~         print(event,  unit, spell )
        if spell and unit == "player" then
            if event == "UNIT_SPELLCAST_SENT" then
                local _,_,_,target = select(1,...)
                if target and UnitExists(target) then
                    lastTarget = target
                    if IsHealCast(spell) then
                        targetPartyName = UnitPartyName(lastTarget)
                        if targetPartyName then
                            lastHealCastTarget = targetPartyName
                        end
                    end
                end
            end
             if  event == "UNIT_SPELLCAST_SUCCEEDED" then
                 --if Debug then chat(spell) end
                 if spell == resSpell then
                    RunMacroText("/w " .. resUnit .. " Реснул тебя, вставай давай!")
                    if InCombatLockdown() then RunMacroText("/w " .. resUnit .. " Но смотри аккуратно, чтоб сразу не умереть!") end
                    resList[resUnit] = GetTime()
                    Notify("Успешно применил "..resSpell .. " на " .. resUnit)
                end
            end
            if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" then
                if IsHealCast(spell) then
                    lastHealCastTarget = nil
                end
                if spell == resSpell then
                    resSpell = nil
                    resUnit = nil
                end
            end
        end
        return
    end
    
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel,agrs2 = select(1, ...)
    if not(destName ~= UnitName("player")) and sourceName ~= nil and not UnitIsFriend("player",sourceName) then 
        if not Paused then 
            NextTarget = sourceName 
            NextGUID = sourceGUID
        end
    end

    if (event=="COMBAT_LOG_EVENT_UNFILTERED") then
--[[        if sourceGUID == UnitGUID("player") and spellId and spellName  then
            print(type, spellName, err, dispel)
        end]]
        if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)  then
            if err then
                if err == "Нечего рассеивать." then
                    if spellName == "Развеивание магии" then
                        if stealTarget and (UnitGUID(stealTarget) == stealTargetGUID) then
                            for i = 1, 40 do
                                local name, _, _, _, _, _, expirationTime, _, isStealable = UnitBuff(stealTarget, i)
                                if name then
                                    local try = 0
                                    if StealBlackList[name] then try = StealBlackList[name] end
                                    if try < 100 then 
                                        try = try + 1
                                        StealBlackList[name] = try
                                    end
                                    stealFailList[name] = GetTime()
                                end
                            end
                        end
                        stealTarget = nil
                        stealTargetGUID = nil
                        --print(spellName," не может ничего развеять c ", destName)
                    else  
                        if dispelTarget and (UnitGUID(dispelTarget) == dispelTargetGUID) then
                            for i = 1, 40 do
                                local name, _, _, _, debuffType, duration, expirationTime = UnitDebuff(dispelTarget, i,true)
                                if name then
                                    local try = 0
                                    if DispelBlackList[name] then try = DispelBlackList[name] end
                                    if try < 100 then 
                                        try = try + 1
                                        DispelBlackList[name] = try
                                    end
                                    dispelFailList[name] = GetTime()
                                end
                            end
                        end
                        dispelTarget = nil
                        dispelTargetGUID = nil
                        --print(spellName," не может ничего раccеять c ", destName)
                    end
                end
            
                if err:match("Действие невозможно") then 
                    if HasDebuff(ControlList, 3.8, "player") and TryEach(GetUnitNames(), function(u) return CanHeal(u) and CalculateHP(u) < 40 end) then 
                        DoCommand("freedom") 
                    end
                end
                if Debug then
                    print("["..spellName .. "]: ".. err)
                end
            end
        end
        if sourceGUID == UnitGUID("player") and ( type == "SPELL_DISPEL") and spellId and spellName and dispel then
            if spellName == "Развеивание магии" then
                local try = 0
                if StealWhiteList[dispel] then try = StealWhiteList[dispel] end
                if try < 100 then 
                    try = try + 1
                    StealWhiteList[dispel] = try
                end
                stealTarget = nil
                stealTargetGUID = nil
                --print(spellName," рассеяло ", dispel, " c ", destName)
            else  
                local try = 0
                if DispelWhiteList[dispel] then try = DispelWhiteList[dispel] end
                if try < 100 then 
                    try = try + 1
                    DispelWhiteList[dispel] = try
                end
                dispelTarget = nil
                dispelTargetGUID = nil
                --print(spellName," рассеяло ", dispel, " c ", destName)
            end
        end

        if sourceGUID == UnitGUID("player") and ( type == "SPELL_INTERRUPT") and spellId and spellName then
            --print(2, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel,agrs2)
            if InterruptKey and InterruptGUID and InterruptGUID == destGUID and GetTime() - InterruptTime < 1 then 
                local try = 0
                if InterruptWhiteList[InterruptKey] then try = InterruptWhiteList[InterruptKey] end
                if try < 100 then try = try + 1 end
                InterruptWhiteList[InterruptKey] = try
                InterruptKey = nil
                InterruptGUID = nil
            end
        end
    end
end
frame:SetScript("OnEvent", onEvent)

function UnitThreatAlert(u)
    local threat, target = UnitThreat(u), format("%s-target", u)
    if UnitAffectingCombat(target) and UnitIsPlayer(target) and IsValidTarget(target) and IsOneUnit(u, target .. "-target") then threat = 3 end
    return threat
end

function DoSpell(spell, target, mana)
    return UseSpell(spell, target, mana)
end
