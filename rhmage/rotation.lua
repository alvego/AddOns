-- Mage Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления", "Рунический покров"}
function Idle()
  local attack = IsAttack()
  local mouse5 = IsMouse(5)
  local player = "player"
  local target = "target"
  local focus = "focus"
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)
  local pvp = IsPvP() or IsAlt()
  local combat = InCombatLockdown()
  local combatMode = InCombatMode()
  local inPlace = PlayerInPlace()
  -- Дизамаунт -----------------------------------------------------------------
  if attack or mouse5 then
      if HasBuff("Замедленное падение") then
        oexecute('CancelUnitBuff("player", "Замедленное падение")')
        return
      end
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
        return
      end
      if CanExitVehicle() then VehicleExit() return end
      if IsMounted() then Dismount()  return end
  end
  ------------------------------------------------------------------------------
  -- дайте поесть (побегать) спокойно
  if not attack and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
  if not attack and HasBuff("Невидимость") then return end

  if (not attack or not combat) then
    if not (HasBuff("интеллект", 5) or HasBuff("гениальность", 5)) and DoSpell(IsBattleground() and (GetItemCount("Порошек чар") > 0) and "Чародейская гениальность Даларана" or "Даларанский интеллект", player) then return end
    if HasSpell("Живая бомба") and not HasBuff("Раскаленный доспех", 5) and DoSpell("Раскаленный доспех", player) then return end
    if HasSpell("Глубокая заморозка") and not HasBuff("доспех", 5) and DoSpell("Ледяной доспех", player) then return end
    if combatMode and HasSpell("Ледяная преграда") and not HasBuff("Ледяная преграда", 0.01) and DoSpell("Ледяная преграда", player) then return end
  end

  if not (combatMode or IsArena()) then return end
  -- TryProtect -----------------------------------------------------------------
  if combat then
    if hp < (TimerLess("Damage", 1) and 80 or 50) and UseEquippedItem("Проржавевший костяной ключ") then return end
    if not (InDuel() or IsArena()) then
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      if mana < 50 and UseItem("Сапфир маны") then return end
      if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
    end
  end
  ----------------------------------------------------------------------------
  local validTarget = IsValidTarget(target)
  -- TryTarget ---------------------------------------------------------------
  TryTarget(attack, true)
  ----------------------------------------------------------------------------
  if TryInterrupt() then return end
  -- Rotation ----------------------------------------------------------------

  if CantAttack(target) then return end

  if HasBuff(reflectBuff, 0.1, target) and DoSpell("Ледяное копье", target) then return end
  if pvp and HasBuff("Magic", 3, target) and IsSpellNotUsed("Чарокрад", 5) and DoSpell("Чарокрад", target) then return end
  if pvp and HasDebuff("Curse", 3, player) and IsSpellNotUsed("Снятие проклятия", 5) and DoSpell("Снятие проклятия", player) then return end
  
  -- local spell, left =  UnitIsCasting("player")
  -- if spell and  left < LagTime * 1.8 then
  --   StopCast("left:" .. left)
  -- end
  if not attack and not CanMagicAttack(target) then
    chat(CanMagicAttackInfo)
    return
  end

  if (IsCtr() or HasBuff("Героизм")) and DoSpell("Зеркальное изображение") then return end

  if HasSpell("Живая бомба") then
    if HasBuff("Путь огня") and InRange("Огненная глыба", target) then
      local spell, left =  UnitIsCasting("player")
      if spell and not HasMyDebuff("Живая бомба", left + 1.5, target) then
        StopCast("Огненная глыба - Путь огня!")
      end
      DoSpell("Огненная глыба", target)
      return
    end


    local enemyInRange = GetEnemyInRange(10, target)
    --if inPlace and IsSpellNotUsed("Огненный столб", 5) and #enemyInRange > 4 and DoSpell("Огненный столб", target) then return end
    if AutoAOE and inPlace and #enemyInRange > 4 and DoSpell("Снежная буря", target) then return end

    if AutoAOE and not inPlace and #enemyInRange > 1  then --and IsSpellNotUsed("Живая бомба", 3)
      local count = math.max(5, #enemyInRange)
      for i = 1, count do
        local uid = enemyInRange[i]
        if not HasMyDebuff("Живая бомба", 0.01, uid) and InRange("Живая бомба", uid) then
          if DoSpell("Живая бомба", uid) then return end
        end
      end
    end

    if inPlace and IsSpellNotUsed("Ожог", 5) and not HasMyDebuff("ожог", 0.01, target) and InRange("Ожог", target) then
      DoSpell("Ожог", target)
      return
    end

    if not HasMyDebuff("Живая бомба", 0.01, target) and InRange("Живая бомба", target) then
      DoSpell("Живая бомба", target)
      return
    end

    if inPlace then
      if IsCtr() and DoSpell("Возгорание", target) then return end
      if UseEquippedItem(GetSlotItemName(10), target) then return end
      if DoSpell("Огненный шар", target) then return end
    else
      if DoSpell("Огненный взрыв", target) then return end
    end
  end

  if HasSpell("Глубокая заморозка") then

    if DoSpell("Глубокая заморозка", target) then return end

    if HasBuff("Огненный шар!") then
      local spell, left =  UnitIsCasting("player")
      if spell and left > 1 then
        StopCast("Огненный шар!")
      end
      if DoSpell("Стрела ледяного огня", target) then return end
      return
    end


    if IsCtr() then
      oexecute("PetAttack()")
      print( HasSpell("Холод") , IsUsableSpell("Холод"))
      if not HasSpell("Холод") and not HasBuff("Стылая кровь") and not IsReadySpell("Стылая кровь") and DoSpell("Холодная хватка") then return end
      if DoSpell("Стылая кровь") then return end
      if DoSpell("Призыв элементаля воды") then return end
      if DoSpell("Зеркальное изображение") then return end
      if not HasDebuff("Обморожение", 0.01, target) and DoSpell("Холод", target) then return end
    end
    local enemyInRange = GetEnemyInRange(10, target)
    --if inPlace and IsSpellNotUsed("Огненный столб", 5) and #enemyInRange > 4 and DoSpell("Огненный столб", target) then return end
    if AutoAOE and inPlace and #enemyInRange > 4 and DoSpell("Снежная буря", target) then return end

    if (pvp or UnitThreat(player, target) == 3) and TimerMore('frost1', 0.5) and inPlace and UnitAffectingCombat(target) and not HasDebuff("Ледяная стрела", 0.01, target) and InRange("Ледяная стрела") then
      if DoSpell("Ледяная стрела(Уровень 1)", target) then
        TimerStart("frost1")
        return
      end
      return
    end
    if inPlace and UseEquippedItem(GetSlotItemName(10), target) then return end
    if inPlace and DoSpell("Ледяная стрела", target) then return end
    if not inPlace and not HasDebuff("Обморожение", 0.01, target) then
      if DoSpell("Огненный взрыв", target) then return end
      if DistanceTo(player, target) < 12 then
        if PlayerFacingTarget(target) and DoSpell("Конус холода") then return end
        if DoSpell("Кольцо льда") then return end
      end
      if attack and not inPlace and DoSpell("Ледяное копье", target) then return end
    end
  end
end