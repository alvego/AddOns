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
local beginAttack = false
function IsAttack()
    if IsMouse(4) then
        if not beginAttack then
          beginAttack = true
          AdvMode = true
        end
        TimerStart('Attack')
    else
      beginAttack = false
    end
    return TimerLess('Attack', 0.05)
end

-- Отключаем авторотацию, при повторном нажатии останавливаем каст (если есть)
function AutoRotationOff()
    if oexecute then
      if UnitIsCasting() and Paused then
          StopCast("Pause")
      end
      oexecute("StopAttack()")
      if Paused then
        oexecute("PetFollow()")
      end
    end
    Paused = true
    echo("Авто ротация: OFF")
end

------------------------------------------------------------------------------------------------------------------
function FaceToTarget(target)
    if not target then target = "target" end
    if not FaceToUnit then return end
    if TimerLess("FaceToTarget", 1) then return end
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
    if TimerLess('DebugFrame', 5) then return end
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
--[[local function updateCombatLogTimer(...)
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
AttachUpdate(resetCombatLog)]]
------------------------------------------------------------------------------------------------------------------
-- Вызывает функцию Idle если таковая имеется, с заданным рекомендованным интервалом UpdateInterval,
-- при включенной Авто-ротации

------------------------------------------------------------------------------------------------------------------
local function corpse_in_range_handler(...)
  if IsAlt() and GetCorpseRecoveryDelay() == 0 then
    oexecute('RetrieveCorpse()')
  else
    print('CORPSE_IN_RANGE: Alt - RetrieveCorpse')
  end
end
AttachEvent('CORPSE_IN_RANGE', corpse_in_range_handler)

local function player_dead_handler(...)
  if IsAlt() then
    oexecute('RepopMe()')
  else
    print('PLAYER_DEAD: Alt - RepopMe')
  end
end
AttachEvent('PLAYER_DEAD', player_dead_handler)

local function resurrect_request_handler(...)
  print(...)
  oexecute('AcceptResurrect()')
end
AttachEvent('RESURRECT_REQUEST', resurrect_request_handler)

local function death_update_handler()
  if not UnitIsDeadOrGhost("player") then return end
  oexecute('AcceptResurrect()')
  if not IsAlt() then return end
  if UnitIsDead("player") then
      oexecute("RepopMe()")
  end
  if UnitIsGhost("player")  and GetCorpseRecoveryDelay() == 0 then
    oexecute("RetrieveCorpse()")
  end
end
AttachUpdate(death_update_handler)
------------------------------------------------------------------------------------------------------------------
TARGETS = {}
UNITS = {}
------------------------------------------------------------------------------------------------------------------
function GetEnemyCountInRange(range)
  local count = 0
  for i = 1, #TARGETS do
    local uid = TARGETS[i]
    local dist = DistanceTo("player", uid)
    if dist <= range then
      count = count + 1
    end
  end
  return count
end

function UpdateObjects(force)
  if not ObjectsCount then return end
  if not force and TimerLess("UpdateObjects", 0.5) then return end
  TimerStart("UpdateObjects")
  wipe(TARGETS)
  local objCount = ObjectsCount()
  for i = 0, objCount - 1 do
    local uid = GUIDByIndex(i)
    if uid and UnitCanAttack("player", uid) and DistanceTo("player", uid) < 25 and not UnitIsDeadOrGhost(uid) then
        tinsert(TARGETS, uid)
    end
  end
  wipe(UNITS)
  local groupUnits = GetGroupUnits()
  for i = 1, #groupUnits do
    local u = groupUnits[i]
    if  UnitIsFriend("player", u) and not UnitCanAttack("player", u) and UnitInRange(u) and not UnitIsDeadOrGhost(u) then
      tinsert(UNITS, u)
    end
  end
end

function UpdateIdle(elapsed)
    if nil == oexecute then
        if not TimerStarted('UnlockTimer') then
          TimerStart('UnlockTimer')
        end
        if AdvMode then
          UIErrorsFrame:Clear()
          UIErrorsFrame:AddMessage("Tребуется инъекция. " .. SecondsToTime(TimerElapsed('UnlockTimer')), 0.0, 1.0, 0.0, 53, 2);
        end
        return
    end

    if StaticPopup1Button2:IsVisible() == 1 and StaticPopup1Button2:IsEnabled() == 1 and StaticPopup1Button2:GetText() == "Пропустить" then
       chat(StaticPopup1.text:GetText())
       StaticPopup1Button2:Click()
    end

    if UpdateCommands() then return end
    if UnitIsDeadOrGhost("player") then return end
    if SpellIsTargeting() then
      if IsAttack() then
        oexecute('SpellStopTargeting()')
      else
          return
      end
    end
    --local autoloog
    if LootFrame:IsVisible()  then
      if IsAttack() then  CloseLoot() end
      return
    end
    if Paused then return end

    if AdvMode and (IsAttack() or InCombatLockdown()) then UpdateObjects(true) end

    if IsMouse(3) and UnitExists("mouseover") and not IsOneUnit("target", "mouseover") then
        oexecute("FocusUnit('mouseover')")
    end

    if Idle then Idle() end
    isAttack = false
end
------------------------------------------------------------------------------------------------------------------
