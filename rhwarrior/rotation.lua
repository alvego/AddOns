-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local myRootDebuff = {"Подрезать сухожилия", "Пронзительный вой" }
local burstList = {
    "Вихрь клинков",
    "Стылая кровь",
    "Гнев карателя",
    "Быстрая стрельба"
}
function Idle()
  local stance = GetShapeshiftForm()
  local attack = IsAttack()
  -- Дизамаунт
  if attack or IsMouse(3) then
      if HasBuff("Парашют") then omacro("/cancelaura Парашют") end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then Dismount() end
  end
  -- дайте поесть (побегать) спокойно
  if not attack and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end

  if stance ~= 2 and not HasBuff("Отражение заклинания", 0.1, player) then
      Equip2H()
  end

  if stance == 2 then
      Equip1HShield()
  end

  if InCombatMode() then

    TryTarget()

    if TryInterrupt("target") then return end

    --if TryTaunt() then return end
    local autoAttack = IsCurrentSpell("Автоматическая атака")
    local player = "player"
    local hp = UnitHealth100(player)
    local rage = UnitMana(player)
    local aoe3 = IsAOE(3)
    local aoe2 = IsAOE(2)
    local target = "target"
    local combat = InCombatLockdown()
    local shield = IsEquippedItemType("Щит")


    local validTarget = IsValidTarget(target)
    local melee = InMelee(target)
    local target2 = target
    local melee2 = melee
    if combat and validTarget and not melee then
      for i=1, #TARGETS do
        local t = TARGETS[i]
        if UnitAffectingCombat(t) and IsValidTarget(t) and InMelee(t) and PlayerFacingTarget(t) then
          target2 = t
          melee2 = true
          if not IsOneUnit("focus", t) then omacro("/focus " .. t) end
        end
      end
    end

    if combat then
      if hp < 50 and UseEquippedItem("Проржавевший костяной ключ") then return end
      if not (InDuel() or IsArena()) then
        if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
        if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      end
      if hp < 50 and UseEquippedItem("Проржавевший костяной ключ") then return end
      if stance == 2 and shield then
        if hp < 32 and DoSpell("Глухая оборона") then return end
        if hp < 60 and DoSpell("Блок щитом") then return end
      end
      if hp < 60 and rage > 15 and HasBuff("Исступление", 0.1, player) and DoSpell("Безудержное восстановление", player, true) then return end

      if not attack and hp < 45 and stance ~= 2 and DoSpell("Оборонительная стойка") then return end
    end

    if (attack or hp > 60) and HasBuff("Длань защиты", 1, player) then omacro("/cancelaura Длань защиты") end


    if validTarget and attack and not UnitInLos(target) then


      if IsSpellNotUsed("Перехват", 1) and InRange("Рывок", target) and GetSpellCooldownLeft("Рывок") < 1 then
        if stance == 1 then
          if DoSpell("Рывок", target) then return end
        else
          if DoSpell("Боевая стойка") then return end
        end
        return
      end

      if rage > 10 and IsSpellNotUsed("Рывок", 1)  and GetSpellCooldownLeft("Рывок") > 2 and InRange("Перехват", target) and GetSpellCooldownLeft("Перехват") < 1 then
        if stance == 3 then
          if DoSpell("Перехват", target, true) then return end
        else
          if DoSpell("Стойка берсерка") then return end
        end
        return
      end
    end

    if (stance == 3 or (attack and stance == 2)) and DoSpell("Боевая стойка") then return end



    if (attack or UnitAffectingCombat(target)) then
      if validTarget and not autoAttack then omacro("/startattack") end
    else
      if autoAttack then  omacro("/stopattack") end
    end
    if not validTarget then return end
    FaceToTarget(target)


    if HasBuff("Проклятие хаоса") then omacro("/cancelaura Проклятие хаоса") end


    --if (not IsPvP() or IsAttack()) and DoSpell("Ярость берсерка") then return end



    if IsCtr() then
        if stance == 3 and DoSpell("Безрассудство") then return end
        if Equiped2H() and HasSpell("Вихрь клинков") and IsReadySpell("Вихрь клинков") and rage >= 25 then
          omacro("/cast Размашистые удары")
          omacro("/cast Вихрь клинков")
          omacro("/cleartarget")
          omacro("/targetenemyplayer")
          omacro("/startattack")
          return
        end
    end

    if stance ~= 2 and IsUsableSpell("Победный раж") and DoSpell("Победный раж", target2) then return end
    if stance == 2 and IsUsableSpell("Реванш") and DoSpell("Реванш", target2) then return end

    if stance == 2 and HasBuff(burstList, 5, target) and DoSpell("Разоружение", target2, true) then return end

    if aoe3 and melee2 and stance ~= 3 and DoSpell("Удар грома") then return end
    if aoe2 and HasSpell("Размашистые удары") and DoSpell("Размашистые удары") then return end
    if aoe2 and DoSpell("Рассекающий удар") then return end



    if GetUnitSpeed(target) > 4.5 and UnitIsPlayer(target) and not HasMyDebuff(myRootDebuff, 1, target) then
        if stance ~= 2 and InRange("Подрезать сухожилия", target) then
          if DoSpell("Подрезать сухожилия", target) then return end
        elseif HasSpell("Пронзительный вой") and DistanceTo(player, target) < 10 then
          if DoSpell("Пронзительный вой") then return end
        end
    end



    if melee and HasSpell("Ударная волна") and DoSpell("Ударная волна") then return end
    if shield and ( IsPvP() and HasBuff("Magic", 3, target2 ) or HasBuff("Щит и меч", 0.1, player) ) and DoSpell("Мощный удар щитом", target2) then return end
    if HasSpell("Сокрушение") and shield and DoSpell("Сокрушение", target2) then return end


    if stance ~= 3 and not HasMyDebuff("Кровопускание", 1, target2) and DoSpell("Кровопускание", target2, true) then return end

    if HasSpell("Смертельный удар") and DoSpell("Смертельный удар", target2, not HasMyDebuff("Смертельный удар", 1, target2)) then return end --, not HasMyDebuff("Смертельный удар", 3, target)
    if stance == 1 and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target2, true) then return end

    --if stance ~= 2 and (not HasSpell("Смертельный удар") or GetSpellCooldownLeft("Смертельный удар") > 2) and HasBuff("Внезапная смерть") and DoSpell("Казнь", target) then return end
    if stance ~= 2 and HasBuff("Внезапная смерть") and DoSpell("Казнь", target2) then return end

    if HasBuff("Сокрушить!") and DoSpell("Мощный удар", target2) then return end
    if stance == 3 and HasSpell("Вихрь") and (melee2 or aoe2) and DoSpell("Вихрь") then return end
    if HasSpell("Кровожадность") and DoSpell("Кровожадность", target2) then return end

    if not aoe2 and rage > 80 then
       if stance ~= 2 and UnitHealth100(target) < 20 then
         if DoSpell("Казнь", target2) then return end
       else
         if melee2 and DoSpell("Удар героя", target2) then return end
       end
    end

    if not ( HasMyBuff("крик", 1, player) or HasBuff("благословение могущества", 1, player)) and DoSpell("Боевой крик") then return end
    if DoSpell("Героический бросок", target) then return end
    --if not aoe2 and PlayerInPlace() and InRange("Выстрел", target) and DoSpell("Выстрел", target) then return end
  end

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
