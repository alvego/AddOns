-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffFF7D0ADruid|r loaded")
-- Binding
BINDING_HEADER_DRH = "Druid Rotation Helper"
BINDING_NAME_DRH_AUTOHEAL = "Вкл/Выкл авто HEAL"
BINDING_NAME_DRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
------------------------------------------------------------------------------------------------------------------
if AutoHeal == nil then AutoHeal = true end
function AutoHealToggle()
    AutoHeal = not AutoHeal
    echo("Авто Heal: " .. ( AutoHeal and "ON" or "OFF" ))
end
------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function ToggeInterrupt()
    CanInterrupt = not CanInterrupt
    echo("Interrupt: " .. ( CanInterrupt and "ON" or "OFF" ))
end

function TryInterrupt(target)
    if not CanInterrupt then return false end
    if not target then target = "target" end
    local spell, left, duration, channel, nointerrupt = UnitIsCasting(target)
    if not spell then return nil end
    if left < (channel and 0.5 or 0.2) then  return  end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
    local name = (UnitName(target)) or target
    if (channel or left < 0.8)  then
      local forme = IsOneUnit(target..'-target', "player")
      if IsPvP() and not tContains(ReflectList, spell) then return false end
      if forme and DoSpell("Слиться с тенью") then
        chat("Cлиться с тенью от " .. name)
        return true
      end
    end
    if ((channel or left < 2.5) and left > 1.8)  then
      local forme = IsOneUnit(target..'-target', "player")
      if IsPvP() and not tContains(ReflectList, spell) then return false end
      if forme and DoSpell("Слиться с тенью") then
        chat("Cлиться с тенью от " .. name)
        return true
      end
      if forme and InMelee(target) and IsReadySpell("Оглушить") and IsReadySpell("Исступление") then
        chat("Стан в " .. name)
        if not InUseCommand("stun") then DoCommand("stun", target) end
        return true
      end
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target)
  return UseSpell(spellName, target)
end
------------------------------------------------------------------------------------------------------------------
local function updateDamage(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, damage = ...
    if type:match("SWING_DAMAGE") and destGUID == UnitGUID("player") then --SWING_DAMAGE
        TimerStart("Damage")
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateDamage)
------------------------------------------------------------------------------------------------------------------
-- Лайфхак, чтоб не разбиться об воду при падении с высоты (защита от ДК с повышенным чувством юмора)
local FallingTime
local function UpdateFormFix()
    if IsFalling() then
        if FallingTime == nil then FallingTime = GetTime() end
        if not IsAttack() and FallingTime and (GetTime() - FallingTime > 2) and not InUseCommand("form") then
           DoCommand("form", (InCombatLockdown() or IsBattleground() or not IsFlyableArea() or not IsOutdoors()) and 3 or 6)
        end
    else
        if FallingTime ~= nil then FallingTime = nil end
    end
    if AdvMode and IsSwimming() and not (IsMounted() or CanExitVehicle()) and not InUseCommand("form") then DoCommand("form", 2) end
end
AttachUpdate(UpdateFormFix)
------------------------------------------------------------------------------------------------------------------
