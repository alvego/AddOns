-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local dispelTypes = {'Magic', 'Disease', 'Poison'}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления"}

local redDispelList = {
    "Превращение",
    "Глубокая заморозка",
    "Огненный шок",
    "Покаяние",
    "Молот правосудия",
    "Замедление",
    "Эффект ледяной ловушки",
    "Эффект замораживающей стрелы",
    "Удушение",
    "Антимагия - немота",
    "Безмолвие",
    "Волшебный поток",
    "Вой ужаса",
    "Ментальный крик",
    "Успокаивающий поцелуй"
}

teammate = "Qo"
function Idle()

  local target = "target"
  local player = "player"
  -- Дизамаунт
  if IsAttack() or IsMouse(3) then
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
      end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() and not IsPvP() then
        if HasBuff("Аура воина Света") then
           oexecute('CancelUnitBuff("player", "Аура воина Света")')
          if HasSpell("Частица Света") and DoSpell("Аура сосредоточенности") then return end
          if HasSpell("Удар воина Света") and DoSpell("Аура воздаяния")  then return end
        end
        Dismount()
      end
  end
  -- дайте поесть (побегать) спокойно
  if not IsPvP() and IsMounted() and not HasBuff("Аура воина Света") and DoSpell("Аура воина Света") then return end

  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end

  -- Heal Rotation ------------------------------------------------------------------------------------------------------------------------------
  if HasSpell("Частица Света") then

    if IsPvP() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end


      if (IsAttack() or InCombatLockdown()) and not HasBuff("Аура сосредоточенности") and DoSpell("Аура сосредоточенности", player) then return end
      --if IsPvP() and not HasBuff("Печать") and DoSpell("Печать праведности") then return true end
      if not HasBuff("Печать") and DoSpell("Печать мудрости", player) then return end
      --if not HasBuff("Печать") and DoSpell("Печать мудрости","player") then return end
      if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
          if not HasBuff("благословение королей") and DoSpell("Великое благословение королей", player) then return end
      end

      local hp = UnitHealth100(player)
      local mana = UnitMana100(player)

      if InCombatLockdown() then
        if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
        if not (InDuel() or IsArena()) then
          if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
          if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
        end
        if IsPvP() and hp < 40 and DoSpell("Длань спасения", player) then return end
      end

      local u = "player"
      local hasShield = HasMyBuff("Священный щит",1, player) and true or false
      local hasLight = HasMyBuff("Частица Света",1, player) and true or false
      local h = UnitHealth100(u)
      for i = 1, #UNITS do
        local _u = UNITS[i]
        local _h = UnitHealth100(_u)
        if not hasShield and HasMyBuff("Священный щит",1,_u) then hasShield = true end
        if not hasLight and HasMyBuff("Частица Света",1,_u) then hasLight = true end
        if _h < h then
          u = _u
          h = _h
        end
      end

      if not u then return end

      if InCombatLockdown() and IsInGroup() and IsSpellNotUsed("Частица Света", 10) and not hasLight and DoSpell("Частица Света", player) then return end

      local l = UnitLostHP(u)
      if mana > 90 then l = l * 2 end
      if HasBuff("Божественное одобрение") and DoSpell("Шок небес", u) then return end
      if InCombatMode() and h < 95 and UseEquippedItem("Украшенные перчатки разгневанного гладиатора") then return end
      if InCombatMode() and mana < 90 and UseEquippedItem("Осколок чистейшего льда") then return end
      if InCombatMode() and IsSpellNotUsed("Священный щит", 5) and (not hasShield or (h < 50 and not HasMyBuff("Священный щит", 1, u))) and DoSpell("Священный щит", u) then return end
      if (h < 35) and UseEquippedItem("Подвеска истинной крови", u) then return end
      if (h < 35) and not IsReadyItem("Подвеска истинной крови") and GetSpellCooldownLeft("Шок небес") < 0.1 and DoSpell("Божественное одобрение") then return end
      if (h < 95 or l > 5000) and DoSpell("Шок небес", u) then return end
      if (HasBuff("Прилив Света") or PlayerInPlace()) and (h < 50 or l > 4000) and DoSpell("Вспышка Света", u) then return end
      if IsSpellNotUsed("Очищение", 2) and HasDebuff(dispelTypes, 1, u) and not HasDebuff("Нестабильное колдовство", 0.1, u) and DoSpell("Очищение", u) then return end

      if InCombatMode() then
        TryTarget()
        if IsValidTarget(target) and DoSpell("Правосудие света", target) then return end
        if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
      end

      return
   end
   --DD_rotation--------------------------------------------------------------------------------------------------------------------------------------------

  if not HasSpell("Удар воина Света") then return end

  if IsPvP() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
  if not HasBuff("Печать") and DoSpell("Печать праведности") then return true end
  if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
      if not HasBuff("благословение королей") and DoSpell("Великое благословение королей", player) then return end
  end

  if InCombatMode() then



    local hp = UnitHealth100(player)
    local mana = UnitMana100(player)

    if not IsArena() and hp < 30 and DoSpell("Возложение рук", player) then return end
    if hp < 25 and DoSpell("Божественный щит", player) then return end

    if mana > 30 and IsSpellNotUsed("Очищение", 2) then
      if HasDebuff(redDispelList, 1, player) and HasDebuff(dispelTypes, 1, player) and not HasDebuff("Нестабильное колдовство", 0.1, player) and DoSpell("Очищение", player) then return end
      if IsInteractUnit(teammate) and HasDebuff(redDispelList, 1, teammate) and not HasDebuff("Нестабильное колдовство", 0.1, teammate) and DoSpell("Очищение", teammate) then return end
    end

    if InCombatLockdown() then
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      if not (InDuel() or IsArena()) then
        if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
        if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
      end
    end

    if HasBuff("Искусство войны") and (not IsValidTarget(target) or GetSpellCooldownLeft("Экзорцизм") > 0.5) then
       if hp < 85 and DoSpell("Вспышка Света", player) then return end
       if IsInteractUnit(teammate) and UnitHealth100(teammate) < 50 and DoSpell("Вспышка Света", teammate) then return end
    end


    if TryTarget() then return end
    if (IsAttack() or UnitAffectingCombat(target)) then
        if IsValidTarget(target) and not IsCurrentSpell("Автоматическая атака") then oexecute("StartAttack()") end
    else
      if IsCurrentSpell("Автоматическая атака") then  oexecute("StopAttack()") end
    end

    if IsReadySpell("Длань возмездия") and UnitIsPlayer(target) and (
      (tContains(steathClass, GetClass(target)) and not InRange("Покаяние", target)) or HasBuff(reflectBuff, 1, target)
    ) and not HasDebuff("Длань возмездия", 1, target) and DoSpell("Длань возмездия", target) then return end

    if UnitHealth100(target) < 20 and DoSpell("Молот гнева", target) then return end
    if IsAlt() and DoSpell("Правосудие справедливости", target) then return end
    if DoSpell("Правосудие мудрости", target) then return end

    if IsPvP() and not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end

    if not IsValidTarget(target) then return end
    FaceToTarget(target)
    if IsCtr() and DoSpell("Очищение", player) then return end
    if HasBuff("Проклятие хаоса") then
       oexecute('CancelUnitBuff("player", "Проклятие хаоса")')
    end
    if not IsInGroup() and not IsOneUnit(player, target .. "-"..target) and DoSpell("Длань возмездия", target) then return end
    if UseSlot(10) then return end
    if not IsEquippedItemType("Щит") and HasBuff("Искусство войны") and DoSpell("Экзорцизм", target) then return end
    if (UnitCreatureType(target) == "Нежить") and mana > 30 and DistanceTo(player, target) < 8 and DoSpell("Гнев небес") then return end
    if DistanceTo(player, target) < 8 and DoSpell("Божественная буря") then return end
    if DoSpell("Удар воина Света", target) then return end
    if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
    if mana > 50 then
      if DistanceTo(player, target) < 8 and (UnitCreatureType(target) == "Нежить") and DoSpell("Гнев небес") then return end
      if InMelee(target) and DoSpell("Освящение") then return end
    end
    if not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end
    if mana < 30 and DoSpell("Святая клятва") then return end

  end

end


------------------------------------------------------------------------------------------------------------------
function TryTarget()
    if not IsValidTarget("target") then
      oexecute("TargetNearestEnemy" .. (IsPvP() and "Player" or "" ) .. "()")
    end
    if UnitExists("target") and (not IsValidTarget("target") or (not IsAttack() and not UnitIsPlayer("target") and not UnitAffectingCombat("target"))) then
      --oexecute("ClearTarget()")
      return true
    end
    return false
end
