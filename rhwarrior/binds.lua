﻿-- Warrior Rotation Helper by Timofeev Alexey & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cff804000Warrior|r loaded")
-- Binding
BINDING_HEADER_WRH = "Warrior Rotation Helper"
BINDING_NAME_WRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_WRH_AUTOTAUNT = "Авто Taunt"
BINDING_NAME_WRH_AUTOAOE = "Вкл/Выкл авто AOE"
------------------------------------------------------------------------------------------------------------------
function Equip1HShield()
  if not IsEquippedItemType("Щит") then
    omacro("/equip Тесак разгневанного гладиатора")
    omacro("/equip Осадный щит разгневанного гладиатора")
  end
end

function Equip2H()
  if not Equiped2H() then
    omacro("/equip Темная Скорбь")
  end
end

function Equiped2H()
  return IsEquippedItem("Темная Скорбь")
end
------------------------------------------------------------------------------------------------------------
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

    if target == nil then target = "target" end



    local spell, left, duration, channel, nointerrupt = UnitIsCasting(target)
    if not spell then return nil end
    if left < (channel and 0.5 or 0.2) then  return  end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик

    if IsPvP() and tContains(InterruptList, spell) then return false end

    local name = (UnitName(target)) or target
    local stance = GetShapeshiftForm()


    if (channel or left < 1.6)  then

      local reflect = tContains(ReflectList, spell)

      if reflect and stance ~= 3 and GetSpellCooldownLeft("Отражение заклинания") == 0 then
        Equip1HShield()
        if DoSpell("Отражение заклинания", player, true) then
          chat("Отражение заклинания от " .. spell .. " - " ..name)
          return true
        end
      end

      if reflect and HasBuff("Отражение заклинания", 0.1, player)  then
        return false;
      end

      if not notinterrupt  and stance == 3 and DoSpell("Зуботычина", target, true) then
        chat("Зуботычина в " .. name)
        return true
      end

      if not notinterrupt  and stance ~= 3 and GetSpellCooldownLeft("Удар щитом") == 0 and InMelee(target) then
        Equip1HShield()
        if IsEquippedItemType("Щит") and DoSpell("Удар щитом", target, true) then
          chat("Удар щитом в " .. name)
          return true
        end
      end

      if HasSpell("Оглушающий удар") and DoSpell("Оглушающий удар", target, true) then
        chat("Оглушающий удар в " .. name)
        return true
      end
    end


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

function DoSpell(spellName, target, force)
   if not force and not IsAttack() then
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    if name and cost and cost > 0 and powerType == 1 and (UnitPower("player", powerType) or 0) <= cost + 20 then
       return false
    end
  end
  return UseSpell(spellName, target)
end
