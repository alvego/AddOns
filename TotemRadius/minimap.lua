local folder, core = ...

--Globals
local GetCVar = GetCVar
local rotateMinimap = GetCVar("rotateMinimap") == "1"
local Minimap = Minimap
local indoors = Minimap:GetZoom() == GetCVar( "minimapInsideZoom" ) + 0;
local CreateFrame = CreateFrame
local Debug = core.Debug
local GetPlayerFacing = GetPlayerFacing
local MiniMapCompassRing = MiniMapCompassRing
local math_sin = math.sin
local math_cos = math.cos
local P -- self.db.profile
local activeTotems
local totemInfo = core.totemInfo
local addonDir = core.addonDir
local pairs = pairs
local math_random = math.random
local GetPlayerMapPosition = GetPlayerMapPosition

local minimapTotems = {}

local minimapSize = { -- size of minimap in yards.
	indoor = {
		[0] = 150,
		[1] = 120,
		[2] = 90,
		[3] = 60,
		[4] = 40,
		[5] = 25,
	},
	outdoor = {
		[0] = 233 + 1/3,
		[1] = 200,
		[2] = 166 + 2/3,
		[3] = 133 + 1/6,
		[4] = 100,
		[5] = 66 + 2/3,
	},
}

local prev_OnEnable = core.OnEnable;
function core:OnEnable(...)
	prev_OnEnable(self, ...)
	P = self.db.profile
	activeTotems = self.activeTotems
	
	self:HookSetZoom()
	rotateMinimap = GetCVar("rotateMinimap") == "1"
end

function core:CVAR_UPDATE(event, ...)
	local cvar, value = ...
	if cvar == "ROTATE_MINIMAP" then
		rotateMinimap = value == "1"
	end
end


function core:HookSetZoom()--	/run TR.HookSetZoom()
	if not self:IsHooked(Minimap, "SetZoom") then
		self:SecureHook(Minimap, "SetZoom", "MinimapSetZoom")
	end
end

function core:MinimapSetZoom(frame, ...)
--~ 	Debug("MinimapSetZoom",...)
	self:UpdateRingSizes()
--~ 	core:MINIMAP_UPDATE_ZOOM("MINIMAP_UPDATE_ZOOM")
end

local function SetSpellSize(icon, size)
	local texture = icon.spellTexture
--~ 	Debug("SetSpellSize", size)
	icon:SetWidth(P.edgeIconSize > 0 and P.edgeIconSize or 1)
	icon:SetHeight(P.edgeIconSize > 0 and P.edgeIconSize or 1)
	
	if size > 0 then
		texture:SetWidth(size)
		texture:SetHeight(size)

		texture:Show()
	else
		texture:Hide()
	end
end

function core:UpdateMiniampSpellSize()
	for GUID, data in pairs(activeTotems) do 
		SetSpellSize(data.minimapIcon, P.iconSize)
	end
end

--[[
local lastZoom = 0
local ignoreZoom = false
function core:MINIMAP_UPDATE_ZOOM(event, ...)
	if ignoreZoom == true then --Keeps us from entering a endless loop due to SetZoom(zoom>0...) later on.
		return
	end
	local Minimap = Minimap
	local zoom = Minimap:GetZoom();
	if zoom ~= lastZoom then --Keeps us from processing the same zoom info repeatedly due to SetZome(zoom) later on. 
		lastZoom = zoom
		if ( GetCVar( "minimapZoom" ) == GetCVar( "minimapInsideZoom" ) ) then -- Indeterminate case
			ignoreZoom = true
 			Minimap:SetZoom( zoom > 0 and zoom - 1 or zoom + 1 ); -- Any change to make the cvars unequal
			ignoreZoom = false
		end
		indoors = Minimap:GetZoom() == GetCVar( "minimapInsideZoom" ) + 0;
		Minimap:SetZoom(zoom);

		local range, size
		local radius = minimapSize[indoors and "indoor" or "outdoor"][Minimap:GetZoom()]
		
		local minimapWidth = Minimap:GetWidth()

		for GUID, data in pairs(activeTotems) do 
			size = (minimapWidth * data.range/radius)
			
			if data.range > 0 then
				data.minimapIcon.outlineTexture:SetWidth(size) -- Set these to whatever height/width is needed 
				data.minimapIcon.outlineTexture:SetHeight(size) -- for your Texture
			end
		end
		
		core:ForceUpdate()
	end
end
]]

--[[
function core:UnhookSetZoom()--	/run TR.HookSetZoom()
	if self:IsHooked(Minimap, "SetZoom") then
		self:Unhook(Minimap, "SetZoom")
	end
end
]]

function core:MINIMAP_UPDATE_ZOOM(event, ...)
--~ 	self:UnhookSetZoom() --Unhook SetZoom so we don't enter a endless loop.
	local zoom = Minimap:GetZoom();
	if GetCVar( "minimapZoom" ) == GetCVar( "minimapInsideZoom" ) then -- Indeterminate case
		Minimap:SetZoom(zoom < 2 and zoom + 1 or zoom - 1)-- Any change to make the cvars unequal
	end
	indoors = Minimap:GetZoom() == GetCVar( "minimapInsideZoom" ) + 0;
	Minimap:SetZoom(zoom);
--~ 	self:HookSetZoom()--Rehook SetZoom.
--~ 	Debug(event, zoom, indoors)
	self:UpdateRingSizes()
end

--~ local lastZoom = 0
function core:UpdateRingSizes()

	local zoom = Minimap:GetZoom()
--~ 	local diffZoom = zoom ~= lastZoom
--~ 	if diffZoom then
		
		local range, size
		local radius = minimapSize[indoors and "indoor" or "outdoor"][zoom]
		
		local minimapWidth = Minimap:GetWidth()
	
		for GUID, data in pairs(activeTotems) do 
			size = (minimapWidth * data.range/radius)
			
			if data.range > 0 then
				data.minimapIcon.outlineTexture:SetWidth(size) -- Set these to whatever height/width is needed 
				data.minimapIcon.outlineTexture:SetHeight(size) -- for your Texture
			end
		end
		
--~ 		lastZoom = zoom
--~ 	end


	
	core:ForceUpdate()
end


local facing
local function CompensateForMinimapRotate(xDist, yDist)
	if GetPlayerFacing then
		facing = GetPlayerFacing()
	else
		facing = -MiniMapCompassRing:GetFacing()
	end

	local cos = math_cos(facing)
	local sin = math_sin(facing)

	local dx, dy = xDist, yDist
	xDist = dx*cos - dy*sin
	yDist = dx*sin + dy*cos
	return xDist, yDist
end

------------------------------------------------------------------------------
local function GetMinimapCoordOffset(self, dist, xDist, yDist)				--
--Returns the offset coords where a icon should be placed on the minimap.	--
------------------------------------------------------------------------------
	local Minimap = Minimap
	local mapWidth = Minimap:GetWidth()
	local mapHeight = Minimap:GetHeight()
	
	local diameter = minimapSize[indoors and "indoor" or "outdoor"][Minimap:GetZoom()] * 2
	local xScale = diameter / mapWidth;
	local yScale = diameter / mapHeight;
	
	
	local mapRadius = diameter / 2;
	local iconDiameter = ((self:GetWidth() / 2) + 3) * xScale;
	
	local maxDist = ((diameter / 2))
	if ( (dist + iconDiameter) > mapRadius ) then 
		--Icon is beyond the range of the minimap.
		--Lets set the coords to be on the edge.
		local factor = (mapRadius - iconDiameter) / dist;
		xDist = xDist * factor;
		yDist = yDist * factor;
		return true, xDist, xScale, yDist, yScale
	end
	return false, xDist, xScale, yDist, yScale
end

function core:UpdateMinimapLocation(totemGUID, range, dist, xDist, yDist, insideRing)
	local icon = minimapTotems[totemGUID]
	
	
	if icon then
	

		
		--Get the correct offset coords for the minimap.
		local onEdge, xDist, xScale, yDist, yScale = GetMinimapCoordOffset(icon, dist, xDist, yDist)
		
		--Do our colour stuff. Also change the size of the spell icon if we're on the edge.
		if range > 0 then
			if onEdge then
				icon.outlineTexture:SetAlpha(0)
				
				if not icon.onEdge then
					icon.onEdge = true
					SetSpellSize(icon, P.edgeIconSize)
				end
			else
				if icon.onEdge then
					icon.onEdge = false
					SetSpellSize(icon, P.iconSize)
				end
				if insideRing == true then
					if P.insideRingAlpha > 0 then
						if P.colourRingBySchool == false then
							icon.outlineTexture:SetVertexColor(P.insideRingColour.r, P.insideRingColour.g, P.insideRingColour.b, P.insideRingAlpha);
						end
					
						icon.outlineTexture:SetAlpha(P.insideRingAlpha)
						icon.outlineTexture:Show()
					else
						icon.outlineTexture:Hide()
					end
				else
					if P.outsideRingAlpha > 0 then
						if P.colourRingBySchool == false then
							icon.outlineTexture:SetVertexColor(P.outsideRingColour.r, P.outsideRingColour.g, P.outsideRingColour.b, P.outsideRingAlpha);
						end
					
						icon.outlineTexture:SetAlpha(P.outsideRingAlpha)
						icon.outlineTexture:Show()
					else
						icon.outlineTexture:Hide()
					end
				end
			end
		end
		
			
		if P.shakeMinimapRings == true and
		not onEdge and
		icon.isInside ~= insideRing then
			icon.isInside = insideRing
			if insideRing == false then
				self:ShakeMinimapRing(icon)
			end
		end
		
		if self.IsShaking ~= true then
			--Check if the minimap is rotating, if so adjust our offset coords.
			if rotateMinimap then
				xDist, yDist = CompensateForMinimapRotate(xDist, yDist)
			end
		
			icon:ClearAllPoints();
			icon:SetPoint("CENTER", Minimap, "CENTER", xDist/xScale, -yDist/yScale);
		end


	end
end

--~ local function SetOnUpdateScript(frame)

--If we don't know the exact coords of a totem, we use the shaman's coords. But this causes the spell icons to stack on each other.
-- These points change the spell icon's position. Fire appearing top left, ground top right, ect. 
local spellSlotPoint = {
	"BOTTOMRIGHT",
	"BOTTOMLEFT",
	"TOPLEFT",
	"TOPRIGHT",
}

----------------------------------------------------------------------------------
function core:AddTotemToMinimap(totemGUID, spellID, totemSlot, range, precise)	--
-- Create a frame for our totem and add textures.								--
----------------------------------------------------------------------------------
	if P.showOnMinimap == true then
		local icon	= CreateFrame("Button",nil,Minimap)
		
		icon:SetWidth(P.edgeIconSize > 0 and P.edgeIconSize or 1)
		icon:SetHeight(P.edgeIconSize > 0 and P.edgeIconSize or 1)
		
		icon.aT = activeTotems[totemGUID]
		icon.totemGUID = totemGUID
		icon.spellID = spellID
		
		local currentMap = core:GetCurrentMap()
		
		icon.currentMap = currentMap
		
		icon.spellTexture = icon:CreateTexture(nil,"ARTWORK")
		icon.spellTexture:SetTexture(totemInfo[spellID].texture)
		SetSpellSize(icon, P.iconSize)
		if precise == true then
			icon.spellTexture:SetPoint("CENTER", icon)
		else
			icon.spellTexture:SetPoint(spellSlotPoint[totemSlot], icon, "CENTER")
		end

		if range > 0 then
			icon.outlineTexture = icon:CreateTexture(nil,"low")
			icon.outlineTexture:SetTexture(addonDir.."textures\\Outline")
			icon.outlineTexture:SetPoint("CENTER", icon);
			icon.outlineTexture:SetAlpha(1)
			
			if P.colourRingBySchool == true then
				icon.outlineTexture:SetVertexColor(P.totemColour[totemSlot].r, P.totemColour[totemSlot].g, P.totemColour[totemSlot].b, 1);
			else
				icon.outlineTexture:SetVertexColor(P.insideRingColour.r, P.insideRingColour.g, P.insideRingColour.b, 1); --first drop, colour it green.
			end

			local radius = minimapSize[indoors and "indoor" or "outdoor"][Minimap:GetZoom()]
			local minimapWidth = Minimap:GetWidth()
			local size = (minimapWidth * range/radius)

			icon.outlineTexture:SetWidth(size) -- Set these to whatever height/width is needed 
			icon.outlineTexture:SetHeight(size) -- for your Texture
		end

		minimapTotems[totemGUID] = icon
		
		icon:ClearAllPoints();
		icon:SetPoint("CENTER", Minimap, "CENTER", 0, 0);
		
		return icon
	end
	return nil
end

function core:RemoveTotemFromMinimap(totemGUID)
	local icon = minimapTotems[totemGUID]
	if icon then
		icon:Hide()
		icon:SetParent(nil)
	end
	if minimapTotems[totemGUID] then
		minimapTotems[totemGUID] = nil
	end
end

function core:HideAllMinimapRings()
	for totemGUID, icon in pairs(minimapTotems) do 
		icon:Hide()
	end
end

function core:ShowAllMinimapRings()
	for totemGUID, icon in pairs(minimapTotems) do 
		icon:Show()
	end
end

----------------------------------------------------------
function core:ShakeMinimapRing(icon)					--
-- Shake a totem ring for half a second on the minimap.	--
----------------------------------------------------------
	local point, relativeTo, relativePoint, xOfs, yOfs = icon:GetPoint()
	if xOfs ~= 0 or yOfs ~= 0 then
		icon.oX = xOfs
		icon.oY = yOfs
		
		icon.IsShaking = true
		icon.lastUpdate = 0
		
		icon:SetScript("OnUpdate", function(self, elapsed)
			self.lastUpdate = self.lastUpdate + elapsed
			
			local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
			if self.lastUpdate >= 0.5 then
				self:SetScript("OnUpdate", nil)
				self.IsShaking = false

				core:TotemUpdate(self.totemGUID, GetPlayerMapPosition("player"))
				return
			end

--~ 			xOfs = xOfs + (math_random(0, 10) - 5) --These go too far away.
--~ 			yOfs = yOfs + (math_random(0, 10) - 5) 
			xOfs = self.oX + (math_random(0, 10) - 5) 
			yOfs = self.oY + (math_random(0, 10) - 5) 
			
			self:ClearAllPoints()
			self:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
		end)
	end
	
end