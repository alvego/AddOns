-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local TotemAlert = {}
function TryTotems(forceTotems)

    if forceTotems then
        print("TryTotems:NeedTotems = true")
        NeedTotems = true
    else
        if NeedTotems and (NotInCombat(5) or not CanAutoTotems()) then
            print("TryTotems:NeedTotems = false")
            NeedTotems = false
        end 
    end
    if InGCD() then return false end

    local fire, earth, water, air = 1,2,3,4
    local force = {}
    local totem = {}
    local earthTotems, fireTotems, waterTotems, airTotems = {}, {}, {}, {}
    -------------------------------------------------------------------------------------------------------------
    -- earth
    --if not HasBuff("Каменная кожа") and not HasBuff("Аура благочестия") then
    if not IsPvP() and not HasBuff("Каменная кожа") then
        local priority = 10
        if IsHeal() then priority = 20 end
        table.insert(earthTotems, { N = "Тотем каменной кожи", P = priority })
    end
    if not IsPvP() and  not HasBuff("Сила земли") and not (HasClass(UNITS, {"DEATHKNIGHT"}) or HasBuff("Зимний горн"))then
        local priority = 10
        if IsMDD() then priority = 20 end
        table.insert(earthTotems, { N = "Тотем силы земли", P = priority })
    end
    if IsReadySpell("Тотем каменного когтя") and UnitThreatAlert("player") > 2 and not HasTotem("Тотем каменного когтя") then
        table.insert(earthTotems, { N = "Тотем каменного когтя", P = 100 })
        force[earth] = true
    end
    if HasTotem("Тотем каменного когтя") then force[earth] = true end
    if not HasTotem("Тотем трепета") and HasDebuff({"Страх", "Вой ужаса", "Устрашающий крик", "Контроль над разумом", "Глубинный ужас", "Ментальный крик"}, 1,UNITS) then 
        TotemAlert["Тотем трепета"] = GetTime() 
    end
    if IsReadySpell("Тотем трепета") then
        local priority = 10
        if not HasTotem("Тотем трепета") 
            and (HasClass(TARGETS, {"WARLOCK", "PRIEST"}) or (TotemAlert["Тотем трепета"] and GetTime() - TotemAlert["Тотем трепета"] < 10)) then 
            priority = 100 
            force[earth] = true
        end
        table.insert(earthTotems, { N = "Тотем трепета", P = priority })
    end
    if not HasTotem("Тотем оков земли") and (IsMouseButtonDown(1) == 1) then TotemAlert["Тотем оков земли"] = GetTime() end
    if not HasClass(TARGETS, {"WARLOCK", "PRIEST"}) and IsReadySpell("Тотем оков земли") then
        local priority = 9
        if IsPvP() then priority = 11 end
        if (TotemAlert["Тотем оков земли"] and GetTime() - TotemAlert["Тотем оков земли"] < 2) then 
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
    -------------------------------------------------------------------------------------------------------------
    --fire
    if not HasBuff("Тотем языка пламени")  then
        local priority = 10
        if IsHeal() then priority = 20 end
        table.insert(fireTotems, { N = "Тотем языка пламени", P = priority })
    end
    if not IsPvP() and IsReadySpell("Опаляющий тотем")  then
        local priority = 15
        if not InGroup() then priority = 25 end
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
    -------------------------------------------------------------------------------------------------------------
    --water
    if HasTotem("Тотем прилива маны") then Notify("Тотем прилива маны!!!") end
    if PlayerInPlace() and not HasTotem("Тотем прилива маны") and HasSpell("Тотем прилива маны") and IsReadySpell("Тотем прилива маны") and UnitMana100("player") < 70 then
        table.insert(waterTotems, { N = "Тотем прилива маны", P = 100 })
        force[water] = true
    end
    if IsReadySpell("Тотем исцеляющего потока") and not InRaid() then
        table.insert(waterTotems, { N = "Тотем исцеляющего потока", P = 15 })
    end
    if not HasTotem("Тотем очищения") and HasDebuff({"Disease", "Poison"}, 1,UNITS) then TotemAlert["Тотем очищения"] = GetTime() end
    if IsReadySpell("Тотем очищения") then
        local priority = 9
        if not HasTotem("Тотем очищения") and  HasClass(TARGETS, {"DEATHKNIGHT", "WARLOCK", "PRIEST", "ROGUE"}) 
            or (TotemAlert["Тотем очищения"] and GetTime() - TotemAlert["Тотем очищения"] < 3) then 
            priority = 90
            force[water] = true
        end
        table.insert(waterTotems, { N = "Тотем очищения", P = priority })
    end
    if not HasBuff("Источник маны") and not HasBuff("Групповая охота") then
        local priority = 10
        if UnitMana100("player") < 50 and not HasTotem("Тотем источника маны") then 
            priority = 50 
            force[water] = true 
        end
        table.insert(waterTotems, { N = "Тотем источника маны", P = priority })
    end
    if HasTotem("Тотем прилива маны") then
        force[water] = false
        wipe(waterTotems)
    end
    if #waterTotems > 0 then
        table.sort(waterTotems, function(x,y) return x.P > y.P end)
        totem[water] = waterTotems[1].N
    else
        totem[water] = nil
    end
    -------------------------------------------------------------------------------------------------------------
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
    if IsPvP() then 
        wipe(airTotems) 
        force[air] = false 
    end
    if #airTotems > 0 then
        table.sort(airTotems, function(x,y) return x.P > y.P end)
        totem[air] = airTotems[1].N
    else
        totem[air] = nil
    end
    -------------------------------------------------------------------------------------------------------------
    -- нужно поставить какой-то тотем, несмотря но то что NeedTotems = false (Экстренная ситуация)
    local forcedNow = TryEach(force, function(value) return value end) and not NeedTotems and InCombatLockdown()

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
        or (GetTime() - TotemTime < 2) -- или только недавно ставил
        or not InCombatLockdown() -- или не в бою
        or not PlayerInPlace()) then -- или на бегу
        return false 
    end

    --try totems
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
    if try then 
        if DoSpell("Зов Духов") then
            print(totemNames)
            TotemTime = GetTime()
        end
    else 
        TotemTime = GetTime()
    end

    return try
end