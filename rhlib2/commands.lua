-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
-- список команд
local Commands = {}
------------------------------------------------------------------------------------------------------------------
-- метод для задания команды, которая имеет приоритет на ротацией
-- SetCommand(string 'произвольное имя', function(...) команда, bool function(...) проверка, что все выполнилось, или выполнение невозможно)
function SetCommand(name, applyFunc, checkFunc)
    Commands[name] = {Last = 0, Timer = 0, Apply = applyFunc, Check = checkFunc, Params == null}
end

------------------------------------------------------------------------------------------------------------------
-- Используется в макросах
-- /run DoCommand('my_command', 'focus')
function DoCommand(cmd, ...)
    if not Commands[cmd] then
        print("DoCommand: Ошибка! Нет такой комманды ".. cmd)
        return
    end
    local d = 1.85
    local t = GetTime() + d
    local spell, _, _, _, _, endTime  = UnitCastingInfo("player")
    if not spell then spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo("player") end
    if spell and endTime then
        t = endTime/1000 + d
        if Commands[cmd].Timer and Commands[cmd].Timer == t then
            StopCast("Commands")
            t = GetTime() + d
        end
    end
    Commands[cmd].Timer = t
    Commands[cmd].Params = { ... }
end

------------------------------------------------------------------------------------------------------------------
-- навешиваем обработчик с максимальным приоритетом на событие OnUpdate, для обработки вызванных комманд
function UpdateCommands()
    if UnitIsCasting("player") then return false end
    local ret = false
    for cmd,_ in pairs(Commands) do
        if not ret then
            if (Commands[cmd].Timer  - GetTime() > 0) then
                ret = true
                if Commands[cmd].Check(unpack(Commands[cmd].Params)) then
                   Commands[cmd].Timer = 0
                else
                   if GetTime() - Commands[cmd].Last > 0.2 and Commands[cmd].Apply(unpack(Commands[cmd].Params)) then
                        Commands[cmd].Last = GetTime()
                   end
                end
            else
                Commands[cmd].Timer = 0
            end
        end
    end
    return ret
end

------------------------------------------------------------------------------------------------------------------
-- // /run if IsReadySpell("s") and СanMagicAttack("target") then DoCommand("spell", "s", "target") end
SetCommand("spell",
    function(spell, target)
        if not target then target = "target" end
        if DoSpell(spell, target) then
            echo(spell.."!",1)
        end
    end,
    function(spell, target)
        if not target then target = "target" end
        if not HasSpell(spell) then
            chat(spell .. " - нет спела!")
            return true
        end
        if not InRange(spell, target) then
            chat(spell .. " - неверная дистанция!")
            return true
        end
        if not IsSpellNotUsed(spell, 1)  then
            chat(spell .. " - успешно сработало!")
            return true
        end
        if GetSpellCooldownLeft(spell) > 0.25 then
            chat(spell .. " - не готово!")
            return true
        end

        local cast = UnitCastingInfo("player")
        if spell == cast then
            chat("Кастуем " .. spell)
            return true
        end
        return false
    end
)
------------------------------------------------------------------------------------------------------------------
local function hookUseAction(slot, ...)
	--print("UseAction", slot, ...)
  local actiontype, id, subtype = GetActionInfo(slot)
  if actiontype and id and id ~= 0 then
      local name = nil
      if actiontype == "spell" then
          name = GetSpellName(id, "spell")
          DoCommand("spell", name) --, IsAlt() and "focus" or "target"
      elseif actiontype == "item" then
          name = GetItemInfo(id)
      elseif actiontype == "companion" then
          name = select(2, GetCompanionInfo(subtype, id))
      elseif actiontype == "macro" then
          name = GetMacroInfo(id)
          if Commands[name] then
            DoCommand(name)
          end
      end
      --[[if name then
          print("UseAction", slot, name, actiontype, ...)
      end]]
  end
end
hooksecurefunc("UseAction", hookUseAction)

--[[function UseAction(slot)
	local isUsable, notEnoughMana = IsUsableAction(slot)
	if not isUsable or notEnoughMana then return false end
	local start, duration = GetActionCooldown(slot)
 	if start and time - (start + duration) < LagTime then return end
	if ActionHasRange(slot) and IsActionInRange(slot) == 0 then return false end
  --use action
  --UseAction(slot)
	return true
end]]
------------------------------------------------------------------------------------------------------------------
