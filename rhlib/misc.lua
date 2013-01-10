-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function SellGray()
	for b=0,4 do                                   
	  for s=1, GetContainerNumSlots(b) do          
		n=GetContainerItemLink(b,s)               
		if n and string.find(n, "ff9d9d9d") then                                 
			UseContainerItem(b,s)                   
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
NotifyFrame = nil
function NotifyFrame_OnUpdate()
        if (NotifyFrameTime < GetTime() - 5) then
                local alpha = NotifyFrame:GetAlpha()
                if (alpha ~= 0) then NotifyFrame:SetAlpha(alpha - .02) end
                if (aplha == 0) then NotifyFrame:Hide() end
        end
end
-- Debug & Notification Frame
NotifyFrame = CreateFrame('Frame')
NotifyFrame:ClearAllPoints()
NotifyFrame:SetHeight(300)
NotifyFrame:SetWidth(300)
NotifyFrame:SetScript('OnUpdate', NotifyFrame_OnUpdate)
NotifyFrame:Hide()
NotifyFrame.text = NotifyFrame:CreateFontString(nil, 'BACKGROUND', 'PVPInfoTextFont')
NotifyFrame.text:SetAllPoints()
NotifyFrame:SetPoint('CENTER', 0, 200)
NotifyFrameTime = 0
-- Debug messages.
function Notify(message)
        NotifyFrame.text:SetText(message)
        NotifyFrame:SetAlpha(1)
        NotifyFrame:Show()
        NotifyFrameTime = GetTime()
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
function printtable(t, indent)
  indent = indent or 0;
  local keys = {};
  for k in pairs(t) do
    keys[#keys+1] = k;
    table.sort(keys, function(a, b)
      local ta, tb = type(a), type(b);
      if (ta ~= tb) then
        return ta < tb;
      else
        return a < b;
      end
    end);
  end
  print(string.rep('  ', indent)..'{');
  indent = indent + 1;
  for k, v in pairs(t) do
    local key = k;
    if (type(key) == 'string') then
      if not (string.match(key, '^[A-Za-z_][0-9A-Za-z_]*$')) then
        key = "['"..key.."']";
      end
    elseif (type(key) == 'number') then
      key = "["..key.."]";
    end
    if (type(v) == 'table') then
      if (next(v)) then
        print(format("%s%s =", string.rep('  ', indent), tostring(key)));
        printtable(v, indent);
      else
        print(format("%s%s = {},", string.rep('  ', indent), tostring(key)));
      end 
    elseif (type(v) == 'string') then
      print(format("%s%s = %s,", string.rep('  ', indent), tostring(key), "'"..v.."'"));
    else
      print(format("%s%s = %s,", string.rep('  ', indent), tostring(key), tostring(v)));
    end
  end
  indent = indent - 1;
  print(string.rep('  ', indent)..'}');
end

------------------------------------------------------------------------------------------------------------------
function TryEach(list, func)
    local state = nil
    for _,value in pairs(list) do 
        if not state then state = func(value) end 
    end
    return state
end

------------------------------------------------------------------------------------------------------------------
function tContainsKey(table, key)
    for name,value in pairs(table) do 
        if key == name then return true end
    end
    return false
end
