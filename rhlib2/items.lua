-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------

function IsReadySlot(slot, checkGCD)
    if not HasAction(slot) then return false end
    local itemID = GetInventoryItemID("player",slot)
    if not itemID or (IsItemInRange(itemID, "target") == 0) then return false end
    if not IsReadyItem(itemID, checkGCD) then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------

function UseSlot(slot)
    if UnitIsCasting() then return false end
    if not IsReadySlot(slot) then return false end
    if not IsReadySlot(slot, true) then return true end
    oexecute("UseInventoryItem(" .. slot .. ")")
    if SpellIsTargeting() then
        UnitWorldClick("target")
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
function GetItemCooldownLeft(name)
    local itemName, itemLink =  GetItemInfo(name)
    if not itemName then
        if Debug then error("Итем [".. name .. "] не найден!") end
        return false;
    end
    local itemID =  itemLink:match("item:(%d+):")
    local start, duration, enabled = GetItemCooldown(itemID);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    return left
end

------------------------------------------------------------------------------------------------------------------
function ItemExists(item)
    return GetItemInfo(item) and true or false
end

------------------------------------------------------------------------------------------------------------------
function ItemInRange(item, unit)
    if ItemExists(item) then
        return (IsItemInRange(item, unit) == 1)
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function IsReadyItem(name)
   local usable = IsUsableItem(name)
   if not usable then return true end
   local left = GetItemCooldownLeft(name)
   return IsReady(left, checkGCD)
end

------------------------------------------------------------------------------------------------------------------
function EquipItem(itemName, slot)
    if IsEquippedItem(itemName) then return false end
    if Debug then
        print(itemName)
    end
    local cmd = "EquipItemByName('".. itemName .."'"
    if slot then
      cmd = cmd ..", ".. slot
    end
    cmd = cmd ..")"
    oexecute(cmd)
    return IsEquippedItem(itemName)
end
------------------------------------------------------------------------------------------------------------------

function UseItem(itemName, target)
    if UnitIsCasting() then return false end
    if not ItemExists(itemName) then return false end
    if not IsEquippedItem(itemName) and not IsUsableItem(itemName) then return false end
    if IsCurrentItem(itemName) then return false end
    if not IsReadyItem(itemName) then return false end
    local itemSpell = GetItemSpell(itemName)
    if itemSpell and IsSpellInUse(itemSpell) then return false end
    local cmd  = "UseItemByName('"..itemSpell.."'"
    if target then
      if not UnitExists(target) then return false end
      if not InRange(itemSpell, target) then return false end
      cmd = cmd .. ", '"..target.."'"
    end
    cmd = cmd .. ")"
    oexecute(cmd)
    if SpellIsTargeting() then
        UnitWorldClick(target or "player")
        oexecute('SpellStopTargeting()')
    end
    return true
end
------------------------------------------------------------------------------------------------------------------
function UseEquippedItem(item, target)
    if IsEquippedItem(item) and UseItem(item, target) then return true end
    return false
end
