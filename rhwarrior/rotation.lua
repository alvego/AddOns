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
  "Ошеломление"
}

local exceptionControlList = { -- > 4
  "Ошеломление", -- 20s
  "Покаяние",
}


function Idle()


  local stance = GetShapeshiftForm()
  local attack = IsAttack()

  local player = "player"
  local hp = UnitHealth100(player)
  local rage = UnitMana(player)
  local warbringer = HasTalent("Вестник войны") > 0
  local defence = warbringer or (not attack and hp < 45)
  local pvp = IsPvP()
  local combat = InCombatLockdown()
  local shield = IsEquippedItemType("Щит")

  if defence then
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

  if InCombatMode() then

    -- Auto AntiControl --------------------------------------------------------
    local debuff = HasDebuff(bloodList, 3, "player")
    if not debuff then
      debuff = HasDebuff(ControlList, 3, "player")
    end
    if debuff and (not tContains(exceptionControlList, debuff) or attack) then
      if IsReadySpell("Ярость берсерка") then
        if IsSpellNotUsed("Каждый за себя", 1) and DoSpell("Ярость берсерка") then return end
      else
        if IsSpellNotUsed("Ярость берсерка", 1) and DoSpell("Каждый за себя") then return end
      end
    end
    --AutoTaunt-----------------------------------------------------------------
    if not pvp and AdvMode and defence and AutoTaunt and IsInGroup()
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
      if AutoAOE then
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
            local face = PlayerFacingTarget(uid, look and 15 or 90)
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
        if hp < 32 and DoSpell("Глухая оборона") then return end
        if hp < 60 and DoSpell("Блок щитом") then return end
      end
      if hp < 60 and rage > 15 and HasBuff("Исступление", 0.1, player) and DoSpell("Безудержное восстановление", player, true) then return end

    end
    ----------------------------------------------------------------------------
    if (attack or hp > 60) and HasBuff("Длань защиты", 1, player) then
      oexecute('CancelUnitBuff("player", "Длань защиты")')
    end
    if attack and HasBuff("Вихрь клинков", 1, player) then
      oexecute('CancelUnitBuff("player", "Вихрь клинков")')
    end

    -- Rotation ----------------------------------------------------------------
    if attack --and not UnitInLos(target)
      and IsSpellNotUsed("Перехват", 1)
      and IsSpellNotUsed("Вмешательство", 1)
      and IsSpellNotUsed("Рывок", 1)  then

      local chargeLeft = GetSpellCooldownLeft("Рывок");
      if validTarget and not UnitInLos(target) and InRange("Рывок", target) and  chargeLeft < 1 then
        if warbringer or stance == 1 then
          if DoSpell("Рывок", target) then return end
        else
          if DoSpell("Боевая стойка") then return end
        end
        return
      end
      local interceptLeft = GetSpellCooldownLeft("Перехват")
      if rage > 10 and validTarget and not UnitInLos(target) and InRange("Перехват", target) and chargeLeft > 2 and interceptLeft < 1 then
        if warbringer or stance == 3 then
          if DoSpell("Перехват", target, true) then return end
        else
          if DoSpell("Стойка берсерка") then return end
        end
        return
      end
    end
    if IsAlt() then ------[[TODO: Need fix]]
      local interveneLeft = GetSpellCooldownLeft("Вмешательство")
      local toTarget = validTarget and not UnitInLos(target) and (DistanceTo("player", target) < 30)
      if IsInGroup() and rage > 10 and (not toTarget or (chargeLeft > 2 and interceptLeft > 2) ) and interveneLeft < 1 then
        local _u = nil
        if toTarget then
            -- Ищем ближайшего к цели из группы
            local _dist = 8
            for i = 1, #UNITS do
              local u = UNITS[i]
              repeat -- для имитации continue
                if not InRange("Вмешательство", u) or UnitInLos(u) then break end
                local dist = DistanceTo(target, u)
                if dist > _dist then break end
                _u = u
                _dist = dist
              until true
            end
        else
          -- Ищем из группы подальше в области видемости 30 градусов
          local _dist = 0
          for i = 1, #UNITS do
            local u = UNITS[i]
            repeat -- для имитации continue
              if not InRange("Вмешательство", u) or UnitInLos(u) then break end
              local face = PlayerFacingTarget(u, 15)
              if not face then break end
              local dist = DistanceTo("player", u)
              if dist < _dist then break end
              _u = u
              _dist = dist
            until true
          end
        end

        if _u then
          if warbringer or stance == 2 then
            if DoSpell("Вмешательство", _u, true) then return end
          else
            if DoSpell("Оборонительная стойка") then return end
          end
          return
        end
      end
    end

    if defence then
      if stance ~= 2 and DoSpell("Оборонительная стойка") then return end
    else
      if stance ~= 1 and DoSpell("Боевая стойка") then return end
    end

    local autoAttack = IsCurrentSpell("Автоматическая атака")
    if (attack or UnitAffectingCombat(target)) then
      if validTarget and not autoAttack then oexecute("StartAttack()") end
    else
      if autoAttack then  oexecute("StopAttack()") end
    end
    if not validTarget then return end
    FaceToTarget(target)


    if HasBuff("Проклятие хаоса") then
      oexecute('CancelUnitBuff("player", "Проклятие хаоса")')
    end

    if not CanAttack(target) and not attack then
      if HasBuff("Сдерживание",1,target) and stance == 1 and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target, true) then return end
      return
    end

    if IsCtr() then
        if stance == 3 and DoSpell("Безрассудство") then return end
        if Equiped2H() and HasSpell("Вихрь клинков") and IsReadySpell("Вихрь клинков") and rage >= 25 then
          DoSpell("Размашистые удары")
          DoSpell("Вихрь клинков", nil, true)
          oexecute("TargetNearestEnemy" .. (pvp and "Player" or "" ) .. "()")
          oexecute("StartAttack()")
          return
        end
    end

    if stance ~= 2 and IsUsableSpell("Победный раж") and DoSpell("Победный раж", target) then return end
    if stance == 2 and IsUsableSpell("Реванш") and DoSpell("Реванш", target) then return end

    if stance == 2 and HasBuff(burstList, 5, target) and DoSpell("Разоружение", target, true) then return end

    if aoe3 and melee and stance ~= 3 and DoSpell("Удар грома") then return end
    if aoe2 and HasSpell("Размашистые удары") and DoSpell("Размашистые удары") then return end
    if aoe2 and DoSpell("Рассекающий удар") then return end

    if not PlayerInPlace() and UnitIsPlayer(target) and not HasMyDebuff(myRootDebuff, 1, target) then
        if stance ~= 2 and InRange("Подрезать сухожилия", target) then
          if DoSpell("Подрезать сухожилия", target) then return end
        elseif HasSpell("Пронзительный вой") and DistanceTo(player, target) < 10 then
          if DoSpell("Пронзительный вой") then return end
        end
    end

    if melee and HasSpell("Ударная волна") and DoSpell("Ударная волна") then return end
    if shield and ( pvp and HasBuff("Magic", 3, target ) or HasBuff("Щит и меч", 0.1, player) ) and DoSpell("Мощный удар щитом", target) then return end
    if HasSpell("Сокрушение") and shield and DoSpell("Сокрушение", target) then return end


    if stance ~= 3 and not HasMyDebuff("Кровопускание", 1, target) and DoSpell("Кровопускание", target, true) then return end

    if HasSpell("Смертельный удар") and DoSpell("Смертельный удар", target, not HasMyDebuff("Смертельный удар", 1, target)) then return end --, not HasMyDebuff("Смертельный удар", 3, target)
    if stance == 1 and IsUsableSpell("Превосходство") and DoSpell("Превосходство", target, true) then return end

    --if stance ~= 2 and (not HasSpell("Смертельный удар") or GetSpellCooldownLeft("Смертельный удар") > 2) and HasBuff("Внезапная смерть") and DoSpell("Казнь", target) then return end
    if stance ~= 2 and HasBuff("Внезапная смерть") and DoSpell("Казнь", target) then return end

    if HasBuff("Сокрушить!") and DoSpell("Мощный удар", target) then return end
    if stance == 3 and HasSpell("Вихрь") and (melee or aoe2) and DoSpell("Вихрь") then return end
    if HasSpell("Кровожадность") and DoSpell("Кровожадность", target) then return end

    if not aoe2 and rage > 80 then
       if stance ~= 2 and UnitHealth100(target) < 20 then
         if DoSpell("Казнь", target) then return end
       else
         if melee and DoSpell("Удар героя", target) then return end
       end
    end
    if defence then
      if not HasMyBuff("крик", 1, player) and DoSpell("Командирский крик") then return end
    else
      if not ( HasMyBuff("крик", 1, player) or HasBuff("благословение могущества", 1, player)) and DoSpell("Боевой крик") then return end
    end
    if not AutoTaunt and DoSpell("Героический бросок", target) then return end
    --if not aoe2 and PlayerInPlace() and InRange("Выстрел", target) and DoSpell("Выстрел", target) then return end
  end

end
