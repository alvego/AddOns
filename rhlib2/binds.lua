-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_HEADER_RHLIB = "Rotation Helper Library"
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"
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
        RunMacroText("/stopcasting") 
    end
    Paused = true
    RunMacroText("/stopattack")
    RunMacroText("/petfollow")
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
local iTargets = {"target", "mouseover"}
TARGETS = {}
ITARGETS = iTargets
UNITS = {"player"}
IUNITS = {} -- Important Units
local StartTime = GetTime()

local function getUnitWeight(u)
    local w = 0
    if IsFriend(u) then w = 2 end
    if IsOneUnit(u, "player") then w = 3 end
    return w
end
local function compareUnits(u1,u2) return getUnitWeight(u1) < getUnitWeight(w2) end
local function getTargetWeight(t)
    local w = 0
    for _,u in pairs(UNITS) do
        if IsOneUnit(u .. "-target", t) then w = max(w, IsFriend(u) and 2 or 1) end
    end
    if IsOneUnit("focus", t) then w = 3 end
    if IsOneUnit("target", t) then w = 4 end
    if IsOneUnit("mouseover", t) then w = 5 end
    w = w + (1 - UnitHealth100(t) / 100) 
    return w
end
function compareTargets(t1,t2) return getTargetWeight(t1) < getTargetWeight(t2) end
local function UpdateIdle()
    if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
    
    if UpdateCommands() then return end
    
    if Paused then return end
    
    if GetTime() - StartTime < 2 then return end
    
    if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") 
        or not UnitPlayerControlled("player") then return end
        
    -- Update units
    UNITS = GetUnits()
    table.sort(UNITS, compareUnits)
    
    -- Update targets
    TARGETS = GetTargets()
    table.sort(TARGETS, compareTargets)
    wipe(IUNITS)
    for _,u in pairs(UNITS) do
		if IsArena() or IsFriend(u) then 
			tinsert(IUNITS, u)
		end
	end
    ITARGETS = IsArena() and iTargets or TARGETS
    if Idle then Idle() end
end
AttachUpdate(UpdateIdle, -1000)

------------------------------------------------------------------------------------------------------------------
--Arena Raid Icons
local unitCD = {}
local raidIconsByClass = {WARRIOR=8,DEATHKNIGHT=7,PALADIN=3,PRIEST=5,SHAMAN=6,DRUID=2,ROGUE=1,MAGE=8,WARLOCK=3,HUNTER=4}
local function UpdateArenaRaidIcons(event, ...)
    if IsArena() then
        local members = GetGroupUnits()
        table.foreach(members, function(_, u) 
            if UnitExists(u) and not GetRaidTargetIndex(u) and (not unitCD[u] or GetTime() - unitCD[u] > 5) then 
                SetRaidTarget(u,raidIconsByClass[select(2,UnitClass(u))]) 
                unitCD[u] = GetTime()
            end
        end)
	end
end
AttachEvent("GROUP_ROSTER_UPDATE", UpdateArenaRaidIcons)
AttachEvent("ARENA_OPPONENT_UPDATE", UpdateArenaRaidIcons)
AttachEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", UpdateArenaRaidIcons)
------------------------------------------------------------------------------------------------------------------
-- Фиксим возможные подвисвния CombatLog
local CombatLogTimer = GetTime();
local CombatLogResetTimer = GetTime();

local function UpdateCombatLogFix()
    if InCombatLockdown() 
        and GetTime() - CombatLogTimer > 15
        and GetTime() - CombatLogResetTimer > 30 then 
        CombatLogClearEntries()
        --chat("Reset CombatLog!")
        CombatLogResetTimer = GetTime()
    end 
end
AttachUpdate(UpdateCombatLogFix)

local function UpdateCombatLogTimer(event, ...)
    CombatLogTimer = GetTime()
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateCombatLogTimer)

------------------------------------------------------------------------------------------------------------------
-- Мониторим, когда начался и когда закончился бой
local startCombatTime = nil
local endCombatTime = nil     
local function UpdateCombatTimers()
    if InCombatLockdown() then
        if not startCombatTime then 
            startCombatTime = GetTime()
        end
        endCombatTime = nil
    else
        if not endCombatTime then
            endCombatTime = GetTime()
        end
        startCombatTime = nil
        
    end
end
AttachUpdate(UpdateCombatTimers)   

function InCombat(t) 
    if not t then t = 0 end
    return InCombatLockdown() and startCombatTime and GetTime() - startCombatTime > t
end
function NotInCombat(t) 
    if not t then t = 0 end
    return not InCombatLockdown() and endCombatTime and GetTime() - endCombatTime > t
end
------------------------------------------------------------------------------------------------------------------
-- Запоминаем атакующие нас цели (TODO: need REVIEW)
local NextTarget = nil
local NextGUID = nil

function NextIsTarget(target)
    if not target then target = "target" end
    return (UnitGUID(target) == NextGUID)
end

function ClearNextTarget()
    NextTarget = nil
    NextGUID = nil
end

function GetNextTarget()
    return NextTarget
end

local function UpdateNextTarget(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
    if not(destName ~= GetUnitName("player")) and sourceName ~= nil and not UnitCanCooperate("player",sourceName) then 
        if not Paused then 
            NextTarget = sourceName
            NextGUID = sourceGUID
        end
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateNextTarget)

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
-- нас сапнул рога
function UpdateSapped(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
	if spellName == "Ошеломление"
	and destGUID == UnitGUID("player")
	and (type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_REFRESH")
	then
		RunMacroText("/к Меня сапнули, помогите плиз!")
		Notify("Словил сап от роги: "..(sourceName or "(unknown)"))
	end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateSapped)
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
local debugFrame = nil
local debugFrameTime = 0
local function debugFrame_OnUpdate()
        if (debugFrameTime > 0 and debugFrameTime < GetTime() - 1) then
                local alpha = debugFrame:GetAlpha()
                if (alpha ~= 0) then debugFrame:SetAlpha(alpha - .02) end
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
debugFrame:SetWidth(200)
debugFrame:SetScript('OnUpdate', debugFrame_OnUpdate)
debugFrame:Hide()
debugFrame.text = debugFrame:CreateFontString(nil, 'BACKGROUND', 'ErrorFont')
debugFrame.text:SetAllPoints()
debugFrame:SetPoint('TOPLEFT', 0, 0)

-- Debug messages.
function debug(message)
        debugFrame.text:SetText(message)
        debugFrame:SetAlpha(1)
        debugFrame:Show()
        debugFrameTime = GetTime()
end

local function UpdateMemoryUsage()
	if not Debug then return end
	UpdateAddOnMemoryUsage()
	debug(ceil(GetAddOnMemoryUsage("rhlib2")) .. "Kb")
end
AttachUpdate(UpdateMemoryUsage) 
