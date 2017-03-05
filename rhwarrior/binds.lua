-- Warrior Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
print("|cff0055ffRotation Helper|r|cffffe00a > |r|cffC79C6EWarrior|r loaded")
-- Binding
BINDING_HEADER_WRH = "Warrior Rotation Helper"
BINDING_NAME_WRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_WRH_AUTOTAUNT = "Авто Taunt"
BINDING_NAME_WRH_AUTOAOE = "Вкл/Выкл авто AOE"
------------------------------------------------------------------------------------------------------------------
function Equip1HShield(pvp)
  if not InCombatMode() and IsEquippedItemType("Удочка") then return end
  if TimerMore('equipweapon', 0.5) and not IsEquippedItemType("Щит") and not HasBuff("Вихрь клинков", 0.01, "player") then
    local titansGrip = HasTalent("Хватка титана") > 0
    if pvp then
      if titansGrip then
		    oexecute("UseEquipmentSet('2H1P')")
        --oexecute("EquipItemByName('Темная Скорбь', 16)")
        --oexecute("EquipItemByName('Осадный щит разгневанного гладиатора', 17)")
      else
        oexecute("UseEquipmentSet('1H')")
      end
    else
      if titansGrip then
		    oexecute("UseEquipmentSet('2H1E')")
        --oexecute("EquipItemByName('Темная Скорбь', 16)")
        --oexecute("EquipItemByName('Мерзлая стена ледяной цитадели', 17)")
      else
		    oexecute("UseEquipmentSet('1HE')")
        --oexecute("EquipItemByName('Последнее желание', 16)")
        --oexecute("EquipItemByName('Мерзлая стена ледяной цитадели', 17)")
      end

    end
    TimerStart('equipweapon')
  end
end


function Equip2H(titansGrip)
  if not InCombatMode() and IsEquippedItemType("Удочка") then return end
  if TimerMore('equipweapon', 0.5) and not Equiped2H() then
    local titansGrip = HasTalent("Хватка титана") > 0
    if titansGrip then
	  oexecute("UseEquipmentSet('4H')")
	  --oexecute("EquipItemByName('Темная Скорбь', 16)")
      --oexecute("EquipItemByName('Глоренцельг, священный клинок Серебряной Длани', 17)")
    else
	  oexecute("UseEquipmentSet('2H')")
    end
    TimerStart('equipweapon')
  end
end

function Equiped2H()
  local titansGrip = HasTalent("Хватка титана") > 0
  if titansGrip then
    return IsEquippedItem("Темная Скорбь") and IsEquippedItem("Глоренцельг, священный клинок Серебряной Длани")
  end
  return IsEquippedItem("Темная Скорбь")
end
------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON")
    else
        echo("Interrupt: OFF")
    end
end

function TryInterrupt(pvp)

    if not CanInterrupt then return false end

    local target = "target"


    local spell, left, duration, channel, nointerrupt = UnitIsCasting(target)
    if not spell then return nil end
    if left < (channel and 0.5 or 0.2) then  return  end -- если уже докастил, нет смысла трепыхаться, тунелинг - нет смысла сбивать последний тик
    if pvp and not tContains(InterruptList, spell) then return false end
    local name = (UnitName(target)) or target
    local stance = GetShapeshiftForm()


    if (channel or left < 0.8)  then

      local reflect = tContains(ReflectList, spell)

      if reflect and stance ~= 3 and GetSpellCooldownLeft("Отражение заклинания") == 0 then
        Equip1HShield(pvp)
        if DoSpell("Отражение заклинания", player, true) then
          chat("Отражение заклинания от " .. spell .. " - " ..name)
          return true
        end
      end

      if reflect and HasBuff("Отражение заклинания", 0.1, player)  then
        return false;
      end

      if not notinterrupt and stance == 3 and DoSpell("Зуботычина", target, true) then
        chat("Зуботычина в " .. name)
        return true
      end

      if not notinterrupt  and stance ~= 3 and GetSpellCooldownLeft("Удар щитом") == 0 and InMelee(target) then
        Equip1HShield(pvp)
        if IsEquippedItemType("Щит") and DoSpell("Удар щитом", target, true) then
          chat("Удар щитом в " .. name)
          return true
        end
      end

      if HasSpell("Оглушающий удар") and DoSpell("Оглушающий удар", target, true) then
        chat("Оглушающий удар в " .. name)
        return true
      end
    end


    return false
end

------------------------------------------------------------------------------------------------------------------
if AutoAOE == nil then AutoAOE = true end

function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON")
    else
        echo("Авто АОЕ: OFF")
    end
end
------------------------------------------------------------------------------------------------------------------
if AutoTaunt == nil then AutoTaunt = true end

function AutoTauntToggle()
    AutoTaunt = not AutoTaunt
    if AutoTaunt then
        echo("Авто Taunt: ON")
    else
        echo("Авто Taunt: OFF")
    end
end

function AddRage()
  if (HasTalent("Улучшенная ярость берсерка") > 0) or TimerLess("Damage", 2) then
    --if IsSpellNotUsed("Кровавая ярость", 1) and IsSpellNotUsed("Ярость берсерка", 1) then
		--omacro("/cast Кровавая ярость")
		--omacro("/cast Ярость берсерка")
      if UseSpell("Кровавая ярость") then return end
      if UseSpell("Ярость берсерка") then return end
    --end
  else
    UseSpell("Кровавая ярость")
    --omacro("/cast Кровавая ярость")
  end
end

------------------------------------------------------------------------------------------------------------------
local function updateDamage(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, damage = ...
    if type:match("_DAMAGE") and destGUID == UnitGUID("player") then --SWING_DAMAGE
        TimerStart("Damage")
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateDamage)
------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target, force)
  local rage = UnitMana("player")

  local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)

  if not name then error(spellName) return false end

  if cost and cost > 0 and powerType == 1 then

    if force then
      if rage < cost then
        AddRage()
      end
    else
      if not IsAttack() and rage <= cost + 25 then return false end
    end

  end
  return UseSpell(spellName, target)
end
