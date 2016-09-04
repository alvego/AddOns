-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}

function Idle()
  -- Дизамаунт
  if IsAttack() or IsMouse(3) then

      if HasBuff("Парашют") then omacro("/cancelaura Парашют") end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then Dismount() end
  end
  -- дайте поесть (побегать) спокойно
  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end



  if InCombatMode() then

    TryTarget()

    --if TryInterrupt("target") then return end

    --if TryTaunt() then return end

      Rotation()

  end

end



function Rotation()
  local target = "target"
  local player = "player"
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)

  if InCombatLockdown() then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if hp < 35 and UseItem("Рунический флакон с лечебным зельем") then return end
  end


  if (IsAttack() or UnitAffectingCombat(target)) then
      if IsValidTarget(target) and not IsCurrentSpell("Автоматическая атака") then omacro("/startattack") end
  else
    if IsCurrentSpell("Автоматическая атака") then  omacro("/stopattack") end
  end
  if not IsValidTarget(target) then return end
  FaceToTarget(target)


  if (IsAttack() or hp > 60) and HasBuff("Длань защиты", 1, player) then omacro("/cancelaura Длань защиты") end


  if HasBuff("Проклятие хаоса") then omacro("/cancelaura Проклятие хаоса") end
  if Stance(1,3) and IsUsableSpell("Победный раж") and DoSpell("Победный раж", target) then return end


  if IsCtr() then
      if Stance(3) and DoSpell("Безрассудство") then return end
      if HasSpell("Вихрь клинков") and InMelee() and DoSpell("Вихрь клинков") then return end
  end


  if IsAOE() and Stance(1,2) and DoSpell("Удар грома") then return end
  if IsAOE() and HasSpell("Размашистые удары") and DoSpell("Размашистые удары") then return end
  if IsAOE() and DoSpell("Рассекающий удар") then return end

  if not IsAOE() and Stance(1,3) and not HasMyDebuff("Подрезать сухожилия", 1, target) and DoSpell("Подрезать сухожилия", target) then return end
  if not IsAOE() and Stance(1,2) and not HasMyDebuff("Кровопускание", 1, target) and DoSpell("Кровопускание", target) then return end

  if Stance(1,3) and HasBuff("Внезапная смерть") and DoSpell("Казнь", target) then return end

  if Stance(1) and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target) then return end

  if HasSpell("Смертельный удар") and DoSpell("Смертельный удар", target) then return end --, not HasMyDebuff("Смертельный удар", 3, target)


  if HasBuff("Сокрушить!") and DoSpell("Мощный удар", target) then return end
  if Stance(3) and HasSpell("Вихрь") and (InMelee() or IsAOE()) and DoSpell("Вихрь") then return end
  if HasSpell("Кровожадность") and DoSpell("Кровожадность", target) then return end

  if mana > 80 then
     if Stance(1,3) and UnitHealth100(target) < 20 then
       if DoSpell("Казнь", target) then return end
     else
       if DoSpell("Удар героя", target) then return end
     end
  end

  if mana < 10 and DoSpell("Кровавая ярость") then return end
  if (not IsPvP() or IsAttack()) and DoSpell("Ярость берсерка") then return end


  if not ( HasMyBuff("крик", 1, player) or HasBuff("благословение могущества", 1, player)) and DoSpell("Боевой крик") then return end

  if IsAttack() then

      if Stance(3) and InRange("Перехват", target) and  DoSpell("Перехват", target) then return end

      if mana > 10 and
          not IsReadySpell("Рывок")
          and GetSpellCooldownLeft("Рывок") > 3
          and GetSpellCooldownLeft("Перехват") < 1
          and InRange("Перехват")
          and not Stance(3)
          and DoSpell("Стойка берсерка") then return end

      if Stance(1) and InRange("Рывок", target) and DoSpell("Рывок", target) then return end

      if not Stance(1) and DoSpell("Боевая стойка") then return end
    end

    if DoSpell("Героический бросок", target) then return end
    if InRange("Выстрел", target) and DoSpell("Выстрел", target) then return end
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
