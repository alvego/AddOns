-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
Teammate = "Qo"
local peaceBuff = {"Пища", "Питье"}
local steathClass = {"ROGUE", "DRUID"}
local player = "player"
local target = "target"
local iUNITS = {"player", Teammate, "Nau"}
local duelUnits = {"player"}
local stance, attack, pvp, combat, combatMode, validTarget, inPlace, rejuvenation
local followUnit = nil
function Idle()
  followUnit = nil
  if AutoFollow and not IsMouselooking() and IsInteractUnit(Teammate) then
    local unit = GetSameGroupUnit(Teammate)
    if unit ~= Teammate then followUnit = unit end
  end

  if followUnit then
    local dist = DistanceTo(player, followUnit)
    if (dist > 15 or not IsVisible(followUnit)) then
      DoFollow(followUnit)
    else
      StopFollow()
    end
  end
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
  if UnitIsCasting("player") then return end
  -- дайте поесть (побегать) спокойно
  if not attack and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or IsStealthed())  then return end
  if PayerIsRooted() then DoCommand('unRoot') end
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

  local hot_u = nil
  local hot_h = nil

  local lowhpmembers = 0
  ------------------------------------------------------------------------------
  UpdateUnits()
  local units = InDuel() and duelUnits or (hp > 60 and UNITS or iUNITS)

  for i = 1, #units do
    local _u = units[i]
    if InInteractRange(_u) then
      local _h = UnitHealth100(_u)
      if HasDebuff("Curse", 2, _u) and (not curse_h or _h < curse_h) then
        curse_u = _u
        curse_h = _h
      end

      if HasDebuff("Poison", 2, _u) and not HasBuff("Устранение яда", 0.5, _u) and (not potion_h or _h < potion_h) then
        potion_u = _u
        potion_h = _h
      end

      if not HasMyBuff("Жизнецвет", 0.01, u) and not HasMyBuff("Омоложение", 0.01, u) and not HasMyBuff("Восстановление", 0.01, u)  and (not hot_h or _h < hot_h) then
        hot_u = _u
        hot_h = _h
      end
      if _h < 50 then lowhpmembers = lowhpmembers + 1 end
      if not h or _h < h then
        u = _u
        h = _h
      end
    end
  end
  -- Auto AntiControl --------------------------------------------------------
  if IsEquippedItem("Медальон Альянса") then
    local debuff, _, _, _, _, _duration, _expirationTime = HasDebuff(ControlList, 3, "player")
    --if debuff then print("Control: " .. debuff, (_duration - (_expirationTime - GetTime()))) end
    if (attack or h < 60) and debuff and ((_duration - (_expirationTime - GetTime())) > 0.45) and UseEquippedItem("Медальон Альянса") then chat("Медальон Альянса - " .. debuff) return end
  end
  -- Auto Damage -------------------------------------------------------------
  if (IsCtr() or not InMelee(target)) and (h > (IsCtr() and 40 or 80)) then
    --[[if AdvMode and pvp then
      UpdateObjects()
      local st = nil
      local mt = nil
      local dist = nil
      local used = false
      for i = 1, #TARGETS do
        local t = TARGETS[i]
        if CanMagicAttack(t) then
          local d = DistanceTo("player", t)
          if not mt and UnitIsPlayer(t) and ((tContains(steathClass, GetClass(t)) and d > 25) or not UnitAffectingCombat(t)) and not HasMyDebuff("Волшебный огонь", 0.1, t) then mt = t end
          if not used then
             used =  HasDebuff("Спячка", 1, t)
             local ctype = UnitCreatureType(t)
             if d and d < 25 and (ctype =="Животное" or ctype == "Дракон") and (not dist or (dist > d)) and not IsOneUnit(t, target) then
                st = t
                dist = d
             end
           end
         end
       end
      if not used and st and DoSpell("Спячка", st) then return end
      if mt and DoSpell("Волшебный огонь", mt) then return end
    end]]
    if not validTarget and IsCtr() then TryTarget(attack) end
    if CanMagicAttack(target) and not CantAttack() then
      if UnitIsPlayer(target) and tContains(steathClass, GetClass(target)) and not HasMyDebuff("Волшебный огонь", 0.1, target) and DoSpell("Волшебный огонь", target) then return end
      if not HasMyDebuff("Рой насекомых", 0.1, target) and DoSpell("Рой насекомых", target) then return end
      if not HasMyDebuff("Лунный огонь", 0.1, target) and DoSpell("Лунный огонь", target) then return end
      if IsCtr() and DoSpell(inPlace and "Гнев" or "Лунный огонь", target) then return end
    end
  end
  -- Heal --------------------------------------------------------------------
  if not IsCtr() then UseShapeshiftForm(5) end
  if not u then return end
  local l = UnitLostHP(u)
  --if IsAlt() then h = 60  l = 8000 end
  if HasBuff("Природная стремительность") then
     DoSpell("Целительное прикосновение", u)
     return
  end

  if hot_u and HasBuff("Ясность мысли") then
   DoSpell("Жизнецвет", hot_u)
   return
  end

  if (h < 70 and l > 10000) and (HasMyBuff("Омоложение", 1, u) or HasMyBuff("Восстановление", 1, u)) and HasSpell("Быстрое восстановление") and DoSpell("Быстрое восстановление", u) then return end
  if (h < 50 and l > 12000) and not IsReadyItem("Подвеска истинной крови") and HasSpell("Природная стремительность") and DoSpell("Природная стремительность") then  return end
  if (h < 45 and l > 12000) and UseEquippedItem("Подвеска истинной крови", u) then return end

  if h > 30 and TryInterrupt() then return end
  if h > 30 and TryInterrupt("focus") then return end
  if h > 40 and TimerLess("Damage", 2) then DoSpell("Хватка природы", player) return end

  if IsReadySpell("Спокойствие") and InCombatLockdown() then
		if (lowhpmembers > 3 and (100 / #units * lowhpmembers > 35)) then
			if not TimerStarted("tranquilityAlert") then
				Notify("Стой на месте! Ща жахнем 'Спокойствие!'")
        TimerStart("tranquilityAlert")
			elseif TimerMore("tranquilityAlert", 1)  then
        if not inPlace then
            if AdvMode then oexecute("MoveForwardStop()") end
        elseif not DoSpell("Дубовая кожа") and DoSpell("Спокойствие") then
				  TimerReset("tranquilityAlert")
		      return
        end
			end
		end
  end

  if inPlace then
     if (h < 50 and l > 6000) and HasMyBuff("Благоволение природы") and not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
     if (h < 40 and l > 8000) and (HasMyBuff("Омоложение", 2, u) or HasMyBuff("Восстановление", 2, u) or HasMyBuff("Жизнецвет", 2, u) or HasMyBuff("Буйный рост", 2, u)) and DoSpell("Покровительство Природы", u) then return end
  end

  local tanking = (UnitThreat(u) > 1) or (hp < 60 and IsOneUnit(u, player))
  if (h < 98 or l > 500 or tanking) and not HasMyBuff("Омоложение", 1, u) and DoSpell("Омоложение", u) then return end
  local count, _, _, last = select(4, HasMyBuff("Жизнецвет", 0.01, u))
  if h > 45 and (((tanking or h <= 95) and (count or 0) < 3) or (tanking and last < 2 and h > 95)) and DoSpell("Жизнецвет", u) then return end


  if hot_u and hot_h and hot_h < 100 then
    if not rejuvenation then rejuvenation = 1 end
    local spell = "Омоложение"
    if rejuvenation > 5 then
      spell = "Жизнецвет"
      rejuvenation = 1
    end
     return HasMyBuff("Жизнецвет", 1, hot_u)
  end

  if IsAlt() or (mana > 50 and h > 77) then
    if potion_u and  IsSpellNotUsed("Устранение яда", 5) and DoSpell("Устранение яда", potion_u) then return end
    if curse_u and IsSpellNotUsed("Снятие проклятия", 5) and DoSpell("Снятие проклятия", curse_u) then return end
  end

  if h > 70 and mana > 50 then
    for i = 1, #iUNITS do
      local _u = iUNITS[i]
      if InInteractRange(_u) then
        if not HasBuff("дикой природы", 1, _u) and DoSpell(IsBattleground() and (GetItemCount("Дикий шиполист") > 0) and "Дар дикой природы" or "Знак дикой природы", _u) then return end
        if not HasBuff("Шипы", 1, _u) and DoSpell("Шипы", _u) then return end
      end
    end
  end
end
------------------------------------------------------------------------------------------------------------------
local l = 0
function MonkRotation()
  if not combatMode then return end
  if not HasBuff("дикой природы") and DoSpell("Знак дикой природы") then return end
  UseShapeshiftForm(5)
  if UnitMana100() < 30 and UseItem("Рунический флакон с зельем маны") then return end
    if UnitMana100(player) < 50 and DoSpell("Озарение", player) then return end
  if not validTarget then TryTarget(attack) end
  if CantAttack() then return end
  if UnitHealth(target) > 200000 and not HasDebuff("Волшебный огонь") and DoSpell("Волшебный огонь", target) then return end
  --if not HasDebuff("Земля и луна") and DoSpell("Гнев", target) then end
  if not HasMyDebuff("Рой насекомых", 1, target) and DoSpell("Рой насекомых", target) then return end
  if not HasMyDebuff("Лунный огонь", 1, target) and DoSpell("Лунный огонь", target) then return end
  if not HasBuff("Солнечное") and (HasBuff("Лунное") or GetTime() - l < 4.6) and DoSpell("Звездный огонь", target) then l = GetTime() return end
  if DoSpell("Гнев", target) then return end
end
------------------------------------------------------------------------------------------------------------------
