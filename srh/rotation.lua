-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local TryResUnit = nil
local TryResTime = 0

function Idle()
    -- дайте поесть спокойно
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted() or HasBuff("Призрачный волк")) then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then RunMacroText("/stopattack") end
    -- геру под крылья на арене
    if IsArena() and TryEach(UNITS, function(u) return HasBuff("Гнев карателя", 10, u) end) then DoCommand("hero") end
    -- тотемчики может поставить?
    if TryTotems() then return end
    -- Зачем вару отражение???
    if IsValidTarget("target") and UnitAffectingCombat("target") and HasBuff("Отражение заклинания", 1, "target") and DoSpell("Пронизывающий ветер") then return end
    -- Рес по средней мышке + контрол
    if IsLeftControlKeyDown() and IsMouseButtonDown(3) then
        if CanRes("mouseover") then
            TryResUnit = TryEach(GetGroupUnits(), function(u) return IsOneUnit(u, "mouseover") and u end) or "mouseover"
            TryResTime = GetTime()
            Notify("Пробуем воскресить " ..UnitName(TryResUnit) .. "("..TryResUnit..")")
        else
            local name = UnitName("mouseover")
            if name and UnitIsPlayer("mouseover") then print("Не могу реснуть", name) end
        end
    end
    -- не судьма реснуть...
    if TryResUnit and (not CanRes(TryResUnit) or (CanRes(TryResUnit) and (GetTime() - TryResTime) > 60) or not PlayerInPlace())  then
        if UnitName(TryResUnit) and not CanHeal(TryResUnit) then Notify("Не удалось воскресить " .. UnitName(TryResUnit)) end
        TryResUnit = nil
        TryResTime = 0
    end
    -- пробуем реснуть
    if TryResUnit and CanRes(TryResUnit) and TryRes(TryResUnit) then return end
    if IsHeal() then 
        HealRotation() 
        return
    end
   
    if (IsAttack() or InCombatLockdown()) then

        if TryEach(TARGETS, TryInterrupt) then return end
           
        if InCombatLockdown() and UnitHealth100() < 31 and UseHealPotion() then return end
        
        if TryProtect() then return end

        if IsSpellNotUsed("Очищение духа", 5) and TryDispel("player") then return end
        TryTarget()
        if not CanAttack() then return end
        if IsMDD() then 
            MDDRotation() 
            return
        end
        if IsRDD() then 
            RDDRotation() 
            return
        end
    end
end

function CheckHealCast(u, h)
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo("player")
    if not spell or not endTime then return end
    if not tContains({"Малая волна исцеления", "Волна исцеления", "Цепное исцеление"}, spell) then return end
    if not InCombatLockdown() then return end
    
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
    if (lost < (spellHeal * 0.3)) then
        RunMacroText("/stopcasting")
        print("Для игрока ", UnitName(lastHealCastTarget), " хилка ", spell, " особо не нужна." )
    end
end

local function TryBuff()
        local name, _, _, _, _, duration, Expires, _, _, _, spellId = UnitBuff("player", "Настой севера") 
        return not (name and spellId == 67016 and Expires - GetTime() >= duration / 2) and UseItem("Настой севера")
end
local shieldChangeTime = 0
function HealRotation()
    
    if IsAltKeyDown() and TrySteal("target") then return end
    if (IsPvP() and InCombatLockdown()) and TryEach(TARGETS, function(t) return CanAttack(t) 
        and UnitHealth100(t) < 4 and not HasMyDebuff("шок", 1, t) and DoSpell("Огненный шок", t) end) then return end
    
    if GetInventoryItemID("player",16) and not DetermineTempEnchantFromTooltip(16) and DoSpell("Оружие жизни земли") then return end
    if UnitMana100() < 80 and InCombat(3) and UnitHealth100("player") > 30 and not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
    
    if IsAttack() and CanAttack() and not IsAltKeyDown() and not IsLeftShiftKeyDown() then
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
        if (myHP < 40) and DoSpell("Дар наару", "player") then return end
        if myHP < 60 and UseEquippedItem("Проржавевший костяной ключ") then return end
        if not IsArena() then
            if myHP < 40 and UseHealPotion() then return end
            if UnitMana100() < 25 and UseItem("Рунический флакон с зельем маны") then return true end
            if UnitMana100() < 51 and UseItem("Бездонный флакон с зельем маны") then return true end
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
    local threatLowHPUnit, lowhpmembers = nil, 0
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
                and (jl > ChainHeal / 4  or jh < 70) then
                c = c + 1 
            end
        end
        
        rUnits[u] = c
        
        if h < 40 then lowhpmembers = lowhpmembers + 1 end
   end 
    if #members < 1 then print("Некого лечить!!!") return end
    local u, h, l = members[1].Unit, members[1].HP, members[1].Lost
    
    if  h > 40 then
        if TryEach(TARGETS, function(t) return TryInterrupt(t, h) end) then return end
        if UnitMana100("player") > 30 and IsReadySpell("Развеивание магии") and TryEach(ITARGETS, 
            function(t) return HasBuff(StealRedList, 2, t) and TrySteal(t) end
        ) then return  end
        if UnitMana100("player") > 30 and IsReadySpell("Очищение духа") and TryEach(IUNITS, 
            function(u) return HasDebuff(DispelRedList, 2, u) and TryDispel(u) end
        ) then return end
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
        if lowhpmembers > 0 and UseEquippedItem("Талисман восстановления") then return end
        if lowhpmembers > 0 and UseEquippedItem("Руна конечной вариации") then return end
        if lowhpmembers > 0 and UseEquippedItem("Брошь в виде розы с шипами") then return end
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
        if h < 7 and DoSpell("Малая волна исцеления", u) then return end
        
        if h > 40 and rUnits[u] > 1 and not IsPvP() and l > ChainHeal and DoSpell("Цепное исцеление", u) then return end 
        if h > 70 and rUnits[u] > 1 and IsBattleground() and (UnitThreatAlert("player") < 3) and l > ChainHeal and DoSpell("Цепное исцеление", u) then return end 
        
        -- мана сейв
        if h > 50 and UnitMana100("player") < 50 and (l > LesserHealingWaveHeal * 1.2) and HasMyBuff("Приливные волны", 1.5, "player") and DoSpell("Малая волна исцеления", u) then return end
        
        if IsPvP() and (l > HealingWaveHeal) and HasMyBuff("Приливные волны", 1.5, "player") and DoSpell("Волна исцеления", u) then return end
        if IsPvP() and (l > LesserHealingWaveHeal) and (l < HealingWaveHeal) and DoSpell("Малая волна исцеления", u) then return end 
        if (l > HealingWaveHeal) and DoSpell("Волна исцеления", u) then return end
        if (l > LesserHealingWaveHeal or h < 70) and DoSpell("Малая волна исцеления", u) then return end
    end
    
    if (h > 60 and UnitMana100("player") > 50) then
        if IsSpellNotUsed("Очищение духа", 5) and TryEach(IUNITS, TryDispel) then return end
        if IsSpellNotUsed("Развеивание магии", 5) and TryEach(ITARGETS, TrySteal) then return end
    end

    
    if IsAttack() and CanAttack() and not IsAltKeyDown() and not IsLeftShiftKeyDown() and PlayerInPlace() and DoSpell("Молния") then return end
    if not IsAttack() and (h > 50 and IsPvP()) and TryEach(TARGETS, 
        function(t) return CanControl(t) and UnitIsPlayer(t) and not HasDebuff({"Оковы земли", "Ледяной шок"}, 0,1, t) and DoSpell("Ледяной шок", t) end
    ) then return end
        
end    

local useWolf = false
function MDDRotation()
    if IsLeftAltKeyDown() then
        if InCombatLockdown() and IsValidTarget("target") then
            useWolf = true
        end
    else
        if not InCombatLockdown() or not IsValidTarget("target") then
            useWolf = false
        end
    end
    
    if not (UnitAffectingCombat("target") or IsAttack()) then return end
    
    if GetInventoryItemID("player",16) and not DetermineTempEnchantFromTooltip(16) and UseSpell("Оружие неистовства ветра") then return end
    if GetInventoryItemID("player",17) and not DetermineTempEnchantFromTooltip(17) and UseSpell("Оружие языка пламени") then return end
    if not UnitAffectingCombat("target") and (not HasBuff("Водный щит") or UnitMana100("player") > 50) then
        if not HasBuff("Щит молний") and DoSpell("Щит молний") then return end
    end
    
    if (not HasBuff("Водный щит") and UnitMana100("player") < 30) and not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
    
    if not IsValidTarget("target") then return end
    RunMacroText("/startattack")
    if (useWolf or UnitHealth100("player") < 40) and DoSpell("Дух дикого волка") then return end
    if not ActualDistance() and IsAttack() then
        if UnitAffectingCombat("target") then
            if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок") then return end
            if DoSpell("Земной шок") then return end
        end 
        if PlayerInPlace() then
            if IsAOE() then
                if DoSpell("Цепная молния") then return end
            end
            if DoSpell("Молния") then return end
        end
    end
    
    if InMelee() and UseEquippedItem("Карманные часы Феззика") then return end
    if InMelee() and UseEquippedItem("Брошь в виде розы с шипами") then return end
    if IsAOE() and HasTotem(1) and DoSpell("Кольцо огня") then return end
    if GetBuffStack("Оружие Водоворота") == 5 then
        if IsAOE() then
            if DoSpell("Цепная молния") then return end
        end
        if DoSpell("Молния") then return end
    end
    if ((GetTime() - dispelTime > 5 or not PlayerInPlace())) and TrySteal("target") then dispelTime = GetTime() return end
    if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок") then return end
    if not HasBuff("Ярость шамана") and DoSpell("Ярость шамана") then return end
    if DoSpell("Удар бури") then return end
    if DoSpell("Земной шок") then return end
    if (not HasBuff("Водный щит") or UnitMana100("player") > 50) and not HasBuff("Щит молний") and DoSpell("Щит молний") then return end
    if DoSpell("Вскипание лавы") then return end
end

function RDDRotation()
    if not (UnitAffectingCombat("target") or IsAttack()) then return end
    if GetInventoryItemID("player",16) and not DetermineTempEnchantFromTooltip(16) and DoSpell("Оружие языка пламени") then return end
    if not UnitAffectingCombat("target") then
        if not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
    end
    if not IsValidTarget("target") then return end
    RunMacroText("/startattack")
    if (GetTime() - dispelTime > 5 or not PlayerInPlace()) and TrySteal("target") then dispelTime = GetTime() return end
    if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок") then return end
    if HasMyDebuff("Огненный шок", 2,"target") and DoSpell("Выброс лавы") then return end
    if IsAOE() and DoSpell("Цепная молния") then return end
    if IsAOE() and HasTotem(1) and DoSpell("Кольцо огня") then return end
    if DoSpell("Молния") then return end
    if not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
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
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target)  then 
                found = true 
                RunMacroText("/startattack " .. target) 
            end
        end

        if not ActualDistance("target") or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end

    end

    if  not IsValidTarget("target") then
        if GetNextTarget() ~= nil then
            RunMacroText("/startattack "..GetNextTarget())
            if not ActualDistance("target") or not NextIsTarget() or not UnitCanAttack("player", "target") then
                RunMacroText("/cleartarget")
            end
            ClearNextTarget()
        end
    end

    if not IsValidTarget("target") then
        RunMacroText("/targetenemy [nodead]")
        
        if not IsAttack() and not ActualDistance("target") or not UnitCanAttack("player", "target") then
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
    local h = CalculateHP("player")
    if InCombatLockdown() then
        if (h < 30) and DoSpell("Кровь земли", "player") then return end
        if (h < 40) and DoSpell("Дар наару", "player") then return end
        if not IsArena() and UnitMana100() < 10 and UseItem("Рунический флакон с зельем маны") then return true end
        if not IsArena() and UnitMana100() < 20 and UseItem("Бездонный флакон с зельем маны") then return true end
        if h < 70 and DoSpell("Дар наару", "player") then return true end
        if GetBuffStack("Оружие Водоворота") == 5 then
            if h < 60 and DoSpell("Волна исцеления", "player") then return true end
        end
        if h < 50 and UseHealPotion() then return true end
        if h < 30 and PlayerInPlace() and DoSpell("Малая волна исцеления", "player") then return true end
    end
    return false;
end
