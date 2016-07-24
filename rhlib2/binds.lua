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
    if IsPlayerCasting() and Paused then
        StopCast("Pause")
    end
    Paused = true
    oexecute("StopAttack()")
    oexecute("PetFollow()")
    echo("Авто ротация: OFF")
end

function IsPaused()
    if Paused then return true end
    for i = 1, 72 do
        local btn = _G["BT4Button"..i]
        if btn ~= nil then
            if btn:GetButtonState() == 'PUSHED' then
                TimerStart('Paused')
                return true
            end
        end
    end
    local t = 0.3
    local spell, _, _, _, _, endTime  = UnitCastingInfo("player")
    if not spell then spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo("player") end
    if spell and endTime then
        t = t + endTime/1000 - GetTime()
    end
    return TimerLess('Paused', t)
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

local function updateFaceTotTarget(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, amount, info = ...
    if type:match("SPELL_CAST_FAILED") and sourceGUID == UnitGUID("player") then
        if (amount == "Цель должна быть перед вами." or amount == "Цель вне поля зрения.") then FaceToTarget() end
        if amount and Debug then
          UIErrorsFrame:Clear()
          UIErrorsFrame:AddMessage(spellName .. ' - ' .. amount, 1.0, 0.2, 0.2);
          --if amount == "Еще не готово." then print("Не готово", spellName , " GCD:", InGCD(), " left:", GetSpellCooldownLeft(spellName), " LagTime:", LagTime) end
        end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateFaceTotTarget)

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
function UpdateIdle(elapsed)

    if nil == oexecute then
        echo("Требуется активация!")
        return
    end

    if UnitIsDeadOrGhost("player") or IsPaused() then return end

    if IsMouse(3) and UnitExists("mouseover") and not IsOneUnit("target", "mouseover") then
        oexecute('FocusUnit("mouseover")')
    end

    if Idle then Idle() end
    isAttack = false
end
------------------------------------------------------------------------------------------------------------------
