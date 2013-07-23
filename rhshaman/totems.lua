-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------

local TotemAlert = {}
local PlayerThreatTime
local fearDebuff = {"Страх", "Вой ужаса", "Устрашающий крик", "Контроль над разумом", "Глубинный ужас", "Ментальный крик"}
local fearClass = {"WARLOCK", "PRIEST"}
local diseaseClass = {"DEATHKNIGHT", "WARLOCK", "PRIEST", "ROGUE"}
local casterClass = {"PRIEST", "SHAMAN", "DRUID", "MAGE", "WARLOCK", "HUNTER", "DEATHKNIGHT"}
local importantTotems = {"Тотем трепета", "Тотем прилива маны", "Тотем источника маны"}
-- поставить независимо от наличия тотема данной стихии
local force = {}
-- текущий тотем (по стихии)
local totem, weight = {}, {}
-- индексы стихий
local fire, earth, water, air = 1,2,3,4
local function pushTotem(idx, name, w)
    if weight[idx] == nil or weight[idx] < w then
        totem[idx] = name
    end
end
ForceRoot = false
TotemTime, NeedTotems = GetTime(), false
function TryTotems(forceTotems, h)
    if h == nil then h = UnitHealth100("player") end
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
    wipe(force)
    wipe(totem)
    wipe(weight)

    -------------------------------------------------------------------------------------------------------------
    -- earth ----------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    if HasDebuff(fearDebuff, 1,UNITS) or
        (IsPvP() and HasClass(TARGETS, fearClass)) then 
        
        TotemAlert["Тотем трепета"] = GetTime() 
    end
    local needTremor = (TotemAlert["Тотем трепета"] and GetTime() - TotemAlert["Тотем трепета"] < 25)
    -------------------------------------------------------------------------------------------------------------
    
    if not (needTremor or ForceRoot or IsPvP()) 
        and not (HasBuff("Каменная кожа") and not HasTotem("Тотем каменной кожи")) then
        local priority = 11
        if IsHeal() then priority = 20 end
        pushTotem(earth, "Тотем каменной кожи", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    if not (needTremor or ForceRoot or IsPvP()) 
        and not (HasBuff("Сила земли") and not HasTotem("Тотем силы земли"))
        and not (HasClass(UNITS, "DEATHKNIGHT") or HasBuff("Зимний горн"))then
        local priority = 12
        if IsMDD() then priority = 20 end
        pushTotem(earth, "Тотем силы земли", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    if not HasTotem("Тотем трепета") and not needTremor and ForceRoot then
        force[earth] = true
        weight[earth] = nil
        if IsReadySpell("Тотем оков земли") then 
            pushTotem(earth, "Тотем оков земли", 90)
        end
    end
    -------------------------------------------------------------------------------------------------------------
    
    if needTremor or IsPvP() then
        weight[earth] = nil
        force[earth] = false
        if not HasTotem("Тотем трепета") and IsReadySpell("Тотем трепета") then
            if needTremor then force[earth] = true end
            pushTotem(earth, "Тотем трепета", 80)
        end
    end
    -------------------------------------------------------------------------------------------------------------
    if UnitThreat("player") == 3 then
        if PlayerThreatTime == nil then PlayerThreatTime = GetTime() end
    else
        PlayerThreatTime = nil
    end
    
    if h > 30 and IsReadySpell("Тотем каменного когтя") 
        and not HasTotem("Тотем каменного когтя")
        and (IsPvP() or (PlayerThreatTime and GetTime() - PlayerThreatTime > 3))
            and (InCombatLockdown() and UnitHealth100("player") < 98) then
        pushTotem(earth, "Тотем каменного когтя", 100)
        force[earth] = true
    end
    
    -------------------------------------------------------------------------------------------------------------
    -- fire -----------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    if not HasBuff("Тотем языка пламени") then
        local priority = 10
        
        if IsHeal() then 
            priority = 20 
        end
        pushTotem(fire, "Тотем языка пламени", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    if not IsPvP() and IsValidTarget("target") and IsReadySpell("Опаляющий тотем")  then
        local priority = 15
        
        if not InGroup() then 
            priority = 25 
        end
        pushTotem(fire, "Опаляющий тотем", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    if IsAOE() then
        local priority = 30
        
        if (not IsHeal() or IsAttack()) and IsLeftShiftKeyDown() and not HasTotem("Тотем магмы") then
            priority = 100
            force[fire] = true
        end
        pushTotem(fire, "Тотем магмы", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    --water -----------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    if not IsReadySpell("Тотем исцеляющего потока") and not InRaid() then
        pushTotem(water, "Тотем исцеляющего потока", 15)
    end
    -------------------------------------------------------------------------------------------------------------
    if IsReadySpell("Тотем очищения") then
        local priority = 9
        if not HasTotem("Тотем очищения") 
            and (IsPvP() and HasClass(TARGETS, diseaseClass))
            or (not HasTotem("Тотем очищения") and IsDispelTotemNeed(UNITS)) then 
            priority = 90
            force[water] = true
        end
        pushTotem(water, "Тотем очищения", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    if not HasBuff("Источник маны") and not HasBuff("Групповая охота") then
        local priority = 10
        if not HasTotem("Тотем очищения") and UnitMana100("player") < 50 and not HasTotem("Тотем источника маны") then 
            priority = 50 
            force[water] = true 
        end
        pushTotem(water, "Тотем источника маны", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    if HasTotem("Тотем прилива маны") then
        force[water] = false
        weight[water] = nil
        Notify("Тотем прилива маны!!!")
    end
    
    if PlayerInPlace() and not HasTotem("Тотем прилива маны") and HasSpell("Тотем прилива маны") 
        and IsReadySpell("Тотем прилива маны") and UnitMana100("player") < 70 then
        pushTotem(water, "Тотем прилива маны", 100)
        force[water] = true
    end
    
    -------------------------------------------------------------------------------------------------------------
    --air -------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    if not (HasBuff("Тотем неистовства ветра") and not HasTotem("Тотем неистовства ветра")) and not HasBuff("Цепкие ледяные когти") then
        local priority = 10
        if IsMDD() then priority = 20 end
        pushTotem(air, "Тотем неистовства ветра", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    if not (HasBuff("Тотем гнева воздуха") and not HasTotem("Тотем гнева воздуха")) then
        local priority = 15
        pushTotem(air, "Тотем гнева воздуха", priority)
    end
    -------------------------------------------------------------------------------------------------------------
    if IsPvP() and HasClass(TARGETS, casterClass) then 
        
        weight[air] = nil
        force[air] = false 
        
        if IsReadySpell("Тотем заземления") then
            pushTotem(air, "Тотем заземления", 20)
            force[air] = true 
        end
    end
    
    -------------------------------------------------------------------------------------------------------------
    -- checks ---------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------
    -- нужно поставить какой-то тотем, несмотря но то что NeedTotems = false (Экстренная ситуация)

    local forcedNow = false
    if not NeedTotems and InCombatLockdown() then
        for i = 1, 4 do 
            if force[i] then 
                forcedNow = true 
                break
            end
        end
    end
    
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
    if not (forcedNow or forceTotems) and (h < 30 -- когда мало хп
        or not InCombatLockdown() -- или не в бою
        or not PlayerInPlace()) then -- или на бегу
        return false 
    end
    if (GetTime() - TotemTime < 2) then return false end -- или только недавно ставил
    
    if h < 40 then 
        -- нужно хилиться, а не тотемы кидать
         for i = 1, 4 do 
            if not totem[i] ~= "Тотем трепета" then totem[i] = nil end
        end
    end
    
    if UnitMana100("player") < 40 then 
        -- нужно только самое необходимое
         for i = 1, 4 do 
            if totem[i] and not tContains(importantTotems, totem[i]) then totem[i] = nil end
        end
    end
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