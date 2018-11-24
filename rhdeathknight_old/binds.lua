-- Death Knight Rotation Helper by Timofeev Alexey
print("|cff0055ffRotation Helper|r|cffffe00a > |cff800000Death Knight|r loaded.")
-- Binding
BINDING_HEADER_RHDEATHKNIGHT = "Death Knight Rotation Helper"
BINDING_NAME_RHDEATHKNIGHT_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_RHDEATHKNIGHT_INTERRUPT = "Вкл/Выкл сбивание кастов"
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
function IsMouse3()
    return  IsMouseButtonDown(3) == 1
end

------------------------------------------------------------------------------------------------------------------
function IsCtr()
    return  (IsControlKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsAlt()
    return  (IsAltKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------

local nointerruptBuffs = {"Мастер аур"}
local lichSpells = {"Превращение", "Сглаз", "Соблазн", "Страх", "Вой ужаса", "Контроль над разумом"}
local conrLichSpells = {"Изгнание зла", "Сковывание нежити"}
function TryInterrupt(target)
    if target == nil then target = "target" end
    if not IsValidTarget(target) then return false end
    local channel = false
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
        channel = true
    end
    
    if not spell then return false end

    if tContains(conrLichSpells, spell) then RunMacroText("/cancelaura Перерождение") end

    if IsPvP() and not InInterruptRedList(spell) then return false end
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end

    m = " -> " .. spell .. " ("..target..")"

    if not notinterrupt and not HasBuff(nointerruptBuffs, 0.1, target) and CanMagicAttack(target) then 
        if (channel or t < 0.8) and InMelee(target) and DoSpell("Заморозка разума", target) then 
            echo("Заморозка разума"..m)
            interruptTime = GetTime() + 4
            return true 
        end
        if (not channel and t < 1.8) and DoSpell("Удушение", target) then 
            echo("Удушение"..m)
            interruptTime = GetTime() + 2
            return true 
        end
    end
    
    if CanAttack(target) and (channel or t < 0.8) and (UnitIsPlayer(target) or not InParty()) and DoSpell("Хватка смерти", target) then 
        echo("Хватка смерти"..m)
        interruptTime = GetTime() + 2
        return true 
    end

    if HasSpell("Перерождение") and IsOneUnit("player",target .. "-target") and tContains(lichSpells, spell) and DoSpell("Перерождение") then 
        echo("Перерождение"..m)
        interruptTime = GetTime() + 2
        return true 
    end

    if HasSpell("Отгрызть") and IsReadySpell("Отгрызть") and CanAttack(target) and (channel or t < 0.8) then 
        RunMacroText("/cast [@" ..target.."] Прыжок")
        RunMacroText("/cast [@" ..target.."] Отгрызть")
        if not IsReadySpell("Отгрызть") then
            echo("Отгрызть"..m)
            interruptTime = GetTime() + 4
            return false 
        end
    end

    if IsPvP() and IsHarmfulSpell(spell) and IsOneUnit("player", target .. "-target") and DoSpell("Антимагический панцирь") then 
        echo("Антимагический панцирь"..m)
        interruptTime = GetTime() + 5
        return true 
    end

end
------------------------------------------------------------------------------------------------------------------
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

    
local exceptionControlList = { -- > 4
"Ошеломление", -- 20s
"Покаяние", 
}

local freedomTime = 0
function UpdateAutoFreedom(event, ...)
    if GetTime() - freedomTime < 1.5 then return end
    local debuff = HasDebuff(lichList, 2, "player")
    if debuff then 
        if HasSpell("Перерождение") and IsReadySpell("Перерождение") then
            print("lich", debuff)
            DoCommand("lich") 
        else
            if not HasBuff("Перерождение") then  
                print("lich->freedom", debuff)
                DoCommand("freedom") 
            end
        end
        freedomTime = GetTime()
        return
    end 
    debuff = HasDebuff(ControlList, 2, "player")
    if debuff and (not tContains(exceptionControlList, debuff) or IsAttack()) then 
        local forceMode = tContains(exceptionControlList, debuff) and IsAttack() and "force!" or ""
        print("freedom", debuff, forceMode)
        DoCommand("freedom") 
        freedomTime = GetTime()
        return
    end 
end
AttachUpdate(UpdateAutoFreedom, -1)
------------------------------------------------------------------------------------------------------------------

local macroSpell = {
    "Отгрызть",
    "Прыжок",
    "Взрыв трупа",
    "Призыв горгульи",
    "Смертельный союз",
    "Воскрешение мертвых"
}

local spellRunes = {
    ["Ледяные оковы"] = 010,
    ["Ледяное прикосновение"] = 010,
    ["Удар чумы"] = 001,
    ["Вскипание крови"] = 100,
    ["Кровавый удар"] = 100,
    ["Удар смерти"] = 011,
    ["Удар Плети"] = 011,
    ["Уничтожение"] = 011,
    ["Костяной щит"] = 001,
    ["Захват рун"] = 100,
    ["Мор"] = 100,
    ["Войско мертвых"] = 111,
    ["Смерть и разложение"] = 111,
    ["Власть крови"] = 100,
    ["Власть льда"] = 010,
    ["Власть нечестивости"] = 001,
    ["Врата смерти"] = 001,
    ["Зона антимагии"] = 001,
    ["Удушение"] = 100,
    ["Удар в сердце"] = 100,

}

local spellCD = {}
function DoSpell(spellName, target, baseRP)
    local t = GetTime()
    local c = spellCD[spellName]
    if c ~= nil and t - c < 0.1 then 
        return false 
    end

    if tContains(macroSpell, spellName) then
        if not IsReadySpell(spellName) or not InRange(spellName, target) then return false end
        local cast = "/cast "
        if target then cast = cast .. "[@" .. target .. "] " end
        RunMacroText(cast .. spellName)
        spellCD[spellName] = t
        chat(spellName)
        return IsReadySpell(spellName)
    end
    runes = spellRunes[spellName]
    if runes ~= nil and not HasRunes(runes) then return false end

    if not baseRP or IsAttack() then baseRP = 0 end
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    if (powerType == 6) then
        -- and IsReadySpell("Призыв горгульи")
        if IsCtr() and HasSpell("Призыв горгульи") and not (spellName == "Призыв горгульи")  then 
            --chat(spellName)
            return false 
        end
        if cost > 0 and UnitMana("player") - cost < baseRP then return false end
    end

    spellCD[spellName] = t
    return UseSpell(spellName, target)
end
------------------------------------------------------------------------------------------------------------------
if TrashList == nil then TrashList = {} end
function IsTrash(n) --n - itemlink
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(n)
    if tContains(TrashList, itemName) then return true end
    if itemRarity == 2 and (itemType == "Оружие" or itemType == "Доспехи") then
      return true
    end
    return false
end


function trashToggle()
    local itemName, ItemLink = GameTooltip:GetItem()
    if nil == itemName then return end
    if tContains(TrashList, itemName) then 
        for i=1, #TrashList do
            if TrashList[i] ==  itemName then 
                tremove(TrashList, i)
                chat(itemName .. " это НЕ Хлам! ")
            end
        end            
    else
        chat(itemName .. " это Хлам! ")
        tinsert(TrashList, itemName)
    end
end