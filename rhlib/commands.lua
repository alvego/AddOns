-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- список команд
local Commands = {}

------------------------------------------------------------------------------------------------------------------
-- метод для задания команды, которая имеет приоритет на ротацией
-- SetCommand(string 'произвольное имя', function команда, bool function проверка, что все выполнилось, или выполнение невозможно)
function SetCommand(name, applyFunc, checkFunc)
    Commands[name] = {Timer = 0, Apply = applyFunc, Check = checkFunc}
end

------------------------------------------------------------------------------------------------------------------
-- Используется в макросах
-- /run DoCommand('my_command')
function DoCommand(cmd)
    if not Commands[cmd] then 
        print("DoCommand: Ошибка! Нет такой комманды ".. cmd)
        return
    end 
    local d = 1.8
    local t = GetTime() + d
    local spell, _, _, _, _, endTime  = UnitCastingInfo("player")
    if not spell then spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo("player") end
    if spell and endTime then 
        t = endTime/1000 + d
        if Commands[cmd].Timer and Commands[cmd].Timer == t then 
            RunMacroText("/stopcasting") 
            t = GetTime() + d
        end
    end
    Commands[cmd].Timer = t
end

------------------------------------------------------------------------------------------------------------------
-- навешиваем обработчик с максимальным приоритетом на событие OnUpdate, для обработки вызванных комманд
local function UpdateCommands()
    if IsPlayerCasting() then return false end
    local ret = false
    for cmd,_ in pairs(Commands) do 
        if not ret then
            if (Commands[cmd].Timer  - GetTime() > 0) then 
                ret = true
                if Commands[cmd].Check() then 
                   Commands[cmd].Timer = 0
                else
                    Commands[cmd].Apply()
                end
            else
                Commands[cmd].Timer = 0
            end 
        end
    end
    return ret
end
AttachUpdate(UpdateCommands, 1000)