-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_HEADER_RHLIB = "Rotation Helper Library"
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_RHLIB_LOG = "Вкл/Выкл окно логирования"
BINDING_NAME_RHLIB_RELOAD = "Перезагрузить интерфейс"
-----------------------------------------------------------------------------------------------------------------
-- Условие для включения ротации
------------------------------------------------------------------------------------------------------------------
if Paused == nil then Paused = false end
-- Условие для включения ротации
function TryAttack()
    if Paused then return end
    TimerStart('Attack')
end
function IsAttack()
    if IsMouse(4) then
        TimerStart('Attack')
    end

    return TimerLess('Attack', 0.5)
end

-- Отключаем авторотацию, при повторном нажатии останавливаем каст (если есть)
function AutoRotationOff()
    if UnitIsCasting() and Paused then
        StopCast("Pause")
    end
    oexecute("StopAttack()")
    if Paused then
      oexecute("PetFollow()")
    end
    Paused = true
    echo("Авто ротация: OFF")
end

------------------------------------------------------------------------------------------------------------------
function FaceToTarget(target)
    if not target then target = "target" end
    if not FaceToUnit then return end
    if TimerLess("FaceToTarget", 0.5) then return end
    if IsMouselooking() then return end
    if not PlayerInPlace() then return end
    if not UnitExists(target) then return end
    if PlayerFacingTarget(target) then return end
    TimerStart("FaceToTarget")
    FaceToUnit(target)
end
------------------------------------------------------------------------------------------------------------------
if Debug == nil then Debug = false end

local debugFrame = CreateFrame('Frame')
debugFrame:ClearAllPoints()
debugFrame:SetHeight(15)
debugFrame:SetWidth(800)
debugFrame.text = debugFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
debugFrame.text:SetAllPoints()
debugFrame:SetPoint('TOPLEFT', 2, 0)
debugFrame:SetScale(0.8);
debugFrame:SetAlpha(1)
local updateDebugStatsTime = 0
local function updateDebugStats()
    if not Debug then
        if debugFrame:IsVisible() then debugFrame:Hide() end
        return
    end
    if TimerLess('DebugFrame', 1) then return end
    TimerStart('DebugFrame')
    UpdateAddOnMemoryUsage()
    local mem  = GetAddOnMemoryUsage("rhlib2")
    local fps = GetFramerate();
    local speed = GetUnitSpeed("player") / 7 * 100
    debugFrame.text:SetText(format('MEM: %.1fKB, LAG: %ims, FPS: %i, SPD: %d%%',  mem, LagTime * 1000, fps, speed))
    if not debugFrame:IsVisible() then debugFrame:Show() end
end

AttachUpdate(updateDebugStats)

function DebugToggle()
    Debug = not Debug
    if Debug then
        debugFrame:Show()
        SetCVar("scriptErrors", 1)
        --UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE");
        SetCVar("Sound_EnableErrorSpeech", "1");
        echo("Режим отладки: ON")
    else
        debugFrame:Hide()
        SetCVar("scriptErrors", 0)
        --UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE");
        SetCVar("Sound_EnableErrorSpeech", "0");
        echo("Режим отладки: OFF")
    end
end

------------------------------------------------------------------------------------------------------------------
local function updateCombatLogTimer(...)
  TimerStart("CombatLog")
end
local function resetCombatLog()
  if InCombatLockdown()
  and TimerStarted("CombatLog") and TimerMore("CombatLog", 6)
  and (not TimerStarted("CombatLogReset") or TimerMore("CombatLogReset", 30))  then
      CombatLogClearEntries()
      TimerStart("CombatLogReset")
      chat("Reset CombatLog!")
  end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateCombatLogTimer)
AttachUpdate(resetCombatLog)
------------------------------------------------------------------------------------------------------------------
-- Вызывает функцию Idle если таковая имеется, с заданным рекомендованным интервалом UpdateInterval,
-- при включенной Авто-ротации

------------------------------------------------------------------------------------------------------------------
TARGETS = {}
UNITS = {}
------------------------------------------------------------------------------------------------------------------\
local objectDist = {}
local enemyCount = {}
function GetEnemyCountInRange(range)
  if not range then range = 8 end
  if enemyCount[range] == nil then
   local count = 0
    for i = 1, #TARGETS do
      local uid = TARGETS[i]
      if objectDist[uid] <= range then
        count = count + 1
      end
    end
    enemyCount[range] = count
  end
  return enemyCount[range]
end

local objectHP = {}
local function compareMinHP(u1, u2) return objectHP[u1] < objectHP[u2] end
local function compareMaxHP(u1, u2) return objectHP[u1] > objectHP[u2] end

function UpdateIdle(elapsed)

  --echo(format('LAG: %ims', LagTime * 1000))
  --print(max((select(2, GetSpellCooldown(61304)) or 0), 0), InGCD(), GetGCDLeft())
    if nil == oexecute then
        if not TimerStarted('UnlockTimer') then
          TimerStart('UnlockTimer')
        end
        UIErrorsFrame:Clear()
        UIErrorsFrame:AddMessage('...');
        UIErrorsFrame:AddMessage(SecondsToTime(TimerElapsed('UnlockTimer')), 1.0, 1.0, 0.0, 53, 2);
        UIErrorsFrame:AddMessage("|TInterface\\Icons\\INV_Gizmo_Runicmanainjector:32|t Tребуется инъекция.", 0.0, 1.0, 0.0, 53, 2);
        return
    end
    if UnitIsDeadOrGhost("player") then return end
    if UpdateCommands() then return end
    if SpellIsTargeting() then return end
    if Paused then return end
    if AdvMode and (IsAttack() or InCombatLockdown()) and ObjectsCount then
      wipe(objectHP)
      wipe(objectDist)
      wipe(enemyCount)
      wipe(TARGETS)
      wipe(UNITS)
      local objCount = ObjectsCount()
      for i = 0, objCount - 1 do
        local uid = GUIDByIndex(i)
        if uid and UnitCanAttack("player", uid) and not UnitInLos(uid) then
          local dist = DistanceTo("player", uid)
          if dist <= 40 then
            --print(UnitName(uid), DistanceTo("player", uid))
            tinsert(TARGETS, uid)
            objectHP[uid] = UnitHealth(uid)
            objectDist[uid] = dist
          end
        end
      end
      local groupUnits = GetGroupUnits()
      for i = 1, #groupUnits do
        local u = groupUnits[i]
        if UnitInRange(u) and not UnitIsDeadOrGhost(u) and not UnitIsEnemy("player", u) and not UnitInLos(u) then
          tinsert(UNITS, u)
          objectHP[u] = UnitHealth(u)
        end
      end
      sort(TARGETS, compareMaxHP)
      sort(UNITS, compareMinHP)
    end


    if IsMouse(3) and UnitExists("mouseover") and not IsOneUnit("target", "mouseover") then
        oexecute('FocusUnit("mouseover")')
    end

    if Idle then Idle() end
    isAttack = false
end
------------------------------------------------------------------------------------------------------------------
