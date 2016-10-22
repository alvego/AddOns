-- Paladin Rotation Helper by Timofeev Alexey
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
  "Ошеломление",

}
  --"Покаяние"

local procList = {"Целеустремленность железного дворфа", "Сила таунка", "Мощь таунка", "Скорость врайкулов", "Ловкость врайкула", "Пронзающая тьма"}

local immuneList = {"Божественный щит", "Ледяная глыба", "Длань защиты" }
Defence = false
function Idle()
  local stance = GetShapeshiftForm()
  local attack = IsAttack()

  local player = "player"
  local hp = UnitHealth100(player)
  local rage = UnitMana(player)
  local warbringer = HasTalent("Вестник войны") > 0
  local titansGrip = HasTalent("Хватка титана") > 0

  if AutoTaunt or warbringer then
    Defence = true
  else
    if attack then
      Defence = false
    else
      if hp < 25 then
        Defence = true
      end
    end
  end

  local pvp = IsPvP()
  local combat = InCombatLockdown()
  local shield = IsEquippedItemType("Щит")

  if Defence then
      Equip1HShield(pvp)
  else
    if not HasBuff("Отражение заклинания", 0.1, player) then
        Equip2H()
    end
  end

  -- Дизамаунт -----------------------------------------------------------------
  if attack or IsMouse(3) then
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
  if InCombatMode() then

    -- Auto AntiControl --------------------------------------------------------
    local debuff = HasDebuff(bloodList, 3, "player")
    	if debuff and  IsSpellNotUsed("Каждый за себя", 1) and DoSpell("Ярость берсерка") then return end
	if not debuff then
		debuff = HasDebuff(ControlList, 3, "player")
    end
    if debuff and  IsSpellNotUsed("Ярость берсерка", 1) and DoSpell("Каждый за себя") then return end

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
          if status and status < 3 and threatpct < _threatpct then
            _t = t
            _threatpct = threatpct
            _isTanking = isTanking
          end
          if status and status < 2 and DistanceTo(player, t) <= 10 then _c = _c + 1 end
        end
      end
      --------------------------------------------------------------------------
      if _c > 1 and DoSpell("Вызывающий крик", nil, true) then return end
      if _t then
        if stance == 2 and not _isTanking and DoSpell("Провокация", _t, true) then return end
        if DoSpell("Героический бросок", _t) then return end
        if stance ~= 3 and DistanceTo(player, _t) < 8 and DoSpell("Удар грома") then return end
        if shield and DoSpell("Мощный удар щитом", _t, true) then return end
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
    ----------------------------------------------------------------------------
    local target = "target"
    local validTarget = IsValidTarget(target)

    --[[if not validTarget and UnitExists(target) then
      oexecute("ClearTarget()")
    end]]
    -- TryTarget ---------------------------------------------------------------
    if not validTarget then
        local _uid = nil
        local _face = false
        local _dist = 100
        local _combat = false
        local look = IsMouselooking()
        for i = 1, #TARGETS do
          local uid = TARGETS[i]
          repeat -- для имитации continue
            if not IsValidTarget(uid) then break end
            local combat = UnitAffectingCombat(uid)
            -- уже есть кто-то в бою
            if _combat and not combat then break end
            -- автоматически выбераем только цели в бою
            if not attack and not combat then break end
            -- не будет лута
            if (UnitIsTapped(uid)) and (not UnitIsTappedByPlayer(uid)) then break end
            if UnitIsPossessed(uid) then break end
            -- в pvp выбираем только игроков
            if pvp and not UnitIsPlayer(uid) then break end
            -- только актуальные цели
            local face = PlayerFacingTarget(uid, look and 30 or 90)
            -- если смотрим, то только впереди
            if look and not face then break end
            local dist = DistanceTo("player", uid)
            if _face and not face and dist > 8 then break end
            if dist > _dist then break end
            _uid = uid
            _combat = combat
            _face = face
            _dist = dist
          until true
        end
        if _uid then
          oexecute("TargetUnit('".. _uid .."')")
          validTarget = true
        end
    end
    ----------------------------------------------------------------------------
    local melee = InMelee(target)
    if TryInterrupt(pvp) then return end
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

    -- Rotation ----------------------------------------------------------------
    if attack and validTarget and IsVisible(target)
      and IsSpellNotUsed("Перехват", 1)
      and IsSpellNotUsed("Рывок", 1)  then

      local chargeLeft = GetSpellCooldownLeft("Рывок");
      local unstoppable = (HasTalent("Неудержимость") > 0)
      local chargeUsable = chargeLeft < 1 and (not combat or warbringer or unstoppable)

      if InRange("Рывок", target) and chargeUsable then
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



    --local autoAttack = IsCurrentSpell("Автоматическая атака")
    if (attack or UnitAffectingCombat(target)) then
      --if validTarget and not autoAttack then oexecute("StartAttack()") end
      if validTarget then oexecute("StartAttack()") end
    else
      --if autoAttack then  oexecute("StopAttack()") end
      oexecute("StopAttack()")
    end
    if not validTarget then return end

    FaceToTarget(target)

    if HasBuff(immuneList, 3, target) and IsReadySpell("Сокрушительный бросок") and rage >= 25  then
		if not PlayerInPlace() then
			echo('Стой!!!')
		end
		if not UnitIsCasting('player') then  DoCommand('shatter') end
    end


    if HasBuff("Проклятие хаоса") then
      oexecute('CancelUnitBuff("player", "Проклятие хаоса")')
    end

    if not CanAttack(target) and not attack then
      if HasBuff("Сдерживание",1,target) and stance == 1 and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target, true) then return end
      return
    end

    if HasBuff("Сокрушить!") then
      local spell, left =  UnitIsCasting("player")
      if spell == "Мощный удар" and left > 1 then
        StopCast("Мощный удар - Сокрушить!")
      end
    end

    if (IsCtr() or pvp or (UnitClassification(target) == "worldboss") or aoe3) and HasBuff(procList, 5, player) then
      if HasSpell("Жажда смерти") then DoSpell("Жажда смерти", nil, true) end
      if stance == 3 then DoSpell("Безрассудство") end
    end
    if IsCtr() then
        if Equiped2H() and HasSpell("Вихрь клинков") and IsReadySpell("Вихрь клинков") and rage >= 25 then
          DoSpell("Размашистые удары")
          DoSpell("Вихрь клинков", nil, true)
          return
        end
        if not IsSpellNotUsed("Вихрь клинков", 0.1) and UnitExists(target) then oexecute("ClearTarget()") end
    end

    if stance ~= 2 and IsUsableSpell("Победный раж") and DoSpell("Победный раж", target) then return end
    if stance == 2 and IsUsableSpell("Реванш") and DoSpell("Реванш", target) then return end

    if stance == 2 and HasBuff(burstList, 5, target) and DoSpell("Разоружение", target, true) then return end


    if aoe2 and HasSpell("Размашистые удары") then  DoSpell("Размашистые удары") end
    if aoe2 then DoSpell("Рассекающий удар", nil, not pvp) end
    if aoe3 and melee and stance ~= 3 and DoSpell("Удар грома") then return end
    
    if not PlayerInPlace() and UnitIsPlayer(target) and not HasDebuff(myRootDebuff, 1, target) then
        if stance ~= 2 and InRange("Подрезать сухожилия", target) then
          if DoSpell("Подрезать сухожилия", target) then return end
        elseif HasSpell("Пронзительный вой") and DistanceTo(player, target) < 10 then
          if DoSpell("Пронзительный вой") then return end
        end
    end

    if melee and HasSpell("Ударная волна") and DoSpell("Ударная волна") then return end
    if shield and ( pvp and HasBuff("Magic", 3, target ) or HasBuff("Щит и меч", 0.1, player) ) and DoSpell("Мощный удар щитом", target) then return end
    if HasSpell("Сокрушение") and shield and DoSpell("Сокрушение", target) then return end

	if HasSpell("Смертельный удар") and DoSpell("Смертельный удар", target, true) then return end --, not HasMyDebuff("Смертельный удар", 3, target) --not HasMyDebuff("Смертельный удар", 1, target)

    if stance ~= 3 and not HasMyDebuff("Кровопускание", 1, target) and DoSpell("Кровопускание", target, true) then return end

    if stance == 1 and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target, true) then return end

	--[[if rage >= 30 and pvp and melee and HasSpell("Смертельный удар") and IsReadySpell("Смертельный удар") and not HasMyDebuff("Смертельный удар", 0.5, target) then
		print('Ждем Смертельный удар')
		return
	end]]

    --if stance ~= 2 and (not HasSpell("Смертельный удар") or GetSpellCooldownLeft("Смертельный удар") > 2) and HasBuff("Внезапная смерть") and DoSpell("Казнь", target) then return end
    if stance ~= 2 and HasBuff("Внезапная смерть") and DoSpell("Казнь", target) then return end



    if HasSpell("Кровожадность") and DoSpell("Кровожадность", target, true) then return end
    if stance == 3 and HasSpell("Вихрь") and (melee or aoe2) and DoSpell("Вихрь", nil, true) then return end
    if HasBuff("Сокрушить!") and DoSpell("Мощный удар", target, true) then return end
    if not aoe2 and rage > ( HasSpell("Кровожадность") and 30 or 90) then --TODO символ на удар героя, когторый возвращает рагу
       if stance ~= 2 and UnitHealth100(target) < 20 then
         if DoSpell("Казнь", target) then return end
       else
         if melee and DoSpell("Удар героя", target) then return end
       end
    end

    if warbringer or HasBuff("благословение могущества", 5, player) then
      if not HasBuff("Командирский крик", 5, player) and DoSpell("Командирский крик") then return end
    else
      if not HasBuff("Боевой крик", 5, player)  and DoSpell("Боевой крик") then return end
    end

    if (pvp or UnitAffectingCombat(target)) and DoSpell("Героический бросок", target) then return end
    --if not aoe2 and PlayerInPlace() and InRange("Выстрел", target) and DoSpell("Выстрел", target) then return end
    if not aoe2 and HasSpell("Вихрь") and GetSpellCooldownLeft("Вихрь") > 1.5 and HasSpell("Кровожадность")  and GetSpellCooldownLeft("Кровожадность") > 1.5 then
      if UnitClassification(target) == "worldboss"  and (select(4, UnitDebuff("Раскол брони", 10, target)) or 0) < 5 and DoSpell("Раскол брони", target) then return end
      if PlayerInPlace() and DoSpell("Мощный удар", target) then return end
    end
  end
end
