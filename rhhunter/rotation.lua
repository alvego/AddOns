-- Hunter Rotation Helper by Timofeev Alexey
print("|cff0055ffRotation Helper|r|cffffe00a > |cffabd473Hunter|r loaded!")
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
-- Общее для всех ротаций
function Idle()
	-- слезаем со всего, если решили драться
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end
    end
    -- дайте поесть спокойно
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then omacro("/stopattack") end
   ---------------------------------------------------------------------------------------------------------------
    -- Выбор цели
    if IsAttack() or InCombatLockdown() then TryTarget() end
    -- сбиваем касты
    for i = 1, #TARGETS do
        TryInterrupt(TARGETS[i])
    end
    --------------------------------------------------------------------------------------------------------------
    Rotation()
end

function Rotation()
    if not IsAttack() and not CanAttack() then return end
    if not (UnitAffectingCombat("target") or IsAttack()) then return end
    if not IsValidTarget("target") then return end
    omacro("/startattack")
    if not HasMyDebuff("Метка охотника", 0.5,"target") and DoSpell("Метка охотника", "target") then return end
    if not HasMyDebuff("Укус змеи", 0.5,"target") and DoSpell("Укус змеи", "target") then return end
    if DoSpell("Контузящий выстрел", "target") then return end
    if DoSpell("Чародейский выстрел", "target") then return end
    if InMelee(target) and not HasMyDebuff("Подрезать крылья", 0.5,"target") and DoSpell("Подрезать крылья", "target") then return end
    if InMelee(target) and DoSpell("Удар ящера", "target") then return end
end


function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
end

function TryTarget()
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then omacro("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and ActualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then
                omacro("/startattack " .. target)
                break
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
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
            or not ActualDistance("target")  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then
            if UnitExists("target") then omacro("/cleartarget") end
        end
    end
end
