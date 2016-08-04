-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_HEADER_RHLIB = "Rotation Helper Library"
BINDING_NAME_RHLIB_FACE = "Лицом к Цели"
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"
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
    Paused = true
    oexecute("StopAttack()")
    oexecute("PetFollow()")
    echo("Авто ротация: OFF")
end

------------------------------------------------------------------------------------------------------------------
function FaceToTarget(force)
    if not force and (IsMouselooking() or not PlayerInPlace()) then
      return
    end
    if not force then force = not PlayerFacingTarget("target") end
    if force and TimerMore("FaceToTarget", 2) and UnitExists("target") and FaceToUnit then
        TimerStart("FaceToTarget")
        FaceToUnit("target")
    end
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
    if TimerLess('DebugFrame', 0.5) then return end
    TimerStart('DebugFrame')
    UpdateAddOnMemoryUsage()
    UpdateAddOnCPUUsage()
    local mem  = GetAddOnMemoryUsage("rhlib2")
    local fps = GetFramerate();
    local speed = GetUnitSpeed("player") / 7 * 100
    debugFrame.text:SetText(format('MEM: %.1fKB, LAG: %ims, FPS: %i, SPD: %d%%', mem, LagTime * 1000, fps, speed))
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
-- Вызывает функцию Idle если таковая имеется, с заданным рекомендованным интервалом UpdateInterval,
-- при включенной Авто-ротации

------------------------------------------------------------------------------------------------------------------

TARGETS = {}
UNITS = {}


------------------------------------------------------------------------------------------------------------------\

function UpdateIdle(elapsed)
    if nil == oexecute then
        echo("Требуется активация!")
        return
    end
    if UnitIsDeadOrGhost("player") then return end
    if SpellIsTargeting() then return end
    if UnitIsCasting() then return end
    if TrySpell() then return end
    if Paused then return end

    if ObjectsCount and not TimerLess("UpdateObjects", 1) then
      TimerStart("UpdateObjects")
      wipe(UNITS)
      wipe(TARGETS)
      local objCount = ObjectsCount()
      for i = 0, objCount - 1 do
        local uid = GUIDByIndex(i)
        if UnitCanAttack("player", uid) then
          if UnitCanAttack("player", uid) then
              tinsert(TARGETS, uid)
          else
            if not UnitIsEnemy("player", uid) and UnitInRange(uid) then
              tinsert(UNITS, uid)
            end
          end
        end
      end
    end

    if IsMouse(3) and UnitExists("mouseover") and not IsOneUnit("target", "mouseover") then
        oexecute('FocusUnit("mouseover")')
    end

    if Idle then Idle() end
    isAttack = false
end
------------------------------------------------------------------------------------------------------------------
