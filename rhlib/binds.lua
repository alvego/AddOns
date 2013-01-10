-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_HEADER_RHLIB = "Rotation Helper Library"
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"

------------------------------------------------------------------------------------------------------------------
-- public variables (saved)
if Paused == nil then Paused = false end
if Debug == nil then Debug = false end

------------------------------------------------------------------------------------------------------------------
-- Условие для включения ротации
function IsAttack()
    return (IsMouseButtonDown(4) == 1)
end

------------------------------------------------------------------------------------------------------------------
-- Отключаем авторотацию, при повторном нажатии останавливаем каст (если есть)
function AutoRotationOff()
    if IsPlayerCasting() and Paused then 
        RunMacroText("/stopcasting") 
    end
    Paused = true
    RunMacroText("/stopattack")
    echo("Авто ротация: OFF",true)
end

------------------------------------------------------------------------------------------------------------------
-- Переключает режим отладки, а так же и показ ошибок lua
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

------------------------------------------------------------------------------------------------------------------
-- Вызывает функцию Idle если таковая имеется, с заданным рекомендованным интервалом UpdateInterval, 
-- при включенной Авто-ротации
TARGETS = {}
UNITS = {}
local StartTime = GetTime()
local LastUpdate = 0
local UpdateInterval = 0.0001
local function UpdateIdle(elapsed)
	LastUpdate = LastUpdate + elapsed
    if LastUpdate < UpdateInterval then return end
    LastUpdate = 0
	
	if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
	
	if Paused then return end
	
	if GetTime() - StartTime < 3 then return end
	
    if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") 
		or not UnitPlayerControlled("player") then return end
    -- Update units
    UNITS = GetUnits()
    local function GetUnitWeight(u)
        local w = 0
        if IsFriend(u) then w = 2 end
        if IsOneUnit(u, "player") then w = 3 end
    end
    table.sort(UNITS, function(u1,u2) return GetUnitWeight(u1) < GetUnitWeight(w2) end)
    -- Update targets
    TARGETS = GetTargets()
    table.sort(TARGETS, function(t1,t2) 
        local w1, w2 = 0, 0
        for _,u in pairs(units) do
            if IsOneUnit(u .. "-target", t1) then w1 = IsFriend(u) and 2 or 1 end
            if IsOneUnit(u .. "-target", t2) then w2 = IsFriend(u) and 2 or 1 end
        end
        if IsOneUnit("focus", t1) then w1 = 3 end
        if IsOneUnit("focus", t2) then w2 = 3 end
        if IsOneUnit("target", t1) then w1 = 4 end
        if IsOneUnit("target", t2) then w2 = 4 end
        if IsOneUnit("mouseover", t1) then w1 = 5 end
        if IsOneUnit("mouseover", t2) then w2 = 5 end
        return w1 < w2 end
    )
    
    if Idle then Idle() end
end
AttachUpdate(UpdateIdle, -1000)

------------------------------------------------------------------------------------------------------------------
-- Фиксим возможные подвисвния CombatLog
local CombatLogTimer = GetTime();
local CombatLogResetTimer = GetTime();

local function UpdateCombatLogFix()
	if InCombatLockdown() 
        and GetTime() - CombatLogTimer > 10
        and GetTime() - CombatLogResetTimer > 10 then 
        CombatLogClearEntries()
        chat("Reset CombatLog!")
        CombatLogResetTimer = GetTime()
    end 
end
AttachUpdate(UpdateCombatLogFix)

local function UpdateCombatLogTimer(event, ...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, agrs12, agrs13,agrs14 = select(1, ...)
    if event:match("DAMAGE") or event:match("HEAL") then 
        CombatLogTimer = GetTime()
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateCombatLogTimer)

------------------------------------------------------------------------------------------------------------------
-- Мониторим, когда начался и когда закончился бой
StartCombatTime = 0
EndCombatTime = 0
local function UpdateCombatTime() 
	if InCombatLockdown() then 
        EndCombatTime = GetTime() 
    else 
        StartCombatTime = GetTime() 
    end 
end
AttachUpdate(UpdateCombatTime)

------------------------------------------------------------------------------------------------------------------
-- Лайфхак, чтоб не разбиться об воду при падении с высоты (защита от ДК с повышенным чувством юмора)
local FallingTime = nil
local function UpdateFallingFix()
    if IsFalling() then
        if FallingTime == nil then FallingTime = GetTime() end
        if FallingTime and (GetTime() - FallingTime > 1) then
            if HasBuff("Хождение по воде") then RunMacroText("/cancelaura Хождение по воде") end
            if HasBuff("Льдистый путь") then RunMacroText("/cancelaura Льдистый путь") end
        end
    else
        if FallingTime ~= nil then FallingTime = nil end
    end
end
AttachUpdate(UpdateFallingFix)

------------------------------------------------------------------------------------------------------------------
-- Автоматическая продажа хлама и починка
local function SellGrayAndRepair()
    SellGray();
    RepairAllItems();
end
AttachEvent('MERCHANT_SHOW', SellGrayAndRepair)

------------------------------------------------------------------------------------------------------------------
-- Запоминаем вредоносные спелы которые нужно кастить (нужно для сбивания кастов, например тотемом заземления)
if HarmfulCastingSpell == nil then HarmfulCastingSpell = {} end
function IsHarmfulCast(spellName)
    return HarmfulCastingSpell[spellName]
end

local function UpdateHarmfulSpell(event, ...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, agrs12, agrs13,agrs14 = select(1, ...)
    if event:match("SPELL_DAMAGE") and spellName and agrs12 > 0 then
        local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellID) 
        if castTime > 0 then HarmfulCastingSpell[name] = true end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateHarmfulSpell)

------------------------------------------------------------------------------------------------------------------
-- Start event cycle (should be called at last line)
InitRotationHelperLibrary()