-- Hunter Rotation Helper by Timofeev Alexey
print("|cff0055ffRotation Helper|r|cffffe00a > |cffabd473Hunter|r loaded!")
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

  if InCombatMode() then

    TryTarget()

    if not UnitIsPlayer("target") and TryInterrupt("target") then return end
    Rotation()
  end

end

function TryBuffs()
    if not HasBuff("Аура меткого выстрела") and DoSpell("Аура меткого выстрела")then return true end
    if UnitMana100() < 30 and not HasBuff("Дух гадюки") and DoSpell("Дух гадюки") then return true end
    if UnitMana100() > 80 and not HasBuff("Дух ястреба") and DoSpell("Дух ястреба") then return true end
    return false
end

function Rotation()

    if (IsAttack() or UnitAffectingCombat("target")) then
      if IsValidTarget("target") then
        if not IsCurrentSpell("Автоматическая атака") then omacro("/startattack") end
        if not IsOneUnit("target", "pet-target") then
            omacro("/petattack [@target]")
        end
      end
    else
      if IsCurrentSpell("Автоматическая атака") then
        omacro("/stopattack")
        omacro("/petfollow")
      end
    end


    if not IsValidTarget("target") then return end
    if not HasMyDebuff("Метка охотника", 0.5,"target") and DoSpell("Метка охотника", "target") then return end
    if UnitHealth100("target") < 20 and DoSpell("Убийственный выстрел", "target") then return end 
    if not HasMyDebuff("Укус змеи", 0.5,"target") and DoSpell("Укус змеи", "target") then return end
    if DoSpell("Выстрел химеры", "target") then return end
    --if DoSpell("Контузящий выстрел", "target") then return end
    if DoSpell("Прицельный выстрел", "target") then return end
    if DoSpell("Чародейский выстрел", "target") then return end
    if UnitHealth100("pet") < 50 and not HasBuff("Лечение питомца", 0.5,"pet") and DoSpell("Лечение питомца") then return end
    if DoSpell("Верный выстрел", "target") then return end
    if InMelee("target") and not HasMyDebuff("Подрезать крылья", 0.5,"target") and DoSpell("Подрезать крылья", "target") then return end
    if InMelee("target") and DoSpell("Укус мангуста", "target") then return end
    if InMelee("target") and DoSpell("Удар ящера", "target") then return end

end


function TryTarget()
    -- помощь в группе
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then omacro("/cleartarget") end

        if IsPvP() then
            omacro("/targetenemyplayer [nodead]")
        else
            omacro("/targetenemy [nodead]")
        end

        if not IsAttack()  -- если в авторежиме
            and (
            not IsValidTarget("target")  -- вообще не цель
            or (not IsArena() and not (CheckInteractDistance("target", 3) == 1))  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then
            if UnitExists("target") then omacro("/cleartarget") end
        end
    end
end
