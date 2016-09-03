-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}

function Idle()
  -- Дизамаунт
  if IsAttack() or IsMouse(3) then
      if HasBuff("Парашют") then oexecute('CancelUnitBuff("player", "Парашют")') end
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



  if HasBuff("Проклятие хаоса") then oexecute('CancelUnitBuff("player", "Проклятие хаоса")') end
  if DoSpell("Победный раж", target) then return end
  if IsAOE() and DoSpell("Удар грома") then return end

  if not HasDebuff("Кровопускание", 1, target) and DoSpell("Кровопускание", target) then return end

  if HasBuff("Внезапная смерть") and DoSpell("Казнь", target) then return end

  if DoSpell("Превосходство", target) then return end

  if DoSpell("Смертельный удар", target) then return end

  if not HasBuff("крик", 1, player) and DoSpell("Боевой крик") then return end

  if IsAttack() and DoSpell("Рывок", target) then return end

  if mana > 80 then
     if UnitHealth100(target) < 20 then
       if DoSpell("Казнь", target) then return end
     else
       if DoSpell("Удар героя", target) then return end
     end
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
