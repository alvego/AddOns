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
  if InCombatMode() or IsArena() then

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
        local enemyCount = GetEnemyCountInRange(15)
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
    if AdvMode and combat and not IsEquippedItemType("Топор") and EquipItem("Темная Скорбь") then return end
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
    if attack and not validTarget and DoSpell("Зимний горн") then return end
    if attack and AdvMode and not HasBuff(stanceBuff) and DoSpell("Власть крови") then return end
    ----------------------------------------------------------------------------
    local melee = InMelee(target)
    if TryInterrupt(pvp, melee) then return end
    -- Rotation ----------------------------------------------------------------
    -- if HasBuff("Проклятие хаоса") then
    --   oexecute('CancelUnitBuff("player", "Проклятие хаоса")')
    -- end

    if HasBuff("Кровоотвод") then
      oexecute('CancelUnitBuff("player", "Кровоотвод")')
    end

    if CantAttack() then return end

    -- Новая ротация

    --local minBloodRunesLeft = min(GetRuneCooldownLeft(1), GetRuneCooldownLeft(2))
    --local minUnholyRunesLeft = min(GetRuneCooldownLeft(3), GetRuneCooldownLeft(4))
    --local minFrostRunesLeft = min(GetRuneCooldownLeft(5), GetRuneCooldownLeft(6))
    local plagueMin = 8 + LagTime
    local expirationTime, unitCaster = select(7, UnitDebuff(target, "Озноб"))
    local frostFeverLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
    local expirationTime, unitCaster = select(7, UnitDebuff(target, "Кровавая чума"))
    local bloodPlagueLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
    local plagueLast = min(frostFeverLast, bloodPlagueLast)
    local plagueAnyLast = max(frostFeverLast, bloodPlagueLast)

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

    --if (IsCtr() or pvp or (UnitClassification(target) == "worldboss") or aoe5) and HasBuff(procList, 5, player) then
    if (IsCtr() or pvp or (UnitClassification(target) == "worldboss")) then --or aoe5
      if HasBuff("Танцующее руническое оружие") and HasSpell("Истерия") and DoSpell("Истерия", player) then return end
      if HasSpell("Танцующее руническое оружие") and DoSpell("Танцующее руническое оружие", target) then return end
    end

    local canMagic = CanMagicAttack(target)
    local frostFeverSpell = pvp and "Ледяные оковы" or "Ледяное прикосновение"
   -- range
   if attack and not melee then
      if DoSpell(frostFeverSpell, target) then return end
      if canMagic and DoSpell("Лик смерти", target) then return end
   end

   -- накладываем болезни
   if bloodPlagueLast < LagTime and DoSpell("Удар чумы", target) then return end
   if frostFeverLast < LagTime and DoSpell(frostFeverSpell, target) then return end
   if melee and DoSpell("Рунический удар", target) then return end
   -- сливаем runic power
   if canMagic and rp > 95 and DoSpell("Лик смерти", target) then return end
   -- aoe
   if melee and aoe5 and plagueLast > plagueMin and IsReadySpell("Смерть и разложение") then
     DoSpell("Смерть и разложение", target)
     return
   end
   if aoe5 and plagueLast > plagueMin and DoSpell("Вскипание крови") then return end
   --if plagueLast < 1.5 and not attack then return end

   if (not HasRunes(100) or hp < (pvp and 80 or 50)) and melee and plagueAnyLast > LagTime and DoSpell("Удар смерти", target) then return end
   if plagueLast > (AutoAOE and plagueMin or LagTime) and not aoe5 and DoSpell("Удар в сердце", target) then return end

   if NoRunes() then
      if canMagic and rp >= 40 and DoSpell("Лик смерти", target) then return end
      if (not HasBuff("Зимний горн") or rp < 40) and DoSpell("Зимний горн") then return end
      -- ресаем все.
      if rp < 80 and DoSpell("Усиление рунического оружия") then return end
   end
  end
end
