-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- protected lock test
RunMacroText("/cleartarget")
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
-- Список обработчик -> вес/значимость
local UpdateList = {}
local function upadteSort(u1,u2) return u1.weight > u2.weight end
function AttachUpdate(f, w) 
    if nil == f then error("Func can't be nil") end  
    if w == nil then w = 0 end
    tinsert(UpdateList, { func = f, weight = w })
    -- сортируем по важности
    table.sort(UpdateList, upadteSort)
end

------------------------------------------------------------------------------------------------------------------
-- Выполняем обработчики события OnUpdate, согласно приоритету (return true - выход)
local LastUpdate = 0
UpdateInterval = 0.03
local function OnUpdate(frame, elapsed)
    LastUpdate = LastUpdate + elapsed 
    if LastUpdate < UpdateInterval then return end -- для снижения нагрузки на проц
    LastUpdate = 0
    
    for i = 1, #UpdateList do
        local upd = UpdateList[i]
        if UpdateInterval == 0 then
            -- выполняем только самое важное
            if upd.weight < 0 then 
                upd.func() 
            end
        else
            -- выполняем все что есть
            upd.func()
        end
    end
end
frame:SetScript("OnUpdate", OnUpdate)
