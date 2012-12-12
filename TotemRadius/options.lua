local folder, core = ...

local LibStub = LibStub
local pairs = pairs
local activeTotems = core.activeTotems
local defaultSettings = core.defaultSettings
local GetSpellInfo = GetSpellInfo
local table_getn = table.getn
local table_insert = table.insert
local table_sort = table.sort
local Debug
local type = type
local table_insert = table.insert
local table_sort = table.sort

local L = core.L or LibStub("AceLocale-3.0"):GetLocale(folder, true)

defaultSettings.profile.trackOthersTotems = true
defaultSettings.profile.broadcastTotemLocation = true
defaultSettings.profile.colourRingBySchool = true
defaultSettings.profile.totemColour[1]	= {r=1, g=0, b=0} --red
defaultSettings.profile.totemColour[2]	= {r=0, g=1, b=0} --green
defaultSettings.profile.totemColour[3]	= {r=0, g=0.5, b=1} --cyan
defaultSettings.profile.totemColour[4]	= {r=0.6, g=0.4, b=0.8} --amethyst

defaultSettings.profile.minimapIconRange = 200
defaultSettings.profile.iconSize = 0
defaultSettings.profile.edgeIconSize = 16

defaultSettings.profile.insideRingColour	= {r=0, g=1, b=0} --green, 15% alpha
defaultSettings.profile.outsideRingColour	= {r=1, g=0, b=0} --red 
defaultSettings.profile.insideRingAlpha = 0.2 -- 20%
defaultSettings.profile.outsideRingAlpha = 1 -- 100%
defaultSettings.profile.shakeMinimapRings = true -- 100%


defaultSettings.profile.showOnMinimap = true

local prev_OnInitialize = core.OnInitialize;
function core:OnInitialize()
	prev_OnInitialize(self)
	Debug = self.Debug
end



local defaultShow = {}



local P
local prev_OnEnable = core.OnEnable;
function core:OnEnable()
	prev_OnEnable(self);

	P = self.db.profile
	
	local name
	for spellID, show in pairs(self.totemList) do
		name = GetSpellInfo(spellID)
		defaultShow[name] = show
	end
	
	self:BuildPrefixUI()
end



local CoreOptionsTable = {
	name = titleFull,
	type = "group",
	childGroups = "tab",

	args = {
		core={
			name = L["Core"],
			type = "group",
			order = 1,
			args={
			
				enable = {
					type = "toggle",	order	= 1,
					name	= L["Enable"],
					desc	= L["Enables / Disables the addon"],
					set = function(info,val) 
						if val == true then
							core:Enable()
						else
							core:Disable()
						end
					end,
					get = function(info) return core:IsEnabled() end
				},
			
				trackOthersTotems = {
					type = "toggle",	order	= 2,
					name	= L["Track other's totems"],
					desc	= L["Add other shaman's totems to your minimap."],
					set = function(info,val) 
						P.trackOthersTotems = val
					end,
					get = function(info) return P.trackOthersTotems end
				},
			
				broadcastTotemLocation = {
					type = "toggle",	order	= 3,
					name	= L["Broadcast totem location"],
					desc	= L["Broadcast your totem's location to group members."],
					set = function(info,val) 
						P.broadcastTotemLocation = val
					end,
					get = function(info) return P.broadcastTotemLocation end
				},
				

				
				fireColour = {
					name = L["Fire Colour"],	order	= 10,
					desc = L["Colour of the circle around the totem"],
					type = "color",
					set = function(info,r,g,b,a) 
						P.totemColour[1].r = r
						P.totemColour[1].g = g
						P.totemColour[1].b = b
					end,
					get = function(info) return P.totemColour[1].r, P.totemColour[1].g, P.totemColour[1].b, P.totemColour[1].a end
				},
			
				earthColour = {
					name = L["Earth Colour"],	order	= 11,
					desc = L["Colour of the circle around the totem"],
					type = "color",
					set = function(info,r,g,b,a) 
						P.totemColour[2].r = r
						P.totemColour[2].g = g
						P.totemColour[2].b = b
					end,
					get = function(info) return P.totemColour[2].r, P.totemColour[2].g, P.totemColour[2].b, P.totemColour[2].a end
				},

				waterColour = {
					name = L["Water Colour"],	order	= 12,
					desc = L["Colour of the circle around the totem"],
					type = "color",
					set = function(info,r,g,b,a) 
						P.totemColour[3].r = r
						P.totemColour[3].g = g
						P.totemColour[3].b = b
						P.totemColour[3].a = a
					end,
					get = function(info) return P.totemColour[3].r, P.totemColour[3].g, P.totemColour[3].b, P.totemColour[3].a end
				},
			
			
				airColour = {
					name = L["Air Colour"],	order	= 13,
					desc = L["Colour of the circle around the totem"],
					type = "color",
					set = function(info,r,g,b,a) 
						P.totemColour[4].r = r
						P.totemColour[4].g = g
						P.totemColour[4].b = b
					end,
					get = function(info) return P.totemColour[4].r, P.totemColour[4].g, P.totemColour[4].b, P.totemColour[4].a end
				},
			


				insideRingColour = {
					name = L["Inside range colour"],	order	= 18,
					desc = L["Colour of the ring when you're inside."],
					type = "color",
					hasAlpha	= false,
					set = function(info,r,g,b,a) 
						P.insideRingColour.r = r
						P.insideRingColour.g = g
						P.insideRingColour.b = b
				--~ 		P.insideRingColour.a = a
					end,
					get = function(info) return P.insideRingColour.r, P.insideRingColour.g, P.insideRingColour.b, P.insideRingColour.a end --
				},
				
				
				outsideRingColour = {
					name = L["Outside range colour"],	order	= 20,
					desc = L["Colour of the ring when you're outside."],
					type = "color",
					hasAlpha	= false,
					set = function(info,r,g,b,a) 
						P.outsideRingColour.r = r
						P.outsideRingColour.g = g
						P.outsideRingColour.b = b
				--~ 		P.outsideRingColour.a = a
						
					end,
					get = function(info) return P.outsideRingColour.r, P.outsideRingColour.g, P.outsideRingColour.b, P.outsideRingColour.a end
				},

			}
		},
		
		minimap={
			name = L["Minimap"],
			type = "group",
			order = 3,
			args={

				showOnMinimap = {
					type = "toggle",	order	= 1,
					name	= L["Show on minimap"],
					desc	= L["Show totem rings on minimap."],
					set = function(info,val) 
						P.showOnMinimap = val
						
						if val == true then
							core.updateThrottle = 0.05
							
							core:ShowAllMinimapRings()
						else
							core.updateThrottle = 0.25
							
							core:HideAllMinimapRings()
						end
					end,
					get = function(info) return P.showOnMinimap end
				},
			
				colourRingBySchool = {
					type = "toggle",	order	= 2,
					name	= L["Colour ring by school"],
					desc	= L["Colour the rings on minimap by totem school instead of range"],
					set = function(info,val) 
						P.colourRingBySchool = val
						
						if val == true then
							local totemSlot
							for totemGUID, data in pairs(activeTotems) do 
								totemSlot = data.totemSlot
								data.icon.outlineTexture:SetVertexColor(P.totemColour[totemSlot].r, P.totemColour[totemSlot].g, P.totemColour[totemSlot].b, P.totemColour[totemSlot].a)
							end
						end
						
					end,
					get = function(info) return P.colourRingBySchool end
				},
			
				minimapIconRange = {
					type	= "range",	order	= 3,
					name = L["Minimap Show Range"],
					desc = L["Hide the icon if we're beyond * yards away."],
					min		= 50,
					max		= 200,
					step	= 5,
					set = function(info,val) 
						P.minimapIconRange = val
						core:ForceUpdate()
					end,
					get = function(info) return P.minimapIconRange end
				},

				iconSize = {
					type	= "range",	order	= 4,
					name = L["Icon Size"],
					desc = L["Size of the totem icon on the minimap. (Not the circle)"],
					min		= 0,
					max		= 32,
					step	= 4,
					set = function(info,val) 
						P.iconSize = val;
						core:UpdateMiniampSpellSize()
						core:ForceUpdate()
					end,
					get = function(info) return P.iconSize end
				},
			
				edgeIconSize = {
					type	= "range",	order	= 5,
					name = L["Edge Icon Size"],
					desc = L["Size of the totem icon when on minimap edge"],
					min		= 0,
					max		= 32,
					step	= 4,
					set = function(info,val) 
						P.edgeIconSize = val
						core:ForceUpdate()
					end,
					get = function(info) return P.edgeIconSize end
				},
			
			
			
				insideRingAlpha = {
					type	= "range",	order	= 6,
					name = L["Inside ring transparency"],
					desc = L["When inside, change ring transparency."],
					min		= 0,
					max		= 1,
					step	= 0.05,
					isPercent	= true,
					set = function(info,val) 
						P.insideRingAlpha = val
						core:ForceUpdate()
					end,
					get = function(info) return P.insideRingAlpha end
				},

				
				outsideRingAlpha = {
					type	= "range",	order	= 7,
					name = L["Outside ring transparency"],
					desc = L["When outside, change ring transparency."],
					min		= 0,
					max		= 1,
					step	= 0.05,
					isPercent	= true,
					set = function(info,val) 
						P.outsideRingAlpha = val
						core:ForceUpdate()
					end,
					get = function(info) return P.outsideRingAlpha end
				},
				

				
				shakeMinimapRings = {
					type = "toggle",	order	= 8,
					name	= L["Shake Minimap Rings"],
					desc	= L["When you move outside a ring, shake it briefly."],
					set = function(info,val) 
						P.shakeMinimapRings = val
					end,
					get = function(info) return P.shakeMinimapRings end
				},
				
			},
		},
	},
}
core.CoreOptionsTable = CoreOptionsTable





function core:BuildPrefixUI()--	/script TR.BuildPrefixUI()
	CoreOptionsTable.args.totems = { --reset
		name = L["Totems"],
		type = "group",
		order = 2,
		args={}
	}
	
	
	local totems = {} --sortable list
	
	local totemName
	for spellID, data in pairs(self.totemInfo) do 
		totemName = data.name or GetSpellInfo(spellID)
		if table_getn(totems) == 0 then
			table_insert(totems, #totems+1, totemName)
		else
			for i=1, table_getn(totems) do 
				if totems[i] == totemName then
					break
				elseif i == table_getn(totems) then
					table_insert(totems, #totems+1, totemName)
				end
			end
		end
		
	end
	
	table_sort(totems, function(a,b) 
		if(a and b) then 
			return a < b
		end 
	end)
		--totemOpts
	for i=1, table_getn(totems) do 
		totemName = totems[i]
--~ 		Debug("BuildPrefixUI", i, totems[i])
		
		
		if P.totemOpts[totemName] == nil then
			P.totemOpts[totemName] = {shown = defaultShow[totemName] or 1} --show by default, using a table incase I need to add options later.
		end
		
		if type(P.totemOpts[totemName].shown) == "boolean" then --old show/hide option.
			P.totemOpts[totemName].shown = defaultShow[totemName] or 1 
		end
		
		CoreOptionsTable.args.totems.args[totemName] = {
			type = "select",	order	= i,
			
			name = totemName,
			desc = L["Track %s's radius"]:format(totemName),

			values = function()
				return {
					[1] = L["Raid totems"],
					[2] = L["Party totems"],
					[3] = L["My totem"],
					[4] = L["Never"],
				}
				
			end,
			set = function(info,val) 
				local totemName = info[2]
			
				P.totemOpts[totemName].shown = val
			end,
			get = function(info) return P.totemOpts[info[2]] and P.totemOpts[info[2]].shown end
		}

		
	end
	
	
end

local function GetFireNovaTotems()
	local totems = {}
	
	for totemName in pairs(P.showFireNova) do 
		table_insert(totems, #totems+1, totemName)
	end
	table_sort(totems)

--~ 	for totemName, show in pairs(P.showFireNova) do 
--~ 		totems[totemName] = show 
--~ 	end
	
	
--~ 	
	
	return totems
end
