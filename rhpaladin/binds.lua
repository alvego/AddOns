-- Paladin Rotation Helper by Timofeev Alexey & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |cffff4080Paladin|r loaded!")
-- Binding
BINDING_HEADER_PRH = "Paladin Rotation Helper"
BINDING_NAME_PRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_PRH_AUTOTAUNT = "Авто Taunt"
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
    if not IsReadySpell("Молот правосудия") then return false end
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
    end
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

  if HasMyBuff("Праведное неистовство", 1, "player") then
     if not AutoTaunt then omacro("/cancelaura Праведное неистовство") end
  else
    if AutoTaunt and DoSpell("Праведное неистовство", player) then return true end
  end

  if not AutoTaunt then return false end

  if not IsInGroup() then return false end

  for i = 1, #UNITS do
    local u = UNITS[i]
    if UnitAffectingCombat(u) and not IsOneUnit("player", u) then
      local _status = UnitThreatSituation(u)
      if type(_status) == "number" and _status > 1 then
        if DoSpell("Праведная защита", u) then return true end

        for j = 1, #TARGETS do
          local t = TARGETS[j]
          local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation(u, t);
          if isTanking then
            if DoSpell("Щит мстителя", t) then return true end
            if DoSpell("Длань возмездия", t) then return true end
          end
        end
      end
    end
  end
  return false
end

------------------------------------------------------------------------------------------------------------------
function TryDispel(unit)
   if TimerLess("Dispel", 2)  then return false end
    if not unit then unit = "player" end
    for i=1,40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitDebuff(unit,i);
        -- Magic, Disease, Poison, Curse
        if name and debuffType and (debuffType == 'Magic' or debuffType == 'Disease' or debuffType == 'Poison') and DoSpell("Очищение", unit) then
            TimerStart("Dispel")
            return true
        end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function IsAOE()
    if IsShiftKeyDown() == 1 then return true end
    if GetEnemyCountInRange(8) > 2 then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
function InForbearance(unit)
    if unit == nil then unit = "player" end
    return ((GetTime() - GetSpellLastTime("Гнев карателя") < 30) or HasDebuff("Воздержанность", 0.01, unit))
end
------------------------------------------------------------------------------------------------------------------
local forbearanceSpells = {"Гнев карателя", "Божественный щит", "Возложение рук", "Божественная защита", "Длань защиты"}
function DoSpell(spellName, target)
    if tContains(forbearanceSpells, spellName) and InForbearance(target) then return false end
    return UseSpell(spellName, target)
end
