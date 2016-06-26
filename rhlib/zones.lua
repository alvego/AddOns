-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------

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

------------------------------------------------------------------------------------------------------------------
local zoneList = {}
local mapFile, currentMap, hasLevels, zoneSize_X, zoneSize_Y

for continent in pairs({ GetMapContinents() }) do
	zoneList[continent] = zoneList[continent] or {}
	for zone, name in pairs({ GetMapZones(continent) }) do
		SetMapZoom(continent, zone)
		mapFile = GetMapInfo()
		zoneList[continent][zone] = zoneList[continent][zone] or {name=name, map=mapFile}
	end
end

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

local function ZoneChanged(event, ...)			--
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
AttachEvent('PLAYER_ENTERING_WORLD', ZoneChanged)
AttachEvent('ZONE_CHANGED', ZoneChanged)
AttachEvent('ZONE_CHANGED_NEW_AREA', ZoneChanged)
AttachEvent('ZONE_CHANGED_INDOORS', ZoneChanged)

local function UpdateZone() 
	if ("IcecrownCitadel7" == GetZoneMap()) and (currentMap ~= "IcecrownCitadel7") then 
		ZoneChanged("ZoneText") 
	end 
end
AttachUpdate(UpdateZone)

------------------------------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------------------------------
function CheckDistanceCoord(unit, x2, y2)
    local x1,y1 = GetYardCoords(unit)
    if x1 == 0 or y1 == 0 or x2 == 0 or y2 == 0 then return nil end
    local dx = (x1-x2)
    local dy = (y1-y2)
    return sqrt( dx^2 + dy^2 )
end

------------------------------------------------------------------------------------------------------------------
function CheckDistance(unit1,unit2)
  local x2,y2 = GetYardCoords(unit2)
  return CheckDistanceCoord(unit1, x2,y2)
end

------------------------------------------------------------------------------------------------------------------
function InDistance(unit1,unit2, distance)
  local d = CheckDistance(unit1, unit2)
  return not d or d < distance
end


------------------------------------------------------------------------------------------------------------------
local LastPosX, LastPosY = GetPlayerMapPosition("player")
local InPlace = true
local function UpdateInPlace() 
	local posX, posY = GetPlayerMapPosition("player")
    InPlace = (LastPosX == posX and LastPosY == posY)
    LastPosX ,LastPosY = GetPlayerMapPosition("player")
    if not InPlace then InPlaceTime = GetTime() end
end
AttachUpdate(UpdateInPlace)
-- Игрок не двигается (можно кастить)
InPlaceTime = GetTime()
function PlayerInPlace()
    return InPlace and (GetTime() - InPlaceTime > 0.08) and (not IsFalling() or IsSwimming())
end
