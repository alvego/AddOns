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
  ----------------------------------------------------------------------------
  -- TryTarget ---------------------------------------------------------------
  ----------------------------------------------------------------------------
  TryTarget(attack, true)
  local validTarget = IsValidTarget(target)
  local validFocus = IsValidTarget(focus)
  local melee = InMelee(target)
  -- Rotation ----------------------------------------------------------------
  if CantAttack() then return end
  -- Новая ротация
  ------------------------------------------------------------------------------
end--idle
