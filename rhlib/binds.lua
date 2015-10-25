-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_HEADER_RHLIB = "Rotation Helper Library"
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_RHLIB_RELOAD = "Перезагрузить интерфейс"
------------------------------------------------------------------------------------------------------------------
-- Условие для включения ротации
function IsAttack()
    return (IsMouseButtonDown(4) == 1)
end

------------------------------------------------------------------------------------------------------------------
if Paused == nil then Paused = false end
-- Отключаем авторотацию, при повторном нажатии останавливаем каст (если есть)
function AutoRotationOff()
    if IsPlayerCasting() and Paused then 
        --stop cast
    end
    --stop attack
    Paused = true
    echo("Авто ротация: OFF",true)
end

------------------------------------------------------------------------------------------------------------------
if Debug == nil then Debug = false end
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
local function UpdateIdle()

    if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
    
    if Paused then return end
    
   
    
    if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") 
        or not UnitPlayerControlled("player") then return end
   
    if Idle then Idle() end
end
AttachUpdate(UpdateIdle, -1000)

------------------------------------------------------------------------------------------------------------------
-- Фиксим возможные подвисвния CombatLog
local CombatLogTimer = GetTime();
local CombatLogResetTimer = GetTime();

local function UpdateCombatLogFix()
    if InCombatLockdown() 
        and GetTime() - CombatLogTimer > 15
        and GetTime() - CombatLogResetTimer > 30 then 
        CombatLogClearEntries()
        chat("Reset CombatLog!")
        CombatLogResetTimer = GetTime()
    end 
end
AttachUpdate(UpdateCombatLogFix)

local function UpdateCombatLogTimer(event, ...)
    CombatLogTimer = GetTime()
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateCombatLogTimer)

------------------------------------------------------------------------------------------------------------------
-- Alert опасных спелов
local checkedTargets = {"target", "focus", "arena1", "arena2", "mouseover"}

--[[
SPELL_AURA_APPLIED Авиена Покаяние Омниссия
SPELL_CAST_SUCCESS Омниссия Каждый за себя nil
SPELL_AURA_REMOVED Авиена Покаяние Омниссия
]]

function UpdateSpellAlert(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
    if InAlertList(spellName) then
        for i=1,#checkedTargets do
            local t = checkedTargets[i]
            if IsValidTarget(t) and UnitGUID(t) == sourceGUID then
                type = strreplace(type, "SPELL_AURA_", "")
                Notify("|cffff7d0a" .. spellName .. " ("..(sourceName or "?")..")|r  - " .. type .. "!")
                break
            end
        end
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateSpellAlert)
------------------------------------------------------------------------------------------------------------------
-- Автоматическая продажа хлама и починка
local function SellGrayAndRepair()
    SellGray();
    RepairAllItems(1); -- сперва пробуем за счет ги банка
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
local debugFrame
local debugFrameTime = 0
local function debugFrame_OnUpdate()
    if (debugFrameTime > 0 and debugFrameTime < GetTime() - 1) then
        local alpha = debugFrame:GetAlpha()
        if (alpha ~= 0) then debugFrame:SetAlpha(alpha - .005) end
        if (aplha == 0) then 
			debugFrame:Hide() 
			debugFrameTime = 0
		end
    end
end
-- Debug & Notification Frame
debugFrame = CreateFrame('Frame')
debugFrame:ClearAllPoints()
debugFrame:SetHeight(15)
debugFrame:SetWidth(800)
debugFrame:SetScript('OnUpdate', debugFrame_OnUpdate)
debugFrame:Hide()
debugFrame.text = debugFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
debugFrame.text:SetAllPoints()
debugFrame:SetPoint('TOPLEFT', 70, 0)

-- Debug messages.
function debug(message)
        debugFrame.text:SetText(message)
        debugFrame:SetAlpha(1)
        debugFrame:Show()
        debugFrameTime = GetTime()
end

local updateDebugStatsTime = 0
local function UpdateDebugStats()
	if not Debug or GetTime() - updateDebugStatsTime < 0.5 then return end
    updateDebugStatsTime = GetTime()
	UpdateAddOnMemoryUsage()
    UpdateAddOnCPUUsage()
    local mem  = GetAddOnMemoryUsage("rhlib")
    local fps = GetFramerate();
    debug(format('MEM: %.1fKB, LAG: %ims, FPS: %i', mem, LagTime * 1000, fps))
end
AttachUpdate(UpdateDebugStats) 
