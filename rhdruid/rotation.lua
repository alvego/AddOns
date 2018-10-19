-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
Teammate = "Qo"
local peaceBuff = {"Пища", "Питье"}
local mountBuff = {"Походный облик", "Облик стремительной птицы", "Водный облик"}
local steathClass = {"ROGUE", "DRUID"}
local player = "player"
local focus = "focus"
local target = "target"
local iUNITS = {"player", Teammate, "Nau"}
local duelUnits = {"player"}
local faceCPSpell = HasSpell("Увечье (кошка)") and "Увечье (кошка)" or "Цапнуть"
local stance, attack, pvp, combat, combatMode, validTarget, inPlace, time
function Idle()
  stance = GetShapeshiftForm()
  attack = IsAttack()
  pvp = IsPvP()
  combat = InCombatLockdown()
  combatMode = InCombatMode()
  validTarget = IsValidTarget(target)
  inPlace = PlayerInPlace()
  time = GetTime()
  local mouse5 = IsMouse(5)
  -- Дизамаунт -----------------------------------------------------------------
  if attack or mouse5 then
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
      end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then Dismount() end
      if (mouse5 and stance ~= 0) or HasBuff(mountBuff) then UseShapeshiftForm(0) end
  end
  ------------------------------------------------------------------------------
  -- дайте поесть (побегать) спокойно
  if not attack and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or HasBuff(mountBuff) or IsStealthed() or IsFishingMode())  then return end
  --if pvp and combat and PayerIsRooted() then DoCommand('unRoot') end
  if HasTalent("Древо Жизни") > 0 then
    HealRotation()
    return
  end
  if HasTalent("Облик лунного совуха") > 0 then
    MonkRotation()
    return
  end
  Rotation()
end
------------------------------------------------------------------------------------------------------------------
function HealRotation()
  if not attack and not(stance == 0 or stance == 5) then return end
  if not (attack or combat or AutoHeal) then return end
  if UnitIsCasting("player") then return end
  ------------------------------------------------------------------------------
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)

  if (not attack or not combat) then
    if not HasBuff("дикой природы") and DoSpell(IsBattleground() and (GetItemCount("Дикий шиполист") > 0) and "Дар дикой природы" or "Знак дикой природы", player) then return end
    if not HasBuff("Шипы") and DoSpell("Шипы", player) then return end
    if InInteractRange(focus) and not HasBuff("Шипы", 0.1, focus) and DoSpell("Шипы", focus) then return end
  end

  if combat then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if hp < 70 and DoSpell("Дубовая кожа", player) then return end
    if TimerLess("Damage", 2) then DoSpell("Хватка природы", player) return end

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

  local full_hp = attack and 101 or 99
  ------------------------------------------------------------------------------
  UpdateUnits()
  local units = InDuel() and duelUnits or (hp > 60 and UNITS or iUNITS)
  local clearcasting = HasBuff("Ясность мысли")
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

      if _h < full_hp and (not rj_u or _h < rj_h) and not HasMyBuff("Омоложение", 0.01, _u) then
        rj_u = _u
        rj_h = _h
      end

      if _h < full_hp and IsReadySpell("Буйный рост") then
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

      if _h < full_hp and clearcasting and (not lb_u or _h < lb_h) and not HasMyBuff("Жизнецвет", 0.01, _u) then
        lb_u = _u
        lb_h = _h
      end

    end
  end

  if mana > 50 and InInteractRange(focus) then
    local f_h = UnitHealth100(focus)
    if f_h > 45 then
      --name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
      local count, _, _, last = select(4, HasMyBuff("Жизнецвет", 0.01, focus))
      if not count or (attack and count < 3) or last - GetTime() < 2  then
         lb_u = focus
         lb_h = f_h
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

  if lb_u and clearcasting then
   DoSpell("Жизнецвет", lb_u)
   return
  end

  if (h < 45 and l > 12000) and UseEquippedItem("Подвеска истинной крови", u) then return end
  if (h < 50 and l > 12000) and HasSpell("Природная стремительность") and DoSpell("Природная стремительность") then  return end
  if (h < 70 and l > 10000) and (HasMyBuff("Омоложение", 1, u) or HasMyBuff("Восстановление", 1, u)) and HasSpell("Быстрое восстановление") and DoSpell("Быстрое восстановление", u) then return end

  -- if IsAlt() then
  --   h = 40
  --   l = 10000
  -- end
  if inPlace then --and HasMyBuff("Благоволение природы")
     if (h < 65 and l > 6000) and not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
     if (h < 55 and l > 8000) and (HasMyBuff("Омоложение", 2, u) or HasMyBuff("Восстановление", 2, u) or HasMyBuff("Жизнецвет", 2, u) or HasMyBuff("Буйный рост", 2, u)) and DoSpell("Покровительство Природы", u) then return end
  end

  if wg_u and DoSpell("Буйный рост", wg_u) then return end

  if lb_u and DoSpell("Жизнецвет", lb_u) then return end

  if IsAlt() or (mana > 50 and h > 70) then
    if potion_u and IsSpellNotUsed("Устранение яда", 5) and DoSpell("Устранение яда", potion_u) then return end
    if curse_u and IsSpellNotUsed("Снятие проклятия", 5) and DoSpell("Снятие проклятия", curse_u) then return end
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
  TryTarget(attack)
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
----------------------------------------------------------------------------------------------------------------

function Rotation()

  if not combatMode then return end
  if (not attack or not combat) and not HasBuff("дикой природы") and DoSpell(IsBattleground() and (GetItemCount("Дикий шиполист") > 0) and "Дар дикой природы" or "Знак дикой природы", player) then return end
  if (not IsSwimming() or attack) and stance == 0 then
    UseShapeshiftForm(3)
    return
  end
  local hp = UnitHealth100(player)
  local mana = UnitMana(player)
  local enemyCount = GetEnemyCountInRange(8)
  if pvp and hp < 50 and TimerLess("Damage", 2) then DoSpell("Хватка природы", player) return end
  if hp < (pvp and 80 or 50) and TimerLess("Damage", 1) then DoSpell("Дубовая кожа", player) return end
  if combat then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if hp < 60 and DoSpell("Дубовая кожа", player) then return end
    if not (InDuel() or IsArena()) then
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
    end
  end
  TryTarget(attack, true)
  if CantAttack() then return end
  local melee = InMelee(target)
  local behind = IsBehind(target)
  if not melee then
    Notify("Ближе!")
  elseif not behind then
    Notify("За спину!")
  end

  if HasBuff("Быстрота хищника") then
      --if IsControlKeyDown() and HasDebuff("Смерч",1,"target") then DoSpell("Смерч") return end
      if hp < ((pvp or not UnitIsBoss(target)) and 95 or 50) then DoSpell("Целительное прикосновение", player) return end
  end

  if HasBuff("Облик лютого медведя") and validTarget then
      if mana < 50 and DoSpell("Исступление") then return end
      if HasSpell("Звериная атака - медведь") and InRange("Звериная атака - медведь", target)  and (mana >= 5 or IsReadySpell("Исступление")) then
          DoSpell("Звериная атака - медведь")
          return
      end
      --if DoSpell("Оглушить") then return end
      --if IsReadySpell("Оглушить") then return end
      --if hp < 60 and DoSpell("Неистовое восстановление") then return end

      -- if enemyCount > 1 and DoSpell("Размах(Облик медведя)") then return end
      -- if  (UnitIsBoss(target) or pvp) and not HasDebuff("Волшебный огонь", 1, target) and DoSpell("Волшебный огонь (зверь)", target) then return end
      -- if not HasMyDebuff("Увечье (медведь)", GCDDuration, target) and DoSpell("Увечье (медведь)", target) then return end
      -- local  name, _, _, count = HasMyDebuff("Растерзать", GCDDuration, target);
      -- if (not name or count < 5) and DoSpell("Растерзать", target) then return end
      -- if not HasMyDebuff("Увечье (медведь)", GCDDuration, target) and DoSpell("Увечье (медведь)", target) then return end
      -- if  (UnitIsBoss(target) or pvp) and not HasDebuff("Устрашающий рев",3) and DoSpell("Устрашающий рев") then return end
      -- if DoSpell("Увечье (медведь)", target) then return end
      -- if melee and mana > 25 and DoSpell("Трепка") then return end

      --return
  end
  if HasBuff("Облик кошки") then

      if not HasBuff("Крадущийся зверь") and HasSpell("Звериная атака - медведь") and IsAttack() and validTarget and InRange("Звериная атака - медведь", "target") and GetSpellCooldownLeft("Звериная атака - кошка") > 2 and GetSpellCooldownLeft("Звериная атака - медведь") == 0 then
          DoSpell("Облик лютого медведя(Смена облика)")
          return
      end

      if IsAttack() and InRange("Волшебный огонь (зверь)", target) and validTarget and not combat and HasBuff("Облик кошки") and IsReadySpell("Крадущийся зверь") then
          DoSpell("Крадущийся зверь")
          return
      end

      --if not (validTarget and combatMode)  then return end

      if attack and HasSpell("Звериная атака - кошка") and (IsStealthed() or not IsReadySpell("Крадущийся зверь")) and DoSpell("Звериная атака - кошка", target) then return end

      if IsStealthed() then
          if behind then
              if DoSpell("Накинуться", target) then return end
          else
              if DoSpell("Наскок", target) then return end
          end
          return
      end

      if combat and attack and validTarget and InRange("Звериная атака - кошка", target) and DoSpell("Звериная атака - кошка", target) then return end



      if IsInGroup() and  UnitIsBoss(target) then
          local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", target)
          if not isTanking and state == 1 and DoSpell("Попятиться", target) then
              chat("Попятиться!!")
              return true
          end
      end


--~      Ротация для кошки
      if enemyCount > 1 then
          if mana < 35 and mana > 25 and not HasBuff("Берсерк") and DoSpell("Тигриное неистовство") then return end
          DoSpell("Размах (кошка)")
          return
      end


      if mana < 30 and DoSpell("Тигриное неистовство") then return end

      if HasDebuff("Глубокая рана") and HasDebuff("Волшебный огонь (зверь)", 5) and HasDebuff("Разорвать",7) and melee then
          if mana > 25 and mana < 85 and HasSpell("Берсерк") and DoSpell("Берсерк") then return end
      end

      if HasBuff("Ясность мысли") then
          if DoSpell(behind and "Полоснуть" or faceCPSpell, target) then return end
          return
      end

      local CP = GetComboPoints("player", "target")
      if (UnitIsBoss(target) or pvp) and not HasDebuff("Волшебный огонь (зверь)", 2) and DoSpell("Волшебный огонь (зверь)", target) then return end
      if HasSpell("Увечье (кошка)") and not (HasDebuff("Увечье (медведь)") or HasDebuff("Увечье (кошка)") or HasDebuff("Травма"))then
              DoSpell("Увечье (кошка)")
          return
      end
      if not HasDebuff("Глубокая рана") then
          DoSpell("Глубокая рана")
          return
      end
      local expirationTime = select(7, UnitBuff(player, "Дикий рев"))
      local savageRoarLeft = expirationTime and max(expirationTime - time, 0) or 0
      local expirationTime, unitCaster = select(7, UnitDebuff(target, "Разорвать"))
      local ripLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
      if (CP > 2) and savageRoarLeft > 0 and savageRoarLeft < 5 and DoSpell("Дикий рев") then return end
      if (CP > 0) and savageRoarLeft == 0 then
          DoSpell("Дикий рев")
          return
      end
      if (CP == 5) then
          if ripLast == 0 and DoSpell("Разорвать", target) then return end
          if savageRoarLeft > 5 and ripLast > 5 and DoSpell("Свирепый укус", target) then return end
          return
      end

      if DoSpell(behind and "Полоснуть" or faceCPSpell, target) then return end

      if (UnitIsBoss(target) or pvp) and not HasDebuff("Волшебный огонь (зверь)", 7) and DoSpell("Волшебный огонь (зверь)", target) then return end

  else
      if (HasBuff("Знак дикой природы") or HasBuff("Дар дикой природы")) and DoSpell("Облик кошки") then return end
  end
end
------------------------------------------------------------------------------------------------------------------
