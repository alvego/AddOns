-- Rotation Helper Library by Timofeev Alexey
--/run print(TryEach({1,2,3}, function(i) print(i) end))
------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"

------------------------------------------------------------------------------------------------------------------
-- public variables (saved)
if Paused == nil then Paused = false end
if Debug == nil then Debug = false end

------------------------------------------------------------------------------------------------------------------
-- Условие для включения ротации
function IsAttack()
    return (IsMouseButtonDown(4) == 1)
end

------------------------------------------------------------------------------------------------------------------
-- Отключаем авторотацию, при повторном нажатии останавливаем каст (если есть)
function AutoRotationOff()
    if IsPlayerCasting() and Paused then 
        RunMacroText("/stopcasting") 
    end
    Paused = true
    RunMacroText("/stopattack")
    echo("Авто ротация: OFF",true)
end

------------------------------------------------------------------------------------------------------------------
-- Переключает режим отладки, а так же и показ ошибок lua
function DebugToggle()
    Debug = not Debug
    if Debug then
         SetCVar("scriptErrors", 1)
        echo("Режим отладки: ON",true)
    else
         SetCVar("scriptErrors", 0)
        echo("Режим отладки: OFF",true)
    end 
end

------------------------------------------------------------------------------------------------------------------
-- Вызывает функцию Idle если таковая имеется, с заданным рекомендованным интервалом UpdateInterval, 
-- при включенной Авто-ротации
local StartTime = GetTime()
local LastUpdate = 0
local UpdateInterval = 0.0001
local function UpdateIdle(elapsed)
	LastUpdate = LastUpdate + elapsed
    if LastUpdate < UpdateInterval then return end
    LastUpdate = 0
	
	if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
	
	if Paused then return end
	
	if GetTime() - StartTime < 3 then return end
	
    if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") 
		or not UnitPlayerControlled("player") then return end
    
    if Idle then Idle() end
end
AttachUpdate(UpdateIdle, -1000)

------------------------------------------------------------------------------------------------------------------
-- Инициализация скрытого фрейма для обработки событий
local frame=CreateFrame("Frame",nil,UIParent)
-- attach events
for event,_ in pairs(EventList) do 
    frame:RegisterEvent(event)
end
-- сортируем по важности
table.sort(UpdateList, function(u1,u2) return u1.weight > u2.weight end)

------------------------------------------------------------------------------------------------------------------
-- Выполняем обработчики события OnUpdate, согласно приоритету (return true - выход)
local function OnUpdate(frame, elapsed)
	if TryEach(UpdateList, function(update) return update.func(elapsed) end) then return end
end
frame:SetScript("OnUpdate", OnUpdate)

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


