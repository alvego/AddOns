-- Warrior Rotation Helper by Timofeev Alexey & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cff804000Warrior|r loaded")
-- Binding
BINDING_HEADER_WRH = "Warrior Rotation Helper"
BINDING_NAME_WRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_WRH_AUTOTAUNT = "Авто Taunt"
BINDING_NAME_WRH_AUTOAOE = "Вкл/Выкл авто AOE"
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON")
    else
        echo("Interrupt: OFF")
    end
end

function TryInterrupt(target)

    if not CanInterrupt then return false end
    --[[if not IsReadySpell("Молот правосудия") then return false end
    if target == nil then target = "target" end
    if UnitIsPlayer(target) then return false end
    local spell, left, duration, channel, nointerrupt = UnitIsCasting(target)
    if not spell then return nil end
    if left < (channel and 0.5 or 0.2) then  return  end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
    local name = UnitName(target)
    name = name or target
    if not notinterrupt and (channel or left < 1.6) and DoSpell("Молот правосудия", target) then
      chat("Молот правосудия в " .. UnitName(target))
      return true
    end]]
    return false
end

------------------------------------------------------------------------------------------------------------------
if AutoAOE == nil then AutoAOE = true end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON")
    else
        echo("Авто АОЕ: OFF")
    end
end


function IsAOE()
    if IsShift() then return true end
    if AutoAOE and GetEnemyCountInRange(8) > 2 then return true end
    return false
end
------------------------------------------------------------------------------------------------------------------
if AutoTaunt == nil then AutoTaunt = true end

function AutoTauntToggle()
    AutoTaunt = not AutoTaunt
    if AutoTaunt then
        echo("Авто Taunt: ON")
    else
        echo("Авто Taunt: OFF")
    end
end

function TryTaunt()

  if not AutoTaunt then return false end

  --[[if not IsInGroup() then return false end

  for i = 1, #UNITS do
    local u = UNITS[i]
    if UnitAffectingCombat(u) and not IsOneUnit("player", u) then
      local _status = UnitThreatSituation(u)
      if type(_status) == "number" and _status > 1 then
        --if DoSpell("Праведная защита", u) then return true end

        for j = 1, #TARGETS do
          local t = TARGETS[j]
          local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation(u, t);
          if isTanking then

            --if DoSpell("Щит мстителя", t) then return true end

          end
        end
      end
    end
  end]]
  return false
end

------------------------------------------------------------------------------------------------------------------

function DoSpell(spellName, target)
   return UseSpell(spellName, target)
end
