-- Warrior Rotation Helper by Timofeev Alexey
print("|cff0055ffRotation Helper|r|cffffe00a > |cff804000Warrior|r loaded.")
-- Binding
BINDING_HEADER_RHWARRIOR = "Warrior Rotation Helper"
BINDING_NAME_RHWARRIOR_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_RHWARRIOR_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_RHWARRIOR_ROLE = "Переключение ролей"
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
   return (IsValidTarget("target") and InMelee("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and InMelee("focus"))
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
if Role == nil then Role = 0 end

function IsTank() return 1 == Role end
function IsDD() return 0 == Role end

function RoleToggle()
    if IsDD() then
        Role = 1
        echo("<TANK>",true)
    else
        Role = 0
        echo("<DD>",true)
    end 
end

------------------------------------------------------------------------------------------------------------------
function Stance(...) 
    for i = 1, select('#', ...) do
        if GetShapeshiftForm() == select(i, ...) then return true end
    end
    return false
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

    if IsPvP() and not InInterruptRedList(spell) then return false end
    local t = endTime/1000 - GetTime()

    if t < 0.2 then return false end
    if channel and t < 0.7 then return false end

    m = " -> " .. spell .. " ("..target..")"

    if not notinterrupt and not HasBuff(nointerruptBuffs, 0.1, target) then 
        
    end
   

end
------------------------------------------------------------------------------------------------------------------
--[[
Diminishing Returns http://forum.wowcircle.com/showthread.php?t=191603
Ярость берсерка
Maim
Repetance
Sap
Gouge
Fear
Howl of Terror
Psychic Scream
Intimidating Shout
Dragon's Breath

]]
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
        print("lich->freedom", debuff)
        DoCommand("freedom") 
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
function DoSpell(spellName, target, mana)
    if not mana or IsAttack() then mana = 0 end
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    if (1 == powerType and cost > 0) then
        if IsShiftKeyDown() then return false end
        if UnitMana("player") - cost < mana then return false end
    end
    return UseSpell(spellName, target)
end
------------------------------------------------------------------------------------------------------------------

if TrashList == nil then TrashList = {} end
function IsTrash(n) --n - itemlink
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(n)
    if tContains(TrashList, itemName) then return true end
    if itemRarity == 2 and (itemType == "Оружие" or itemType == "Доспехи") then return true end
    return false
end


function trashToggle()
    local itemName, ItemLink = GameTooltip:GetItem()
    if nil == itemName then Notify("Наведите на предмет") return end
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