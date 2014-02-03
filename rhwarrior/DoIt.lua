local DoItUpdate=true
local DoItNext="none"
local DoItPrev
local spell = "none"
local spell1 = "none"
local DoItCombat 

local advance = 0.015
local reDoT = 0.25
local UtlCD = 4
local UtlTick = 0.1
local LastUtl =0
local MnCD = 0.3
local LastMn = 0

local PrUnit = "none"
local DPTry = 0
local DPFlag = false

local OnHeroic = true
local HeroicFlag = false

local DoItFrame=CreateFrame("Frame",nil,UIParent)
-- Create the square itself
DoItFrame.t = DoItFrame:CreateTexture()
local width = 2
local height = 2
DoItFrame:ClearAllPoints()
DoItFrame:SetScale(1)
DoItFrame:SetFrameStrata("HIGH")
DoItFrame:SetWidth(width)
DoItFrame:SetHeight(height)
DoItFrame:SetPoint("TOPLEFT",UIParent)
DoItFrame.t:SetAllPoints(DoItFrame)
DoItFrame.t:SetTexture(0,0,0)
DoItFrame:Show()

local T = {}

local function DiItInit()
	-- Check Who am I?
	
	WorldFrame:ClearAllPoints()
	WorldFrame:SetPoint("TOPLEFT", 0, -height)
	WorldFrame:SetPoint("BOTTOMRIGHT", 0, 0)

			DEFAULT_CHAT_FRAME:AddMessage("DoIt: Воин армс")
			DoItCombat = ArmsCombat
			DoItFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			DoItFrame:SetScript("OnUpdate", 
				function()
					if DoItUpdate then
						DoItPrev=DoItNext
						DoItRecountArms()
						if DoItNext ~= DoItPrev then
							DoItSetFury(DoItNext)
						end
					end
				end
			)

end




T["Bladestorm"] = GetSpellInfo(46924)
T["Charge"] = GetSpellInfo(100)
T["Heroic Throw"] = GetSpellInfo(57755)
T["Mortal Strike"] = GetSpellInfo(21551)
T["Overpower"] = GetSpellInfo(7384)
T["Rend"] = GetSpellInfo(772)
T["Cleave"] = GetSpellInfo(845)
T["Slam"] = GetSpellInfo(47475)
T["Execute"] = GetSpellInfo(47471)
T["Sunder Armor"] = GetSpellInfo(7386)
T["Heroic Strike"] = GetSpellInfo(47450)
T["Bloodrage"] = GetSpellInfo(2687)
T["Battle Shout"] = GetSpellInfo(47436)
T["Commanding Shout"] = GetSpellInfo(47440)
T["Victory Rush"] = GetSpellInfo(34428)
T["Expose Armor"] = GetSpellInfo(8647)
T["Acid Spit"] = GetSpellInfo(55754)



function ArmsCombat( ... )
	local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName = select(1, ...)
	--if sourceGUID == UnitGUID("player") then
	if (sourceGUID == UnitGUID("player")) and (type:match("^SWING") or (spellName and ((spellName == T["Heroic Strike"]) or (spellName == T["Cleave"])))) then
--		print(sourceName .. ": " .. type)
		OnHeroic = true
--		DoItMnRst()
	end
end

local ShTry = 0
local ShFlag = false

function DoItRecountArms()
	local start, duration, usable, norage, WhLeft, BTLeft, OnExec, InMelee, index, enabled, temp
	local ShoutOK = false
	local SlamOK = false

	local IsStill = (GetUnitSpeed("player") == 0)
	
	-- filter non-combat or friendly target
	DoItNext = "none"
	if not InCombatLockdown() or UnitIsFriend("player","target") then
		OnHeroic = true
		ShTry = 0
		return
	end

	InMelee = IsSpellInRange(T["Sunder Armor"],"TARGET")
	
	OnExec, _ = IsUsableSpell(T["Execute"])

	--bloodrage
	if InMelee == 1 and UnitMana("PLAYER")<30 then
		usable, _ = IsUsableSpell(T["Bloodrage"])
		if usable then
			start, duration = GetSpellCooldown(T["Bloodrage"])
			if start and (start + duration - GetTime() < advance) then
				DoItNext = "Bloodrage"
				return
			end
		end
	end

	-- filter GCD
	start, duration = GetSpellCooldown(T["Sunder Armor"])
	if start and (start + duration - GetTime() > advance) then
		if ShFlag then
			ShTry = ShTry + 1
			ShFlag = false
		end
		return
	end

	index = 1
	while UnitBuff("PLAYER", index) do
		local name, _, _, _, _, _, _, IsMine = UnitBuff("PLAYER", index)
		if (name == T["Battle Shout"] or name == T["Commanding Shout"]) and IsMine == "player"  then
			ShoutOK = true
			ShTry = 0
		end
		index = index + 1
	end
	
	if InMelee==1 then
	end
	
	if DoItUtlRdy() and ShTry <3 and not ShoutOK then
		start, duration = GetSpellCooldown(T["Battle Shout"])
		usable, _ = IsUsableSpell(T["Battle Shout"])
		if start and usable and (start + duration - GetTime() < advance) then
			DoItNext = "Battle Shout"
			ShFlag = true
			DoItUtlRst()
			return
		end
	end

	
	if InMelee == 1 then
	--victory
		usable, _ = IsUsableSpell(T["Victory Rush"])
		if usable then
			start, duration = GetSpellCooldown(T["Victory Rush"])
			if start and (start + duration - GetTime() < advance) then
				DoItNext = "Victory Rush"
				return
			end
		end
		
	-- rend
		usable, _ = IsUsableSpell(T["Rend"])
		if usable then
			index = 1
			temp = 0
			while UnitDebuff("TARGET", index) do
				local name, _, _, _, _, _, _, isMine = UnitDebuff("target", index)
				if isMine and isMine == "player" then
					if name == T["Rend"] then
						temp = 1
					end				
				end
				index = index + 1
			end
			if temp == 0 then
				DoItNext = "Rend"
				return
			end
		end

	-- Sunder armor
		index = 1
		local SunderOK = (UnitClassification("target") ~= "worldboss")
		local SunderLeft = 0
		while UnitDebuff("target", index) do
			local name, _, _, count, _, _, Expires = UnitDebuff("target", index)
			if (not ((name == T["Sunder Armor"]) and ((Expires - GetTime())<5))) and (name == T["Expose Armor"] or name == T["Acid Spit"] or ((name == T["Sunder Armor"]) and count == 5 and ((Expires - GetTime())>5))) then
				SunderOK = true
				SunderLeft = Expires - GetTime()
			end
			index = index + 1
		end

		if not SunderOK then
			start, duration = GetSpellCooldown(T["Sunder Armor"])
			usable, _ = IsUsableSpell(T["Sunder Armor"])
			if start and usable and (start + duration - GetTime() < advance) then
				DoItNext = "Sunder Armor"
				return
			end
		end
		
	-- mortal
		usable, _ = IsUsableSpell(T["Mortal Strike"])
		if usable then
			start, duration = GetSpellCooldown(T["Mortal Strike"])
			if start and (start + duration - GetTime() < advance) then
				DoItNext = "Mortal Strike"
				return
			end
		end
		
	-- execut	
		if UnitMana("PLAYER")>40 then
			usable, _ = IsUsableSpell(T["Execute"])
			if usable then
				start, duration = GetSpellCooldown(T["Execute"])
				if start and (start + duration - GetTime() < advance) then
					DoItNext = "Execute"
					return
				end
			end
		end
		
	-- over	
		usable, _ = IsUsableSpell(T["Overpower"])
		if usable then
			start, duration = GetSpellCooldown(T["Overpower"])
			if start and (start + duration - GetTime() < advance) then
				DoItNext = "Overpower"
				return
			end
		end

	-- blad
		usable, _ = IsUsableSpell(T["Bladestorm"])
		if usable and SunderOK and SunderLeft > 8 then
			start, duration = GetSpellCooldown(T["Bladestorm"])
			if start and (start + duration - GetTime() < advance) then
				DoItNext = "Bladestorm"
				return
			end
		end
		
	end

	usable, _ = IsUsableSpell(T["Charge"])
	if usable then
		start, duration = GetSpellCooldown(T["Charge"])
		if start and (start + duration - GetTime() < advance) and (IsSpellInRange(T["Charge"],"TARGET") == 1) then
			DoItNext = "Charge"
			return
		end
	end
	
	usable, _ = IsUsableSpell(T["Heroic Throw"])
	if usable then
		start, duration = GetSpellCooldown(T["Heroic Throw"])
		if start and (start + duration - GetTime() < advance) and InMelee == 0 then
			DoItNext = "Heroic Throw"
			return
		end
	end	
	
	if InMelee==1 then
	-- slam	
		if IsStill and UnitMana("PLAYER")>45 then
			usable, _ = IsUsableSpell(T["Slam"])
			if usable then
				start, duration = GetSpellCooldown(T["Slam"])
				if start and (start + duration - GetTime() < advance) then
					DoItNext = "Slam"
					return
				end
			end
		end
	end

	return
end

function DoItSetFury(donext)
	if donext == "none" then
		DoItColorCode(0)
	elseif donext == "Bladestorm" then
		DoItColorCode(1)
	elseif donext == "Charge" then
		DoItColorCode(2)
	elseif donext == "Heroic Throw" then
		DoItColorCode(3)
	elseif donext == "Mortal Strike" then
		DoItColorCode(4)
	elseif donext == "Overpower" then
		DoItColorCode(5)
	elseif donext == "Rend" then
		DoItColorCode(6)
	elseif donext == "Slam" then
		DoItColorCode(7)
	elseif donext == "Execute" then
		DoItColorCode(8)
	elseif donext == "Sunder Armor" then
		DoItColorCode(9)
	elseif donext == "Bloodrage" then
		DoItColorCode(10)
	elseif donext == "Battle Shout" then
		DoItColorCode(11)
	elseif donext == "Victory Rush" then
		DoItColorCode(12)
	end

	return
end



function DoItColorCode(code)
	if code == 0 then
		DoItFrame.t:SetTexture(0,0,0)
	elseif code == 1 then
		DoItFrame.t:SetTexture(0.047,0,0)
	elseif code == 2 then
		DoItFrame.t:SetTexture(0.094,0,0)
	elseif code == 3 then
		DoItFrame.t:SetTexture(0,0.047,0)
	elseif code == 4 then
		DoItFrame.t:SetTexture(0.047,0.047,0)
	elseif code == 5 then
		DoItFrame.t:SetTexture(0.094,0.047,0)
	elseif code == 6 then
		DoItFrame.t:SetTexture(0,0.094,0)
	elseif code == 7 then
		DoItFrame.t:SetTexture(0.047,0.094,0)
	elseif code == 8 then
		DoItFrame.t:SetTexture(0.094,0.094,0)
	elseif code == 9 then
		DoItFrame.t:SetTexture(0,0,0.047)
	elseif code == 10 then
		DoItFrame.t:SetTexture(0.047,0,0.047)
	elseif code == 11 then
		DoItFrame.t:SetTexture(0.094,0,0.047)
	elseif code == 12 then
		DoItFrame.t:SetTexture(0,0.047,0.047)
	elseif code == 13 then
		DoItFrame.t:SetTexture(0.047,0.047,0.047)
	elseif code == 14 then
		DoItFrame.t:SetTexture(0.094,0.047,0.047)
	elseif code == 15 then
		DoItFrame.t:SetTexture(0,0.094,0.047)
	elseif code == 16 then
		DoItFrame.t:SetTexture(0.047,0.094,0.047)

	end

	return
end

function DoItUtlRdy()
	return ((GetTime() - LastUtl) > UtlCD) or ((GetTime() - LastUtl) < UtlTick)
end

function DoItUtlRst()
	if (GetTime() - LastUtl) > 2*UtlTick then
		LastUtl = GetTime()
		LastMn = GetTime()
	end
	return
end

function DoItMnRdy()
	return ((GetTime() - LastMn) > MnCD) or ((GetTime() - LastMn) < UtlTick)
end

function DoItMnRst()
	if (GetTime() - LastMn) > 2*UtlTick then
		LastMn = GetTime()
	end
	return
end

DoItFrame:RegisterEvent("PLAYER_ALIVE");
DoItFrame:RegisterEvent("PLAYER_LOGIN");
DoItFrame:RegisterEvent("PLAYER_TALENT_UPDATE");

local function eventHandler(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		DoItCombat( ... )
	else
		DiItInit()
	end
	return
end

DoItFrame:SetScript("OnEvent", eventHandler);
