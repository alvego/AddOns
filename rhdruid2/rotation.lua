-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
Teammate = "Nau"
Defence = false
local bloodList = { "Увечье (кошка)", "Увечье (медведь)", "Травма" }
local aggroUnitTypes = {"worldboss", "rareelite", "elite"}
local peaceBuff = {"Пища", "Питье", "Походный облик", "Облик стремительной птицы", "Водный облик"}
local mountBuff = {"Походный облик", "Облик стремительной птицы", "Водный облик"}
local steathClass = {"ROGUE", "DRUID"}
local player = "player"
local focus = "focus"
local target = "target"
local bearHealBuffs = {"Инстинкты выживания", "Неистовое восстановление"}
local stance, attack, pvp, combat, combatMode, canAttackTarget, inPlace, time,
  mouse5, hp, mana, enemyCount, cat, bear, arena, mounted, vehicle, duel, melee,
  dist, stealth
function Idle()
  stance = GetShapeshiftForm()
  attack = IsAttack()
  pvp = IsPvP()
  combat = InCombatLockdown()
  combatMode = InCombatMode()
  canAttackTarget = CanAttack(target)
  inPlace = PlayerInPlace()
  time = GetTime()
  mouse5 = IsMouse(5)
  hp = UnitHealth100(player)
  mana = UnitMana(player)
  cat = HasBuff("Облик кошки")
  bear = HasBuff("Облик лютого медведя")
  arena = IsArena()
  mounted = IsMounted()
  vehicle = CanExitVehicle()
  duel = InDuel()
  stealth = IsStealthed()
  -- Дизамаунт -----------------------------------------------------------------
  if attack or mouse5 then
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
      end
      if vehicle then VehicleExit() end
      if mounted then Dismount() end
      if (mouse5 and stance ~= 0) or HasBuff(mountBuff) then UseShapeshiftForm(0) end
  end
  ------------------------------------------------------------------------------
  -- дайте поесть (побегать) спокойно
  if not attack and (mounted or vehicle or stealth
    or HasBuff(peaceBuff) or IsFishingMode()) then return end

  local bearHeal = HasBuff(bearHealBuffs)
    ------------------------------------------------------------------------------
  if AutoTaunt then
    Defence = true
  else
    if attack then
      if bearHeal and hp > 95 then
        chat("Хилимся в мишке, hp: ".. hp)
      else
        Defence = false
      end
    else
      if hp < (pvp and 50 or 30) then
        Defence = true
      end
    end
  end
  ------------------------------------------------------------------------------
  if (not attack or not combat) and not HasBuff("дикой природы") and DoSpell(IsBattleground() and (GetItemCount("Дикий шиполист") > 0) and "Дар дикой природы" or "Знак дикой природы", player) then return end
  ------------------------------------------------------------------------------
  if not (combatMode or arena) then return end
  ------------------------------------------------------------------------------
  -- TryProtect -----------------------------------------------------------------
  if combat then
    --if hp < 50 and UseEquippedItem("Проржавевший костяной ключ") then return end
    if not (duel or arena) then
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    end
    if hp < (pvp and 80 or 60) and DoSpell("Дубовая кожа") then return end
    if pvp and hp < 50 and TimerLess("Damage", 2) then DoSpell("Хватка природы", player) return end
    if hp < (pvp and 50 or 35) and Defence and bear then
      ApplyCommand("bearHeal")
      return
    end
  end
  --AutoTaunt-------------------------------------------------------------------
  if not pvp and bear and AdvMode and AutoTaunt and IsInGroup() then
    local _t = nil
    local _c = 0;
    local _threatpct = 100
    local _isTanking = true
    --------------------------------------------------------------------------
    for i = 1, #TARGETS do
      local t = TARGETS[i]
      if UnitAffectingCombat(t) then
        local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("player", t);
        if status and threatpct < _threatpct then
          _t = t
          _threatpct = threatpct
          _isTanking = isTanking
        end
        if status and not isTanking and DistanceTo(player, t) <= 10 then _c = _c + 1 end
      end
    end
    --------------------------------------------------------------------------
    if _c > 1 and DoSpell("Вызывающий рев", nil, true) then return end
    if _t then
      if not _isTanking then
        if DoSpell("Рык", _t, true) then return end
      end
      if DoSpell("Растерзать", _t) then return end
    end
  end
  ----------------------------------------------------------------------------
  if (attack or hp > 85) and HasBuff("Длань защиты", 1, player) then
    oexecute('CancelUnitBuff("player", "Длань защиты")')
  end
  -- TryTarget ---------------------------------------------------------------
  TryTarget(attack, true)
  -- InMelee -----------------------------------------------------------------
  canAttackTarget = CanAttack(target)
  dist = DistanceTo(player, target)
  -- Rotation ----------------------------------------------------------------
  local chargeCatLeft = GetSpellCooldownLeft("Звериная атака - кошка");
  if not stealth
    and attack
    and dist < ((chargeCatLeft < 2) and 30 or 10)
    and canAttackTarget
    and not combat
    and cat
    and IsReadySpell("Крадущийся зверь") then
      DoSpell("Крадущийся зверь")
      return
  end

  if attack and canAttackTarget and (dist >= 8 and dist <=25)
    and IsSpellNotUsed("Звериная атака - медведь", 1)
    and IsSpellNotUsed("Звериная атака - кошка", 1)  then

    local canCatCharge = chargeCatLeft < 1
    if Defence then
      canCatCharge = false
    end
    if canCatCharge then
      if cat then
        if DoSpell("Звериная атака - кошка", target) then return end
      else
        if DoSpell("Облик кошки") then return end
      end
      return
    end

    local chargeBearLeft = GetSpellCooldownLeft("Звериная атака - медведь")
    local canBearCharge = not canCatCharge
    if cat and stealth  then
      canBearCharge = false
    end
    if bear then
        if mana < 10 and not IsReadySpell("Исступление") and not HasBuff("Исступление", 5) then
          chat('Раги всего ' .. mana .. ' и Исступление не готово')
          canCatCharge = false
        end
    else
      if not IsReadySpell("Исступление") then
        chat('Исступление не готово')
        canCatCharge = false
      end
    end
    if chargeBearLeft < 1 and canBearCharge then
      if bear then
        if mana < 10 and DoSpell("Исступление") then return end
        if DoSpell("Звериная атака - медведь", target, true) then return end
      else
        if DoSpell("Облик лютого медведя") then return end
      end
      return
    end

  end

  if Defence then
    if not bear and DoSpell("Облик лютого медведя") then return end
  else
    if not cat and DoSpell("Облик кошки") then return end
  end
  if CantAttack() then return end
  melee = InMelee(target)
  -- IsAOE -------------------------------------------------------------------
  enemyCount = AutoAOE and GetEnemyCountInRange(bear and 8 or 5) or 1

  if not bear and HasBuff("Быстрота хищника") then
      --if IsCtr() and HasDebuff("Смерч",1,"target") then DoSpell("Смерч") return end
      if hp < (pvp or not (IsInstance() and IsInGroup()) and 95 or 50) then DoSpell("Целительное прикосновение", player) return end
  end

  if cat then
    local behind = IsBehind(target)
    if not melee then
      Notify("Ближе!")
    elseif not behind then
      Notify("За спину!")
    end

    if stealth then

        if behind then
            if DoSpell("Накинуться", target) then return end
        else
            if DoSpell("Наскок", target) then return end
        end
        return
    end

    if not pvp and IsInGroup() and tContains(aggroUnitTypes, UnitClassification(unit)) then
        local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", target)
        if (isTanking or state == 1) and DoSpell("Попятиться", target) then
            chat("Попятиться! " .. scaledPercent )
            return true
        end
    end
    local bersBuff = HasBuff(50334)
    --~      Ротация для кошки
    if enemyCount > 1 then
        if mana < 45 and not bersBuff and DoSpell("Тигриное неистовство") then return end
        DoSpell("Размах (кошка)")
        return
    end

    local canAddEnergy = true
    local hasBers = HasSpell("Берсерк")
    local needBers = hasBers and canBers()
    local bersLeft = hasBers and GetSpellCooldownLeft("Берсерк") or 0
    if (needBers and bersLeft < 30) then canAddEnergy = false end
    if canAddEnergy and mana < 30 and not bersBuff and DoSpell("Тигриное неистовство") then return end

    local rakeLeft = max((select(7, HasMyDebuff("Глубокая рана", 0.01, target)) or 0) - time, 0)
    local bloodLeft = max((select(7, HasDebuff(bloodList, 0.01, target)) or 0) - time, 0)
    local savageRoarLeft = max((select(7, UnitBuff(player, "Дикий рев")) or 0) - time, 0)
    local ripLast = max((select(7, HasMyDebuff("Разорвать", 0.01, target)) or 0) - time, 0)
    local sorcerousFireLeft = max((select(7, HasDebuff("Волшебный огонь", 0.01, target)) or 0) - time, 0)

    if needBers and melee and bersLeft < 1
      and (mana > 60 or IsReadySpell("Тигриное неистовство"))
      and rakeLeft > 5 and bloodLeft > 8 then
        if mana < 60 and  DoSpell("Тигриное неистовство") then return end
        DoSpell("Берсерк")
        return
    end

    if (UnitIsBoss(target) or pvp) and sorcerousFireLeft < 5 and DoSpell("Волшебный огонь (зверь)", target) then return end

    if HasSpell("Увечье (кошка)") and bloodLeft < 3 then
        DoSpell("Увечье (кошка)", target)
        return
    end
    if rakeLeft == 0 then
        DoSpell("Глубокая рана", target)
        return
    end
    if HasBuff("Ясность мысли") then
        if DoSpell(behind and "Полоснуть" or (HasSpell("Увечье (кошка)") and "Увечье (кошка)" or "Цапнуть"), target) then return end
        return
    end
    local CP = GetComboPoints("player", "target")
    if (CP > 1) and isNeedStun() then
        DoSpell("Калечение", target)
        return
    end
    if (CP > 3) and savageRoarLeft > 0 and savageRoarLeft < 8 and DoSpell("Дикий рев") then return end
    if (CP > 0) and savageRoarLeft == 0 then
        DoSpell("Дикий рев")
        return
    end
    if (CP == 5) then
        if ripLast == 0 and DoSpell("Разорвать", target) then return end
        if savageRoarLeft > 8 and ripLast > 5 and DoSpell("Свирепый укус", target) then return end
        return
    end

    if DoSpell(behind and "Полоснуть" or (HasSpell("Увечье (кошка)") and "Увечье (кошка)" or "Цапнуть"), target) then return end
  end
  if bear then
    if not melee then
      Notify("Ближе!")
    end
    local canBearHeal = (hp < 50) and IsReadySpell("Инстинкты выживания") and IsReadySpell("Неистовое восстановление")
    if not attack and (canBearHeal or bearHeal) and mana < 60 then return end
    if canBers() and DoSpell("Берсерк") then return end
    if mana < 15 and DoSpell("Исступление") then return end
    if IsReadySpell("Оглушить") and isNeedStun() then
      if DoSpell("Оглушить") then return end
      return
    end
    if enemyCount > 1 and DoSpell("Размах(Облик медведя)") then return end
    if  (UnitIsBoss(target) or pvp) and not HasDebuff("Волшебный огонь", 1, target) and DoSpell("Волшебный огонь (зверь)", target) then return end
    if not HasMyDebuff("Увечье (медведь)", 5, target) and DoSpell("Увечье (медведь)", target) then return end
    local  name, _, _, count = HasMyDebuff("Растерзать", 1, target);
    if (not name or count < 5) and DoSpell("Растерзать", target) then return end
    if not HasMyDebuff("Увечье (медведь)", GCDDuration, target) and DoSpell("Увечье (медведь)", target) then return end
    if  (UnitIsBoss(target) or pvp or enemyCount > 4) and not HasDebuff("Устрашающий рев",1) and DoSpell("Устрашающий рев") then return end
    if DoSpell("Увечье (медведь)", target) then return end
    if melee and mana > 25 and not (IsCurrentSpell("Трепка") == 1) and DoSpell("Трепка") then return end
  end
end
----------------------------------------------------------------------------------------------------------------
function isNeedStun()
  if not CanInterrupt then return false end
  local spell, left, duration, channel, nointerrupt = UnitIsCasting(target)
  if not spell then return false end
  if left < (channel and 0.5 or 0.2) then  return false end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
  if pvp and not tContains(InterruptList, spell) then return false end
  if pvp and tContains(HealList, spell) and (not IsValidTarget(focus) or UnitHealth100(focus) > 50) then return false end
  return melee
end
----------------------------------------------------------------------------------------------------------------
function canBers()
  if IsCtr() then return true end
  if not AutoBers then return false end
  return not not (pvp or (enemyCount > 4) or UnitIsBoss(target))
end
