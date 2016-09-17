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
      if HasBuff("Парашют") then omacro("/cancelaura Парашют") end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then
        if HasMyBuff("Аура воина Света") then
          omacro("/cancelaura Аура воина Света")
          if HasSpell("Частица Света") and not HasBuff("Аура сосредоточенности") and DoSpell("Аура сосредоточенности") then return end
          if HasSpell("Удар воина Света") and not HasBuff("Аура воздаяния") and DoSpell("Аура воздаяния")  then return end
        end
        Dismount()
      end
  end
  -- дайте поесть (побегать) спокойно
  if not IsPvP() and IsMounted() and not HasBuff("Аура воина Света") and DoSpell("Аура воина Света") then return end

  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end

  if not HasSpell("Удар воина Света") then return end

  if IsPvP() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end

  if HasMyBuff("Аура воина Света") then omacro("/cancelaura Аура воина Света") end
  if (IsAttack() or InCombatLockdown()) and not HasBuff("Аура") and DoSpell("Аура воздаяния", player) then return end
  if IsPvP() and not HasBuff("Печать") and DoSpell("Печать праведности") then return true end
  if not HasBuff("Печать") and DoSpell("Печать мщения") then return true end
  if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
      if not HasBuff("благословение королей") and DoSpell("Великое благословение королей", player) then return end
  end

  if InCombatMode() then

    TryTarget()

    local hp = UnitHealth100(player)
    local mana = UnitMana100(player)
    if mana > 10 and IsSpellNotUsed("Очищение", 2) then
      if HasDebuff(redDispelList, 1, player) and HasDebuff(dispelTypes, 1, player) and not HasDebuff("Нестабильное колдовство", 0.1, player) and DoSpell("Очищение", player) then return end
      if IsInteractUnit(teammate) and HasDebuff(redDispelList, 1, teammate) and not HasDebuff("Нестабильное колдовство", 0.1, teammate) and DoSpell("Очищение", teammate) then return end
    end

    if IsReadySpell("Длань возмездия") and UnitIsPlayer(target) and (
      (tContains(steathClass, GetClass(t)) and not InRange("Покаяние", t)) or HasBuff(reflectBuff, 1, target)
    ) and not HasDebuff("Длань возмездия", 1, target) and DoSpell("Длань возмездия", target) then return end


    if InCombatLockdown() then
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      if not (InDuel() or IsArena()) then
        if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
        if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
      end
      if IsPvP() and hp < 40 and DoSpell("Длань спасения", player) then return end
    end

    if IsPvP() and not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end

    if HasBuff("Искусство войны") and not (IsValidTarget(target) and IsReadySpell("Экзорцизм")) then
        if hp < 85 and DoSpell("Вспышка Света", player) then return end
        if IsInteractUnit(teammate) and UnitHealth100(teammate) < 50 and DoSpell("Вспышка Света", teammate) then return end
    end

    if hp < 35 and DoSpell("Божественная защита", player) then return end

    if (IsAttack() or UnitAffectingCombat(target)) then
        if IsValidTarget(target) and not IsCurrentSpell("Автоматическая атака") then omacro("/startattack") end
    else
      if IsCurrentSpell("Автоматическая атака") then  omacro("/stopattack") end
    end
    if not IsValidTarget(target) then return end
    FaceToTarget(target)
    if IsCtr() and DoSpell("Очищение", player) then return end
    if HasBuff("Проклятие хаоса") then omacro("/cancelaura Проклятие хаоса") end
    if UnitHealth100(target) < 20 and DoSpell("Молот гнева", target) then return end
    if not IsInGroup() and not IsOneUnit(player, target .. "-"..target) and DoSpell("Длань возмездия", target) then return end
    if UseItem("Чешуйчатые рукавицы разгневанного гладиатора") then return end
    if not IsEquippedItemType("Щит") and HasBuff("Искусство войны") and DoSpell("Экзорцизм", target) then return end
    if IsAlt() and DoSpell("Правосудие справедливости", target) then return end
    if DoSpell("Правосудие мудрости", target) then return end
    if DistanceTo(player, target) < 8 and DoSpell("Божественная буря") then return end
    if DoSpell("Удар воина Света", target) then return end
    if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
    if mana > 60 then
      if DistanceTo(player, target) < 8 and (UnitCreatureType(target) == "Нежить") and DoSpell("Гнев небес") then return end
      if InMelee(target) and DoSpell("Освящение") then return end
    end
    if not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end
    if mana < 30 and DoSpell("Святая клятва") then return end

    if IsSpellNotUsed("Очищение", 5) and HasDebuff(dispelTypes, 1, player) and not HasDebuff("Нестабильное колдовство", 0.1, player) and DoSpell("Очищение", player) then return end
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
