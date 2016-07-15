-- Shaman Rotation Helper by Timofeev Alexey
print("|cff0055ffRotation Helper|r|cffffe00a > |cff0000ffShaman|r loaded!")
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье", "Призрачный волк"}
-- Общее для всех ротаций
function Idle()
	-- слезаем со всего, если решили драться
    if IsAttack() then
        if HasBuff("Призрачный волк") then orun("/cancelaura Призрачный волк") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end
    end
    -- дайте поесть спокойно
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then orun("/stopattack") end
    -- геру под крылья на арене


   ---------------------------------------------------------------------------------------------------------------

    -- прожим деф абилок
    if TryProtect() then return end
    -- Выбор цели
    if IsAttack() or InCombatLockdown() then TryTarget() end
    -- сбиваем касты
    for i = 1, #TARGETS do
        TryInterrupt(TARGETS[i])
    end
    --------------------------------------------------------------------------------------------------------------
    -- Элем
    if IsRDD() then
        RDDRotation()
        return
    end
end

function RDDRotation()
    --if not InCombatLockdown() and not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
    if GetInventoryItemID("player",16) and not GetTemporaryEnchant(16) and DoSpell("Оружие языка пламени") then return end
    if not IsAttack() and not CanAttack() then return end
    if not (UnitAffectingCombat("target") or IsAttack()) then return end
    if not IsValidTarget("target") then return end
    orun("/startattack")
    --ротация элема древняя версия для Идеала
    if IsBurst() and DoSpell("Покорение стихий") then return end
    if IsEquippedItem("Талисман восстановления") and HasBuff("Покорение стихий", player) and UseItem("Талисман восстановления") then return end
    if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок", "target") then return end
    if HasMyDebuff("Огненный шок", 1.5,"target") and DoSpell("Выброс лавы", "target") then return end
    if UnitMana100() < 10 and DoSpell("Гром и молния") then return end
    if IsAOE() and DoSpell("Цепная молния", "target") then return end
    if IsAOE() and AutoAOE and HasTotem(1) ~= "Тотем магмы VII" and DoSpell("Тотем магмы") then return end
    if IsAOE() and AutoAOE and HasTotem(1) and DoSpell("Кольцо огня") then return end
    --if (IsRightAltKeyDown() == 1) and DoSpell("Зов Стихий") then return end
    if DoSpell("Молния", "target") then return end
    if not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
end


function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
end

function TryTarget()
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then orun("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and ActualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then
                orun("/startattack " .. target)
                break
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then orun("/cleartarget") end

        if IsPvP() then
            orun("/targetenemyplayer [nodead]")
        else
            orun("/targetenemy [nodead]")
        end
        if not IsAttack()  -- если в авторежиме
            and (
            not IsValidTarget("target")  -- вообще не цель
            or not ActualDistance("target")  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then
            if UnitExists("target") then orun("/cleartarget") end
        end
    end

end

function TryProtect()
    if InCombatLockdown() then
        local hp = CalculateHP("player")
        if not IsPvP() then
            if hp < 40 and UseHealPotion() then return true end
            if UnitMana100("player") < 10 and UseItem("Рунический флакон с зельем маны") then return true end
            if UnitMana100("player") < 30 and UseItem("Бездонный флакон с зельем маны") then return true end
        end
        if hp < 70 and HasSpell("Дар наару") and DoSpell("Дар наару", 'player') then return true end
        if hp < 30 and PlayerInPlace() and DoSpell("Малая волна исцеления", 'player') then return true end
    end
    return false
end
