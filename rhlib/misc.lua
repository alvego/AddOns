-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--UIParentLoadAddOn("Blizzard_DebugTools");
--DevTools_Dump(n)
function SellGray()
    for b=0,4 do                                   
      for s=1, GetContainerNumSlots(b) do          
        local n=GetContainerItemLink(b,s)
        if n then
            if string.find(n, "ff9d9d9d") or (IsTrash and IsTrash(n)) then                                 
              UseContainerItem(b,s)                   
            end
        end
      end                                          
    end                                            
end

------------------------------------------------------------------------------------------------------------------
function buy(name,q) 
    local c = 0
    for i=0,3 do 
        local numberOfFreeSlots = GetContainerNumFreeSlots(i);
        if numberOfFreeSlots then c = c + numberOfFreeSlots end
    end
    if c < 1 then return end
    if q == nil then q = 255 end
    for i=1,100 do 
        if name == GetMerchantItemInfo(i) then
            local s = c*GetMerchantItemMaxStack(i) 
            if q > s then q = s end
            BuyMerchantItem(i,q)
        end 
    end
end

------------------------------------------------------------------------------------------------------------------
function sell(name) 
    if not name then name = "" end
    for bag = 0,4,1 do 
        for slot = 1, GetContainerNumSlots(bag), 1 do 
            local item = GetContainerItemLink(bag,slot)
            if item and string.find(item,name) then 
                UseContainerItem(bag,slot) 
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------------
-- Update Debug Frame
local notifyFrame
local notifyFrameTime = 0
local function notifyFrame_OnUpdate()
  if (notifyFrameTime > 0 and notifyFrameTime < GetTime() - 5) then
    local alpha = notifyFrame:GetAlpha()
    if (alpha ~= 0) then notifyFrame:SetAlpha(alpha - .02) end
    if (aplha == 0) then 
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
notifyFrame:SetPoint('CENTER', 0, 0)

-- Debug messages.
function Notify(message)
        notifyFrame.text:SetText(message)
        notifyFrame:SetAlpha(1)
        notifyFrame:Show()
        notifyFrameTime = GetTime()
end

------------------------------------------------------------------------------------------------------------------
function echo(msg, cls)
    if (cls ~= nil) then UIErrorsFrame:Clear() end
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end

------------------------------------------------------------------------------------------------------------------
function chat(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.5, 0.5);
end
------------------------------------------------------------------------------------------------------------------
function tContainsKey(table, key)
    for name,value in pairs(table) do 
        if key == name then return true end
    end
    return false
end

function sContains(str, sub)
    if (not str or not sub) then
      return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end