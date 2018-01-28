-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
Teammate = "Qo"
local peaceBuff = {"Пища", "Питье"}
local steathClass = {"ROGUE", "DRUID"}
local player = "player"
local focus = "focus"
local target = "target"
local iUNITS = {"player", Teammate, "Nau"}
local duelUnits = {"player"}
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
      if (mouse5 and stance ~= 0) or (stance == 2 or stance == 4 or stance == 6) then UseShapeshiftForm(0) end
  end
  ------------------------------------------------------------------------------
  -- дайте поесть (побегать) спокойно
  if not attack and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or IsStealthed() or IsFishingMode())  then return end
  if pvp and combat and PayerIsRooted() then DoCommand('unRoot') end
  --if not attack and (stance == 2 or stance == 4 or stance == 6) then return end
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
  if not attack and not(stance == 0 or stance == 5) then return end
  if not (attack or combat or AutoHeal) then return end
  if UnitIsCasting("player") then return end
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
  local h = hp

  local curse_u = nil
  local curse_h = nil

  local potion_u = nil
  local potion_h = nil

  --Rejuvenation Омоложение
  local rj_u = nil
  local rj_h = nil

  -- Lifebloom Жизнецвет
  local lb_u = nil
  local lb_h = nil

  -- Wild Growth Буйный рост
  local wg_u = nil
  local wg_c = 0

  local full_hp = attack and 101 or 100
  ------------------------------------------------------------------------------
  UpdateUnits()
  local units = InDuel() and duelUnits or (hp > 60 and UNITS or iUNITS)

  for i = 1, #units do
    local _u = units[i]
    if InInteractRange(_u) then
      local _h = UnitHealth100(_u)
      if not h or _h < h then
        u = _u
        h = _h
      end

      if AutoDispel then
        if HasDebuff("Curse", 2, _u) and (not curse_h or _h < curse_h) then
          curse_u = _u
          curse_h = _h
        end

        if HasDebuff("Poison", 2, _u) and not HasBuff("Устранение яда", 0.5, _u) and (not potion_h or _h < potion_h) then
          potion_u = _u
          potion_h = _h
        end
      end

      if _h < full_hp then

        if (not rj_u or _h < rj_h) and not HasMyBuff("Омоложение", 0.01, _u) then
          rj_u = _u
          rj_h = _h
        end

        if (not lb_u or _h < lb_h) and not HasMyBuff("Жизнецвет", 0.01, _u) then
          lb_u = _u
          lb_h = _h
        end

        if IsReadySpell("Буйный рост") then
            local _c = 1;
            for j = 1, #units do
              local __u = units[j]
              local __h = UnitHealth100(__u)
              if __h < full_hp and DistanceTo(_u, __u) < 15 then
                _c = _c + 1
              end
            end
            if not wg_u or wg_c < _c then
              wg_u = _u
              wg_c = _c
            end
        end

      end
    end
  end
  -- Auto AntiControl --------------------------------------------------------
  if IsEquippedItem("Медальон Альянса") then
    local debuff, _, _, _, _, _duration, _expirationTime = HasDebuff(ControlList, 3, "player")
    --if debuff then print("Control: " .. debuff, (_duration - (_expirationTime - GetTime()))) end
    if (attack or h < 60) and debuff and ((_duration - (_expirationTime - GetTime())) > 0.45) and UseEquippedItem("Медальон Альянса") then chat("Медальон Альянса - " .. debuff) return end
  end
  -- Heal --------------------------------------------------------------------
  if not IsCtr() and (not IsSwimming() or attack) then UseShapeshiftForm(5) end
  if not u then return end
  local l = UnitLostHP(u)
  --if IsAlt() then h = 60  l = 8000 end
  if HasBuff("Природная стремительность") then
     DoSpell("Целительное прикосновение", u)
     return
  end

  if lb_u and HasBuff("Ясность мысли") then
   DoSpell("Жизнецвет", lb_u)
   return
  end

  if (h < 45 and l > 12000) and UseEquippedItem("Подвеска истинной крови", u) then return end
  if (h < 50 and l > 12000) and HasSpell("Природная стремительность") and DoSpell("Природная стремительность") then  return end
  if (h < 70 and l > 10000) and (HasMyBuff("Омоложение", 1, u) or HasMyBuff("Восстановление", 1, u)) and HasSpell("Быстрое восстановление") and DoSpell("Быстрое восстановление", u) then return end

  if h > 40 and TimerLess("Damage", 2) then DoSpell("Хватка природы", player) return end

  -- if IsAlt() then
  --   h = 40
  --   l = 10000
  -- end
  if inPlace then --and HasMyBuff("Благоволение природы")
     if (h < 65 and l > 6000) and not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
     if (h < 55 and l > 8000) and (HasMyBuff("Омоложение", 2, u) or HasMyBuff("Восстановление", 2, u) or HasMyBuff("Жизнецвет", 2, u) or HasMyBuff("Буйный рост", 2, u)) and DoSpell("Покровительство Природы", u) then return end
  end

  if mana > 50 and InInteractRange(focus) then
    f_h = UnitHealth100(focus)
    if f_h > 45 then
      local count, _, _, last = select(4, HasMyBuff("Жизнецвет", 0.01, focus))
      if ((count or 0) < 3) or (last < 2 and f_h > 95) then
         if DoSpell("Жизнецвет", focus) then return end
      end
    end
  end

  if wg_u and DoSpell("Буйный рост", wg_u) then return end

  if IsAlt() or (mana > 50 and h > 70) then
    if potion_u and IsSpellNotUsed("Устранение яда", 5) and DoSpell("Устранение яда", potion_u) then return end
    if curse_u and IsSpellNotUsed("Снятие проклятия", 5) and DoSpell("Снятие проклятия", curse_u) then return end
  end

  if h > 90 and mana > 50 then
    for i = 1, #iUNITS do
      local _u = iUNITS[i]
      if InInteractRange(_u) then
        if not HasBuff("дикой природы", 1, _u) and DoSpell(IsInGroup() and (GetItemCount("Дикий шиполист") > 0) and "Дар дикой природы" or "Знак дикой природы", _u) then return end
        if not HasBuff("Шипы", 1, _u) and DoSpell("Шипы", _u) then return end
      end
    end
  end

  if rj_u and DoSpell("Омоложение", rj_u) then return end
end
------------------------------------------------------------------------------------------------------------------
function MonkRotation()
  if not attack and not(stance == 0 or stance == 5) then return end
  if not combatMode then return end
  -- casting
  local spell, left = UnitIsCasting(player)
  if spell and spell  == "Звездный огонь" and not HasBuff("Лунное") and left > 1 then StopCast("!Лунное") end
  if spell and spell  ~= "Гнев" and HasBuff("Солнечное", 1) and left > 1 then  StopCast("Солнечное") end
  if spell then return end
  -- Auto AntiControl --------------------------------------------------------
  if attack and IsEquippedItem("Медальон Альянса") then
    local debuff, _, _, _, _, _duration, _expirationTime = HasDebuff(ControlList, 3, "player")
    --if debuff then print("Control: " .. debuff, (_duration - (_expirationTime - GetTime()))) end
    if debuff and ((_duration - (_expirationTime - GetTime())) > 0.45) and UseEquippedItem("Медальон Альянса") then chat("Медальон Альянса - " .. debuff) return end
  end
  if (not attack or not combat) and not HasBuff("дикой природы") and DoSpell(IsBattleground() and (GetItemCount("Дикий шиполист") > 0) and "Дар дикой природы" or "Знак дикой природы", player) then return end
  if (not attack or not combat) and not HasBuff("Шипы") and DoSpell("Шипы", player) then return end
  if TimerLess("Damage", 2) then DoSpell("Хватка природы", player) return end
  if TimerLess("Damage", 1) then DoSpell("Дубовая кожа", player) return end
  if (not IsSwimming() or attack) then UseShapeshiftForm(5) end
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
  if not validTarget then TryTarget(attack) end
  if not CanMagicAttack(target) then chat(CanMagicAttackInfo) return end
  if CantAttack() then return end
  if not HasDebuff("Земля и луна") and DoSpell("Гнев", target) then end
  if not HasMyDebuff("Лунный огонь", 1, target) and DoSpell("Лунный огонь", target) then return end
  if not HasMyDebuff("Рой насекомых", 1, target) and DoSpell("Рой насекомых", target) then return end
  if UnitHealth(target) > 200000 and not HasDebuff("Волшебный огонь") and DoSpell("Волшебный огонь", target) then return end
  if HasBuff("Лунное", 2) and DoSpell("Звездный огонь", target) then return end
  if (IsAlt() or pvp) and not attack then
    if HasDebuff("Poison", 2, player) and not HasBuff("Устранение яда", 0.5, player) and IsSpellNotUsed("Устранение яда", 5) and DoSpell("Устранение яда", player) then return end
    if HasDebuff("Curse", 2, player) and  IsSpellNotUsed("Снятие проклятия", 5) and DoSpell("Снятие проклятия", player) then return end
  end
  if DoSpell("Гнев", target) then return end
end
------------------------------------------------------------------------------------------------------------------
