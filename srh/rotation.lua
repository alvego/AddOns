-- Shaman Rotation Helper by Timofeev Alexey
-- Жабу под конец покаяния
-- Геру под крылья и стан
local StartTime = GetTime()
local StartComatTime = 0
local TryResUnit = nil
local TryResTime = 0
local harmTarget = {}
local units = {}

SetCommand("hero", 
    function() 
        if DoSpell("Героизм") then
            print("Гера!")
        end
    end, 
    function() 
        return not InCombatLockdown() or HasDebuff("Изнеможение", 1, "player") or (not InGCD() and not IsReadySpell("Героизм")) 
    end
)
SetCommand("hex", 
    function() 
--[[        if HasSpell("Природная стремительность") then 
            DoSpell("Природная стремительность") 
        end]]
        if DoSpell("Сглаз") then
            print("Сглаз")
        end
    end, 
    function() 
        if not IsValidTarget("target") or HasDebuff("Сглаз", 1, "target") or (not InGCD() and not IsReadySpell("Сглаз"))  then return true end
        if not UnitIsPlayer("target") then
            local creatureType = UnitCreatureType("target")
            if creatureType ~= "Humanoid" or creatureType ~= "Beast" then return true end
        end
        return false
    end
)

SetCommand("freedom", 
    function() return UseEquippedItem("Медальон Альянса") end, 
    function() local item = "Медальон Альянса" return not IsEquippedItem(item) or (not InGCD() and not IsReadyItem(item)) end
)

local tryMount = false
SetCommand("mount", 
    function() 
        if InCombatLockdown() or IsArena() or not PlayerInPlace() then
            return DoSpell("Призрачный волк") 
        end
        if (IsLeftControlKeyDown() or IsSwimming()) and not HasBuff("Хождение по воде", 1, "player") and DoSpell("Хождение по воде", "player") then return end
        if InGCD() or IsPlayerCasting() or InCombatLockdown() or not IsOutdoors() then return false end
        local mount = "Большой Лиловый элекк"
        if IsFlyableArea() and not IsLeftControlKeyDown() then mount = "Черный дракон" end
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then tryMount = true return end
    end, 
    function() 
        if (HasBuff("Призрачный волк") or IsMounted() or CanExitVehicle()) then return true end
        if tryMount then
            tryMount = false
            return true
        end
        return false 
    end
)

SetCommand("dismount", 
    function() 
        if HasBuff("Призрачный волк") then RunMacroText("/cancelaura Призрачный волк") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end, 
    function() 
        return not (HasBuff("Призрачный волк") or IsMounted() or CanExitVehicle())
    end
)

local totemTime, needTotems = GetTime(), false, false
SetCommand("totems", 
    function() 
        return TryTotems(true)
    end, 
    function() 
        return (GetTime() - totemTime < 0.5)
    end
)



function TryTotems(forceTotems)

    if forceTotems then
        needTotems = true
    else
        if not InCombatLockdown() or not CanAutoTotems() then
            needTotems = false
        end 
    end
     
    if not needTotems or InGCD() then return false end
    if not PlayerInPlace() and not forceTotems then return false end
    
    local fire, earth, water, air = 1,2,3,4
    local force = {}
    local totem = {}
    local earthTotems, fireTotems, waterTotems, airTotems = {}, {}, {}, {}
    
    -- earth
    if not HasBuff("Каменная кожа") and not HasBuff("Аура благочестия") then
        local priority = 10
        if IsHeal() then priority = 20 end
        table.insert(earthTotems, { N = "Тотем каменной кожи", P = priority })
    end
    if not HasBuff("Сила земли") and not HasClass(units, {"DEATHKNIGHT"}) then
        local priority = 10
        if IsMDD() then priority = 20 end
        table.insert(earthTotems, { N = "Тотем силы земли", P = priority })
    end
    if IsReadySpell("Тотем каменного когтя") and UnitThreatAlert("player") > 2 then
        table.insert(earthTotems, { N = "Тотем каменного когтя", P = 100 })
        force[earth] = true
    end
    if HasTotem("Тотем каменного когтя") then force[earth] = true end
    if IsReadySpell("Тотем трепета") then
        local priority = 10
        if HasClass(harmTarget, {"WARLOCK", "PRIEST"}) or HasDebuff({"Страх", "Вой ужаса", "Устрашающий крик", "Контроль над разумом", "Глубинный ужас", "Ментальный крик"}, 1,units) then 
            priority = 100 
            force[earth] = true
        end
        table.insert(earthTotems, { N = "Тотем трепета", P = priority })
    end
    if IsReadySpell("Тотем оков земли") then
        local priority = 10
        if IsPvP() then priority = 30 end
        if not PlayerInPlace() then 
            priority = 90 
            force[earth] = true
        end
        table.insert(earthTotems, { N = "Тотем оков земли", P = priority })
    end
    if #earthTotems > 0 then
        table.sort(earthTotems, function(x,y) return x.P > y.P end)
        totem[earth] = earthTotems[1].N
    else
        totem[earth] = nil
    end
    --fire
    if IsReadySpell("Тотем языка пламени") and not HasBuff("Чародейская гениальность Даларана") and not HasBuff("Чародейский интеллект") then
        local priority = 10
        if IsHeal() then priority = 20 end
        table.insert(fireTotems, { N = "Тотем языка пламени", P = priority })
    end
    if IsReadySpell("Опаляющий тотем")  then
        local priority = 15
        if IsPvP() then priority = 25 end
        table.insert(fireTotems, { N = "Опаляющий тотем", P = priority })
    end
    if IsAOE() then
        local priority = 30
        if (not IsHeal() or IsAttack()) and IsLeftShiftKeyDown() and not HasTotem("Тотем магмы") then
            priority = 100
            force[fire] = true
        end
        table.insert(fireTotems, { N = "Тотем магмы", P = priority })
    end
    if #fireTotems > 0 then
        table.sort(fireTotems, function(x,y) return x.P > y.P end)
        totem[fire] = fireTotems[1].N
    else
        totem[fire] = nil
    end
    --water
    if not HasBuff("Источник маны") and (UnitMana100("player") < 50) and not HasBuff("Групповая охота") then
        local priority = 10
        if UnitMana100("player") < 50 then priority = 20 end
        table.insert(waterTotems, { N = "Тотем источника маны", P = priority })
    end
    if HasSpell("Тотем прилива маны") and IsReadySpell("Тотем прилива маны") and UnitHealth100() < 70 then
        table.insert(waterTotems, { N = "Тотем прилива маны", P = 100 })
        if not HasTotem("Тотем прилива маны") then force[water] = true end
    end
    if IsReadySpell("Тотем исцеляющего потока") then
        table.insert(waterTotems, { N = "Тотем исцеляющего потока", P = 15 })
    end
    if IsReadySpell("Тотем очищения") then
        local priority = 10
        if HasClass(harmTarget, {"DEATHKNIGHT", "WARLOCK", "PRIEST", "ROGUE"}) or HasDebuff({"Disease", "Poison"}, 1,units) then 
            priority = 100 
            force[waterTotems] = true
        end
        table.insert(waterTotems, { N = "Тотем очищения", P = priority })
    end
    if #waterTotems > 0 then
        table.sort(waterTotems, function(x,y) return x.P > y.P end)
        totem[water] = waterTotems[1].N
    else
        totem[water] = nil
    end
    --air
    if not HasBuff("Тотем неистовства ветра") and not HasBuff("Цепкие ледяные когти") then
        local priority = 10
        if IsMDD() then priority = 20 end
        table.insert(airTotems, { N = "Тотем неистовства ветра", P = priority })
    end
    if not HasBuff("Тотем гнева воздуха") then
        local priority = 15
        table.insert(airTotems, { N = "Тотем гнева воздуха", P = priority })
    end
    if IsReadySpell("Тотем заземления") and (IsPvP() or UnitThreatAlert("player") > 2) then
        local priority = 10
        if IsPvP() then 
            priority = 100 
            force[air] = true
        end
        table.insert(airTotems, { N = "Тотем заземления", P = priority })
    end
    if #airTotems > 0 then
        table.sort(airTotems, function(x,y) return x.P > y.P end)
        totem[air] = airTotems[1].N
    else
        totem[air] = nil
    end
    --try totems
    local try = false;
    for i = 1, 4 do
        local s = 140 + i
        if totem[i] then
            if force[i] or (forceTotems and not IsTotemPushedNow(i)) or (not HasTotem(i)) then
                SetMultiCastSpell(s, GetSpellId(totem[i]))  
                try = true
            else 
                SetMultiCastSpell(s)
            end
        end
    end
    
    if try and DoSpell("Зов Духов") then
        totemTime = GetTime()
    end
    return try
end


function Idle()
    if not InCombatLockdown() then StartComatTime = GetTime() end
    if GetTime() - StartTime < 3 then return end
    harmTarget = GetHarmTarget()
    units = GetUnitNames() 
    
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted() or HasBuff("Призрачный волк")) then return end
    
    
    if TryTotems() then return end
    
    if IsLeftControlKeyDown() and IsMouseButtonDown(3) then
        if CanRes("mouseover") then
            TryResUnit = UnitPartyName("mouseover")
            TryResTime = GetTime()
            Notify("Пробуем воскресить " ..UnitName(TryResUnit) .. "("..TryResUnit..")")
        else
            local name = UnitName("mouseover")
            if name and UnitIsPlayer("mouseover") then print("Не могу реснуть", name) end
        end
    end
    
    if TryResUnit and (not CanRes(TryResUnit) or (CanRes(TryResUnit) and (GetTime() - TryResTime) > 60) or not PlayerInPlace())  then
        if UnitName(TryResUnit) and not CanHeal(TryResUnit) then Notify("Не удалось воскресить " .. UnitName(TryResUnit)) end
        TryResUnit = nil
        TryResTime = 0
    end
    if TryResUnit and CanRes(TryResUnit) and TryRes(TryResUnit) then return end
    
    if IsHeal() then 
        HealRotation() 
        return
    end
    
    if (IsAttack() or InCombatLockdown()) then
    
        if CanUseInterrupt() then
            local ret = false
            for key,value in pairs(harmTarget) do if not ret and TryInterrupt(value) then ret = true end end
            if ret then return end
        end 
           
        if InCombatLockdown() and UnitHealth100() < 31 and UseHealPotion() then return end
        
        if TryProtect() then return end

        if TryDispel("player") then return end
        TryTarget()
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

function CanHeal(t)
    if IsInteractTarget(t) 
        and InRange("Волна исцеления", t)
        and IsVisible(t)
    then return true end 
    return false
end   


function UnitLostHP(unit)
    local hp = UnitHP(unit)
    local maxhp = UnitHealthMax(unit)
    local lost = maxhp - hp
    if UnitThreat(unit) == 3 then lost = lost * 1.2 end
    return lost
end

function CheckHealCast(u, h)
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo("player")
    local lastHealCastTarget = GetLastHealCastTarget()
    if not lastHealCastTarget then return end
    if UnitThreatAlert(lastHealCastTarget) == 3 then return end
    if not spell or not endTime then return end
    if not IsHealCast(spell) then return end
    if not InCombatLockdown() then return end
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


local shieldChangeTime = 0
function HealRotation()
    --CalculateHealing
    if GetInventoryItemID("player",16) and not DetermineTempEnchantFromTooltip(16) and DoSpell("Оружие жизни земли") then return end
    
    if IsAttack() and not IsAltKeyDown() and not IsLeftShiftKeyDown() and IsValidTarget("target") and UnitAffectingCombat("target") then
        if UnitIsPlayer("target") then 
            if DoSpell("Ледяной шок") then return end
        else
            if HasMyDebuff("Огненный шок", 1, "target") and PlayerInPlace() then
                if DoSpell("Земной шок") then return end
            else
                if DoSpell("Огненный шок") then return end
            end
        end
    end    

    if IsAttack() then 
        if not IsInteractTarget("target") then TryTarget(false) end
        if IsLeftShiftKeyDown() and HasTotem(1) and DoSpell("Кольцо огня") then return end
    else
        if InCombatLockdown() and UnitName("target") and not IsInteractTarget("target") and not IsOneUnit("target-target", "player") and UnitThreat("player") == 3 then
            RunMacroText("/cleattarget")
        end
    end
    
    local myHP = CalculateHP("player")
    
    if myHP < 50 and DoSpell("Дар наару", "player") then return end
    if InCombatLockdown() then
        if myHP < 40 and UseHealPotion() then return end
        if UnitMana100() < 25 and UseItem("Рунический флакон с зельем маны") then return true end
        if UnitMana100() < 31 and UseItem("Бездонный флакон с зельем маны") then return true end
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
        for i=1,#units do
           if not res and TryRes(units[i]) then res = true end
        end
        if res then return end
        
        for i=1,#units do
           if CanRes(units[i]) then needRes = true end
        end
        if res then return end
    end
    
           
    for i=1,#units do
        local u = units[i]
        if CanHeal(u) then  
            h =  CalculateHP(u)

            if IsOneUnit(u, "player") then 
                h = h  - ((100 - h) * 1.2) 
            end
            
            if UnitIsPet(u) then
                if UnitAffectingCombat("player") then 
                    h = h * 1.5
                end
            else
                if UnitThreat(u) == 3 then h = h - 5 end
                if HasBuff("Частица Света", 1, u) then h = h + 3 end
                if HasBuff("Щит земли", 1, u) then h = h + 3 end
                if  myHP < 50 and not IsOneUnit("player", u) and not (UnitThreat(u) == 3) then
                    h = h + 40
                end
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
        
        if (UnitThreatAlert(u) == 3) and (hp < threatLowHP) then
           threatLowHPUnit = u  
           threatLowHP = hp  
        end

        for j=1,#members do
            local ju, jl = members[j].Unit, members[j].Lost
            local d = CheckDistance(u, ju)
            
            if not IsOneUnit("player", ju) 
                and not IsOneUnit("player", u) 
                and d 
                and d < 10 --12.5
                and jl > ChainHeal / 4 then
                c = c + 1 
            end
        end
        
        rUnits[u] = c
        
        if h < 40 then lowhpmembers = lowhpmembers + 1 end
   end 
    if #members < 1 then print("Некого лечить!!!") return end
    local u, h, l = members[1].Unit, members[1].HP, members[1].Lost
    CheckHealCast(u, h)

    if not IsAttack() and CanHeal("focus") and h > 40  and CalculateHP("focus") < 100 then
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
    
    if threatLowHPUnit and (GetTime() - StartComatTime > 3) then
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
    
    if IsArena() and not unitWithShield and DoSpell("Щит земли", "player") then return end
    
    if (h > 70 or IsArena()) and CanUseInterrupt() then
        local ret = false
        for key,value in pairs(harmTarget) do if not ret and TryInterrupt(value) then ret = true end end
        if ret then return end
    end
    
    if (h > 60 or IsArena()) and CanUseInterrupt() then
        local ret = false
        for key,value in pairs(harmTarget) do if not ret and TrySteal(value) then ret = true end end
        if ret then return end
    end 
    
    if (h > 20 or IsArena()) and CanUseInterrupt() then
        local ret = false
        for i=1,#members do if not ret and TryDispel(members[i].Unit) then ret = true end end
        if ret then return end
    end 
    
    
    if HasSpell("Быстрина") and IsReadySpell("Быстрина") then
        local ret = false
        for i=1,#members do 
            if not ret and not HasMyBuff("Быстрина",1,members[i].Unit) and (members[i].Lost > RiptideHeal) and DoSpell("Быстрина", members[i].Unit) then ret = true end end
        if ret then return end
    end

    if h < 80 and DoSpell("Дар наару", u) then return end
    if InCombatLockdown() then
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
    
    if PlayerInPlace() then
        if h > 30 and rUnits[u] > 1 and not IsPvP() and l > ChainHeal and DoSpell("Цепное исцеление", u) then return end 
        if h > 40 and rUnits[u] > 2 and IsBattleground() and (UnitThreatAlert("player") < 3) and l > ChainHeal and DoSpell("Цепное исцеление", u) then return end 
        if h < 20 and DoSpell("Малая волна исцеления", u) then return end
        if (l > LesserHealingWaveHeal) and not (l > HealingWaveHeal) and not HasMyBuff("Приливные волны", 0.1, "player") and DoSpell("Малая волна исцеления", u) then return end
        if IsPvP() and (l > LesserHealingWaveHeal) and DoSpell("Малая волна исцеления", u) then return end 
        if UnitThreatAlert("player") < 3 and (l > HealingWaveHeal) and DoSpell("Волна исцеления", u) then return end
    end
    
    if UnitMana100() < 80 and (GetTime() - StartTime > 3) and not HasBuff("Щит земли") and not HasBuff("Водный щит") and DoSpell("Водный щит") then return end
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
    if not UnitAffectingCombat("target") then
        if not HasBuff("Щит молний") and DoSpell("Щит молний") then return end
    end
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
    if TrySteal("target") then return end
    if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок") then return end
    if not HasBuff("Ярость шамана") and DoSpell("Ярость шамана") then return end
    if DoSpell("Удар бури") then return end
    if DoSpell("Земной шок") then return end
    if not HasBuff("Щит молний") and DoSpell("Щит молний") then return end
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
    if TrySteal("target") then return end
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
        local members = GetPartyOrRaidMembers()
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
   
    if useFocus and not IsValidTarget("focus") then
        local found = false
        for _,target in pairs(harmTarget) do 
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target) and not IsOneUnit("target", target) then 
                found = true 
                RunMacroText("/focus " .. target) 
            end
        end
    end

    if useFocus and not IsValidTarget("focus") or IsOneUnit("target", "focus") or not ActualDistance("focus") then
        RunMacroText("/clearfocus")
    end
end

function TryProtect()
    local h = CalculateHP("player")
    if InCombatLockdown() then
        if UnitMana100() < 10 and UseItem("Рунический флакон с зельем маны") then return true end
        if UnitMana100() < 10 and UseItem("Бездонный флакон с зельем маны") then return true end
        if h < 70 and DoSpell("Дар наару", "player") then return true end
        if GetBuffStack("Оружие Водоворота") == 5 then
            if h < 60 and DoSpell("Волна исцеления", "player") then return true end
        end
        if h < 50 and UseHealPotion() then return true end
        if h < 30 and PlayerInPlace() and DoSpell("Малая волна исцеления", "player") then return true end
    end
    return false;
end
