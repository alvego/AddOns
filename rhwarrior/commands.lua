-- Warrior Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--[[local flyMounts = {
    "Небесный голем",
    "Драгоценная ониксовая пантера",
    "Ракета на обедненном кипарии",
    "Геосинхронный вращатель мира",
    "Непобедимый",
    "Песчаниковый дракон",
    --"Золотистый грифон",
}
local groundMounts = {
    "Небесный голем",
    --"Золотистый грифон",
    "Драгоценная ониксовая пантера",
    "Ракета на обедненном кипарии",
    "Геосинхронный вращатель мира",
    "Непобедимый",
    "Анжинерский чоппер",
    "Большой як для путешествий"
}
SetCommand("mount",
    function()
        if not IsArena() then
            -- ускорение
            if IsAlt() and not PlayerInPlace() and UseSlot(6) then
                chat("Ускорители")
                TimerStart('Mount')
                return true
            end
            -- Парашют
            if GetFalingTime() > 1 and UseSlot(15) then
                chat("Парашют")
                TimerStart('Mount')
                return true
            end
            -- рыбная ловля
            if IsEquippedItemType("Удочка") and DoSpell("Рыбная ловля") then
                TimerStart('Mount')
                return true
            end
        end

        if InGCD() or IsPlayerCasting() then return end

        if IsFalling() and GetFalingTime() < 1 and DoSpell("Хождение по воде", "player") then
            TimerStart('Mount')
            return true
        end

        if IsMounted() or CanExitVehicle()  then
            TimerStart('Mount')
            return true
        end

        if not HasBuff("Призрачный волк") and InCombatLockdown() or IsArena() or not PlayerInPlace() or not IsOutdoors() then
            DoSpell("Призрачный волк")
            TimerStart('Mount')
            return true
        end

        --local mount = "Ракета на обедненном кипарии"
        --local mount = "Небесный голем" --"Драгоценная ониксовая пантера"
        local mount = (IsShift() or IsBattleground() or not IsFlyableArea()) and groundMounts[random(#groundMounts)] or flyMounts[random(#flyMounts)]
        ----"Непобедимый"--"Золотистый грифон"
        if IsAlt() then mount = "Тундровый мамонт путешественника" end --"Большой як для путешествий"
        if IsSwimming() then
            mount = "Подчиненный морской конек"
        end
        if UseMount(mount) then
            TimerStart('Mount')
            return true
        end
    end,
    function()
        if TimerStarted('Mount') and TimerElapsed('Mount') > 0.01 then
            TimerReset('Mount')
            return  true
        end

        return false
    end
)]]
----------------------------------------------------------------------------------------------------------------
