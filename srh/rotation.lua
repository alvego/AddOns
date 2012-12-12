-- Shaman Rotation Helper by Timofeev Alexey
local StartTime = GetTime()
local StartComatTime = 0
local TryResUnit = nil
local TryResTime = 0
local ThreatEnd = 0
local ThreatList = {}
local harmTarget = {}
local units = {}


local totemTime, needTotems = GetTime(), false
function TryTotems()
    if not IsLeftControlKeyDown() and IsMouseButtonDown(3) then
        needTotems = true
    else
        if not InCombatLockdown() or not CanAutoTotems() then
            needTotems = false
        end 
    end
        
    if (not needTotems or (GetTime() - totemTime < 2) or InGCD() or (not PlayerInPlace() and not IsAOE())) then return false end
    
    local fire, earth, water, air = 1,2,3,4
    local force = {}
    local totem = {}
    local earthTotems, fireTotems, waterTotems, airTotems = {}, {}, {}, {}
    
    -- earth
    if not InNotMyTotemRange("Тотем каменной кожи") and not HasBuff("Аура благочестия") then
        local priority = 10
        if IsHeal() then priority = 20 end
        table.insert(earthTotems, { N = "Тотем каменной кожи", P = priority })
    end
    if not InNotMyTotemRange("Тотем силы земли") and not HasBuff("Зимний горн") then
        local priority = 10
        if IsMDD() then priority = 20 end
        table.insert(earthTotems, { N = "Тотем силы земли", P = priority })
    end
    if IsReadySpell("Тотем каменного когтя") and UnitThreatAlert("player") > 2 then
        table.insert(earthTotems, { N = "Тотем каменного когтя", P = 100 })
        force[earth] = true
    end
    if HasTotem("Тотем каменного когтя") then force[earth] = true end
    if not InNotMyTotemRange("Тотем трепета") then
        local priority = 10
        if IsPvP() then priority = 40 end
        table.insert(earthTotems, { N = "Тотем трепета", P = priority })
    end
    if not InNotMyTotemRange("Тотем оков земли") then
        local priority = 10
        if IsPvP() then priority = 30 end
        if IsAOE() and not PlayerInPlace() then 
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
    if not InNotMyTotemRange("Тотем языка пламени") and not HasBuff("Чародейская гениальность Даларана") and not HasBuff("Чародейский интеллект") then
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
        table.insert(fireTotems, { N = "Тотем магмы", P = 30 })
    end
    if #fireTotems > 0 then
        table.sort(fireTotems, function(x,y) return x.P > y.P end)
        totem[fire] = fireTotems[1].N
    else
        totem[fire] = nil
    end
    --water
    if not InNotMyTotemRange("Тотем источника маны") and (UnitMana100("player") < 50) and not HasBuff("Групповая охота") then
        local priority = 10
        if UnitMana100("player") < 50 then priority = 20 end
        table.insert(waterTotems, { N = "Тотем источника маны", P = priority })
    end
    if HasSpell("Тотем прилива маны") and IsReadySpell("Тотем прилива маны") and not InNotMyTotemRange("Тотем прилива маны") and UnitHealth100() < 70 then
        table.insert(waterTotems, { N = "Тотем прилива маны", P = 100 })
        if not HasTotem("Тотем прилива маны") then force[water] = true end
    end
    if not InNotMyTotemRange("Тотем исцеляющего потока") then
        table.insert(waterTotems, { N = "Тотем исцеляющего потока", P = 15 })
    end
    if not InNotMyTotemRange("Тотем очищения") then
        local priority = 10
        if IsPvP() then priority = 70 end
        table.insert(waterTotems, { N = "Тотем очищения", P = priority })
    end
    if #waterTotems > 0 then
        table.sort(waterTotems, function(x,y) return x.P > y.P end)
        totem[water] = waterTotems[1].N
    else
        totem[water] = nil
    end
    --air
    if not InNotMyTotemRange("Тотем неистовства ветра") and not HasBuff("Цепкие ледяные когти") then
        local priority = 10
        if IsMDD() then priority = 20 end
        table.insert(airTotems, { N = "Тотем неистовства ветра", P = priority })
    end
    if not InNotMyTotemRange("Тотем гнева воздуха") and not HasBuff("Цепкие ледяные когти") then
        local priority = 15
        table.insert(airTotems, { N = "Тотем гнева воздуха", P = priority })
    end
    if IsReadySpell("Тотем заземления") and (IsPvP() or UnitThreatAlert("player") > 2) then
        local priority = 10
        if IsPvP() then priority = 25 end
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
        local t, s = HasTotem(i), 132 + i
        if not force[i] and (t and InMyTotemRange(t)) then 
            SetMultiCastSpell(s) 
        else 
            if totem[i] then
                SetMultiCastSpell(s, GetSpellId(totem[i]))  
                try = true
            end
        end
    end
    
    if try and DoSpell("Зов Стихий") then
        totemTime = GetTime()
        return true 
    end
   
    return false
end


function Idle()
    if not InCombatLockdown() then StartComatTime = GetTime() end
    if GetTime() - StartTime < 2 then return end
    harmTarget = GetHarmTarget()
    units = GetUnitNames() 
    
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted() or HasBuff("Призрачный волк")) then return end
    if (IsRightControlKeyDown() == 1) and not (FindAura("Героизм")) and UseSpell("Героизм") then return end
    
    if IsLeftControlKeyDown() and IsMouseButtonDown(3) then
        if CanRes("mouseover") then
            TryResUnit = UnitPartyName("mouseover")
            TryResTime = GetTime()
            Notify("Пробуем воскресить " ..UnitName(TryResUnit) .. "("..TryResUnit..")")
        else
            local name = UnitName("mouseover")
            if name then print("Не могу реснуть", name) end
        end
    end
    
    if TryResUnit and (not CanRes(TryResUnit) or (CanRes(TryResUnit) and (GetTime() - TryResTime) > 60) or not PlayerInPlace())  then
        if UnitName(TryResUnit) and not CanHeal(TryResUnit) then Notify("Не удалось воскресить " .. UnitName(TryResUnit)) end
        TryResUnit = nil
        TryResTime = 0
    end
    if TryResUnit and CanRes(TryResUnit) and TryRes(TryResUnit) then return end
            
    if not InCombatLockdown() and #ThreatList > 0 then wipe(ThreatList) end
    if InCombatLockdown() and InGroup() and (UnitThreat("player") == 3) and GetTime() - ThreatEnd > 30 then 
        local ret = false
        for _,t in pairs(harmTarget) do 
            local g = UnitGUID(t)
            if not ret and IsValidTarget(t) and UnitAffectingCombat(t) and IsOneUnit(t.."-target", "player") and  UnitHealth(t) > 14000 then 
                if not ThreatList[g]  then ThreatList[g] = GetTime() end
                if ThreatList[g] and (GetTime() - ThreatList[g]) > 5 then 
                    RunMacroText("/к СНИМИТЕ ЕГО С МЕНЯ!!!!")
                    RunMacroText("/helpme")
                    ThreatEnd = GetTime()
                    ret = true 
                end
            else
                if ThreatList[g]  then ThreatList[g] = nil end
            end 
        end
    end
    
    

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
    if UnitThreatAlert(unit) == 3 then lost = lost * 1.5 end
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

local manaEnd = 0
local hpEnd = 0
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

    if IsLeftControlKeyDown() and IsAttack() and IsValidTarget("target") and not HasDebuff("Сглаз", 1, "target") then
        DoSpell("Природная стремительность")
        if DoSpell("Сглаз", "target") then return end
    end
        
    if IsLeftShiftKeyDown() and IsAttack() then
        if not HasTotem(1) and DoSpell("Тотем языка пламени") then return end
        if HasTotem(1) and DoSpell("Кольцо огня") then return end
    end
    
    

    if IsAttack() then 
        if not IsInteractTarget("target") then TryTarget(false) end
        if not InCombatLockdown() and not HasBuff("Щит земли") and DoSpell("Щит земли") then return end
    else
        if InCombatLockdown() and UnitName("target") and not IsInteractTarget("target") and not IsOneUnit("target-target", "player") and UnitThreat("player") == 3 then
            RunMacroText("/cleattarget")
        end
    end
    
    local myHP = CalculateHP("player")
    if InCombatLockdown() then
        if myHP < 50 and DoSpell("Дар наару", "player") then return end
        if myHP < 20 and UseHealPotion() then return end
        if UnitMana100() < 25 and UseItem("Рунический флакон с зельем маны") then return true end
        if UnitMana100() < 31 and UseItem("Бездонный флакон с зельем маны") then return true end
        if UnitMana100() < 70 and DoSpell("Тотем прилива маны") then return true end
    end

    local RiptideHeal = GetMySpellHeal("Быстрина")
    local ChainHeal = GetMySpellHeal("Цепное исцеление")
    local HealingWaveHeal = GetMySpellHeal("Волна исцеления")
    local LesserHealingWaveHeal = GetMySpellHeal("Волна исцеления")
    
    local members = {}
   
    if not IsPvP() and PlayerInPlace() and not InCombatLockdown() then
        if myHP < 55 then 
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

            if not InCombatLockdown() and IsAttack() and IsOneUnit(u, "mouseover") then 
                h = h - 56 
            end
            
            if IsOneUnit(u, "player") then 
                h = h - 1 
            end
            
            if (u:match("pet")) then
                if UnitAffectingCombat("player") then 
                    h = h * 1.5
                end
            else
                if UnitThreat(u) == 3 then h = h - 10 end
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
                and d < 12.5 
                and jl > ChainHeal / 4 then
                c = c + 1 
            end
        end
        
        rUnits[u] = c
        
        if h < 67 then lowhpmembers = lowhpmembers + 1 end
   end 

    if InCombatLockdown() and UnitPowerType("player") == 0 and UnitMana100() < 9 and GetTime() - manaEnd > 120 then 
        RunMacroText("/с Недостаточно маны...")
        RunMacroText("/oom")
        manaEnd = GetTime()
    end
    
    if InCombatLockdown() and myHP < 25 and (UnitThreat("player") == 3) and GetTime() - hpEnd > 120 then 
        RunMacroText("/с Ааааааа! Хила убиваааают!")
        RunMacroText("/helpme")
        hpEnd = GetTime()
    end        
    
   
    local u, h, l = members[1].Unit, members[1].HP, members[1].Lost
    CheckHealCast(u, h)

    if UnitPowerType("player") == 0 and UnitMana100() < 70 and not InCombatLockdown() and not(UnitAffectingCombat(u)) then return end
    
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
        if unitWithShield and UnitThreatAlert(unitWithShield) < 3 then
            shieldChangeTime = GetTime() - 2
            unitWithShield = nil
        end
        if not unitWithShield and DoSpell("Щит земли", threatLowHPUnit) then return end
        
        if unitWithShield and not IsOneUnit(unitWithShield, threatLowHPUnit) and threatLowHP < 65 and (GetTime() - shieldChangeTime > 6) and DoSpell("Щит земли", threatLowHPUnit) then 
            shieldChangeTime = GetTime()
            return
        end
    end
    
    if h > 70 and CanUseInterrupt() then
        local ret = false
        for key,value in pairs(GetHarmTarget()) do if not ret and TryInterrupt(value) then ret = true end end
        if ret then return end
    end
    
    if h > 60 and CanUseInterrupt() then
        local ret = false
        for key,value in pairs(GetHarmTarget()) do if not ret and TrySteal(value) then ret = true end end
        if ret then return end
    end 
    
    if h > 20 and CanUseInterrupt() then
        local ret = false
        for i=1,#members do if not ret and TryDispel(members[i].Unit) then ret = true end end
        if ret then return end
    end 
    
    
    if HasSpell("Быстрина") and IsReadySpell("Быстрина") then
        local ret = false
        for i=1,#members do 
            if not ret and not HasMyBuff("Быстрина",1,members[i].Unit) and (members[i].Lost > RiptideHeal) and DoSpell("Быстрина", u) then ret = true end end
        if ret then return end
    end

    if InCombatLockdown() then
        if h < 80 and DoSpell("Дар наару", "player") then return end
        if lowhpmembers > 0 and UseEquippedItem("Руна конечной вариации") then return end
        if lowhpmembers > 0 and UseEquippedItem("Брошь в виде розы с шипами") then return end
        if (h < 45 or lowhpmembers > 2) and HasSpell("Природная стремительность") and DoSpell("Природная стремительность") then  return end
        if (h < 65 or lowhpmembers > 1) and HasSpell("Сила прилива") and DoSpell("Сила прилива") then return end
    end

    --local RiptideHeal = GetMySpellHeal("Быстрина")
    --local ChainHeal = GetMySpellHeal("Цепное исцеление")
    --local HealingWaveHeal = GetMySpellHeal("Волна исцеления")
    --local LesserHealingWaveHeal = GetMySpellHeal("Волна исцеления")
    
    if PlayerInPlace() then
        if h > 30 and rUnits[u] > 1 and not IsPvP() and l > ChainHeal and DoSpell("Цепное исцеление", u) then return end 
        if h > 30 and rUnits[u] > 2 and IsPvP() and (UnitThreatAlert("player") < 3) and l > ChainHeal and DoSpell("Цепное исцеление", u) then return end 
        if h < 20 and DoSpell("Малая волна исцеления", u) then return end
        if (l > LesserHealingWaveHeal) and HasMyBuff("Приливные волны", 2, u) and DoSpell("Малая волна исцеления", u) then return end
        if IsPvP() and (l > LesserHealingWaveHeal) and not (l > HealingWaveHeal) and DoSpell("Малая волна исцеления", u) then return end 
        if UnitThreatAlert("player") < 3 and (l > HealingWaveHeal) and DoSpell("Волна исцеления", u) then return end
        if (l > LesserHealingWaveHeal) and DoSpell("Малая волна исцеления", u) then return end 
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
    if TotemCount() > 1 and not HasTotem(3) and DoSpell("Тотем исцеляющего потока") then return end
    if TotemCount() > 1 and not HasTotem(4) and DoSpell("Тотем неистовства ветра") then return end
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
    if IsAOE() and (not HasTotem(1) or (IsShiftKeyDown() and not HasTotem("Тотем магмы"))) and DoSpell("Тотем магмы") then return end
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
    if TotemCount() > 1 and not HasTotem(3) and DoSpell("Тотем источника маны") then return end
    if TotemCount() > 1 and not HasTotem(4) and DoSpell("Тотем гнева воздуха") then return end
    if not IsValidTarget("target") then return end
    RunMacroText("/startattack")
    if TrySteal("target") then return end
    if not HasMyDebuff("Огненный шок", 0.5,"target") and DoSpell("Огненный шок") then return end
    if HasMyDebuff("Огненный шок", 2,"target") and DoSpell("Выброс лавы") then return end
    if IsAOE() and DoSpell("Цепная молния") then return end
    if IsAOE() and not HasTotem(1) and DoSpell("Тотем магмы") then return end
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
