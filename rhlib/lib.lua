-- Rotation Helper Library by Timofeev Alexey
SetCVar("cameraDistanceMax", 50)
SetCVar("cameraDistanceMaxFactor", 3.4)

local zoneData = { -- {width, height}
	Arathi = { 3599.9998779297, 2399.9999237061, 1},
	Ogrimmar = { 1402.6044921875, 935.41662597656, 2},
	Undercity = { 959.37503051758, 640.10412597656, 4},
	Barrens = { 10133.333007813, 6756.2498779297, 5},
	Darnassis = { 1058.3332519531, 705.7294921875, 6},
	AzuremystIsle = { 4070.8330078125, 2714.5830078125, 7},
	UngoroCrater = { 3699.9998168945, 2466.6665039063, 8},
	BurningSteppes = { 2929.166595459, 1952.0834960938, 9},
	Wetlands = { 4135.4166870117, 2756.25, 10},
	Winterspring = { 7099.9998474121, 4733.3332519531, 11},
	Dustwallow = { 5250.0000610352, 3499.9997558594, 12},
	Darkshore = { 6549.9997558594, 4366.6665039063, 13},
	LochModan = { 2758.3331298828, 1839.5830078125, 14},
	BladesEdgeMountains = { 5424.9997558594, 3616.6663818359, 15},
	Durotar = { 5287.4996337891, 3524.9998779297, 16},
	Silithus = { 3483.333984375, 2322.916015625, 17},
	ShattrathCity = { 1306.25, 870.83337402344, 18},
	Ashenvale = { 5766.6663818359, 3843.7498779297, 19},
	Azeroth = { 40741.181640625, 27149.6875, 20},
	Nagrand = { 5525, 3683.3331680298, 21},
	TerokkarForest = { 5399.9997558594, 3600.0000610352, 22},
	EversongWoods = { 4925, 3283.3330078125, 23},
	SilvermoonCity = { 1211.4584960938, 806.7705078125, 24},
	Tanaris = { 6899.9995269775, 4600, 25},
	Stormwind = { 1737.499958992, 1158.3330078125, 26},
	SwampOfSorrows = { 2293.75, 1529.1669921875, 27},
	EasternPlaguelands = { 4031.25, 2687.4998779297, 28},
	BlastedLands = { 3349.9998779297, 2233.333984375, 29},
	Elwynn = { 3470.8332519531, 2314.5830078125, 30},
	DeadwindPass = { 2499.9999389648, 1666.6669921875, 31},
	DunMorogh = { 4924.9997558594, 3283.3332519531, 32},
	TheExodar = { 1056.7705078125, 704.68774414063, 33},
	Felwood = { 5749.9996337891, 3833.3332519531, 34},
	Silverpine = { 4199.9997558594, 2799.9998779297, 35},
	ThunderBluff = { 1043.7499389648, 695.83331298828, 36},
	Hinterlands = { 3850, 2566.6666259766, 37},
	StonetalonMountains = { 4883.3331298828, 3256.2498168945, 38},
	Mulgore = { 5137.4998779297, 3424.9998474121, 39},
	Hellfire = { 5164.5830078125, 3443.7498779297, 40},
	Ironforge = { 790.62506103516, 527.6044921875, 41},
	ThousandNeedles = { 4399.9996948242, 2933.3330078125, 42},
	Stranglethorn = { 6381.2497558594, 4254.166015625, 43},
	Badlands = { 2487.5, 1658.3334960938, 44},
	Teldrassil = { 5091.6665039063, 3393.75, 45},
	Moonglade = { 2308.3332519531, 1539.5830078125, 46},
	ShadowmoonValley = { 5500, 3666.6663818359, 47},
	Tirisfal = { 4518.7498779297, 3012.4998168945, 48},
	Aszhara = { 5070.8327636719, 3381.2498779297, 49},
	Redridge = { 2170.8332519531, 1447.916015625, 50},
	BloodmystIsle = { 3262.4990234375, 2174.9999389648, 51},
	WesternPlaguelands = { 4299.9999084473, 2866.6665344238, 52},
	Alterac = { 2799.9999389648, 1866.6666564941, 53},
	Westfall = { 3499.9998168945, 2333.3330078125, 54},
	Duskwood = { 2699.9999389648, 1800, 55},
	Netherstorm = { 5574.999671936, 3716.6667480469, 56},
	Ghostlands = { 3300, 2199.9995117188, 57},
	Zangarmarsh = { 5027.0834960938, 3352.0832519531, 58},
	Desolace = { 4495.8330078125, 2997.9165649414, 59},
	Kalimdor = { 36799.810546875, 24533.200195313, 60},
	SearingGorge = { 2231.2498474121, 1487.4995117188, 61},
	Expansion01 = { 17464.078125, 11642.71875, 62},
	Feralas = { 6949.9997558594, 4633.3330078125, 63},
	Hilsbrad = { 3199.9998779297, 2133.3332519531, 64},
	Sunwell = { 3327.0830078125, 2218.7490234375, 65},
	Northrend = { 17751.3984375, 11834.265014648, 66},
	BoreanTundra = { 5764.5830078125, 3843.7498779297, 67},
	Dragonblight = { 5608.3331298828, 3739.5833740234, 68},
	GrizzlyHills = { 5249.9998779297, 3499.9998779297, 69},
	HowlingFjord = { 6045.8328857422, 4031.2498168945, 70},
	IcecrownGlacier = { 6270.8333129883, 4181.25, 71},
	SholazarBasin = { 4356.25, 2904.1665039063, 72},
	TheStormPeaks = { 7112.4996337891, 4741.666015625, 73},
	ZulDrak = { 4993.75, 3329.1665039063, 74},
	ScarletEnclave = { 3162.5, 2108.3333740234, 76},
	CrystalsongForest = { 2722.9166259766, 1814.5830078125, 77},
	LakeWintergrasp = { 2974.9998779297, 1983.3332519531, 78},
	StrandoftheAncients = { 1743.7499389648, 1162.4999389648, 79},
	Dalaran = { 0, 0, 80},
	Naxxramas = { 1856.2497558594, 1237.5, 81},
	Naxxramas1 = { 1093.830078125, 729.21997070313, 82},
	Naxxramas2 = { 1093.830078125, 729.21997070313, 83},
	Naxxramas3 = { 1200, 800, 84},
	Naxxramas4 = { 1200.330078125, 800.21997070313, 85},
	Naxxramas5 = { 2069.8098144531, 1379.8798828125, 86},
	Naxxramas6 = { 655.93994140625, 437.2900390625, 87},
	TheForgeofSouls = { 11399.999511719, 7599.9997558594, 88},
	TheForgeofSouls1 = { 1448.0998535156, 965.400390625, 89},
	AlteracValley = { 4237.4998779297, 2824.9998779297, 90},
	WarsongGulch = { 1145.8333129883, 764.58331298828, 91},
	IsleofConquest = { 2650, 1766.6665840149, 92},
	TheArgentColiseum = { 2599.9999694824, 1733.3333435059, 93},
	TheArgentColiseum1 = { 369.9861869812, 246.65798950195, 95},
	TheArgentColiseum2 = { 739.99601745606, 493.33001708984, 96},
	HrothgarsLanding = { 3677.0831298828, 2452.083984375, 97},
	AzjolNerub = { 1072.9166450501, 714.58329772949, 98},
	AzjolNerub1 = { 752.97399902344, 501.98300170898, 99},
	AzjolNerub2 = { 292.97399902344, 195.31597900391, 100},
	AzjolNerub3 = { 367.5, 245, 101},
	Ulduar77 = { 3399.9998168945, 2266.6666641235, 102},
	Ulduar771 = { 920.1960144043, 613.46606445313, 103},
	DrakTharonKeep = { 627.08331298828, 418.75, 104},
	DrakTharonKeep1 = { 619.94100952148, 413.29399108887, 105},
	DrakTharonKeep2 = { 619.94100952148, 413.29399108887, 106},
	HallsofReflection = { 12999.999511719, 8666.6665039063, 107},
	HallsofReflection1 = { 879.02001953125, 586.01953125, 108},
	TheObsidianSanctum = { 1162.499917984, 775, 109},
	HallsofLightning = { 3399.9999389648, 2266.6666641235, 110},
	HallsofLightning1 = { 566.23501586914, 377.48999023438, 111},
	HallsofLightning2 = { 708.23701477051, 472.16003417969, 112},
	IcecrownCitadel = { 12199.999511719, 8133.3330078125, 113},
	IcecrownCitadel1 = { 1355.4700927734, 903.64703369141, 114},
	IcecrownCitadel2 = { 1067, 711.33369064331, 115},
	IcecrownCitadel3 = { 195.46997070313, 130.31500244141, 116},
	IcecrownCitadel4 = { 773.71008300781, 515.81030273438, 117},
	IcecrownCitadel5 = { 1148.7399902344, 765.82006835938, 118},
	IcecrownCitadel6 = { 373.7099609375, 249.1298828125, 119},
	IcecrownCitadel7 = { 293.26000976563, 195.50701904297, 120},
	IcecrownCitadel8 = { 247.92993164063, 165.28799438477, 121},
	TheRubySanctum = { 752.08331298828, 502.08325195313, 122},
	VioletHold = { 383.33331298828, 256.25, 123},
	VioletHold1 = { 256.22900390625, 170.82006835938, 124},
	NetherstormArena = { 2270.833190918, 1514.5833740234, 125},
	CoTStratholme = { 1824.9999389648, 1216.6665039063, 126},
	CoTStratholme1 = { 1125.299987793, 750.19995117188, 127},
	TheEyeofEternity = { 3399.9998168945, 2266.6666641235, 128},
	TheEyeofEternity1 = { 430.07006835938, 286.71301269531, 129},
	Nexus80 = { 2600, 1733.3332214356, 130},
	Nexus801 = { 514.70697021484, 343.13897705078, 131},
	Nexus802 = { 664.70697021484, 443.13897705078, 132},
	Nexus803 = { 514.70697021484, 343.13897705078, 133},
	Nexus804 = { 294.70098876953, 196.46398925781, 134},
	VaultofArchavon = { 2599.9998779297, 1733.3332519531, 135},
	VaultofArchavon1 = { 1398.2550048828, 932.17001342773, 136},
	Ulduar = { 3287.4998779297, 2191.6666259766, 137},
	Ulduar1 = { 669.45098876953, 446.30004882813, 138},
	Ulduar2 = { 1328.4609985352, 885.63989257813, 139},
	Ulduar3 = { 910.5, 607, 140},
	Ulduar4 = { 1569.4599609375, 1046.3000488281, 141},
	Ulduar5 = { 619.46899414063, 412.97998046875, 142},
	Dalaran1 = { 830.01501464844, 553.33984375, 143},
	Dalaran2 = { 563.22399902344, 375.48974609375, 144},
	Gundrak = { 1143.7499694824, 762.49987792969, 145},
	Gundrak1 = { 905.03305053711, 603.35009765625, 146},
	TheNexus = { 0, 0, 147},
	TheNexus1 = { 1101.2809753418, 734.1875, 148},
	PitofSaron = { 1533.3333129883, 1022.9166717529, 149},
	Ahnkahet = { 972.91667175293, 647.91661071777, 150},
	Ahnkahet1 = { 972.41796875, 648.2790222168, 151},
	ArathiBasin = { 1756.249923706, 1170.8332519531, 152},
	UtgardePinnacle = { 6549.9995117188, 4366.6665039063, 153},
	UtgardePinnacle1 = { 548.93601989746, 365.95701599121, 154},
	UtgardePinnacle2 = { 756.17994308472, 504.1190032959, 155},
	UtgardeKeep = { 0, 0, 156},
	UtgardeKeep1 = { 734.58099365234, 489.72150039673, 157},
	UtgardeKeep2 = { 481.08100891113, 320.72029304504, 158},
	UtgardeKeep3 = { 736.58100891113, 491.05451202393, 159},
}

local zoneList = {}
local mapFile
for continent in pairs({ GetMapContinents() }) do
	zoneList[continent] = zoneList[continent] or {}
	for zone, name in pairs({ GetMapZones(continent) }) do
		SetMapZoom(continent, zone)
		mapFile = GetMapInfo()
		zoneList[continent][zone] = zoneList[continent][zone] or {name=name, map=mapFile}
	end
end

local frame=CreateFrame("Frame",nil,UIParent)
-- attach events
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_SENT")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:RegisterEvent("PLAYER_ENTERING_WORLD") --This event fires before DungeonLevel(), ZoneName() and GetPlayerCoords() are updated

if HarmfulCastingSpell == nil then HarmfulCastingSpell = {} end
local currentMap, hasLevels, zoneSize_X, zoneSize_Y

local function GetMapData()
    local tex = GetMapInfo() or "?"
	local level = GetCurrentMapDungeonLevel()
	--These zones return the wrong dungeon level.
	if tex == "Ulduar" or tex == "CoTStratholme" then 
		level = level-1 
	end
	return tex, level
end

local function GetZoneMap()								--
-- Returns the map the user's currently looking at. 	--
-- This is used when GetUnitPosition() changes the map.	--
----------------------------------------------------------
	local tex, level = GetMapData()
	if level>0 then
		tex=tex..level
	end
	local cMap=tex
	if zoneData[cMap] then
		return cMap
	end
	return currentMap
end

local function OnUpdate()
	local zoneText = GetZoneMap()
	if ("IcecrownCitadel7" == zoneText) and (currentMap~="IcecrownCitadel7") then
        ZoneChanged("ZoneText")
	end
end
frame:SetScript("OnUpdate", OnUpdate)

local function ZoneChanged(event)			--
-- Function copied from AVR.			--
-- It's better then what I was doing.	--
------------------------------------------
	if event=="ZONE_CHANGED" and not hasLevels then return end
	SetMapToCurrentZone()
	local tex, level = GetMapData()
	hasLevels=(level>0)
	if level>0 then
		tex=tex..level
	end
	currentMap=tex
    if zoneData[currentMap] then
        zoneSize_X, zoneSize_Y = unpack(zoneData[currentMap])
	end
end

function GetYardCoords(unit)
	if not unit then unit = "player" end
-- Returns our coords in yards instead of map coords.							--
-- Every map has coords of 0-100, but each zone is a different size in yards.	--
----------------------------------------------------------------------------------
	local x, y = GetPlayerMapPosition(unit)
	if not zoneSize_X or not zoneSize_Y then 
		local mapFileName, textureHeight, textureWidth = GetMapInfo()
        if not mapFileName then 
            textureWidth = 1
            textureHeight = 1
        end
		zoneSize_X = textureWidth
		zoneSize_Y = textureHeight
	end
	------------------------------------------
	local yX = zoneSize_X * x
	local yY = zoneSize_Y * y
	return yX, yY
end

local LagTime = 0
local sendTime = 0
local function onEvent(self, event, ...)
    if event:match("^ZONE_CHANGED") or event == "PLAYER_ENTERING_WORLD" then 
        ZoneChanged(event)
    end
    if event:match("^UNIT_SPELLCAST") then
        local unit, spell = select(1,...)
        if spell and unit == "player" then
            if event == "UNIT_SPELLCAST_START" then
                if not sendTime then return end
                LagTime = GetTime() - sendTime
            end
            if event == "UNIT_SPELLCAST_SENT" then
                sendTime = GetTime()
            end
        end
        return
    end
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, agrs12, agrs13,agrs14 = select(1, ...)
        if type:match("SPELL_DAMAGE") then
            if spellName and agrs12 > 0 then
                local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellId) 
                if castTime > 0 then
                    HarmfulCastingSpell[spellName] = true
                end
            end
        end
    end
end
frame:SetScript("OnEvent", onEvent)


function IsHarmfulCast(spellName)
    return HarmfulCastingSpell[spellName]
end

function GetLagTime()
    return LagTime
end

function GetSpellId(name, rank)
    local link = GetSpellLink(name,rank)
    if not link then return nil end
    return 0 + link:match("spell:%d+"):match("%d+")
end

function IsPlayerCasting()
    local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo("player")
    if spell == nil then
        spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo("player")
    end
    if not spell or not endTime then return false end
    local res = ((endTime/1000 - GetTime()) < LagTime)
    if res then return false end
    return true
end

function IsBattleField()
    return (GetBattlefieldInstanceRunTime() > 0)
end

function IsArena()
    return (UnitName("arena1") or UnitName("arena2") or UnitName("arena3")  or UnitName("arena4") or UnitName("arena5"))
end

function IsPvP()
    return (IsBattleField() or IsArena() or (IsValidTarget("target") and UnitIsPlayer("target")))
end

function GetClass(target)
    if not target then target = "player" end
    local _, class = UnitClass(target)
    return class
end

function GetUnitType(target)
    if not target then target = "target" end
    local unitType = UnitName(target)
    if UnitIsPlayer(target) then
        unitType = GetClass(target)
    end
    if UnitIsPet(target) then
        unitType ='PET'
    end
    return unitType
end

function UnitIsNPC(unit)
    return not (UnitIsPlayer(unit) or UnitPlayerControlled(unit) or UnitCanAttack("player", unit));
end

function UnitIsPet(unit)
    return not UnitIsNPC(unit) and not UnitIsPlayer(unit) and UnitPlayerControlled(unit);
end 


function HasSpell(spellName)
    local spell = GetSpellInfo(spellName)
    return spell == spellName
end

function UseHealPotion()
    local potions = { 
    "Камень здоровья из Скверны",
    "Великий камень здоровья",
    "Рунический флакон с лечебным зельем",
    "Бездонный флакон с лечебным зельем",
    }
    local ret = false
    for name,value in pairs(potions) do 
        if not ret and UseItem(value) then ret = true end
    end
    return ret
end


IgnoredNames = {}

function Ignore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then 
        Notify(target .. " not exists")
        return 
    end
    IgnoredNames[n] = true
    Notify("Ignore " .. n)
end

function IsIgnored(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil or not IgnoredNames[n] then return false end
    -- Notify(n .. " in ignore list")
    return true
end

function NotIgnore(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n then 
        IgnoredNames[n] = false
        Notify("Not ignore " .. n)
    end
end

function NotIgnoreAll()
    wipe(IgnoredNames)
    Notify("Not ignore all")
end

function IsValidTarget(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then return false end
    if IsIgnored(target) then return false end
    if UnitIsDeadOrGhost(target) then return false end
    if UnitIsEnemy("player",target) and UnitCanAttack("player", target) then return true end 
    if (UnitInParty(target) or UnitInRaid(target)) then return false end 
    return UnitCanAttack("player", target)
end

function IsInteractTarget(t)
    if UnitExists(t) 
        and not IsIgnored(t) 
        and not UnitIsCharmed(t)
        and not UnitIsDeadOrGhost(t) 
        and not UnitIsEnemy("player",t)
        and UnitIsConnected(t)
    then return true end 
    return false
end

local HealComm = LibStub("LibHealComm-4.0")
function UnitGetIncomingHeals(target, s)
    if not target then 
        target = "player" 
    end
    if not s then 
        if UnitHealth100(target) < 10 then return 0 end
        s = 4
        if UnitThreatSituation(target) == 3 then s = 2 end
    end
    return HealComm:GetHealAmount(UnitGUID(target), HealComm.CASTED_HEALS, GetTime() + s) or 0
end

function CalculateHP(t)
  return 100 * UnitHP(t) / UnitHealthMax(t)
end

function UnitHP(t)
  local incomingheals = UnitGetIncomingHeals(t)
  local hp = UnitHealth(t) + incomingheals
  if hp > UnitHealthMax(t) then hp = UnitHealthMax(t) end
  return hp
end

function InGroup()
    return (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0)
end

function GetUnitNames()
    local units = {"player", "target", "focus" }
    local members = GetPartyOrRaidMembers()
    for i = 1, #members, 1 do 
        table.insert(units, members[i])
        table.insert(units, members[i] .."pet")
    end
    table.insert(units, "mouseover")
    realUnits = {}
    for i = 1, #units, 1 do 
        local u = units[i]
        local exists = false
        for j = 1, #realUnits, 1 do
            if UnitName(u) and IsOneUnit(realUnits[j], u) then exists = true end
        end
        if not exists then table.insert(realUnits, u) end
    end
    return realUnits
end

function GetPartyOrRaidMembers()
    local members = {}
    local group = "party"
    if GetNumRaidMembers() > 0 then group = "raid" end
    for i = 1, 40, 1 do 
        if UnitExists(group..i) and UnitName(group..i) ~= nil then table.insert(members, group..i) end
    end
--~     table.sort(members, function(u1, u1) return (UnitThreatSituation(u1) > UnitThreatSituation(u2)) end)
    return members
end


function GetHarmTarget()
    local units = {"target","mouseover","focus","targetlastenemy","arena1","arena2","arena3","arena4","arena5","bos1","bos2","bos3","bos4"}
    local members = GetPartyOrRaidMembers()
    for i = 1, #members, 1 do 
         table.insert(units, members[i] .."-target")
    end
    realUnits = {}
    for i = 1, #units, 1 do 
        local u = units[i]
        local exists = false
        for j = 1, #realUnits, 1 do
            if IsOneUnit(realUnits[j], u) then exists = true end
        end
        if not exists and IsValidTarget(u) then table.insert(realUnits, u) end
    end
    return realUnits
end


function tContainsKey(table, key)
    for name,value in pairs(table) do 
        if key == name then return true end
    end
    return false
end


function IsReadySlot(slot)
    local itemID = GetInventoryItemID("player",slot)
    if not itemID or (IsItemInRange(itemID, "target") == 0) then return false end
    if not IsReadyItem(itemID) then return false end
    return true
end


function UseSlot(slot)
    if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end  
    if IsPlayerCasting() then return false end
    if not IsReadySlot(slot) then return false end
    RunMacroText("/use " .. slot) 
    return true
end

function HasDebuff(debuff, last, target)
    if debuff == nil then return false end
    if target == nil then target = "target" end
    if last == nil then last = 0.1 end
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, debuff) 
    if name == nil then return false end;
    return (expirationTime - GetTime() >= last or expirationTime == 0)
end

function HasBuff(buff, last, target)
    if buff == nil then return false end
    if target == nil then target = "player" end
    if last == nil then last = 0.1 end
    local name, _, _, _, _, _, Expires = UnitBuff(target, buff)
    if name == nil then return false end;
    return (Expires - GetTime() >= last or Expires == 0)
end

function GetBuffStack(aura, target)
    if aura == nil then return false end
    if target == nil then target = "player" end
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(target, aura) 
    if not name or unitCaster ~= "player" or not count then return 0 end;
    return count
end

function GetDebuffTime(aura, target)
    if aura == nil then return false end
    if target == nil then target = "player" end
    local name, _, _, count, _, _, Expires  = UnitDebuff(target, aura) 
    if not name then return 0 end
    if expirationTime == 0 then return 10 end
    local left =  expirationTime - GetTime()
    if left < 0 then left = 0 end
    return left
end

function GetDebuffStack(aura, target)
    if aura == nil then return false end
    if target == nil then target = "target" end
    local name, _, _, count, _, _, Expires  = UnitDebuff(target, aura) 
    if not name or not count then return 0 end;
    return count
end


function GetMyDebuffTime(debuff, target)
    if debuff == nil then return false end
    if target == nil then target = "target" end
    local i = 1
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
    local result = false
        while (i <= 40) and not result do
        if name and strlower(name):match(strlower(debuff)) and (unitCaster == "player")then 
            result = true
        end
        i = i + 1
        if not result then
            name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
        end
    end
    if not result then return 0 end
    if expirationTime == 0 then return 10 end
    local left =  expirationTime - GetTime()
    if left < 0 then left = 0 end
    return left
end



function FindAura(aura, target)
    if aura == nil then return nil end
    if target == nil then target = "player" end
    local i = 1
    local name  = UnitAura(target, i)
    local result = false
    while (i <= 40) and not result  do
        if name and strlower(name):match(strlower(aura)) then result = name end
        i = i + 1
        if not result then name = UnitAura(target, i) end
    end
    return result
end

function HasMyBuff(buff, last, target)
    if buff == nil then return false end
    if target == nil then target = "player" end
    if last == nil then last = 0.1 end
    local i = 0
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(target, i)
    local result = false
    while (i <= 40) and not result do
        if name and strlower(name):match(strlower(buff)) and (unitCaster == nil or unitCaster == "player") then 
            result = true
        end
        i = i + 1
        if not result then
            name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(target, i)
        end
    end
    if not result then return false end
    return (expirationTime - GetTime() >= last or expirationTime == 0)
end

function HasMyDebuff(debuff, last, target)
    if debuff == nil then return false end
    if target == nil then target = "target" end
    if last == nil then last = 0.1 end
    local i = 0
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
    local result = false
    while (i <= 40) and not result do
        if name and strlower(name):match(strlower(debuff)) and (unitCaster == "player") then 
            result = true
        end
        i = i + 1
        if not result then
            name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
        end
    end
    if not result then return false end
    return (expirationTime - GetTime() >= last or expirationTime == 0)
end

function GetUtilityTooltips()
    if ( not RH_Tooltip1 ) then
        for idxTip = 1,2 do
            local ttname = "RH_Tooltip"..idxTip
            local tt = CreateFrame("GameTooltip", ttname)
            tt:SetOwner(UIParent, "ANCHOR_NONE")
            tt.left = {}
            tt.right = {}
            -- Most of the tooltip lines share the same text widget,
            -- But we need to query the third one for cooldown info
            for i = 1, 30 do
                tt.left[i] = tt:CreateFontString()
                tt.left[i]:SetFontObject(GameFontNormal)
                if i < 5 then
                    tt.right[i] = tt:CreateFontString()
                    tt.right[i]:SetFontObject(GameFontNormal)
                    tt:AddFontStrings(tt.left[i], tt.right[i])
                else
                    tt:AddFontStrings(tt.left[i], tt.right[4])
                end
            end 
         end
    end
    local tt1,tt2 = RH_Tooltip1, RH_Tooltip2
    
    tt1:ClearLines()
    tt2:ClearLines()
    return tt1,tt2
end

--~ using: TempEnchantName = DetermineTempEnchantFromTooltip(16 or 17)
function DetermineTempEnchantFromTooltip(i_invID)
    local tt1,tt2 = GetUtilityTooltips()
    
    tt1:SetInventoryItem("player", i_invID)
    local n,h = tt1:GetItem()

    tt2:SetHyperlink(h)
    
    -- Look for green lines present in tt1 that are missing from tt2
    local nLines1, nLines2 = tt1:NumLines(), tt2:NumLines()
    local i1, i2 = 1,1
    while ( i1 <= nLines1 ) do
        local txt1 = tt1.left[i1]
        if ( txt1:GetTextColor() ~= 0 ) then
            i1 = i1 + 1
        elseif ( i2 <= nLines2 ) then
            local txt2 = tt2.left[i2]
            if ( txt2:GetTextColor() ~= 0 ) then
                i2 = i2 + 1
            elseif (txt1:GetText() == txt2:GetText()) then
                i1 = i1 + 1
                i2 = i2 + 1
            else
                break
            end
        else
            break
        end
    end
    if ( i1 <= nLines1 ) then
        local line = tt1.left[i1]:GetText()
        local paren = line:find("[(]")
        if ( paren ) then
            line = line:sub(1,paren-2)
        end
        return line
    end    
end

function Runes(slot)
    local c = 0
    if slot == 1 then
       if IsRuneReady(1) then c = c + 1 end
       if IsRuneReady(2) then c = c + 1 end
    elseif slot == 2 then
        if IsRuneReady(5) then c = c + 1 end
        if IsRuneReady(6) then c = c + 1 end
    elseif slot == 3 then
        if IsRuneReady(3) then c = c + 1 end
        if IsRuneReady(4) then c = c + 1 end
    end
    return c;
end

function NoRunes(t)
    if (t == nil) then t = 1.6 end
    if GetRuneCooldownLeft(1) < t then return false end
    if GetRuneCooldownLeft(2) < t then return false end
    if GetRuneCooldownLeft(3) < t then return false end
    if GetRuneCooldownLeft(4) < t then return false end
    if GetRuneCooldownLeft(5) < t then return false end
    if GetRuneCooldownLeft(6) < t then return false end
    return true
end

function IsRuneReady(id)
    local left = GetRuneCooldownLeft(id)
    if left == 0 then return true end
    return false;
end


function GetRuneCooldownLeft(id)
    local start, duration, enabled = GetRuneCooldown(id);
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    if left < 0 then left = 0 end
    return left;
end


function GetItemCooldownLeft(name)
    local start, duration = GetItemCooldown(name);
    if not start then return 0 end
    if not duration or duration < 1.45 then duration = 1.45  end
    local left = start + duration - GetTime()
    if left < 0.01 then 
        return 0
    end
    return left
end

function IsReadyItem(name)
   local usable = IsUsableItem(name) 
   if not usable then return true end
   local left = GetItemCooldownLeft(name)
   return (left < 0.01)
end


function UseItem(itemName)
    if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end  
    if IsPlayerCasting() then return false end
    if not IsEquippedItem(itemName) and not IsUsableItem(itemName) then return false end
    if not IsReadyItem(itemName) then return false end
    RunMacroText("/use " .. itemName)
    return true
end

function UseEquippedItem(item)
    if IsEquippedItem(item) and UseItem(item) then return true end
    return false
end

function UseMount(mountName)
    if IsPlayerCasting() then return false end
    if InGCD() then return false end
    if IsMounted()then return false end
    if IsDebug() then
        print(mountName)
    end
    RunMacroText("/use "..mountName)
    return true
end

  
  
  
  
function HasTotem(name, last)
--[[Где (1) Это Огненный 
(2) = Земляной
(3) = Водный
(4) = Воздух]]
    if not last then last = 0.01 end
    
    local n = tonumber(name)
    if n ~= nil then
        local _, totemName, startTime, duration = GetTotemInfo(n)
        if totemName and startTime and (startTime+duration-GetTime() > last) then return totemName end
        return false
    end
    
    for index=1,4 do
        local _, totemName, startTime, duration = GetTotemInfo(index)
        if totemName and strlower(totemName):match(strlower(name)) and startTime and (startTime+duration-GetTime() > last) then return true end
    end
    return false
end

function TotemCount()
    local n = 0
    for index=1,4 do
        local _, totemName, startTime, duration = GetTotemInfo(index)
        if totemName and startTime and (startTime+duration-GetTime() > 0.01) then n = n + 1 end
    end
    return n
end

function GetGCDSpellID()
    -- Use these spells to detect GCD
	local GCDSpells = {
		PALADIN = 635,       -- Holy Light I [OK]
		PRIEST = 1243,       -- Power Word: Fortitude I
		SHAMAN = 8071,       -- Rockbiter I
		WARRIOR = 772,       -- Rend I (only from level 4) [OK]
		DRUID = 5176,        -- Wrath I
		MAGE = 168,          -- Frost Armor I
		WARLOCK = 687,       -- Demon Skin I
		ROGUE = 1752,        -- Sinister Strike I
		HUNTER = 1978,       -- Serpent Sting I (only from level 4)
		DEATHKNIGHT = 45902, -- Blood Strike I
	}

    return GCDSpells[GetClass()]
end

function InGCD()
    local gcdStart = GetSpellCooldown(GetGCDSpellID());
    return (gcdStart and (gcdStart>0));
end

function GetMeleeSpell()
    -- Use these spells to melee GCD
	local MeleeSpells = {
		DRUID = "Цапнуть",        
		DEATHKNIGHT = "Удар чумы", 
        PALADIN = "Щит праведности",
        SHAMAN = "Удар бури"
	}
    
    return MeleeSpells[GetClass()]
end

function InMelee(target)
    if (target == nil) then target = "target" end
    return (IsSpellInRange(GetMeleeSpell(),target) == 1)
end

function SpellCastTime(spell)
    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spell)
    if not name then return 0 end
    return castTime / 1000
end

function IsOneUnit(unit1, unit2)
    if not UnitExists(unit1) or not UnitExists(unit2) then return false end
    return UnitGUID(unit1) == UnitGUID(unit2)
end

function UnitThreat(u, t)
    local threat = UnitThreatSituation(u, t)
    if threat == nil then threat = 0 end
    return threat
end


function UnitHealth100(target)
    if target == nil then target = "player" end
    return UnitHealth(target) * 100 / UnitHealthMax(target)
end

function UnitMana100(target)
    if target == nil then target = "player" end
    return UnitMana(target) * 100 / UnitManaMax(target)
end

--~ local GCDSpellList = {}
function IsReadySpell(name)
    local usable, nomana = IsUsableSpell(name)
    if not usable then return false end
    local left = GetSpellCooldownLeft(name)
    local spellName, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(name)
--~     local leftGCD = GetSpellCooldownLeft(GetGCDSpellID())
--~     
--~     if InGCD() and tContains(GCDSpellList,name) then
--~         return false
--~     end
--~     
--~     if InGCD() and (left == leftGCD) then
--~         if not tContains(GCDSpellList,name) then 
--~             tinsert(GCDSpellList, name)
--~         end
--~     end
    
    if left > 0 then return false end
    
    if cost and cost > 0 and not(UnitPower("player", powerType) >= cost) then return false end
    
    return true
end

function GetSpellCooldownLeft(name)
    local start, duration, enabled = GetSpellCooldown(name);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
--~     if duration < 1 then 
--~         print(name, duration)
--~         duration = 1.4 
--~     end
    local left = start + duration - GetTime()
    return left
end


function CheckDistanceCoord(unit, x2, y2)
    local x1,y1 = GetYardCoords(unit)
    if x1 == 0 or y1 == 0 or x2 == 0 or y2 == 0 then return nil end
    local dx = (x1-x2)
    local dy = (y1-y2)
    return sqrt( dx^2 + dy^2 )
end

function CheckDistance(unit1,unit2)
  local x2,y2 = GetYardCoords(unit2)
  return CheckDistanceCoord(unit1, x2,y2)
end

function InRange(spell, target) 
    if target == nil then target = "target" end
    if spell and IsSpellInRange(spell,target) == 0 then return false end 
    return true    
end

function UseSpell(spellName, target)
    if SpellIsTargeting() then return false end 
     
    if IsPlayerCasting() then return false end

    local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange  = GetSpellInfo(spellName)
    
    if not name or (name ~= spellName)  then
        if IsDebug() then print("UseSpell:Ошибка! Спел [".. spellName .. "] не найден!") end
        return false;
    end
    
    
    if not InRange(name,target) then return false end  
    if IsReadySpell(spellName) then
        
        local cast = "/cast "
        if target ~= nil then cast = cast .."[target=".. target .."] "  end
        if cost and cost > 0 and UnitManaMax("player") > cost and UnitMana("player") <= cost then return false end
        if IsDebug() then
            -- print(spellName, cost, UnitMana("player"), target)
        end
        
        RunMacroText(cast .. "!" .. spellName)
        if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end 

        return true
    end
    return false
end


-------------------------------------------------------------------------------
-- Debug & Notification Frame
-------------------------------------------------------------------------------
-- Update Debug Frame
NotifyFrame = nil
function NotifyFrame_OnUpdate()
        if (NotifyFrameTime < GetTime() - 5) then
                local alpha = NotifyFrame:GetAlpha()
                if (alpha ~= 0) then NotifyFrame:SetAlpha(alpha - .02) end
                if (aplha == 0) then NotifyFrame:Hide() end
        end
end

-- Debug messages.
function Notify(message)
        NotifyFrame.text:SetText(message)
        NotifyFrame:SetAlpha(1)
        NotifyFrame:Show()
        NotifyFrameTime = GetTime()
end

-- Debug Notification Frame
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


function echo(msg, cls)
    if (cls ~= nil) then UIErrorsFrame:Clear() end
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end


function chat(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1.0, 0.5, 0.5);
end



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

function sell(name) 
    if not name then name = "" end
    for bag = 0,4,1 do for slot = 1, GetContainerNumSlots(bag), 1 do local item = GetContainerItemLink(bag,slot); if item and string.find(item,name) then UseContainerItem(bag,slot) end; end;end
end




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

