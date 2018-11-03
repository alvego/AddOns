-- Paladin Rotation Helper 2 by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local dispelTypes = {'Magic', 'Disease', 'Poison'}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления"}
local physicDebuff = {"Смертельный удар"}

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

local function canDispel(u)
  return HasDebuff(dispelTypes, 1, u) and not HasDebuff("Нестабильное колдовство", 0.1, u)
end

function Idle()
  local isCC, isRoot, isSilence, isSnare, isDisarm, isImmune, isPvE = GetControlState(player)
  local target = "target"
  local player = "player"
  local last2H
  local isFinishHim = CanAttack(target) and UnitHealth100(target) < 35
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)
  local shield = IsEquippedItemType("Щит")
  -- Дизамаунт
  if IsAttack() then
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
      end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then Dismount() end
  end
  -- дайте поесть (побегать) спокойно
  --if not IsPvP() and IsMounted() and not HasBuff("Аура воина Света") and DoSpell("Аура воина Света") then return end
  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end

  if not isFinishHim and not HasBuff("Аура") and DoSpell("Аура воздаяния")  then return end
  if not HasBuff("Печать") and DoSpell("Печать праведности", player) then return  end
  if IsCtr() and HasDebuff(dispelTypes, 1, player) and not IsSilence and DoSpell("Очищение", player) then return end
  if IsShift() and InInteractRange(teammate) and HasDebuff(dispelTypes, 1, teammate) and not IsSilence and DoSpell("Очищение", teammate) then return end
  if not isFinishHim and not HasBuff("Праведное неистовство") and IsSpellNotUsed("Праведное неистовство", 5) and not IsSilence and DoSpell("Праведное неистовство") then return end
  if not isFinishHim and not InCombatMode() then
    if not HasMyBuff("благословение королей")
        and not HasMyBuff("благословение могущества")
        and not HasBuff("благословение королей")
        and not IsSilence and DoSpell("благословение королей", player) then return end
        return
    end
-- Defence----------------------------------------------------------------------
  if not InDuel() then
    if hp < 50 and DoSpell("Священная жертва") then return end
    if not IsArena() and hp < 30 and DoSpell("Возложение рук", player) then return end
    if hp < 25 and not IsSilence and DoSpell("Божественный щит", player) then return end
  end
-- switch weapons---------------------------------------------------------------
  if TimerMore('equipweapon', 0.5) then
    if hp < 40 and not shield then
      last2H = GetSlotItemName(16)
      -- одеваем одноручку и цит
      oexecute("UseEquipmentSet('upheal')")
      TimerStart('equipweapon')
      return
    end
    if hp > 80 and shield then
      -- одеваем двуручку
      EquipItem(last2H or 'Темная Скорбь', 16)
      TimerStart('equipweapon')
      return
    end
  end
-- dispels and heal-------------------------------------------------------------
  if not isFinishHim and mana > 30 and IsSpellNotUsed("Очищение", 5) and InInteractRange(teammate) and HasDebuff(redDispelList, 3, teammate)
    and not HasDebuff("Нестабильное колдовство", 0.1, teammate) and not IsSilence and DoSpell("Очищение", teammate) then return end
  if InCombatLockdown() then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if not (InDuel() or IsArena()) then
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
      if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
    end
  end
  if HasBuff("Искусство войны") then
     if hp < 85 and not IsSilence and DoSpell("Вспышка Света", player) then return end
     if InInteractRange(teammate) and UnitHealth100(teammate) < 50 and not IsSilence and DoSpell("Вспышка Света", teammate) then return end
  end
  if AdvMode then
    for i = 1, #TARGETS do
      local t = TARGETS[i]
      if CanMagicAttack(t) and UnitHealth100(t) < 19.99 and DoSpell("Молот гнева", t) then return end
    end
  end
  -- TryTarget------------------------------------------------------------------
  -- Rotation-------------------------------------------------------------------
  if not CanAttack(target) then return end
  if (IsAttack() or UnitAffectingCombat(target)) then oexecute("StartAttack()") end
  FaceToTarget(target)
  --if HasBuff("Проклятие хаоса") then oexecute('CancelUnitBuff("player", "Проклятие хаоса")') end
  if UnitHealth100(target) < 19.99 and not IsSilence and DoSpell("Молот гнева", target) then return end
  --if IsShift() and UseEquippedItem("Ремень триумфа разгневанного гладиатора", target) then return end
  if IsReadySpell("Длань возмездия") and UnitIsPlayer(target) and (
    (tContains(steathClass, GetClass(target)) and not InRange("Покаяние", target)) or HasBuff(reflectBuff, 1, target)
  ) and not HasDebuff("Длань возмездия", 1, target) and DoSpell("Длань возмездия", target) then return end
 print(IsSilence)
  if CanMagicAttack(target) and IsAlt() and not IsSilence and DoSpell("Правосудие справедливости", target) then return end
  if not isFinishHim and not HasBuff("Священный щит") and IsSpellNotUsed("Священный щит", 4) and not IsSilence and DoSpell("Священный щит", player) then return end
  if UseEquippedItem(GetSlotItemName(10), target) then return end
  if (UnitCreatureType(target) == "Нежить") and mana > 30 and DistanceTo(player, target) < 8 and not IsSilence and DoSpell("Гнев небес") then return end
  if not isDisarm and DoSpell("Удар воина Света", target) then return end
  if not isDisarm and (InMelee(target) or DistanceTo(player, target) < 7) and (IsReadySpell("Божественная буря") or (GetSpellCooldownLeft("Божественная буря") < 0.5)) then
    DoSpell("Божественная буря")
    return
  end
  if CanMagicAttack(target) and not IsSilence and DoSpell(((mana > 95) and "Правосудие света" or "Правосудие мудрости"), target) then return end
  if mana < 30 and not IsSilence and DoSpell("Святая клятва") then return end
  if shield then
    if DoSpell("Щит праведности", target) then return end
  else
    if HasBuff("Искусство войны") and CanMagicAttack(target) and not IsSilence and DoSpell("Экзорцизм", target) then return end
  end
  if mana > 50 then
    if DistanceTo(player, target) < 8 and (UnitCreatureType(target) == "Нежить") and not IsSilence and DoSpell("Гнев небес") then return end
    if HasBuff("Искусство войны") and hp < 95 and not IsSilence and DoSpell("Вспышка Света", player) then return end
    --if not InDuel() and InMelee(target) and DoSpell("Освящение") then return end
  end
end
