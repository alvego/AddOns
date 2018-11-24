-- Death Knight Rotation Helper 2 by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local stanceBuff = {"Власть крови", "Власть льда", "Власть нечестивости"}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления", "Рунический покров"}
local min = math.min
local max = math.max
Defence = false
function Idle()
  local attack = IsAttack()
  local mouse5 = IsMouse(5)
  local player = "player"
  local target = "target"
  local focus = "focus"
  local isCC, isRoot, isSilence, isSnare, isDisarm, isImmune, isPvE = GetControlState(player)
  local hp = UnitHealth100(player)
  local rp = UnitMana(player)
  local pvp = IsPvP()
  local combat = InCombatLockdown()
  local time = GetTime()
  local enemyCount = (AutoAOE or InDuel()) and 1 or GetEnemyCountInRange(10)
  if attack then
    Defence = false
  else
    if hp < 30 then
      Defence = true
    end
  end
  -- Дизамаунт -----------------------------------------------------------------
  if attack or mouse5 then
    if CanExitVehicle() then VehicleExit() end
    if IsMounted() then Dismount() end
  end
  ------------------------------------------------------------------------------
  -- дайте поесть (побегать) спокойно
  if not attack and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
  ----------------------------------------------------------------------------
  if not (InCombatMode() or IsArena()) then return end
  if combat then
    if not (InDuel() or IsArena()) then
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    end
  end
  ------------------------------------------------------------------------------
  -- TryTarget -----------------------------------------------------------------
  ------------------------------------------------------------------------------
  TryTarget(attack, true)
  local validTarget = IsValidTarget(target)
  local validFocus = IsValidTarget(focus)
  local melee = InMelee(target)
  -- Rotation ------------------------------------------------------------------
  if CantAttack() then return end
  -- Новая ротация
  ------------------------------------------------------------------------------
  local hasPet = BT4PetButton1:IsVisible()
  if hasPet then
      if hp < 30 and rp >= 40 and DoSpell("Смертельный союз") then return end
      local petTarget = nil
      if validTarget then petTarget = target end
      if IsAlt() and validFocus then petTarget = focus end
      local isPetAttack = BT4PetButton1:GetChecked()
      local validPetTarget = IsValidTarget("pet-target")
      if (attack or not validPetTarget) and petTarget and (not isPetAttack or not IsOneUnit("pet-target", petTarget)) then
          omacro("/petattack [@".. petTarget .."]")
      end
      petTarget = "pet-target"
      validPetTarget = IsValidTarget(petTarget)
      if validPetTarget then
        local mana = UnitMana("pet")
        if IsCtr() and InRange("Отгрызть", petTarget) then
          if mana >= 30 and IsReadySpell("Отгрызть") and InRange("Отгрызть", petTarget) then omacro("/cast [@pet-target] Отгрызть") end
          if GetSpellCooldownLeft("Отгрызть") > 10 and rp >= 40 then
            omacro("/cast [@pet] Взрыв трупа")
          end
        end
        if mana >= 10 and IsReadySpell("Прыжок") and InRange("Прыжок", petTarget) then omacro("/cast [@pet-target] Прыжок") end
        if mana >= (attack and 40 or 70) and IsReadySpell("Цапнуть") and InRange("Цапнуть", petTarget) then omacro("/cast [@pet-target] Цапнуть") end
      end

  else
    if DoSpell("Воскрешение мертвых") then return end
  end


  if validTarget then
    if IsCtr() then
      for i = 1, 40 do
          local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitDebuff(target, i)
        	if not name then break end
          if name == "Нечестивая порча" then print(name, spellId) end
      end
    end
    local frostFeverId = 55095
    local bloodPlagueId = 55078
    local unholyBlightId = 50536
    local frostFeverLast = max((select(7, HasMyDebuff(frostFeverId, 0.01, target)) or 0) - time, 0)
    local bloodPlagueLast = max((select(7, HasMyDebuff(bloodPlagueId, 0.01, target)) or 0) - time, 0)
    local unholyBlightLast = max((select(7, HasMyDebuff(unholyBlightId, 0.01, target)) or 0) - time, 0)
    local plagueLeft = min(frostFeverLast, bloodPlagueLast)
    if AutoAOE and plagueLeft > 0.5 and plagueLeft < 3 and DoSpell("Мор", target) then return end
    if frostFeverLast == 0 and DoSpell("Ледяные оковы", target) then return end
    if bloodPlagueLast == 0 and DoSpell("Удар чумы", target) then return end
    if unholyBlightLast == 0 and rp >= 40 and DoSpell("Лик смерти", target) then return end
    if plagueLeft > 3 and DoSpell(hp > 95 and "Удар плети" or "Удар смерти", target) then return end
    if rp > 60 and DoSpell("Лик смерти", target) then return end
    if plagueLeft > 6 and DoSpell("Кровавый удар", target) then return end
  end


  ------------------------------------------------------------------------------
end--idle
