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
  if not IsPvP() and (IsMounted() or CanExitVehicle()) and not HasBuff("Аура воина Света") and DoSpell("Аура воина Света", "player") then return end
  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
  if (IsAttack() or InCombatLockdown()) and HasBuff("Аура воина Света") and oexecute('CancelUnitBuff("player", "Аура воина Света")') then return end

  if TryBuffs() then return end

  if InCombatMode() then

    TryTarget()

    if TryInterrupt("target") then return end

    --if TryDispel(player) then return end

    if TryTaunt() then return end
    --if true then return end
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
        if IsPvP() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return true end
        if (IsAttack() or InCombatLockdown()) and not HasBuff("Аура") and DoSpell("Аура воздаяния", player) then return true end
        if IsPvP() and not HasBuff("Печать") and DoSpell("Печать праведности") then return true end
        if not HasBuff("Печать") and DoSpell("Печать мщения") then return true end
        if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
            if not HasBuff("благословение королей") and DoSpell("Великое благословение королей","player") then return true end
            --if (not HasBuff("Боевой крик") or not HasBuff("благословение могущества")) and DoSpell("Великое благословение могущества","player") then return true end
        end
        return false
    end
    if HasSpell("Щит мстителя") then
        if (IsAttack() or InCombatLockdown()) and not HasMyBuff("Аура", 1, player) and DoSpell("Аура благочестия", player) then return true end
        if not HasMyBuff("Великое благословение неприкосновенности") and DoSpell("Великое благословение неприкосновенности", player) then return true end
        if not HasMyBuff("Печать", 0.1, player) then
          local seal = "Печать мщения"
          if HasSpell("Печать повиновения") then seal = "Печать повиновения" end
          if DoSpell(seal, player) then return true end
        end
        return false
    end
end

function Retribution()
  local target = "target"
  local player = "player"
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)

  if InCombatLockdown() then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if not InDuel() and hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
    if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
    if IsPvP() and hp < 40 and DoSpell("Длань спасения", player) then return end
  end

  if IsPvP() and not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end

  if hp < 85 and HasBuff("Искусство войны") --[[and GetSpellCooldownLeft("Экзорцизм") > 3]] then
     if DoSpell("Вспышка Света", player) then return end
  end
  if hp < 35 and DoSpell("Божественная защита", player) then return end
  --[[if PlayerInPlace() and HasBuff("Божественный щит", 2, player) then
      if hp < 50 and DoSpell("Свет небес", player) then return end
      if hp < 80 and DoSpell("Вспышка Света", player) then return end
  end]]

  if (IsAttack() or UnitAffectingCombat(target)) then
      if IsValidTarget(target) and not IsCurrentSpell("Автоматическая атака") then omacro("/startattack") end
  else
    if IsCurrentSpell("Автоматическая атака") then  omacro("/stopattack") end
  end
  if not IsValidTarget(target) then return end
  FaceToTarget(target)

  if IsCtr() and DoSpell("Очищение", player) then return end
  if HasBuff("Проклятие хаоса") then oexecute('CancelUnitBuff("player", "Проклятие хаоса")') end
  if UnitHealth100(target) < 20 and DoSpell("Молот гнева", target) then return end
  if not IsInGroup() and not IsOneUnit(player, target .. "-"..target) and DoSpell("Длань возмездия", target) then return end
  if UseItem("Чешуйчатые рукавицы разгневанного гладиатора") then return end
  if not IsEquippedItemType("Щит") and HasBuff("Искусство войны") and DoSpell("Экзорцизм", target) then return end
  if IsAlt() and DoSpell("Правосудие справедливости", target) then return end
  if DoSpell("Правосудие мудрости", target) then return end
  if DistanceTo(player, target) < 8 and DoSpell("Божественная буря") then return end
  if DoSpell("Удар воина Света", target) then return end
  if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
  --if (IsAttack() or mana > 70) and IsAOE() then
  if mana > 60 then
    if DistanceTo(player, target) < 8 and (UnitCreatureType(target) == "Нежить") and DoSpell("Гнев небес") then return end
    if InMelee(target) and DoSpell("Освящение") then return end
  end
  if not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end
  if mana < 30 and DoSpell("Святая клятва") then return end
end

--[[function Tank()
  local target = "target"
  local player = "player"
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)
  local valid = IsValidTarget(target)

  if InCombatLockdown() then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if hp < 35 and UseItem("Рунический флакон с лечебным зельем") then return end
    if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end

    if hp < 70 and UseEquippedItem("Гниющий палец Ика") then return end
    if hp < 50 and UseEquippedItem("Символ неукротимости") then return end

    if hp < 20 and DoSpell("Возложение рук", player) then return end
    if hp < 30 and DoSpell("Длань спасения", player) then return end
  end

  if not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end
  if not HasBuff("Святая клятва") and DoSpell("Святая клятва", player) then return end
  if not HasBuff("Щит небес",0.1) and DoSpell("Щит небес", player) then return end

  if (IsAttack() or UnitAffectingCombat(target)) then
      if valid and not IsCurrentSpell("Автоматическая атака") then omacro("/startattack") end
  else
    if IsCurrentSpell("Автоматическая атака") then  omacro("/stopattack") end
  end
  if not valid then return end
  FaceToTarget(target)

  if (IsAttack() or mana > 70) and IsAOE() then
      if DoSpell("Освящение") then return end
      if (UnitCreatureType(target) == "Нежить") and DoSpell("Гнев небес") then return end
  end
  if UnitHealth100(target) <= 20 and DoSpell("Молот гнева", target) then return end
  if DoSpell("Молот праведника", target) then return end
  if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
  if (IsAttack() or mana > 70) and IsAOE() and DoSpell("Щит мстителя", target) then return end
  if DoSpell(hp < 70 and "Правосудие света" or "Правосудие мудрости", target) then return end
end]]

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


--[[hooksecurefunc("MoveBackwardStart"	, function() print("MoveBackwardStart",format('SPD: %d%%', GetUnitSpeed("player") / 7 * 100)) end)
hooksecurefunc("MoveBackwardStop"	, function() print("MoveBackwardStop",format('SPD: %d%%', GetUnitSpeed("player") / 7 * 100)) end)

local function hookPlayerMove(...)
	print(111,...)
end

hooksecurefunc("MoveForwardStart"	, hookPlayerMove)
hooksecurefunc("MoveBackwardStart"	, hookPlayerMove)
hooksecurefunc("StrafeLeftStart"	, hookPlayerMove)
hooksecurefunc("StrafeRightStart"	, hookPlayerMove)
hooksecurefunc("JumpOrAscendStart"	, hookPlayerMove)
hooksecurefunc("ToggleAutoRun"		, hookPlayerMove)]]
