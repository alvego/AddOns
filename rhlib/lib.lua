-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- protected lock test
RunMacroText("/cleartarget")
-- Инициализация скрытого фрейма для обработки событий
local frame=CreateFrame("Frame",nil,UIParent)

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
        for _,func in pairs(funcList) do 
            func(event, ...)
        end
    end
end
frame:SetScript("OnEvent", onEvent)

------------------------------------------------------------------------------------------------------------------
-- Список обработчик -> вес/значимость
local UpdateList = {}
function AttachUpdate(f, w) 
    if nil == f then error("Func can't be nil") end  
    if w == nil then w = 0 end
    tinsert(UpdateList, { func = f, weight = w })
    -- сортируем по важности
    table.sort(UpdateList, function(u1,u2) return u1.weight > u2.weight end)
end

------------------------------------------------------------------------------------------------------------------
-- Выполняем обработчики события OnUpdate, согласно приоритету (return true - выход)
local LastUpdate = 0
local UpdateInterval = 0.01
local function OnUpdate(frame, elapsed)
    LastUpdate = LastUpdate + elapsed 
    if LastUpdate < UpdateInterval then return end -- для снижения нагрузки на проц
    LastUpdate = 0
    if TryEach(UpdateList, function(update) return update.func(elapsed) end) then return end
end
frame:SetScript("OnUpdate", OnUpdate)
