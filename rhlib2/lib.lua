-- Rotation Helper Library by Alex Tim
------------------------------------------------------------------------------------------------------------------
--[[
BehindUnit
FaceToUnit
UnitInLos
UnitWorldClick
UnitPosition
UnitFacing
oexecute
]]

-- Инициализация скрытого фрейма для обработки событий
local frame=CreateFrame("Frame","RHLIB2FRAME",UIParent)
------------------------------------------------------------------------------------------------------------------
-- Список событие -> обработчики
local EventList = {}
function AttachEvent(event, func)
    if nil == func then error("Func can't be nil") end
    local funcList = EventList[event]
    if nil == funcList then
        funcList = {}
        -- attach events
        frame:RegisterEvent(event)
    end
    tinsert(funcList, func)
    EventList[event] = funcList
end

------------------------------------------------------------------------------------------------------------------
-- Выполняем обработчики соответсвующего события
local function onEvent(self, event, ...)
    if EventList[event] ~= nil then
        local funcList = EventList[event]

        for i = 1, #funcList do
            funcList[i](event, ...)
        end
    end
end
frame:SetScript("OnEvent", onEvent)

------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
local UpdateList = {}
function AttachUpdate(f)
    if nil == f then error("Func can't be nil") end
    tinsert(UpdateList, f)
end

------------------------------------------------------------------------------------------------------------------
AdvMode = false;
local update = 1
-- Выполняем обработчики события OnUpdate
local function OnUpdate(frame, elapsed)
    if Paused and IsAttack() then
        echo("Авто ротация: ON")
        Paused = false
        AdvMode = true
    end
    local throttle =  1 / GetFramerate()
    if throttle < 0.02 then throttle = 0.02 end
    update = update + elapsed
    if update > throttle then
        AdvMode = false;
        if not TimerStarted("AdvMode") or TimerMore("AdvMode", 0.5) then
          TimerStart("AdvMode")
          AdvMode = true
        end

        UpdateIdle(update)
        for i=1, #UpdateList do
           UpdateList[i](update)
        end
        update = 0
    end
end
frame:SetScript("OnUpdate", OnUpdate)
------------------------------------------------------------------------------------------------------------------
function omacro(macro)
    oexecute("RunMacroText('"..macro.."')")
end
------------------------------------------------------------------------------------------------------------------
