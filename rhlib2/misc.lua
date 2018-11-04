-- Rotation Helper Library by Alex Tim
------------------------------------------------------------------------------------------------------------------
--UIParentLoadAddOn("Blizzard_DebugTools");
--DevTools_Dump(n)

--[[
  /run UIParentLoadAddOn("Blizzard_DebugTools");
  /fstack true
  /etrace
]]

-- wow-circle error fix
local _format = format
format = function(str, ...)
  if str == nil then
    str = ""
    for i = 1, select('#', ...) do
        str = str .. '%s '
    end
  end
  return _format( gsub(str, "%%%s", "%%s "), ...)
end
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
-- Update Debug Frame
local notifyFrame
local notifyFrameTime = 0
local function notifyFrame_OnUpdate()
  if (notifyFrameTime > 0 and notifyFrameTime < GetTime() - 2) then
    local alpha = notifyFrame:GetAlpha()
    if alpha ~= 0 then notifyFrame:SetAlpha(alpha - .02) end
    if aplha == 0 then
      notifyFrame:Hide()
      notifyFrameTime = 0
    end
  end
end
-- Debug & Notification Frame
notifyFrame = CreateFrame('Frame')
notifyFrame:ClearAllPoints()
notifyFrame:SetHeight(300)
notifyFrame:SetWidth(800)
notifyFrame:SetScript('OnUpdate', notifyFrame_OnUpdate)
notifyFrame:Hide()
notifyFrame.text = notifyFrame:CreateFontString(nil, 'BACKGROUND', 'PVPInfoTextFont')
notifyFrame.text:SetAllPoints()
notifyFrame:SetPoint('CENTER', 0, 100)

-- Debug messages.
function Notify(message, r, g, b)
    r = r or 1
    b = b or 0
    g = g or 0
    notifyFrame.text:SetTextColor(r,g,b)
    notifyFrame.text:SetText(message)
    notifyFrame:SetAlpha(1)
    notifyFrame:Show()
    notifyFrameTime = GetTime()
end
------------------------------------------------------------------------------------------------------------------
function echo(msg)
    UIErrorsFrame:Clear()
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end
------------------------------------------------------------------------------------------------------------------
local lastMsg = {}
function chat(msg, r, g, b)
    r = r or 1.0
    b = b or 0.5
    g = g or 0.5
    local key  =  r * 100 + g * 10 + b
    if lastMsg[key] == msg and TimerLess('EchoMsg'..key, 2) then return end

    DEFAULT_CHAT_FRAME:AddMessage(msg, r, b, g);
    TimerStart('EchoMsg'..key)
    lastMsg[key] = msg
end
------------------------------------------------------------------------------------------------------------------
function tContainsKey(table, key)
    local result = false
    for name,value in pairs(table) do
        if key == name then
          result = true
          break
        end
    end
    return result
end
------------------------------------------------------------------------------------------------------------------
function sContains(str, sub)
    if (not str or not sub) then
      return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end

------------------------------------------------------------------------------------------------------------------
function IsMouse(n)
    return  IsMouseButtonDown(n) == 1
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
function IsShift()
    return  (IsShiftKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end
------------------------------------------------------------------------------------------------------------------
local timers = {}
function TimerReset(name)
  timers[name] = 0
end
function TimerStarted(name)
  return (timers[name] or 0) > 0
end
function TimerStart(name, offset)
  timers[name] = GetTime() + (offset or 0)
end
function TimerElapsed(name)
  return  GetTime() - (timers[name] or 0)
end
function TimerLess(name, less)
  return TimerElapsed(name) < (less or 0)
end

function TimerMore(name, less)
  return TimerElapsed(name) > (less or 0)
end

function TimerToggle(name, toggle)
  if toggle then
    if not TimerStarted(name) then TimerStart(name) end
  else
    if TimerStarted(name) then TimerReset(name) end
  end
end
------------------------------------------------------------------------------------------------------------------
if ExcludeItemsList == nil then ExcludeItemsList = {} end
------------------------------------------------------------------------------------------------------------------

function GetMinEquippedItemLevel()
  local minItemLevel = nil
  for i = 1, 18 do
    local itemID = GetInventoryItemID("player",i)
    if itemID then
      local name, _, _, itemLevel, _, itemType, itemSubType = GetItemInfo(itemID)
      --print(name, itemLevel, itemType, itemSubType)
      if itemType == "Доспехи" and itemSubType ~= "Разное" and (not minItemLevel or (itemLevel < minItemLevel)) then

        minItemLevel = itemLevel
      end
    end
  end
  return minItemLevel
end
------------------------------------------------------------------------------------------------------------------
local function IsTrash(n, minItemLevel)
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(n)
    if nil == itemName then return "!found" end
    local status = ExcludeItemsList[itemName]
    if status ~= nil then
      if status then
        return nil
      else
        return "Список"
      end
    end
    if string.find(n, "ff9d9d9d") then return "Мусор" end
    if not Farm then return nil end
    --[[if sContains(itemName, "Эскиз:") or sContains(itemName, "ларец") or sContains(itemName, "сейф") then
      --print(n, " - Выкидываем эскизы, ларецы и сейфы в режиме фарма")
      return "Ящик"
    end]]
    local m = 0.67
    --print(itemType, itemSubType)
    if minItemLevel and itemSellPrice > 0 and #itemEquipLoc > 0 and itemLevel and itemLevel < math.floor(minItemLevel * m) and itemSubType ~= "Разное" then
      --print(n, " - низкий уровень предмета ", itemLevel, " min: " .. minItemLevel)
      return "ilvl < " .. math.floor(minItemLevel * m)
    end
    return nil
end


local tipHook = function (self, ...)
  local itemName, itemLink = self:GetItem()
  if not itemLink or not GetItemInfo(itemLink) then return end
  local auto = (ExcludeItemsList[itemName] == nil)
  local info = IsTrash(ItemLink, Farm and GetMinEquippedItemLevel() or nil)
  if info or not auto then
    local line1 = (info == nil and format('|cff55ff55%s|r', "Нужный предмет!") or format('|cffff5555%s|r', "Будет продан!"))
    local line2 = format('|cff00ff9a( %s )|r', info and info or (auto and "Авто" or "Список"))
    self:AddDoubleLine(line1, line2)
    self:Show()
  end
end
GameTooltip:HookScript('OnTooltipSetItem', tipHook)
ItemRefTooltip:HookScript('OnTooltipSetItem', tipHook)

function TrashToggle()
    local itemName, ItemLink = GameTooltip:GetItem()
    if nil == itemName then return end
    local status = ExcludeItemsList[itemName]
    if status == nil then
      status = true
      print(itemName, '- в списке как нужная вещь ')
    elseif status then
      status = false
      print(itemName, '- в списке как хлам')
    else
      status = nil
      print(itemName, '- удален из списка')
    end
    ExcludeItemsList[itemName] = status
    print('ExcludeItemsList[',itemName,'] = ', status)
end
------------------------------------------------------------------------------------------------------------------
function SellGray()
  ClearCursor()
  local minItemLevel = Farm and GetMinEquippedItemLevel() or nil
  for bag=0,NUM_BAG_SLOTS do
       for slot=1,GetContainerNumSlots(bag) do
           local link = GetContainerItemLink(bag,slot)
           if link then
             if IsTrash(link, minItemLevel) then
               local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(link)
               if itemSellPrice > 0 then
                 UseContainerItem(bag,slot)
               else
                 PickupContainerItem(bag, slot)
                 DeleteCursorItem()
               end
             end
           end
       end
   end
end
-------------------------------------------------------------------------------------------------------------------
-- Автоматическая продажа хлама и починка
local money = 0
OpenMerchant = false
local function SellGrayAndRepair()
    OpenMerchant = true
    money = GetMoney()
    TimerStart('Sell')
    if CanMerchantRepair() then
      RepairAllItems(1) -- сперва пробуем за счет ги банка
      RepairAllItems()
    end
    SellGray()
end
AttachEvent('MERCHANT_SHOW', SellGrayAndRepair)
local function StopSell()
  local m = GetMoney() - money
  if not (math.abs(m) < 1) then
    m =  (m > 0 and "+" or '-') .. GetCoinTextureString(math.abs(m))
    chat(("Итого: %s, за %s"):format(m , SecondsToTime(TimerElapsed('Sell'))), 1, 1, 1);
  end
  OpenMerchant = false
end
AttachEvent('MERCHANT_CLOSED', StopSell)
------------------------------------------------------------------------------------------------------------------
function sell(name)
  if not OpenMerchant then
    chat("Нужен торговец")
    return
  end
  if not name then name = "" end
  local find = false
  for bag=0,NUM_BAG_SLOTS do
     for slot=1,GetContainerNumSlots(bag) do
       local link = GetContainerItemLink(bag,slot)
       if link then
         if string.find(link, name) then
           find = true
           UseContainerItem(bag,slot)
         end
       end
     end
   end
   if not find then
     chat("Прeдмет " .. name .. " не найден в сумках")
   end
end

------------------------------------------------------------------------------------------------------------------
function DelGray()
  ClearCursor()
  for bag=0,NUM_BAG_SLOTS do
       for slot=1,GetContainerNumSlots(bag) do
           local link = GetContainerItemLink(bag,slot)
           if link then
             if IsTrash(link) then
               PickupContainerItem(bag, slot)
               DeleteCursorItem()
             end
           end
       end
   end
end
------------------------------------------------------------------------------------------------------------------
function GetFreeBagSlotCount()
  local free = 0
  -- считаем сободное место
    for bag=0, NUM_BAG_SLOTS do
        local n = GetContainerNumFreeSlots(bag);
        if n then free = free + n end
    end
    return free
end
------------------------------------------------------------------------------------------------------------------
-- Автоматическая покупка предметов
function buy(name, count)
  if not OpenMerchant then
    chat("Нужен торговец")
    return
  end
  if count == nil then count = 1 end
  local merchantIndex = nil
  for i=1,100 do
      local itemName = GetMerchantItemInfo(i)
      if itemName and itemName:match(name) then
          merchantIndex = i
          break
      end
  end
  if merchantIndex == nil then
    chat("Прeдмет " .. name .. " не найден у торговца")
    return
  end
  local freeBagSlots = GetFreeBagSlotCount()
  if freeBagSlots < 1 then
    chat("Нет свободныйх слотов в сумках")
    return
  end

  local currentCount = GetItemCount(name)
  local needToBuy = count - currentCount
  if needToBuy < 1 then
    chat("В сумках уже есть "  .. count .. " " .. name)
    return
  end
  if needToBuy > 255 then
    needToBuy = 255
    chat("Нельзя купить больше чем 255шт. за 1 раз")
  end
  BuyMerchantItem(merchantIndex, needToBuy)
end
------------------------------------------------------------------------------------------------------------------
