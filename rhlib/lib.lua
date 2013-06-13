-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Список событие -> обработчики
local EventList = {}
function AttachEvent(name, func) 
  if nil == func then error("Func can't be nil") end  
  local funcList = EventList[name]
  if nil == funcList then funcList = {} end
  tinsert(funcList, func)
  EventList[name] = funcList
end

------------------------------------------------------------------------------------------------------------------
-- Список обработчик -> вес/значимость
local UpdateList = {}
function AttachUpdate(f, w) 
    if nil == f then error("Func can't be nil") end  
    if w == nil then w = 0 end
    tinsert(UpdateList, { func = f, weight = w })
end

------------------------------------------------------------------------------------------------------------------
-- Инициализация библиотеки
local LastUpdate = 0
local UpdateInterval = 0.05
function InitRotationHelperLibrary()
    -- protected lock test
    RunMacroText("/cleartarget")
    -- Инициализация скрытого фрейма для обработки событий
    local frame=CreateFrame("Frame",nil,UIParent)
    -- attach events
    for event,_ in pairs(EventList) do 
        frame:RegisterEvent(event)
    end
    -- сортируем по важности
    table.sort(UpdateList, function(u1,u2) return u1.weight > u2.weight end)
    -- Выполняем обработчики события OnUpdate, согласно приоритету (return true - выход)
    local function OnUpdate(frame, elapsed)
        LastUpdate = LastUpdate + elapsed 
        if LastUpdate < UpdateInterval then return end -- для снижения нагрузки на проц
        LastUpdate = 0
        if TryEach(UpdateList, function(update) return update.func(elapsed) end) then return end
    end
    frame:SetScript("OnUpdate", OnUpdate)
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
end 
