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
        for _,func in pairs(funcList) do 
            func(event, ...)
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
UpdateInterval = 0
local function update(upd) return upd.func() end
local function OnUpdate(frame, elapsed)
    LastUpdate = LastUpdate + elapsed 
    if InCombatLockdown() then
        local start, duration = GetSpellCooldown(GCDSpellID);
            --ждем конца GCD чтоб запустить ротацию с нуля
        if start and (start>0) and duration - (GetTime() - start) < 0.25 then
            if duration - (GetTime() - start) < 0.25 then
                LastUpdate = 100
                return
            end
            UpdateInterval = 0.25
        else
            --no gcd
            UpdateInterval = 0
        end 
    else
        UpdateInterval = 0.5
    end
    if IsAttack() then UpdateInterval = 0 end
    if LastUpdate < UpdateInterval then return end -- для снижения нагрузки на проц
    LastUpdate = 0
    for _,upd in pairs(UpdateList) do
		if upd.func(elapsed) then return end
    end
end
frame:SetScript("OnUpdate", OnUpdate)
