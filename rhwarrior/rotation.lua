-- Warrior Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local myRootDebuff = {"Подрезать сухожилия", "Пронзительный вой" }
local burstList = {
    "Вихрь клинков",
    "Стылая кровь",
    "Гнев карателя",
    "Быстрая стрельба"
}

local bloodList = {
  "Сон",
  "Соблазн",
  "Страх",
  "Вой ужаса",
  "Устрашающий крик",
  "Контроль над разумом",
  "Глубинный ужас",
  "Ментальный крик",
  "Ослепление",
  "Ошеломление"
}
  --"Покаяние"

local procList = {"Целеустремленность железного дворфа", "Сила таунка", "Мощь таунка", "Скорость врайкулов", "Ловкость врайкула", "Пронзающая тьма"}

local immuneList = {"Божественный щит", "Ледяная глыба", "Длань защиты" }
local needSheeld = false;
Defence = false
function Idle()
  local stance = GetShapeshiftForm()
  local attack = IsAttack()
  local mouse5 = IsMouse(5)
  local player = "player"
  local focus = "focus"
  local hp = UnitHealth100(player)
  local rage = UnitMana(player)
  local warbringer = HasTalent("Вестник войны") > 0
  local titansGrip = HasTalent("Хватка титана") > 0
  local pvp = IsPvP()
  local combat = InCombatLockdown()
  local shield = IsEquippedItemType("Щит")

  local damage = attack or IsCtr() or HasBuff("Вихрь клинков")
  if AutoTaunt or warbringer then
    Defence = true
  else
    if damage  then
      Defence = false
    else
      if hp < (pvp and 50 or 30) then
        Defence = true
      end
    end
  end


  if Defence or mouse5 then
     needSheeld = true
  end
  if damage then
     needSheeld = false
  end

  if needSheeld then
      Equip1HShield()
  else
    if not HasBuff("Отражение заклинания", 0.1, player) then
        Equip2H()
    end
  end

  -- Дизамаунт -----------------------------------------------------------------
  if attack or mouse5 then
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
      end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then Dismount() end
  end
  ------------------------------------------------------------------------------
  -- дайте поесть (побегать) спокойно
  if not attack and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
  if IsCtr() then AddRage() end
  if InCombatMode() or IsArena() then

    -- Auto AntiControl --------------------------------------------------------

    local debuff, _, _, _, _, _duration, _expirationTime = HasDebuff(bloodList, 3, "player")
    if debuff and ((_duration - (_expirationTime - GetTime())) > 0.45) and IsSpellNotUsed("Каждый за себя", 2) and DoSpell("Ярость берсерка") then chat("Ярость берсерка - " .. debuff) return end
	  if not debuff then
		     debuff, _, _, _, _, _duration, _expirationTime = HasDebuff(ControlList, 3, "player")
    end
    if debuff and ((_duration - (_expirationTime - GetTime())) > 0.45) and IsSpellNotUsed("Ярость берсерка", 2) and DoSpell("Каждый за себя") then chat("Каждый за себя - " .. debuff) return end

    --AutoTaunt-----------------------------------------------------------------
    if not pvp and AdvMode and AutoTaunt and IsInGroup() --and Defence
      and IsSpellNotUsed("Вызывающий крик", 1)
      and IsSpellNotUsed("Провокация", 1)
      and IsSpellNotUsed("Дразнящий удар", 1) then
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
      if _c > 1 and DoSpell("Вызывающий крик", nil, true) then return end
      if _t then
        if not _isTanking then
          if stance == 2 and DoSpell("Провокация", _t, true) then return end
          if DoSpell("Героический бросок", _t) then return end
          if stance ~= 3 and DistanceTo(player, _t) < 8 and DoSpell("Удар грома") then return end
          if shield and DoSpell("Мощный удар щитом", _t, true) then return end
        end
        if stance ~= 3 and DoSpell("Дразнящий удар", _t, true) then return end
      end
    end
    -- IsAOE -------------------------------------------------------------------
    local aoe2 = false
    local aoe3 = false

    if IsShift() then
      aoe2 = true
      aoe3 = true
    else
      if AutoAOE and not InDuel() then
        local enemyCount = GetEnemyCountInRange(6)
        aoe2 = enemyCount >= 2
        aoe3 = enemyCount >= 3
      end
    end

    -- TryProtect -----------------------------------------------------------------
    if combat then
      --if hp < 50 and UseEquippedItem("Проржавевший костяной ключ") then return end
      if not (InDuel() or IsArena()) then
        if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
        if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      end
      if stance == 2 and shield then
        if hp < 52 and DoSpell("Глухая оборона") then return end
        if hp < 80 and DoSpell("Блок щитом") then return end
      end
      if hp < 60 and rage > 15 and HasBuff("Исступление", 0.1, player) and DoSpell("Безудержное восстановление", player, true) then return end
    end

    ----------------------------------------------------------------------------
    if (attack or hp > 60) and HasBuff("Длань защиты", 1, player) then
      oexecute('CancelUnitBuff("player", "Длань защиты")')
    end
    ----------------------------------------------------------------------------
    local target = "target"
    local validTarget = IsValidTarget(target)
    -- TryTarget ---------------------------------------------------------------
    TryTarget(attack, true)
    ----------------------------------------------------------------------------
    local melee = InMelee(target)
    if TryInterrupt(pvp) then return end
    if TryInterrupt(pvp, focus) then return end
    -- Rotation ----------------------------------------------------------------
    if attack and validTarget and IsVisible(target)
      and IsSpellNotUsed("Перехват", 1)
      and IsSpellNotUsed("Рывок", 1)  then

      local chargeLeft = GetSpellCooldownLeft("Рывок");
      local unstoppable = (HasTalent("Неудержимость") > 0)
      local chargeUsable = chargeLeft < 1 and (not combat or warbringer or unstoppable)

      if not IsCtr() and InRange("Рывок", target) and chargeUsable then
        if warbringer or stance == 1 then
          if DoSpell("Рывок", target) then return end
        else
          if DoSpell("Боевая стойка") then return end
        end
        return
      end


      local interceptLeft = GetSpellCooldownLeft("Перехват")
      if interceptLeft > 3 and (HasTalent("Неистовство героя") > 0) and DoSpell("Неистовство героя") then
        interceptLeft = 0
      end

      if (rage > 10 or stance == 3) and interceptLeft < 1 and InRange("Перехват", target) and not chargeUsable then
        if warbringer or stance == 3 then
          if DoSpell("Перехват", target, true) then return end
        else
          if DoSpell("Стойка берсерка") then return end
        end
        return
      end
    end


    if Defence then
      if stance ~= 2 and DoSpell("Оборонительная стойка") then return end
    else
      if titansGrip then
        if stance ~= 3 and DoSpell("Стойка берсерка") then return end
      else
        if stance ~= 1 and DoSpell("Боевая стойка") then return end
      end
    end

    if HasBuff(immuneList, 3, target) and IsReadySpell("Сокрушительный бросок") and rage >= 25  then
  		if not PlayerInPlace() then
  			echo('Стой!!!')
  		end
  		if not UnitIsCasting('player') and ApplyCommand('shatter') then return end
    end


    -- if not pvp and HasBuff("Проклятие хаоса") then
    --   oexecute('CancelUnitBuff("player", "Проклятие хаоса")')
    -- end

    if not CanAttack(target) then
      if Debug then chat('!CanAttack ' .. CanAttackInfo) end
      if HasBuff("Сдерживание",0.1, target) and stance == 1 and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target, true) then return end
    end
    if CantAttack() then return end

    if IsCtr() then
        if Equiped2H() and HasSpell("Вихрь клинков") and IsReadySpell("Вихрь клинков") and rage >= 25 then
          if not DoSpell("Размашистые удары") then
            DoSpell("Вихрь клинков", nil, true)
            return
          end
        end
    end
    if HasMyBuff("Вихрь клинков") and IsValidTarget(target) and IsValidTarget(focus) and (DistanceTo("player", focus) > DistanceTo("player", target)) then switchFocusTarget() end
    if (attack or (UnitHealth100(target) < 50) or UnitIsCasting(target)) and stance == 1 and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target, true) then return end

    if HasBuff("Сокрушить!") then
      local spell, left =  UnitIsCasting("player")
      if spell == "Мощный удар" and left > 1 then
        StopCast("Мощный удар - Сокрушить!")
      end
    end

    --if (IsCtr() or pvp or UnitIsBoss(target) or aoe3) and HasBuff(procList, 5, player) then
    if (IsCtr() or UnitIsBoss(target)) and HasBuff(procList, 5, player) then

      if HasSpell("Жажда смерти") then DoSpell("Жажда смерти", nil, true) end
      if stance == 3 then DoSpell("Безрассудство") end
    end

	--if AutoTaunt and UnitIsBoss(target) and (select(4, UnitDebuff("Раскол брони", 10, target)) or 0) < 5 and DoSpell("Раскол брони", target) then return end

    if shield and ( pvp and HasBuff("Magic", 3, target ) or HasBuff("Щит и меч", 0.1, player) ) and DoSpell("Мощный удар щитом", target, true) then return end
    if melee and stance == 2 and DoSpell("Разоружение", target, true) then return end
    if not attack and melee and HasBuff(burstList, 5, target) and ApplyCommand("disarm") then return end
    if stance ~= 2 and IsUsableSpell("Победный раж") and DoSpell("Победный раж", target) then return end
    if stance == 2 and IsUsableSpell("Реванш") and DoSpell("Реванш", target) then return end
    if aoe2 and HasSpell("Размашистые удары") then  DoSpell("Размашистые удары") end
    if aoe2 then DoSpell("Рассекающий удар", nil, not pvp) end
    if aoe3 and melee and stance ~= 3 and DoSpell("Удар грома") then return end

    if not attack and not PlayerInPlace() and UnitIsPlayer(target) and not HasBuff("Длань свободы", 0.1, target) and not HasDebuff(myRootDebuff, 1, target) then
        if stance ~= 2 and InRange("Подрезать сухожилия", target) then
          if DoSpell("Подрезать сухожилия", target) then return end
        elseif HasSpell("Пронзительный вой") and DistanceTo(player, target) < 10 then
          if DoSpell("Пронзительный вой") then return end
        end
    end
    if HasSpell("Сокрушение") and shield and DoSpell("Сокрушение", target) then return end
    if HasSpell("Смертельный удар") and DoSpell("Смертельный удар", target, true) then return end
    if stance ~= 3 and not HasMyDebuff("Кровопускание", 1, target) and DoSpell("Кровопускание", target, true) then return end
    if stance ~= 2 and HasBuff("Внезапная смерть") and DoSpell("Казнь", target) then return end
    if melee and HasSpell("Ударная волна") and DoSpell("Ударная волна") then return end
    if HasSpell("Кровожадность") and DoSpell("Кровожадность", target, true) then return end
    if stance == 3 and HasSpell("Вихрь") and (melee or aoe2) and DoSpell("Вихрь", nil, true) then return end
    if HasBuff("Сокрушить!") and DoSpell("Мощный удар", target, true) then return end
    if stance == 1 and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target) then return end
    if not aoe2 and rage > ( HasSpell("Кровожадность") and 11 or 95) then --TODO символ на удар героя, когторый возвращает рагу
	     if melee then DoSpell("Удар героя", target) end
    end
    if not attack then
      if warbringer or HasBuff("благословение могущества", 3, player) then
        if not HasBuff("Командирский крик", 3, player) and DoSpell("Командирский крик") then return end
      else
       if not HasBuff("благословение могущества", 3, player) then
  		if not HasBuff("Боевой крик", 3, player) and DoSpell("Боевой крик") then return end
       end
      end
    end
    if (pvp or UnitAffectingCombat(target)) and DoSpell("Героический бросок", target) then return end
    if not aoe2 and HasSpell("Вихрь") and GetSpellCooldownLeft("Вихрь") > 1.5 and HasSpell("Кровожадность")  and GetSpellCooldownLeft("Кровожадность") > 1.5 then
       if stance ~= 2 and UnitHealth100(target) < 20 then
         if DoSpell("Казнь", target) then return end
       end
    end
  end
end
