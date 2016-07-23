-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}

function Idle()
  -- Дизамаунт
  if IsAttack() or IsMouse(3) then
      if HasBuff("Парашют") then oexecute('CancelUnitBuff("player", "Парашют")') return end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then Dismount() return end
  end
  -- дайте поесть (побегать) спокойно
  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end


  if TryBuffs() then return end
  if true then return end
  if InCombatMode() then
    --TryTarget()
    if not UnitIsPlayer("target") and TryInterrupt("target") then return end

    if AutoAGGRO and IsInGroup() then
        local TARGETS = GetTargets()
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if UnitAffectingCombat(t) and TryTaunt(t) then return end
        end
    end

    if HasSpell("Удар воина Света") then
        Retribution()
        return
    end

    if HasSpell("Щит мстителя") then
        Tank()
        return
    end
  end

end

function TryBuffs()
    if HasSpell("Удар воина Света") then
        if HasSpell("Священная жертва") and not InCombatLockdown() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
        -- if HasBuff("Праведное неистовство") and RunMacroText("/cancelaura Праведное неистовство") then return end
        if not HasBuff("Печать") and DoSpell("Печать мщения") then return end
        if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
            if not HasBuff("благословение королей") and DoSpell("Великое благословение королей","player") then return end
            if (not HasBuff("Боевой крик") or not HasBuff("благословение могущества")) and DoSpell("Великое благословение могущества","player") then return end
        end
        return false
    end
    if HasSpell("Щит мстителя") then
        if not HasBuff("Благословение") and DoSpell("Великое благословение неприкосновенности","player") then return end
        if not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
        if HasSpell("Печать мщения") and not HasBuff("Печать мщения") and DoSpell("Печать мщения") then return end
        if HasSpell("Печать порчи") and not HasBuff("Печать порчи") and DoSpell("Печать порчи") then return end
        if not HasBuff("Священный щит") and DoSpell("Священный щит","player") then return end
        if not HasBuff("Святая клятва") and DoSpell("Святая клятва") then return end
        if not HasBuff("Щит небес",0.8) and DoSpell("Щит небес") then return end
        return false
    end
end

function Retribution()

end

function Tank()
  local target = "target"


end

------------------------------------------------------------------------------------------------------------------
function TryTarget()
    -- помощь в группе
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end

        if IsPvP() then
            RunMacroText("/targetenemyplayer [nodead]")
        else
            RunMacroText("/targetenemy [nodead]")
        end

        if not IsAttack()  -- если в авторежиме
            and (
            not IsValidTarget("target")  -- вообще не цель
            or (not IsArena() and not (CheckInteractDistance("target", 3) == 1))  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then
            if UnitExists("target") then RunMacroText("/cleartarget") end
        end
    end


end


function TryTaunt(target)

  if TimerLess("Taunt", 1)  then return false end

  if UnitIsPlayer(target) or not UnitAffectingCombat(target) then return false end

  local tt = UnitName(target .. "-target")
  if not UnitExists(tt) then return false end

  if IsOneUnit("player", tt) then return false end


  if DoSpell("Длань возмездия", target) then
     TimerStart("Taunt")
     -- chat("Длань возмездия на " .. UnitName(target))
     return true
  end

  if not IsReadySpell("Длань возмездия") and IsInteractUnit(tt) and DoSpell("Праведная защита", tt) then
     TimerStart("Taunt")
     -- chat("Праведная защита на " .. UnitName(tt))
     return true
  end
  return false
end
