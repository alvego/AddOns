-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local TryResUnit = nil
local TryResTime = 0
------------------------------------------------------------------------------------------------------------------
-- дебафы обязательные к снятию в первую очередь
DispelRedList = {
    "Озноб",
    "Сглаз",
    "Проклятие стихий",
    "Проклятие косноязычия",
    "Проклятие агонии",
    "Укус змеи",
    "Укус гадюки"
}
------------------------------------------------------------------------------------------------------------------
-- бафы противников обязательные к снятию в первю очередь
StealRedList = {
    -- Burst
    "Жажда крови",
    "Святая клятва",
    "Гнев карателя",
    "Стылая кровь",
    "Чародейское ускорение",
    "Героизм",
    "Мощь тайной магии"
}
------------------------------------------------------------------------------------------------------------------
-- Хоты и т. д.
StealHotRedList = {
    -- Hots etc
    "Быстрина",
    "Быстрота хищника",
    "Озарение",
    "Молитва восстановления",
    "Частица Света",
    "Жизнь Земли",
    "Покров Света",
    "Жизнецвет",
    "Омоложение",
    "Буйный рост",
    "Божественное покровительство",
    "Вдохновение",
    "Милость"
}
------------------------------------------------------------------------------------------------------------------
-- Щиты и деф абилки
StealShieldsRedList = {
    -- defs
    "Слово силы: Щит",
    "Дубовая кожа",
    "Щит Бездны",
    "Щит маны",
    "Щит земли",
    "Щит из костей",
    "Защита Пустоты",
    "Быстрина",
    "Божественная защита",
    "Призрачный волк",
    "Длань свободы",
    "Длань защиты",
    "Ледяная преграда",
    "Жертвоприношение",
    "Незыблемость льда",
    "Быстрота хищника",
    "Затвердевшая кожа",
    "Покровительство",
    "Священный щит",
    "Совершенство природы"
}
------------------------------------------------------------------------------------------------------------------
-- Общее для всех ротаций
function Idle()
    if IsAttack() then
        if HasBuff("Призрачный волк") then RunMacroText("/cancelaura Призрачный волк") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть спокойно
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted() or CanExitVehicle() or HasBuff("Призрачный волк")) then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then RunMacroText("/stopattack") end
    -- геру под крылья на арене
    if IsArena() and TryEach(UNITS, function(u) return HasBuff("Гнев карателя", 10, u) end) then DoCommand("hero") end
    -- Зачем вару отражение???
    if TryEach(TARGETS, function(t) 
        return CanAttack(t) and UnitAffectingCombat(t) and HasBuff({"Отражение заклинания", "Рунический покров"}, 1, t) and DoSpell("Пронизывающий ветер", t)
    end) then return end
    
    --------------------------------------------------------------------------------------------------------------
    -- Рес по средней мышке + контрол
    if IsLeftControlKeyDown() and IsMouseButtonDown(4) then
        if CanRes("mouseover") then
            TryResUnit = TryEach(GetGroupUnits(), function(u) return IsOneUnit(u, "mouseover") and u end) or "mouseover"
            TryResTime = GetTime()
            Notify("Пробуем воскресить " ..UnitName(TryResUnit) .. "("..TryResUnit..")")
        else
            local name = UnitName("mouseover")
            if name and UnitIsPlayer("mouseover") then print("Не могу реснуть", name) end
        end
    end
    --------------------------------------------------------------------------------------------------------------
    -- не судьба реснуть...
    if TryResUnit and (not CanRes(TryResUnit) or (CanRes(TryResUnit) and (GetTime() - TryResTime) > 60) or not PlayerInPlace())  then
        if UnitName(TryResUnit) and not CanHeal(TryResUnit) then Notify("Не удалось воскресить " .. UnitName(TryResUnit)) end
        TryResUnit = nil
        TryResTime = 0
    end
    --------------------------------------------------------------------------------------------------------------
    -- пробуем реснуть
    if TryResUnit and CanRes(TryResUnit) and TryRes(TryResUnit) then return end
    
    --------------------------------------------------------------------------------------------------------------
    -- Хил ротация
    if IsHeal() then 
        HealRotation() 
        return
    end
   ---------------------------------------------------------------------------------------------------------------
    
    -- прожим деф абилок
    if TryProtect() then return end
    -- Выбор цели
    if IsAttack() or InCombatLockdown() then TryTarget() end
    -- сбиваем касты
    if TryEach(TARGETS, TryInterrupt) then return end
    -- тотемчики может поставить?
     if TryTotems() then return end
    --------------------------------------------------------------------------------------------------------------
    -- Энх
    if IsMDD() then 
        MDDRotation() 
        return
    end
    --------------------------------------------------------------------------------------------------------------
    -- Элем
    if IsRDD() then 
        RDDRotation() 
        return
    end
    
end

-- Актуально при игре в 2 хила, для уменьшения оверхила
function CheckHealCast(u, h)
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo("player")
    if not spell or not endTime then return end
    if not tContains({"Малая волна исцеления", "Волна исцеления", "Цепное исцеление"}, spell) then return end
    if not InCombatLockdown() or IsControlKeyDown() then return end
    
    local lastHealCastTarget = GetLastSpellTarget(spell)
    if not lastHealCastTarget then return end
    if UnitThreat(lastHealCastTarget) == 3 then return end

    local last = endTime/1000 - GetTime()
    if last > 0.4 and not(h < 45 and not IsOneUnit(u, lastHealCastTarget)) then return end
    local incomingheals = UnitGetIncomingHeals(u)
    local hp = UnitHealth(u) + incomingheals
    local maxhp = UnitHealthMax(u)
    local spellHeal = GetMySpellHeal(spell)
    local lost = maxhp - (hp - spellHeal)
    if (lost < (spellHeal * 0.3)) then -- 30% оверхила допустимо
        RunMacroText("/stopcasting")
        print("Для игрока ", UnitName(lastHealCastTarget), " хилка ", spell, " особо не нужна." )
    end
end

local function TryBuff()
        local name, _, _, _, _, duration, Expires, _, _, _, spellId = UnitBuff("player", "Настой севера") 
        return not (name and spellId == (IsMDD() and 67017 or 67016) and Expires - GetTime() >= duration / 2) and UseItem("Настой севера")
end
local shieldChangeTime = 0
function HealRotation()
    
    if IsAltKeyDown() and TrySteal("target") then return end
    if (IsPvP() and InCombatLockdown()) and TryEach(TARGETS, function(t) return CanAttack(t) 
        and UnitHealth100(t) < 4 and not HasMyDebuff("шок", 1, t) and DoSpell("Огненный шок", t) end) then return end
    
    if GetInventoryItemID("player",16) and not DetermineTempEnchantFromTooltip(16) and DoSpell("Оружие жизни земли") then return end
    if UnitMana100() < 80 and InCombat(3) and UnitHealth100("player") > 30 and not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
    
    if IsAttack() and CanAttack() and not IsAltKeyDown() and not IsLeftShiftKeyDown() and not IsLeftControlKeyDown() then
        if HasMyDebuff("шок", 1, "target") and PlayerInPlace() then
            if DoSpell("Выброс лавы") then return end
        else
            if DoSpell("Огненный шок") then return end
        end
    end    

    if IsAttack() then 
        if not IsInteractUnit("target") then TryTarget(false) end
        if IsLeftShiftKeyDown() and HasTotem(1) and DoSpell("Кольцо огня") then return end
    else
        if InCombatLockdown() and UnitName("target") and not IsInteractUnit("target") and not IsOneUnit("target-target", "player") and UnitThreat("player") == 3 then
            RunMacroText("/cleattarget")
        end
    end
    
    local myHP = CalculateHP("player")

    if InCombatLockdown() then
        if (myHP < 30) and DoSpell("Кровь земли", "player") then return end
        if (myHP < 40) and HasSpell("Дар наару") and DoSpell("Дар наару", "player") then return end
        if myHP < 60 and UseEquippedItem("Проржавевший костяной ключ") then return end
        if not IsArena() then
            if myHP < 40 and UseHealPotion() then return end
            if UnitMana100("player") < 25 and UseItem("Рунический флакон с зельем маны") then return true end
            if UnitMana100("player") < 51 and UseItem("Бездонный флакон с зельем маны") then return true end
        end
    end

    local RiptideHeal = GetMySpellHeal("Быстрина")
    local ChainHeal = GetMySpellHeal("Цепное исцеление")
    local HealingWaveHeal = GetMySpellHeal("Волна исцеления")
    local LesserHealingWaveHeal = GetMySpellHeal("Малая волна исцеления")
    
    local members = {}
    if not IsPvP() and PlayerInPlace() and not InCombatLockdown() then
        if myHP < 100 and (IsReadySpell("Быстрина") or HasMyBuff("Приливные волны",1,u))  then 
            local u = "player"
            if not HasMyBuff("Быстрина", 3, u) and DoSpell("Быстрина", u) then return end
            if HasMyBuff("Приливные волны", 2, u) and DoSpell("Малая волна исцеления", u) then return end
            return
        end
        local res = false
        local groupUnits = GetGroupUnits()
        tinsert(groupUnits, "target")
        tinsert(groupUnits, "focus")
        tinsert(groupUnits, "mouseover")
        for i=1,#groupUnits do
           if not res and TryRes(groupUnits[i]) then res = true end
        end
        if res then return end
        
        for i=1,#groupUnits do
           if CanRes(groupUnits[i]) then needRes = true end
        end
        if res then return end
    end
    
    if not InCombatLockdown() and TryBuff() then return end
           
    for i=1,#UNITS do
        local u = UNITS[i]
        if CanHeal(u) then  
            h =  CalculateHP(u)
            if IsFriend(u) or IsOneUnit(u, "player") then 
                if UnitAffectingCombat(u) and h > 99 then h = h - 1 end
                h = h  - ((100 - h) * 1.15) 
            end
            
            if UnitIsPet(u) then
                if UnitAffectingCombat("player") then 
                    h = h * 1.5
                end
            else
                if UnitThreat(u) == 3 then h = h - 5 end
                if HasBuff({"Ледяная глыба", "Божественный щит", "Превращение", "Щит земли", "Частица Света"}, 1, u) then h = h + 3 end
                if not IsArena() and myHP < 50 and not IsOneUnit("player", u) and not (UnitThreat(u) == 3) then h = h + 30 end
            end
            table.insert(members, { Unit = u, HP = h, Lost = UnitLostHP(u) } )
        end
    end
    table.sort(members, function(x,y) return x.HP < y.HP end)

    local unitWithShield, threatLowHPUnit, threatLowHP = nil, nil, 1000
    local threatLowHPUnit, lowhpmembers, notfullhpmembers = nil, 0, 0
    local rUnit, rCount, rUnits = nil, 0, {}
    for i=1,#members do 
        local u, hp, c = members[i].Unit,members[i].HP, 0
        
        if HasMyBuff("Щит земли",1,u) then unitWithShield = u end
        if IsFriend(u) then hp = hp - 1 end
        if (UnitThreatAlert(u) == 3) and (hp < threatLowHP) and (not IsOneUnit(u, "player") or (UnitMana100("player") > 50 and UnitHealth100("player") < 30)) then
           threatLowHPUnit = u  
           threatLowHP = hp  
        end

        for j=1,#members do
            local ju, jl, jh = members[j].Unit, members[j].Lost, members[j].HP
            local d = CheckDistance(u, ju)
            
            if not IsOneUnit("player", ju) 
                and not IsOneUnit("player", u) 
                and d 
                and d < 10 --12.5
                then
                if jh < 100 then
                    if h < 100 then notfullhpmembers = notfullhpmembers + 1 end
                end
                if (jl > ChainHeal / 4  or jh < 70) then
                    c = c + 1 
                end
            end
                       
        end
        
        rUnits[u] = c
        
        if h < 40 then lowhpmembers = lowhpmembers + 1 end
        
   end 
    if #members < 1 then print("Некого лечить!!!") return end
    local u, h, l = members[1].Unit, members[1].HP, members[1].Lost
    
    if TryEach(TARGETS, function(t) return TryInterrupt(t, h) end) then return end
    -- тотемчики может поставить?
    if TryTotems(nil, h) then return end
    
    if  h > 50 then
        
        if UnitMana100("player") > 30 and IsReadySpell("Очищение духа") and TryEach(IUNITS, 
            function(u) return HasDebuff(DispelRedList, 2, u) and TryDispel(u) end
        ) then return end
        
        
        if UnitMana100("player") > 30 and IsReadySpell("Развеивание магии") then
            -- получаем приоритетные цели (например цель дд в тиме, сортируем их по хп)
            local targets = {}
            table.foreach(IUNITS, function(_,u)
                local t = u .. "-target"
                if IsFriend(u) and IsValidTarget(t) and CanMagicAttack(t) then
                    tinsert(targets, t)
                end
            end)
            -- снимем щиты с целей дд
            table.sort(targets, function(t1, t2) return UnitHealth100(t1) < UnitHealth100(t2) end)
            if TryEach(targets, 
                function(t) return HasBuff(StealShieldsRedList, 2, t) and TrySteal(t) end
            ) then return  end
            -- снимаем хоты, с целей дд, если есть смысл (не фул хп)
            if TryEach(targets, 
                function(t) return UnitHealth100(t) < 100 and HasBuff(StealHotRedList, 2, t) and TrySteal(t) end
            ) then return  end
            -- обрабатываем по стандартной схеме всех ( снимаем бурст бафы)
            if TryEach(ITARGETS, 
                function(t) return HasBuff(StealRedList, 2, t) and TrySteal(t) end
            ) then return  end
            -- зачем противнику хоты? (если фул хп то в хотах нет осбого смысла)
            if TryEach(ITARGETS, 
                function(t) return UnitHealth100(t) < 99 and HasBuff(StealHotRedList, 2, t) and TrySteal(t) end
            ) then return  end
        end
        
        
        
        if UnitMana100("player") > 30 and IsReadySpell("Развеивание магии") and TryEach(ITARGETS, 
            function(t) return HasBuff(StealRedList, 2, t) and TrySteal(t) end
        ) then return  end
    end
    
    
    CheckHealCast(u, h)

    if not IsArena() and not IsAttack() and CanHeal("focus") and h > 40  and CalculateHP("focus") < 100 then
        u = "focus"
        h = 40
        rUnits[u] = 0
    end
   
    
    if (HasBuff("Природная стремительность")) then
        if rUnits[u] > 1 and h > 40 then
            if DoSpell("Цепное исцеление", u) then return end 
        else
            if DoSpell("Волна исцеления", u) then return end
        end
        return 
    end
    
    if IsArena() and not InCombatLockdown() and not HasBuff("Водный щит") and not unitWithShield and DoSpell("Щит земли", "player") then return end
    if threatLowHPUnit and InCombat(3) then
        if unitWithShield and UnitThreatAlert(unitWithShield) < 3 and threatLowHPUnit and (threatLowHP < 70) then
            shieldChangeTime = 0
            unitWithShield = nil
        end
        
        if not unitWithShield and (GetTime() - shieldChangeTime > 3) and DoSpell("Щит земли", threatLowHPUnit) then 
            shieldChangeTime = GetTime()
            return 
        end
        
        if unitWithShield and not IsOneUnit(unitWithShield, threatLowHPUnit) and threatLowHP < 65 and (GetTime() - shieldChangeTime > 6) and DoSpell("Щит земли", threatLowHPUnit) then 
            shieldChangeTime = GetTime()
            return
        end
    end
    
    if InCombatLockdown() then
        if h < 20 and DoSpell("Дар наару", u) then return end
        if (lowhpmembers > 2 or l > HealingWaveHeal * 1.5) and UseEquippedItem("Талисман восстановления") then return end
        if (lowhpmembers > 1 or l > HealingWaveHeal * 1.2) and UseEquippedItem("Крылатый талисман") then return end
        if (l > (HealingWaveHeal * 1.5)) and HasSpell("Сила прилива") then DoSpell("Сила прилива") end
        if (h < 20 or lowhpmembers > 2) and HasSpell("Природная стремительность") and DoSpell("Природная стремительность") then return end
    end

    --local RiptideHeal = GetMySpellHeal("Быстрина")
    --local ChainHeal = GetMySpellHeal("Цепное исцеление")
    --local HealingWaveHeal = GetMySpellHeal("Волна исцеления")
    --local LesserHealingWaveHeal = GetMySpellHeal("Малая волна исцеления")
    
    if HasSpell("Быстрина") and IsReadySpell("Быстрина") and TryEach(members, 
        function(m) return not HasMyBuff("Быстрина",1,m.Unit) and (m.Lost > RiptideHeal or m.HP < 65) and DoSpell("Быстрина", m.Unit) end
        ) then return end
    
    if PlayerInPlace() then
    
        if h < 25 and (l > HealingWaveHeal) and HasMyBuff("Приливные волны", 1, "player") and DoSpell("Волна исцеления", u) then return end
        if h < 10 and DoSpell("Малая волна исцеления", u) then return end
        
        if h > 40 and rUnits[u] > 1 and not IsPvP() and (l > ChainHeal or h < 80) and DoSpell("Цепное исцеление", u) then return end 
        if h > 70 and rUnits[u] > 1 and IsBattleground() and (UnitThreatAlert("player") < 3) and (l > ChainHeal or h < 80) and DoSpell("Цепное исцеление", u) then return end 
        
        -- мана сейв
        if h > 50 and UnitMana100("player") < 50 and (l > LesserHealingWaveHeal * 1.2) and HasMyBuff("Приливные волны", 1.5, "player") and DoSpell("Малая волна исцеления", u) then return end
        
        if IsPvP() and (l > HealingWaveHeal) and HasMyBuff("Приливные волны", 1.5, "player") and DoSpell("Волна исцеления", u) then return end
        if IsPvP() and (l > LesserHealingWaveHeal) and (l < HealingWaveHeal) and DoSpell("Малая волна исцеления", u) then return end 
        
        if (l > HealingWaveHeal) and DoSpell("Волна исцеления", u) then return end
        
        if (h < 40 or l > LesserHealingWaveHeal) and UnitMana100("player") > 50 and DoSpell("Малая волна исцеления", u) then return end
        
        
        if h < 100 and IsControlKeyDown() then
            if notfullhpmembers > 1 and rUnits[u] > 0 then
                if DoSpell("Цепное исцеление", u) then return end 
            else
                if DoSpell("Малая волна исцеления", u) then return end
            end
        end
        
    end
    
    if (h > 60 and UnitMana100("player") > 50) then
        if IsSpellNotUsed("Очищение духа", 5) and TryEach(IUNITS, TryDispel) then return end
        if IsSpellNotUsed("Развеивание магии", 5) and TryEach(ITARGETS, TrySteal) then return end
    end

    
    if IsAttack() and CanAttack() and not IsAltKeyDown() and PlayerInPlace() then
        if IsAOE() then
            if DoSpell("Цепная молния", "target") then return end
        end
        if DoSpell("Молния", "target") then return end
    end
    if not IsAttack() and h > 50 and IsPvP() and TryEach(TARGETS, 
        function(t) return CanControl(t) and UnitIsPlayer(t) and not HasDebuff({"Оковы земли", "Ледяной шок"}, 0,1, t) and DoSpell("Ледяной шок", t) end
    ) then return end
        
end    

function MDDRotation()
    if not InCombatLockdown() and TryBuff() then return end
    if GetInventoryItemID("player",16) and not DetermineTempEnchantFromTooltip(16) and UseSpell("Оружие неистовства ветра") then return end
    if OffhandHasWeapon() and GetInventoryItemID("player",17) and not DetermineTempEnchantFromTooltip(17) and UseSpell("Оружие языка пламени") then return end
    
    if not UnitAffectingCombat("target") and (not HasBuff("Водный щит") or UnitMana100("player") > 50) then
        if not HasBuff("Щит молний") and DoSpell("Щит молний") then return end
    end
    
    if (not HasBuff("Водный щит") and UnitMana100("player") < 30) and not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
    
    if not IsAttack() and not CanAttack("target") then return end
    if not (UnitAffectingCombat("target") or IsAttack()) then return end
    
    if IsAttack() then RunMacroText("/startattack") end
    if (UnitHealth100("player") < 35) and DoSpell("Дух дикого волка") then return end
    if CanMagicAttack("target") and not ActualDistance() and IsAttack() then
        if UnitAffectingCombat("target") then
            if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок", "target") then return end
            if DoSpell("Земной шок") then return end
        end 
        if PlayerInPlace() then
            if IsAOE() then
                if DoSpell("Цепная молния", "target") then return end
            end
            if DoSpell("Молния", "target") then return end
        end
    end
    
    if InMelee() and UseEquippedItem("Карманные часы Феззика") then return end
    if InMelee() and UseEquippedItem("Знак превосходства") then return end
    if IsAOE() and HasTotem(1) and DoSpell("Кольцо огня") then return end
    if CanMagicAttack("target") and GetBuffStack("Оружие Водоворота") == 5 then
        if IsAOE() then
            if DoSpell("Цепная молния", "target") then return end
        end
        if DoSpell("Молния", "target") then return end
    end
    if IsSpellNotUsed("Развеивание магии", 5) and UnitMana100("player") > 30 and IsReadySpell("Развеивание магии") and CanMagicAttack("target") then
        if HasBuff(StealShieldsRedList, 2, "target") and TrySteal("target") then return end
        if HasBuff(StealRedList, 2, "target") and TrySteal("target") then return end
        if UnitHealth100("target") < 100 and HasBuff(StealHotRedList, 2, "target") and TrySteal("target") then return end
    end
    if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок", "target") then return end
    if not HasBuff("Ярость шамана") and DoSpell("Ярость шамана") then return end
    if DoSpell("Удар бури", "target") then return end
    if DoSpell("Земной шок", "target") then return end
    if (not HasBuff("Водный щит") or UnitMana100("player") > 50) and not HasBuff("Щит молний") and DoSpell("Щит молний") then return end
    if DoSpell("Вскипание лавы", "target") then return end
end

function RDDRotation()
    if not InCombatLockdown() and TryBuff() then return end
    if not InCombatLockdown() and not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
    if GetInventoryItemID("player",16) and not DetermineTempEnchantFromTooltip(16) and DoSpell("Оружие языка пламени") then return end
    
    if not IsAttack() and not CanAttack() then return end
    if not (UnitAffectingCombat("target") or IsAttack()) then return end
    
    if not UnitAffectingCombat("target") then
        
    end
    if not IsValidTarget("target") then return end
    RunMacroText("/startattack")
    if IsSpellNotUsed("Развеивание магии", 5) and UnitMana100("player") > 30 and IsReadySpell("Развеивание магии") and CanMagicAttack("target") then
        if HasBuff(StealShieldsRedList, 2, "target") and TrySteal("target") then return end
        if HasBuff(StealRedList, 2, "target") and TrySteal("target") then return end
        if UnitHealth100("target") < 100 and HasBuff(StealHotRedList, 2, "target") and TrySteal("target") then return end
    end
    --[[if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок", "target") then return end
    if HasMyDebuff("Огненный шок", 2,"target") and DoSpell("Выброс лавы", "target") then return end
    if IsAOE() and DoSpell("Цепная молния", "target") then return end
    if IsAOE() and HasTotem(1) and DoSpell("Кольцо огня") then return end
    if DoSpell("Молния", "target") then return end
    if not HasBuff("Водный щит") and DoSpell("Водный щит") then return end]]
    --ротация элема древняя версия для Идеала
    if (
                            HasBuff("Жажда крови") or
                            HasBuff("Неустойчивая сила") or
                            HasBuff("Гиперскоростное ускорение") or
                            HasBuff("Покорение стихий") or
                            HasBuff("Берсерк")) then
                            if IsEquippedItem("Заговоренное перо Магхиа") and UseItem("Заговоренное перо Магхиа") then return end
                        end
                        
                        if  HasDebuff("Огненный шок") and not(
                            HasBuff("Жажда крови") or
                            HasBuff("Неустойчивая сила") or
                            HasBuff("Гиперскоростное ускорение") or
                            HasBuff("Покорение стихий") or
                            HasBuff("Берсерк")) then

                            
                            if UseSpell("Покорение стихий") then return end
                            if (IsReadySlot(10)) then UseSlot(10) return end
                            if UseSpell("Берсерк") then return end
                            if IsEquippedItem("Фетиш неустойчивой силы") and UseItem("Фетиш неустойчивой силы") then return end
                        end
                        
                        if HasBuff("Жажда крови") and not(HasBuff("Дикая магия")) then UseItem("Зелье дикой магии") end
                           
                        --if not HasMyDebuff("Огненный шок", 0.5) and (IsSpellInRange("Огненный шок", "target") == 1) and  UseSpell("Огненный шок") then return end
                        --if HasMyDebuff("Огненный шок", 3) and (IsSpellInRange("Выброс лавы", "target") == 1) and  UseSpell("Выброс лавы") then return end
                        if not HasMyDebuff("Огненный шок", 0.5,"target") and (IsSpellInRange("Огненный шок", "target") == 1) and  UseSpell("Огненный шок") then return end
                        if HasMyDebuff("Огненный шок", 2,"target") and (IsSpellInRange("Выброс лавы", "target") == 1) and  UseSpell("Выброс лавы") then return end
                        if (IsRightControlKeyDown() == 1) and not (FindAura("Жажада крови")) and UseSpell("Жажда крови") then return end
                        if (IsAOE() and IsSpellInRange("Цепная молния", "target") == 1) and UseSpell("Цепная молния") then return end
                        if (IsLeftAltKeyDown() == 1) and HasTotem(1) ~= "Тотем магмы VII" and UseSpell("Тотем магмы") then return end
                        if (IsRightAltKeyDown() == 1) and UseSpell("Зов стихий") then return end
                        if (IsSpellInRange("Молния", "target") == 1) and UseSpell("Молния") then return end
    
end


function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
end

function TryTarget(useFocus)
    if useFocus == nil then useFocus = true end
    if not IsValidTarget("target") then
        local found = false
        local members = GetGroupUnits()
        for _,member in pairs(members) do 
            target = member .. "-target"
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target) and (not IsPvP() or UnitIsPlayer(target))  then 
                found = true 
                RunMacroText("/startattack " .. target) 
            end
        end

        if not ActualDistance("target") or not UnitCanAttack("player", "target") or (IsPvP() and not UnitIsPlayer("target")) then
            RunMacroText("/cleartarget")
        end

    end

    if  not IsValidTarget("target") then
        if GetNextTarget() ~= nil then
            RunMacroText("/startattack "..GetNextTarget())
            if not ActualDistance("target") or not NextIsTarget() or not UnitCanAttack("player", "target") or (IsPvP() and not UnitIsPlayer("target")) then
                RunMacroText("/cleartarget")
            end
            ClearNextTarget()
        end
    end

    if not IsValidTarget("target") then
        if IsPvP() then
            RunMacroText("/targetenemyplayer [nodead]")
        else
            RunMacroText("/targetenemy [nodead]")
        end
        if not IsAttack() and not ActualDistance("target") or not UnitCanAttack("player", "target") or (IsPvP() and not UnitIsPlayer("target")) then
            RunMacroText("/cleartarget")
        end
    end

    if not IsValidTarget("target") or (IsAttack() and  not UnitCanAttack("player", "target")) then
        RunMacroText("/cleartarget")
    end
   
    if not IsArena() then
        if useFocus and not IsValidTarget("focus") then
            local found = false
            for _,target in pairs(TARGETS) do 
                if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target) and not IsOneUnit("target", target) then 
                    found = true 
                    RunMacroText("/focus " .. target) 
                end
            end
        end

        if useFocus and not IsValidTarget("focus") or IsOneUnit("target", "focus") or not ActualDistance("focus") then
            RunMacroText("/clearfocus")
        end
    else
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
            if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
        end
    end
    

end

function TryProtect()
    if InCombatLockdown or IsArena() then
        local hp = CalculateHP("player")
        if (hp < 30) and DoSpell("Кровь земли", "player") then return end
        if not IsArena() and hp < 40 and UseHealPotion() then return true end
        if not IsArena() and UnitMana100("player") < 10 and UseItem("Рунический флакон с зельем маны") then return true end
        if not IsArena() and UnitMana100("player") < 30 and UseItem("Бездонный флакон с зельем маны") then return true end
        local members = {}
        for i=1,#IUNITS do
            local u = IUNITS[i]
            if CanHeal(u) then table.insert(members, { Unit = u, HP = CalculateHP(u), Lost = UnitLostHP(u) } ) end
        end
        table.sort(members, function(x,y) return x.HP < y.HP end)
        if #members > 0 then 
            local u, h, l = members[1].Unit, members[1].HP, members[1].Lost
            
            if h < 70 and DoSpell("Дар наару", u) then return true end
            if GetBuffStack("Оружие Водоворота") == 5 then
                if h < 60 and DoSpell("Волна исцеления", u) then return true end
            end
            if h < 30 and PlayerInPlace() and DoSpell("Малая волна исцеления", u) then return true end
        end
    end
    return false
end
