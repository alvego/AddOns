-- DK Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_DKRH = "Dead Knight Rotation Helper"
BINDING_NAME_DKRH_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_DKRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_DKRH_DEATHGRIP = "Авто Хватка смерти"
BINDING_NAME_DKRH_BERSMOD = "Режим берсерка"
------------------------------------------------------------------------------------------------------------------
if CanAOE == nil then CanAOE = true end

function AOEToggle()
    CanAOE = not CanAOE
    if CanAOE then
        echo("AOE: ON",true)
    else
        echo("AOE: OFF",true)
    end 
end

function IsAOE()
   if not CanAOE then return false end
   if IsShiftKeyDown() == 1 then return true end
   return (IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and Dotes(7) and Dotes(7, "focus"))
end

------------------------------------------------------------------------------------------------------------------
if CanInterrupt == nil then CanInterrupt = true end

function InterruptToggle()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end 
end

------------------------------------------------------------------------------------------------------------------
if DeathGripState == nil then DeathGripState = false end

function DeathGripToggle()
    DeathGripState = not DeathGripState
    if DeathGripState then
        echo("Хватка смерти: ON",true)
    else
        echo("Хватка смерти: OFF",true)
    end 
end

------------------------------------------------------------------------------------------------------------------
if BersState == nil then BersState = false end

function BersModToggle()
    BersState = not BersState
    if BersState then
        echo("Берс Мод: ON",true)
    else
        echo("Берс Мод: OFF",true)
    end 
end
------------------------------------------------------------------------------------------------------------------
function IsNeedTaunt()
    return  IsMouseButtonDown(5) == 1
end
------------------------------------------------------------------------------------------------------------------
local interruptTime = 0
local redList = { 
    "Ледяная стрела",
    "Сковывание нежити",
    "Молния"
}
function TryInterrupt(target)
    if (GetTime() - interruptTime < 1) then return false end
    
    if target == nil then target = "target" end
    if not IsValidTarget(target) then return false end
    local channel = false
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    
    if not spell then return false end
    
    if not CanInterrupt and not InInterruptRedList(spell) and not tContains(redList, spell) then return false end
    
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end
    
    m = " -> " .. spell .. " ("..target..")"
    
    if not notinterrupt and not HasBuff({"Мастер аур"}, 0.1, target) and CanMagicAttack(target) then 
        if (channel or t < 0.8) and InMelee(target) and DoSpell("Заморозка разума", target) then 
            echo("Заморозка разума"..m)
            interruptTime = GetTime()
            return true 
        end
        if (not channel and t < 1.8) and HasRunes(100) and DoSpell("Удушение", target) then 
            echo("Удушение"..m)
            interruptTime = GetTime()
            return true 
        end
    end
    
    if CanAttack(target) and (channel or t < 0.8) and (GetDeathGripState() or UnitIsPlayer("target")) and DoSpell("Хватка смерти", target) then 
        echo("Хватка смерти"..m)
        interruptTime = GetTime()
        return true 
    end

    if CanAttack(target) and (channel or t < 1.8) and IsOneUnit(target, "mouseover") 
        and (GetUnitName("player") == GetUnitName(target .. "-target") or  UnitClassification(target) == "worldboss") and UseSlot(6) then 
        echo("Наременная граната"..m)
        interruptTime = GetTime()+2
        return true 
    end

    if GetUnitName("player") == GetUnitName(target .. "-target") and DoSpell("Антимагический панцирь") then 
        echo("Антимагический панцирь"..m)
        interruptTime = GetTime() + 5
        return true 
    end
--~     echo("Нечем сбить"..m)
    return false    
end

------------------------------------------------------------------------------------------------------------------
local DeathPact = 0
local function UpdateDeathPact(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
    if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)  then
    
        if spellName == "Смертельный союз" and err == "У вас нет питомца." then
            DeathPact = GetTime()
        end

        if Debug and err then
            print("["..spellName .. "]: ".. err)
        end
        
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateDeathPact)

local pact = false
function NeedDeathPact()
    if pact and not IsReadySpell("Смертельный союз") then
        chat("Сожрал пета!")
        pact = false
    end
    if pact then return true end
    if (InCombatLockdown() and CalculateHP("player") < 60) and IsReadySpell("Войско мертвых") and IsReadySpell("Смертельный союз") and (GetTime() - DeathPact > 10) then return true end
    return false
end


function TryDeathPact()
    if InGCD() or UnitCastingInfo("player") ~= nil or UnitChannelInfo("player") ~= nil then return false end
    if pact then 
        if IsReadySpell("Смертельный союз") then
            RunMacroText("/cast Смертельный союз")
            return true
        end
        return false
    end
    if not NeedDeathPact() then return false end
    if IsReadySpell("Войско мертвых") and IsReadySpell("Смертельный союз") then
        RunMacroText("/cast Воскрешение мертвых")
        chat("Вызвал пета!")
        pact = true
        return true
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
local freedomList = { -- > 4
"Калечение", -- 5s max
"Сон", -- 20s
"Тайфун", -- 6s
"Эффект замораживающей стрелы", -- 20s
"Эффект замораживающей ловушки", -- 10s
"Глубокая заморозка", -- 5s
"Дыхание дракона", -- 5s
"Молот правосудия", -- 6s
"Покаяние", -- 6s
"Удар по почкам", -- 6s max
"Сглаз", -- 30s
"Огненный шлейф", -- 5s
"Оглушающий удар", -- 5s
"Пронзительный вой", -- 6s
"Головокружение", -- 6s
"Ошеломление", -- 20s
}

local lichList = {
"Сон",
"Соблазн",
"Страх", 
"Вой ужаса", 
"Устрашающий крик", 
"Контроль над разумом", 
"Глубинный ужас", 
"Ментальный крик"
}
function UpdateAutoFreedom(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel = select(1, ...)
    if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)
        and err and err:match("Действие невозможно")  then
        if HasDebuff(lichList, 3.8, "player") then DoCommand("lich") end 
        if HasDebuff(freedomList, 3.8, "player") then DoCommand("freedom") end 
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateAutoFreedom)

------------------------------------------------------------------------------------------------------------------
function DoSpell(spellName, target, runes)
    if runes == nil then runes = 0 end 
    
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    
    if NeedDeathPact() then 
        if name ~= "Смертельный союз" then 
            if IsReadySpell("Смертельный союз") or (powerType == 6) then return false end
        end
        if IsReadySpell("Войско мертвых") and IsReadySpell("Смертельный союз") and name ~= "Войско мертвых" then return false end
    end
    
    if (powerType == 6) then
        if cost > 0 and UnitMana("player") - cost <= runes then return false end
    end
    return UseSpell(spellName, target)
end
