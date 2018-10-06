-- Death Knight Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local stanceBuff = {"Власть крови", "Власть льда", "Власть нечестивости"}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления", "Рунический покров"}
local burstList = {"Вихрь клинков", "Стылая кровь", "Гнев карателя", "Быстрая стрельба"}
local burstSpell = {"Истерия", "Танцующее руническое оружие"}
local procList = {"Целеустремленность железного дворфа", "Сила таунка", "Мощь таунка", "Скорость врайкулов", "Ловкость врайкула", "Пронзающая тьма"}
local immuneList = {"Божественный щит", "Ледяная глыба", "Длань защиты" }
local min = math.min
local max = math.max
Defence = false
function Idle()

  --print(HasRunes(200),HasRunes(020), HasRunes(002))
  --if true then return end

  local attack = IsAttack()
  local mouse5 = IsMouse(5)
  local player = "player"
  local target = "target"
  local focus = "focus"
  local hp = UnitHealth100(player)
  local rp = UnitMana(player)
  local pvp = IsPvP()
  local combat = InCombatLockdown()
  local time = GetTime()

  if AutoTaunt then
    Defence = true
  else
    if attack or IsCtr() or HasBuff(burstSpell) then
      Defence = false
    else
      if hp < (pvp and 50 or 30) then
        Defence = true
      end
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
  ----------------------------------------------------------------------------
  if not InCombatMode() and not HasBuff("Зимний горн") and DoSpell("Зимний горн") then return end
  if not HasBuff(stanceBuff) and DoSpell("Власть крови") then return end
  if not (InCombatMode() or IsArena()) then return end


  -- Auto AntiControl --------------------------------------------------------
  if AdvMode then
    local debuff, _, _, _, _, _duration, _expirationTime = HasDebuff(ControlList, 3, player)
    if debuff and ((_duration - (_expirationTime - time)) > 0.45) and DoSpell("Каждый за себя") then
      chat("Каждый за себя - " .. debuff)
      return
    end
  end

  -- IsAOE -------------------------------------------------------------------
  local aoe2 = false
  local aoe5 = false

  if IsShift() then
    aoe2 = true
    aoe5 = true
  else
    if AutoAOE and not InDuel() then
      local enemyCount = GetEnemyCountInRange(10)
      aoe2 = enemyCount >= 2
      aoe5 = enemyCount >= 5
    end
  end

  -- TryProtect -----------------------------------------------------------------

  if rp >= 40 and not IsSpellNotUsed("Воскрешение мертвых", 3) and IsReadySpell("Смертельный союз") then
    echo('Едим пета!!')
    oexecute('CastSpellByName("Смертельный союз")')
    return
  end

  if combat then
    if not (InDuel() or IsArena()) then
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    end
    if hp < 40 and rp >= 40 and IsReadySpell("Воскрешение мертвых") then
      oexecute('CastSpellByName("Воскрешение мертвых")')
      return
    end
    if hp < 50 and DoSpell("Кровь вампира", player) then return end
    if hp < 60 and TimerLess("Damage", 2) and DoSpell("Незыблемость льда") then return end
    if hp < 80 and HasSpell("Захват рун") and DoSpell("Захват рун") then return end
  end
  ----------------------------------------------------------------------------

  if Defence then
    if not HasBuff("Власть льда") and DoSpell("Власть льда") then return end
  else
    if not HasBuff("Власть крови") and DoSpell("Власть крови") then return end
  end
  --AutoTaunt-----------------------------------------------------------------
  if not pvp and AdvMode and AutoTaunt and IsInGroup() --and Defence
  and IsSpellNotUsed("Хватка смерти", 1)
  and IsSpellNotUsed("Темная власть", 1) then
  local _t = nil
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
    end
  end
  --------------------------------------------------------------------------
  if _t and not _isTanking then
    if DoSpell("Темная власть", _t) then
        chat("Темная власть на " .. UnitName(_t))
       return
     end
    if DoSpell("Хватка смерти", _t) then
        chat("Хватка смерти на " .. UnitName(_t))
       return
     end
  end
  end
  ----------------------------------------------------------------------------
  if (attack or hp > (Defence and 90 or 60)) and HasBuff("Длань защиты", 1, player) then
    oexecute('CancelUnitBuff("player", "Длань защиты")')
  end
  ----------------------------------------------------------------------------
  local validTarget = IsValidTarget(target)
  local validFocus = IsValidTarget(focus)
  ----------------------------------------------------------------------------
  if AdvMode and pvp and IsReadySpell("Темная власть") then
    if validTarget and UnitIsPlayer(target) and ((tContains(steathClass, GetClass(target)) and not InRange("Ледяные оковы", target)) or HasBuff(reflectBuff, 1, target)) and not HasDebuff("Темная власть", 1, target) and DoSpell("Темная власть", target) then return end
    if validFocus and UnitIsPlayer(focus) and ((tContains(steathClass, GetClass(focus)) and not InRange("Ледяные оковы", focus)) or HasBuff(reflectBuff, 1, target)) and not HasDebuff("Темная власть", 1, focus) and DoSpell("Темная власть", focus) then return end
  end

  -- TryTarget ---------------------------------------------------------------
  TryTarget(attack, true)
  ----------------------------------------------------------------------------
  local melee = InMelee(target)
  if TryInterrupt(pvp, melee) then return end
  -- Rotation ----------------------------------------------------------------


  if CantAttack() then return end

  -- Новая ротация

  local minBloodRunesLeft = min(GetRuneCooldownLeft(1), GetRuneCooldownLeft(2))
  --local minUnholyRunesLeft = min(GetRuneCooldownLeft(3), GetRuneCooldownLeft(4))
  --local minFrostRunesLeft = min(GetRuneCooldownLeft(5), GetRuneCooldownLeft(6))
  local plagueMin = 8 + LagTime
  local expirationTime, unitCaster = select(7, UnitDebuff(target, "Озноб"))
  local frostFeverLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
  local expirationTime, unitCaster = select(7, UnitDebuff(target, "Кровавая чума"))
  local bloodPlagueLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
  local plagueLast = min(frostFeverLast, bloodPlagueLast)
  local plagueAnyLast = max(frostFeverLast, bloodPlagueLast)

  local canMagic = CanMagicAttack(target)
  local frostFeverSpell = pvp and "Ледяные оковы" or "Ледяное прикосновение"
  local norunes = NoRunes()
  -- range
  if attack and not melee then
    if canMagic and DoSpell("Лик смерти", target) and frostFeverLast > 0 then return end
    if HasSpell("Воющий ветер") and frostFeverLast > 0 then
      if canMagic and DoSpell("Воющий ветер", target) then return end
    end
    if frostFeverLast < LagTime and DoSpell(frostFeverSpell, target) then return end
    if frostFeverLast > 0 and DoSpell("Вскипание крови", target) then return end
  end

  -- накладываем болезни
  if plagueLast == 0 then
    if bloodPlagueLast == 0 and HasRunes(001, HasSpell("Ледяной удар")) and UseSpell("Удар чумы", target) then return end
    if frostFeverLast == 0 and HasRunes(010, HasSpell("Ледяной удар")) and UseSpell(frostFeverSpell, target) then return end
    return
  end
  if melee and not (IsCurrentSpell("Рунический удар") == 1) and UseSpell("Рунический удар", target) then return end
  ------------------------------------------------------------------------------

  if HasSpell("Ледяной удар") then --Start Frost

    local enchantId = GetEnchantId(17)
    if not HasMyDebuff("Уязвимость к магии льда", 5, target) and enchantId ~= '3370' then
      SwitchEquipmentSet("жар")
    elseif enchantId ~= '3369' then
      SwitchEquipmentSet("лед")
    end

    if HasBuff("Кровоотвод") and IsReadySpell("Несокрушимая броня") then
      DoSpell("Несокрушимая броня")
      return
    end
    --------------------------------------------------------------------------------------------------
    ----TEST------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------
    -- if not HasRunes(011, false, GCDDuration) and GetRuneType(1) == 1 and IsRuneReady(1, GCDDuration) then
    --   if UseSpell("Мор", target) then return end
    -- elseif GetRuneType(2) == 1 and IsRuneReady(1, GCDDuration) then
    --   if IsReadySpell("Кровоотвод") then
    --     UseSpell("Кровоотвод")
    --     return
    --   end
    --   if UseSpell("Кровавый удар", target) then return end
    --   return
    -- elseif not HasRunes(011, true) and HasRunes(011, false) then
    --   if UseSpell(aoe5 and "Воющий ветер" or "Уничтожение", target) then return end
    -- elseif HasBuff("Кровоотвод") and GetRuneType(1) == 4 and GetRuneType(2) == 1 then
    --   chat("Отмена Кровоотвод")
    --   oexecute('CancelUnitBuff("player", "Кровоотвод")')
    --   return
    -- elseif HasRunes(011, false) then
    --   if UseSpell(aoe5 and "Воющий ветер" or "Уничтожение", target) then return end
    -- elseif not HasRunes(100, true, 2) and not HasRunes(011, false, 2) then
    --   if rp < (HasBuff("Машина для убийств") and 90 or 32) and HasBuff("Морозная дымка") then
    --       if UseSpell("Воющий ветер", target) then return end
    --   else
    --     if UseSpell("Ледяной удар", target) then return end
    --   end
    -- end
    --
    -- if true then return end
    --------------------------------------------------------------------------------------------------
    if GetRuneType(1) == 4 and GetRuneType(2) == 4 and IsRuneReady(1, LagTime) and IsRuneReady(2, LagTime) then
      UseSpell(aoe5 and "Воющий ветер" or "Уничтожение", target)
      return
    end

    if GetRuneType(1) == 4 and GetRuneType(2) == 1 and GetRuneCooldownLeft(1) > 0 and GetRuneCooldownLeft(2) < GCDDuration then
      if plagueLast < 15 then
        UseSpell("Мор", target)
        return
      end
      if IsReadySpell("Кровоотвод") then
        UseSpell("Кровоотвод")
        return
      end
      UseSpell("Кровавый удар", target)
      return
    end

    if HasBuff("Кровоотвод") and GetRuneType(1) == 4 and GetRuneType(2) == 1 then
      chat("Отмена Кровоотвод")
      oexecute('CancelUnitBuff("player", "Кровоотвод")')
      return
    end

    if HasRunes(200, true, GCDDuration) then
      UseSpell(plagueLast > 10 and "Кровавый удар" or "Мор", target)
      return
    end

    if plagueLast > GCDDuration  and HasRunes(011, true) then
      UseSpell(aoe5 and "Воющий ветер" or "Уничтожение", target)
      return
    end

    if plagueLast > GCDDuration then
      if rp < (HasBuff("Машина для убийств") and 90 or 32) and HasBuff("Морозная дымка") then
        UseSpell("Воющий ветер", target)
        return
      end
      if UseSpell("Ледяной удар", target) then return end
    end

    if plagueLast > 9 then

      if not HasBuff("Зимний горн") then
        UseSpell("Зимний горн")
        return
      end

      if norunes and GetRuneType(1) == 4 and GetRuneType(2) == 4 and IsReadySpell("Усиление рунического оружия") then
        UseSpell("Усиление рунического оружия")
        return
      end

      if IsCtr() and IsReadySpell("Воскрешение мертвых") then
        DoSpell("Воскрешение мертвых")
        return
      end

      if rp < 90 and DoSpell("Зимний горн") then return end
    end
    return --rotation
  end --frost
  ------------------------------------------------------------------------------
  if HasSpell("Удар в сердце") then
    -- if HasBuff("Проклятие хаоса") then
    --   oexecute('CancelUnitBuff("player", "Проклятие хаоса")')
    -- end

    if HasBuff("Кровоотвод") then
      oexecute('CancelUnitBuff("player", "Кровоотвод")')
    end
    --if (IsCtr() or pvp or UnitIsBoss(target) or aoe5) and HasBuff(procList, 5, player) then
    if (IsCtr() or pvp or UnitIsBoss(target)) then --or aoe5
      if HasBuff("Танцующее руническое оружие") and HasSpell("Истерия") and DoSpell("Истерия", player) then return end
      if HasSpell("Танцующее руническое оружие") and DoSpell("Танцующее руническое оружие", target) then return end
    end
    -- обновить болезни на цели
    if AutoAOE and melee then
      local needPestilence = plagueLast > LagTime and plagueLast < plagueMin
      -- focus
      if not needPestilence and IsValidTarget(focus) and DistanceTo(target, focus) < 15 then
        local expirationTime, unitCaster = select(7, UnitDebuff(focus, "Озноб"))
        local _frostFeverLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
        local expirationTime, unitCaster = select(7, UnitDebuff(focus, "Кровавая чума"))
        local _bloodPlagueLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
        local _plagueLast = min(_frostFeverLast, _bloodPlagueLast)
        -- с цели на фокус
        needPestilence = _plagueLast < 0.1 and plagueLast > LagTime
        if aoe5 and not needPestilence and max(_frostFeverLast, _bloodPlagueLast) < 0.1 and UnitHealth(target) < 15000 and plagueAnyLast > LagTime then
          echo('Хоть одну болезнь развесить!')
          needPestilence = true;
        end
      end
      if needPestilence then
        -- кд рун крови дольше чем остаток болезней
        if not HasRunes(100) then
           -- ресаем руну крови
           DoSpell("Кровоотвод")
        end
        DoSpell("Мор")
      end
    end
    if AdvMode and combat and not IsEquippedItemType("Топор") and EquipItem("Темная Скорбь") then return end
    -- сливаем runic power
    if canMagic and rp > 95 and DoSpell("Лик смерти", target) then return end
    -- aoe
    if melee and aoe5 and plagueLast > plagueMin and IsReadySpell("Смерть и разложение") then
      DoSpell("Смерть и разложение", target)
      return
    end
    if aoe5 and plagueLast > plagueMin and DoSpell("Вскипание крови") then return end
    if (not HasRunes(100) or hp < (pvp and 80 or 50)) and melee and plagueAnyLast > LagTime and DoSpell("Удар смерти", target) then return end
    if plagueLast > (AutoAOE and plagueMin or LagTime) and not aoe5 and DoSpell("Удар в сердце", target) then return end
    if norunes then
      if canMagic and rp >= 40 and DoSpell("Лик смерти", target) then return end
      if (not HasBuff("Зимний горн") or rp < 40) and DoSpell("Зимний горн") then return end
      -- ресаем все.
      if rp < 80 and DoSpell("Усиление рунического оружия") then return end
    end
    return --rotation
  end --blood
end--idle
