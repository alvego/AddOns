-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local TotemAlert = {}
local PlayerThreatTime = nil
ForceRoot = false
TotemTime, NeedTotems = GetTime(), false
function TryTotems(forceTotems)
    -- поставить независимо от наличия тотемов (например отбежал далеко)
    if forceTotems then
        -- обновлять тотемы по необходимости
        NeedTotems = true
    else
        if NeedTotems and (NotInCombat(5) or not CanAutoTotems()) then
            -- не обновлять тотемы
            NeedTotems = false
        end 
    end
    
    -- в гкд не поствить тотемы
    if InGCD() then return false end
    -------------------------------------------------------------------------------------------------------------
    -- индексы стихий
    local fire, earth, water, air = 1,2,3,4
    -- поставить независимо от наличия тотема данной стихии
    local force = {}
    -- текущий тотем (по стихии)
    local totem = {}
    -- тотемы по приоритету
    local earthTotems, fireTotems, waterTotems, airTotems = {}, {}, {}, {}
    -------------------------------------------------------------------------------------------------------------
    -- earth ----------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    if HasDebuff({
        "Страх", 
        "Вой ужаса", 
        "Устрашающий крик", 
        "Контроль над разумом", 
        "Глубинный ужас", 
        "Ментальный крик"}, 1,UNITS) or
        (IsPvP() and HasClass(TARGETS, {"WARLOCK", "PRIEST"})) then 
        
        TotemAlert["Тотем трепета"] = GetTime() 
    end
    local needTremor = (TotemAlert["Тотем трепета"] and GetTime() - TotemAlert["Тотем трепета"] < 5)
    -------------------------------------------------------------------------------------------------------------
    
    if not needTremor and not ForceRoot and not HasBuff("Каменная кожа") then
        local priority = 11
        if IsHeal() then priority = 20 end
        table.insert(earthTotems, { N = "Тотем каменной кожи", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    if not needTremor and not ForceRoot and not HasBuff("Сила земли") 
        and not (HasClass(UNITS, {"DEATHKNIGHT"}) or HasBuff("Зимний горн"))then
        local priority = 12
        if IsMDD() then priority = 20 end
        table.insert(earthTotems, { N = "Тотем силы земли", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    if not needTremor and (ForceRoot or IsPvP()) then
        
        local priority = 10
        
        if ForceRoot or HasTotem("Тотем оков земли") then
            TotemAlert["Тотем оков земли"] = GetTime()
        end
        
        if (TotemAlert["Тотем оков земли"] and GetTime() - TotemAlert["Тотем оков земли"] < 5) then
            priority = 25
        end
        
        if ForceRoot then
            force[earth] = true
            wipe(earthTotems)
        end
        
        if IsReadySpell("Тотем оков земли") then 
            if ForceRoot then priority = 90 end
            table.insert(earthTotems, { N = "Тотем оков земли", P = priority })
        end
    end
    -------------------------------------------------------------------------------------------------------------
    
    if needTremor then

        wipe(earthTotems)
        force[earth] = false
        
        if not HasTotem("Тотем трепета") and IsReadySpell("Тотем трепета") then
            force[earth] = true
        
            table.insert(earthTotems, { N = "Тотем трепета", P = 80 })
        end
    end
    -------------------------------------------------------------------------------------------------------------
    if UnitThreat("player") == 3 then
        if PlayerThreatTime == nil then PlayerThreatTime = GetTime() end
    else
        PlayerThreatTime = nil
    end
    
    if IsReadySpell("Тотем каменного когтя") 
        and not HasTotem("Тотем каменного когтя")
        and ((PlayerThreatTime and GetTime() - PlayerThreatTime > 3) 
            or (InCombatLockdown() and UnitHealth100("player") < 85)) then
        table.insert(earthTotems, { N = "Тотем каменного когтя", P = 100 })
        force[earth] = true
    end
    -------------------------------------------------------------------------------------------------------------
    -- sort air totems by priority
    -------------------------------------------------------------------------------------------------------------
    if #earthTotems > 0 then
        table.sort(earthTotems, function(x,y) return x.P > y.P end)
        totem[earth] = earthTotems[1].N
    else
        totem[earth] = nil
    end
    -------------------------------------------------------------------------------------------------------------
    -- fire -----------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    if not HasBuff("Тотем языка пламени") then
        local priority = 10
        
        if IsHeal() then 
            priority = 20 
        end
        
        table.insert(fireTotems, { N = "Тотем языка пламени", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    if not IsPvP() and IsValidTarget("target") and IsReadySpell("Опаляющий тотем")  then
        local priority = 15
        
        if not InGroup() then 
            priority = 25 
        end
        
        table.insert(fireTotems, { N = "Опаляющий тотем", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    if IsAOE() then
        local priority = 30
        
        if (not IsHeal() or IsAttack()) and IsLeftShiftKeyDown() and not HasTotem("Тотем магмы") then
            priority = 100
            force[fire] = true
        end
        
        table.insert(fireTotems, { N = "Тотем магмы", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    -- sort air totems by priority
    -------------------------------------------------------------------------------------------------------------
    if #fireTotems > 0 then
        table.sort(fireTotems, function(x,y) return x.P > y.P end)
        totem[fire] = fireTotems[1].N
    else
        totem[fire] = nil
    end
    -------------------------------------------------------------------------------------------------------------
    --water -----------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    if IsReadySpell("Тотем исцеляющего потока") and not InRaid() then
        table.insert(waterTotems, { N = "Тотем исцеляющего потока", P = 15 })
    end
    -------------------------------------------------------------------------------------------------------------
    if IsReadySpell("Тотем очищения") then
        local priority = 9
        if not HasTotem("Тотем очищения") 
            and (IsPvP() and HasClass(TARGETS, {"DEATHKNIGHT", "WARLOCK", "PRIEST", "ROGUE"}))
            or (not HasTotem("Тотем очищения") and IsDispelTotemNeed(UNITS)) then 
            priority = 90
            force[water] = true
        end
        table.insert(waterTotems, { N = "Тотем очищения", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    if not HasBuff("Источник маны") and not HasBuff("Групповая охота") then
        local priority = 10
        if not HasTotem("Тотем очищения") and UnitMana100("player") < 50 and not HasTotem("Тотем источника маны") then 
            priority = 50 
            force[water] = true 
        end
        table.insert(waterTotems, { N = "Тотем источника маны", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    if HasTotem("Тотем прилива маны") then
        force[water] = false
        wipe(waterTotems)
        Notify("Тотем прилива маны!!!")
    end
    
    if PlayerInPlace() and not HasTotem("Тотем прилива маны") and HasSpell("Тотем прилива маны") 
        and IsReadySpell("Тотем прилива маны") and UnitMana100("player") < 70 then
        table.insert(waterTotems, { N = "Тотем прилива маны", P = 100 })
        force[water] = true
    end
    -------------------------------------------------------------------------------------------------------------
    -- sort water totems by priority
    -------------------------------------------------------------------------------------------------------------
    if #waterTotems > 0 then
        table.sort(waterTotems, function(x,y) return x.P > y.P end)
        totem[water] = waterTotems[1].N
    else
        totem[water] = nil
    end
    -------------------------------------------------------------------------------------------------------------
    --air -------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    if not HasBuff("Тотем неистовства ветра") and not HasBuff("Цепкие ледяные когти") then
        local priority = 10
        if IsMDD() then priority = 20 end
        table.insert(airTotems, { N = "Тотем неистовства ветра", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    if not HasBuff("Тотем гнева воздуха") then
        local priority = 15
        table.insert(airTotems, { N = "Тотем гнева воздуха", P = priority })
    end
    -------------------------------------------------------------------------------------------------------------
    if IsPvP() and HasClass(TARGETS, {
        "PRIEST", 
        "SHAMAN", 
        "DRUID", 
        "MAGE", 
        "WARLOCK", 
        "HUNTER", 
        "DEATHKNIGHT" }) then 
        
        wipe(airTotems) 
        force[air] = false 
        
        if IsReadySpell("Тотем заземления") then
            table.insert(airTotems, { N = "Тотем заземления", P = 20 })
            force[air] = true 
        end
    end
    -------------------------------------------------------------------------------------------------------------
    -- sort air totems by priority
    -------------------------------------------------------------------------------------------------------------
    if #airTotems > 0 then
        table.sort(airTotems, function(x,y) return x.P > y.P end)
        totem[air] = airTotems[1].N
    else
        totem[air] = nil
    end
    -------------------------------------------------------------------------------------------------------------
    -- checks ---------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    -- нужно поставить какой-то тотем, несмотря но то что NeedTotems = false (Экстренная ситуация)
    local forcedNow = TryEach(force, function(value) return value end) 
                        and not NeedTotems 
                        and InCombatLockdown()
    
    
    if forcedNow then 
        -- оставляем только экстренные тотемы
        for i = 1, 4 do 
            if not force[i] then totem[i] = nil end
        end
    end
    
    -- нет критических тотемов или вообще NeedTotems = false (выходим)
    if not (forcedNow or NeedTotems) then 
        return false 
    end
    -- ничего настолько строчного, чтоб ставить тотемы
    if not (forcedNow or forceTotems) and (UnitHealth100("player") < 30 -- когда мало хп
        or not InCombatLockdown() -- или не в бою
        or not PlayerInPlace()) then -- или на бегу
        return false 
    end
    if (GetTime() - TotemTime < 2) then return false end -- или только недавно ставил
    -------------------------------------------------------------------------------------------------------------
    -- try totems -----------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    local try = false;
    
    local totemNames = 'Ставим '
    if forceTotems then totemNames = totemNames .. '{force} ' end
    
    for i = 1, 4 do
        local s = 140 + i
        if totem[i] and (force[i] or (forceTotems and not IsTotemPushedNow(i)) or (not HasTotem(i))) then
            SetMultiCastSpell(s, GetSpellId(totem[i]))  
            totemNames = totemNames .. '[' ..totem[i] .. '] '
            try = true
        else 
            SetMultiCastSpell(s)
        end
    end
    -------------------------------------------------------------------------------------------------------------
    if try then 
    
        if DoSpell("Зов Духов") then
            print(totemNames)
            TotemTime = GetTime()
        end
        
    else 
        TotemTime = GetTime()
    end
    -------------------------------------------------------------------------------------------------------------
    return try
end