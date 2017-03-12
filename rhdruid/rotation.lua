-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local player = "player"
local target = "target"
local stance, attack, pvp, combat, combatMode, validTarget, inPlace
function Idle()
  stance = GetShapeshiftForm()
  attack = IsAttack()
  pvp = IsPvP()
  combat = InCombatLockdown()
  combatMode = InCombatMode()
  validTarget = IsValidTarget(target)
  inPlace = PlayerInPlace()
  local mouse5 = IsMouse(5)
  -- Дизамаунт -----------------------------------------------------------------
  if attack or mouse5 then
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
      end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then Dismount() end
      if mouse5 and stance ~= 0 then omacro("/cancelform") end
  end
  ------------------------------------------------------------------------------
  -- дайте поесть (побегать) спокойно
  if not attack and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) or stance == 4 or stance == 6 then return end
  if HasTalent("Древо Жизни") > 0 then
    HealRotation()
    return
  end
  if HasTalent("Облик лунного совуха") > 0 then
    MonkRotation()
    return
  end
end
------------------------------------------------------------------------------------------------------------------
function HealRotation()
  if not (attack or combat or AutoHeal) then return end
  if not HasBuff("Древо Жизни") and DoSpell("Древо Жизни") then return end
  if not HasBuff("дикой природы") and DoSpell("Знак дикой природы") then return end
  ------------------------------------------------------------------------------
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)
  if combat then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if hp < 70 and DoSpell("Дубовая кожа", player) then return end
    if not (InDuel() or IsArena()) then
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
      if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
    end
    if mana < 60 and DoSpell("Озарение", player) then return end
    if mana < 80 and UseEquippedItem("Осколок чистейшего льда", player) then return end
  end
  local u = "player"
  local h = nil
  local curse_u = nil
  local curse_h = nil

  local potion_u = nil
  local potion_h = nil

  local lifebloom_u = nil
  local lifebloom_h = nil
  ------------------------------------------------------------------------------
  UpdateUnits()
  for i = 1, #UNITS do
    local _u = UNITS[i]
    if IsVisible(_u) then
      local _h = UnitHealth100(_u)

      if HasDebuff("Curse", 2, _u) and (not curse_h or _h < curse_h) then
        curse_u = _u
        curse_h = _h
      end

      if HasDebuff("Poison", 2, _u) and not HasBuff("Устранение яда", 0.5, _u) and (not potion_h or _h < potion_h) then
        potion_u = _u
        potion_h = _h
      end

      if (select(4, HasMyBuff("Жизнецвет", 0.01, u)) or 0) < 3 and (not lifebloom_h or _h < lifebloom_h) then
        lifebloom_u = _u
        lifebloom_h = _h
      end

      if not h or _h < h then
        u = _u
        h = _h
      end
    end
  end
  if not u then return end
  local l = UnitLostHP(u)
  if mana > 50 then l = l * 1.2 end -- оверхил
  --if IsAlt() then h = 60  l = 8000 end
  if HasBuff("Природная стремительность") then
     DoSpell("Целительное прикосновение", u)
     return
  end

  if lifebloom_u and HasBuff("Ясность мысли") then
   DoSpell("Жизнецвет", lifebloom_u)
   return
  end

  if IsAlt() or (mana > 50 and h > 60) then
    if potion_u and  IsSpellNotUsed("Устранение яда", 3) and DoSpell("Устранение яда", potion_u) then return end
    if curse_u and IsSpellNotUsed("Снятие проклятия", 3) and DoSpell("Снятие проклятия", curse_u) then return end
  end

  local tanking = (UnitThreat(u) > 1) or (combat and pvp and IsOneUnit(u, player))

  if (h < 70 and l > 10000) and (HasMyBuff("Омоложение", 1, u) or HasMyBuff("Восстановление", 1, u)) and HasSpell("Быстрое восстановление") and DoSpell("Быстрое восстановление", u) then return end
  if (h < 50 and l > 12000) and not IsReadyItem("Подвеска истинной крови") and HasSpell("Природная стремительность") and DoSpell("Природная стремительность") then  return end
  if (h < 45 and l > 12000) and UseEquippedItem("Подвеска истинной крови", u) then return end
  if (h < 98 or l > 500 or tanking) and not HasMyBuff("Омоложение", 1, u) and DoSpell("Омоложение", u) then return end

  local count, _, _, last = select(4, HasMyBuff("Жизнецвет", 0.01, u))
  if mana > 30 and h > 35 and (((tanking or h < 90) and (count or 0) < 3) or (tanking and last < 2 and h > 95)) and DoSpell("Жизнецвет", u) then return end

  if inPlace then
     if (h < 65 and l > 6000) and HasMyBuff("Благоволение природы") and not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
     if (h < 55 and l > 8000) and (HasMyBuff("Омоложение", 2, u) or HasMyBuff("Восстановление", 2, u) or HasMyBuff("Жизнецвет", 2, u) or HasMyBuff("Буйный рост", 2, u)) and DoSpell("Покровительство Природы", u) then return end
  end
end
------------------------------------------------------------------------------------------------------------------
local l = 0
function MonkRotation()
  if not combatMode then return end
  if not HasBuff("дикой природы") and DoSpell("Знак дикой природы") then return end
  if not HasBuff("Облик лунного совуха") and DoSpell("Облик лунного совуха") then return end
  if UnitMana100() < 30 and UseItem("Рунический флакон с зельем маны") then return end
    if UnitMana100(player) < 50 and DoSpell("Озарение", player) then return end
  if not validTarget then TryTarget() end
  if CantAttack() then return end
  if UnitHealth(target) > 200000 and not HasDebuff("Волшебный огонь") and DoSpell("Волшебный огонь", target) then return end
  --if not HasDebuff("Земля и луна") and DoSpell("Гнев", target) then end
  if not HasMyDebuff("Рой насекомых", 1, target) and DoSpell("Рой насекомых", target) then return end
  if not HasMyDebuff("Лунный огонь", 1, target) and DoSpell("Лунный огонь", target) then return end
  if not HasBuff("Солнечное") and (HasBuff("Лунное") or GetTime() - l < 4.6) and DoSpell("Звездный огонь", target) then l = GetTime() return end
  if DoSpell("Гнев", target) then return end
end
------------------------------------------------------------------------------------------------------------------
