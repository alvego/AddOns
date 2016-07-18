-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--[[
BehindUnit
FaceToUnit
UnitInLos
UnitWorldClick
UnitPosition
UnitPtr
oexecute
olog
ohelp
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

local update = 1
-- Выполняем обработчики события OnUpdate
local function OnUpdate(frame, elapsed)

    if ((IsAttack() or IsMouse(3)) and Paused) then
        echo("Авто ротация: ON")
        Paused = false
    end
    local throttle = 1 / GetFramerate()
    update = update + elapsed
    if update > throttle then
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
