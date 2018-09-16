-- Warrior Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local burstList = {"Вихрь клинков", "Стылая кровь", "Гнев карателя", "Быстрая стрельба"}
local procList = {"Целеустремленность железного дворфа", "Сила таунка", "Мощь таунка", "Скорость врайкулов", "Ловкость врайкула", "Пронзающая тьма"}
local immuneList = {"Божественный щит", "Ледяная глыба", "Длань защиты" }
local min = math.min
local max = math.max
function Idle()
  local attack = IsAttack()
  local mouse5 = IsMouse(5)
  local player = "player"
  local focus = "focus"
  local hp = UnitHealth100(player)
  local rp = UnitMana(player)
  local pvp = IsPvP()
  local combat = InCombatLockdown()
  local time = GetTime()

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

    local debuff, _, _, _, _, _duration, _expirationTime = HasDebuff(ControlList, 3, player)
    if debuff and ((_duration - (_expirationTime - GetTime())) > 0.45) and DoSpell("Каждый за себя") then chat("Каждый за себя - " .. debuff) return end

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
      if not (InDuel() or IsArena()) then
        if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
        if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      end
      if hp < 50 and DoSpell("Кровь вампира", player) then return end
      local hasPet = HasSpell("Цапнуть")
      if hp <= 50 and mana >= 40 and hasPet and DoSpell("Смертельный союз") then return end
      if hp <= 40 and mana >= 60 and not hasPet and DoSpell("Воскрешение мертвых") then  end
      if hp < 80 and HasSpell("Захват рун") and DoSpell("Захват рун") then return end
      if hp < 60 and TimerLess("Damage", 2) and DoSpell("Незыблемость льда") then return end

    end
    ----------------------------------------------------------------------------
    if (attack or hp > 60) and HasBuff("Длань защиты", 1, player) then
      oexecute('CancelUnitBuff("player", "Длань защиты")')
    end
    ----------------------------------------------------------------------------
    local target = "target"
    local validTarget = IsValidTarget(target)
    -- TryTarget ---------------------------------------------------------------
    if not validTarget then TryTarget(attack, true) end
    ----------------------------------------------------------------------------
    if attack and not validTarget and DoSpell("Зимний горн") then return end
    ----------------------------------------------------------------------------
    local melee = InMelee(target)
    if TryInterrupt(pvp, melee) then return end
    -- Rotation ----------------------------------------------------------------
    if not pvp and HasBuff("Проклятие хаоса") then
      oexecute('CancelUnitBuff("player", "Проклятие хаоса")')
    end

    if HasBuff("Кровоотвод") then
      oexecute('CancelUnitBuff("player", "Кровоотвод")')
    end

    if CantAttack() then return end


    if (IsCtr() or pvp or (UnitClassification(target) == "worldboss") or aoe3) and HasBuff(procList, 5, player) then
      if DoSpell("Истерия", player) then return end
      if DoSpell("Танцующее руническое оружие", target) then return end
    end

    -- Новая ротация


    local expirationTime, unitCaster = select(7, UnitDebuff(target, "Озноб"))
    local frostFeverLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
    local expirationTime, unitCaster = select(7, UnitDebuff(target, "Кровавая чума"))
    local bloodPlagueLast = (expirationTime and unitCaster == player) and max(expirationTime - time, 0) or 0
    local plagueLast = min(frostFeverLast, bloodPlagueLast)
    if AutoAOE and melee and plagueLast > 0.1 and plagueLast < 2 and DoSpell("Мор", target) then return end


    local canMagic = CanMagicAttack(target)
   -- накладываем болезни
   if canMagic and rp > 80 and DoSpell("Лик смерти", target) then return end
   if bloodPlagueLast < 0.1 and DoSpell("Удар чумы", target) then return end
   if frostFeverLast < 0.1 and DoSpell(pvp and "Ледяные оковы" or "Ледяное прикосновение", target) then return end
   if aoe3 and DoSpell("Смерть и разложение", target) then return end
   if aoe3 and DoSpell("Вскипание крови") then return end
   if plagueLast < 1.5 and not attack then return end
   if melee and DoSpell("Рунический удар", target) then return end
   if plagueLast > 0 and not aoe3 and DoSpell("Удар в сердце", target) then return end
   if plagueLast > 0 and melee and DoSpell("Удар смерти", target) then return end

   if attack and not melee and DoSpell(pvp and "Ледяные оковы" or "Ледяное прикосновение") then return end

   local norunes = NoRunes()
   if norunes and (not HasBuff("Зимний горн") or rp <= 60) and DoSpell("Зимний горн") then return end
   -- ресаем все.
   if norunes and DoSpell("Усиление рунического оружия") then return end
   -- ресаем руну крови
   if norunes and DoSpell("Кровоотвод") then return end

  end
end
