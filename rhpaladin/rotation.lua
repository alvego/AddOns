-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}

function Idle()
  -- Дизамаунт
  if IsAttack() or IsMouse(3) then
      if HasBuff("Парашют") then oexecute('CancelUnitBuff("player", "Парашют")') return end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then Dismount() return end
  end
  -- дайте поесть (побегать) спокойно
  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end


  if TryBuffs() then return end

  if InCombatMode() then

    TryTarget()

    if not UnitIsPlayer("target") and TryInterrupt("target") then return end

    if AutoAGGRO and IsInGroup() then
        local TARGETS = GetTargets()
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if UnitAffectingCombat(t) and TryTaunt(t) then return end
        end
    end

    if HasSpell("Удар воина Света") then
        Retribution()
        return
    end

    if HasSpell("Щит мстителя") then
        Tank()
        return
    end
  end

end

function TryBuffs()
    local player = "player"
    if HasSpell("Удар воина Света") then
        if HasSpell("Священная жертва") and not InCombatLockdown() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
        -- if HasBuff("Праведное неистовство") and RunMacroText("/cancelaura Праведное неистовство") then return end
        if not HasBuff("Печать") and DoSpell("Печать мщения") then return end
        if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
            if not HasBuff("благословение королей") and DoSpell("Великое благословение королей","player") then return end
            if (not HasBuff("Боевой крик") or not HasBuff("благословение могущества")) and DoSpell("Великое благословение могущества","player") then return end
        end
        return false
    end
    if HasSpell("Щит мстителя") then
        if not HasBuff("Благословение") and DoSpell("Великое благословение неприкосновенности", player) then return end
        if not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство", player) then return end
        if not HasMyBuff("Печать", 0.1, player) then
          local seal = "Печать мщения"
          if IsAOE() and HasSpell("Печать повиновения") then seal = "Печать повиновения" end
          if DoSpell(seal, player) then return end
        end
        return false
    end
end

function Retribution()
    local target = "target"
    local player = "player"

    if (IsAttack() or UnitAffectingCombat(target)) and not IsCurrentSpell("Автоматическая атака") then
      omacro("/startattack")
    end
    if not attack and not UnitAffectingCombat(target) then return end
    local hp = UnitHealth100("player")
    local mana = UnitMana100("player")

    if HasBuff("Праведное неистовство", 0.1, player) and not IsOneUnit(player, target .. "-"..target) and DoSpell("Длань возмездия") then return end
    if DoSpell("Молот гнева") then return end
    if UnitBuff(player, "Искусство войны") and DoSpell("Экзорцизм") then return end

    if GetSpellCooldownLeft("Экзорцизм") > 3 and UnitBuff(player, "Искусство войны") and hp < 90 then
       if DoSpell("Вспышка Света") then return end
    end


    local justice = "Правосудие света"
     if mana < 60 then
        justice = "Правосудие мудрости"
    end

    if DoSpell(justice) then return end
    if DoSpell("Удар воина Света") then return end
    if InRange("Удар воина Света", target) and DoSpell("Божественная буря") then return end
end

function Tank()
  local target = "target"
  local player = "player"
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)

  if InCombatLockdown() then
    if hp < 35 and UseItem("Рунический флакон с лечебным зельем") then return end
    if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
  end

  if not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end
  if not HasBuff("Святая клятва") and DoSpell("Святая клятва", player) then return end
  if not HasBuff("Щит небес",0.1) and DoSpell("Щит небес", player) then return end

  if TryInterrupt(target) then return end

  if TryDispel(player) then return end

  if (IsAttack() or UnitAffectingCombat(target)) and not IsCurrentSpell("Автоматическая атака") then omacro("/startattack") end

  if not IsAttack() and not UnitAffectingCombat(target) then return end

  if hp < 20 and DoSpell("Возложение рук") then return end
  if hp < 30 and DoSpell("Длань спасения") then return end

  if (attack or mana > 50) and InRange("Молот праведника", target) then
      if DoSpell("Освящение") then return end
      if (UnitCreatureType(target) == "Нежить") and DoSpell("Гнев небес") then return end
  end

  if DoSpell("Молот гнева") then return end
  if DoSpell("Молот праведника") then return end
  if DoSpell("Щит праведности") then return end
  if (IsAttack() or mana > 50) and DoSpell("Щит мстителя") then return end
  if DoSpell("Правосудие мудрости") then return end
end

------------------------------------------------------------------------------------------------------------------
function TryTarget()
    -- помощь в группе
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then omacro("/cleartarget") end

        if IsPvP() then
            omacro("/targetenemyplayer [nodead]")
        else
            omacro("/targetenemy [nodead]")
        end

        if not IsAttack()  -- если в авторежиме
            and (
            not IsValidTarget("target")  -- вообще не цель
            or (not IsArena() and not (CheckInteractDistance("target", 3) == 1))  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then
            if UnitExists("target") then omacro("/cleartarget") end
        end
    end


end


function TryTaunt(target)

  if TimerLess("Taunt", 1)  then return false end

  if UnitIsPlayer(target) or not UnitAffectingCombat(target) then return false end

  local tt = UnitName(target .. "-target")
  if not UnitExists(tt) then return false end

  if IsOneUnit("player", tt) then return false end


  if DoSpell("Длань возмездия", target) then
     TimerStart("Taunt")
     -- chat("Длань возмездия на " .. UnitName(target))
     return true
  end

  if not IsReadySpell("Длань возмездия") and IsInteractUnit(tt) and DoSpell("Праведная защита", tt) then
     TimerStart("Taunt")
     -- chat("Праведная защита на " .. UnitName(tt))
     return true
  end
  return false
end


function TryDispel(unit)
   if TimerLess("Dispel", 3)  then return false end
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
