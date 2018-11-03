-- Rotation Helper Library by Alex Tim
------------------------------------------------------------------------------------------------------------------
local controlSpellIds = { -- form addon LoseControl (some spell id only for level 1)
	-- Death Knight
	[47481] = "CC",		-- Gnaw (Ghoul)
	[51209] = "CC",		-- Hungering Cold
	[47476] = "Silence",	-- Strangulate
	[45524] = "Snare",	-- Chains of Ice
	[55666] = "Snare",	-- Desecration (no duration, lasts as long as you stand in it)
	[58617] = "Snare",	-- Glyph of Heart Strike
	[50436] = "Snare",	-- Icy Clutch (Chilblains)
	-- Druid
	[5211]  = "CC",		-- Bash (also Shaman Spirit Wolf ability)
	[33786] = "CC",		-- Cyclone
	[2637]  = "CC",		-- Hibernate (works against Druids in most forms and Shamans using Ghost Wolf)
	[22570] = "CC",		-- Maim
	[9005]  = "CC",		-- Pounce
	[339]   = "Root",	-- Entangling Roots
	[19675] = "Root",	-- Feral Charge Effect (immobilize with interrupt [spell lockout, not silence])
	[58179] = "Snare",	-- Infected Wounds
	[61391] = "Snare",	-- Typhoon
	-- Hunter
	[60210] = "CC",		-- Freezing Arrow Effect
	[3355]  = "CC",		-- Freezing Trap Effect
	[24394] = "CC",		-- Intimidation
	[1513]  = "CC",		-- Scare Beast (works against Druids in most forms and Shamans using Ghost Wolf)
	[19503] = "CC",		-- Scatter Shot
	[19386] = "CC",		-- Wyvern Sting
	[34490] = "Silence",	-- Silencing Shot
	[53359] = "Disarm",	-- Chimera Shot - Scorpid
	[19306] = "Root",	-- Counterattack
	[19185] = "Root",	-- Entrapment
	[35101] = "Snare",	-- Concussive Barrage
	[5116]  = "Snare",	-- Concussive Shot
	[13810] = "Snare",	-- Frost Trap Aura (no duration, lasts as long as you stand in it)
	[61394] = "Snare",	-- Glyph of Freezing Trap
	[2974]  = "Snare",	-- Wing Clip
	-- Hunter Pets
	[50519] = "CC",		-- Sonic Blast (Bat)
	[50541] = "Disarm",	-- Snatch (Bird of Prey)
	[54644] = "Snare",	-- Froststorm Breath (Chimera)
	[50245] = "Root",	-- Pin (Crab)
	[50271] = "Snare",	-- Tendon Rip (Hyena)
	[50518] = "CC",		-- Ravage (Ravager)
	[54706] = "Root",	-- Venom Web Spray (Silithid)
	[4167]  = "Root",	-- Web (Spider)
	-- Mage
	[44572] = "CC",		-- Deep Freeze
	[31661] = "CC",		-- Dragon's Breath
	[12355] = "CC",		-- Impact
	[118]   = "CC",		-- Polymorph
	[18469] = "Silence",	-- Silenced - Improved Counterspell
	[64346] = "Disarm",	-- Fiery Payback
	[33395] = "Root",	-- Freeze (Water Elemental)
	[122]   = "Root",	-- Frost Nova
	[11071] = "Root",	-- Frostbite
	[55080] = "Root",	-- Shattered Barrier
	[11113] = "Snare",	-- Blast Wave
	[6136]  = "Snare",	-- Chilled (generic effect, used by lots of spells [looks weird on Improved Blizzard, might want to comment out])
	[120]   = "Snare",	-- Cone of Cold
	[116]   = "Snare",	-- Frostbolt
	[47610] = "Snare",	-- Frostfire Bolt
	[31589] = "Snare",	-- Slow
	-- Paladin
	[853]   = "CC",		-- Hammer of Justice
	[2812]  = "CC",		-- Holy Wrath (works against Warlocks using Metamorphasis and Death Knights using Lichborne)
	[20066] = "CC",		-- Repentance
	[20170] = "CC",		-- Stun (Seal of Justice proc)
	[10326] = "CC",		-- Turn Evil (works against Warlocks using Metamorphasis and Death Knights using Lichborne)
	[63529] = "Silence",	-- Shield of the Templar
	[20184] = "Snare",	-- Judgement of Justice (100% movement snare; druids and shamans might want this though)
	-- Priest
	[605]   = "CC",		-- Mind Control
	[64044] = "CC",		-- Psychic Horror
	[8122]  = "CC",		-- Psychic Scream
	[9484]  = "CC",		-- Shackle Undead (works against Death Knights using Lichborne)
	[15487] = "Silence",	-- Silence
	--[64058] = "Disarm",	-- Psychic Horror (duplicate debuff names not allowed atm, need to figure out how to support this later)
	[15407] = "Snare",	-- Mind Flay
	-- Rogue
	[2094]  = "CC",		-- Blind
	[1833]  = "CC",		-- Cheap Shot
	[1776]  = "CC",		-- Gouge
	[408]   = "CC",		-- Kidney Shot
	[6770]  = "CC",		-- Sap
	[1330]  = "Silence",	-- Garrote - Silence
	[18425] = "Silence",	-- Silenced - Improved Kick
	[51722] = "Disarm",	-- Dismantle
	[31125] = "Snare",	-- Blade Twisting
	[3409]  = "Snare",	-- Crippling Poison
	[26679] = "Snare",	-- Deadly Throw
	-- Shaman
	[39796] = "CC",		-- Stoneclaw Stun
	[51514] = "CC",		-- Hex (although effectively a silence+disarm effect, it is conventionally thought of as a "CC", plus you can trinket out of it)
	[64695] = "Root",	-- Earthgrab (Storm, Earth and Fire)
	[63685] = "Root",	-- Freeze (Frozen Power)
	[3600]  = "Snare",	-- Earthbind (5 second duration per pulse, but will keep re-applying the debuff as long as you stand within the pulse radius)
	[8056]  = "Snare",	-- Frost Shock
	[8034]  = "Snare",	-- Frostbrand Attack
	-- Warlock
	[710]   = "CC",		-- Banish (works against Warlocks using Metamorphasis and Druids using Tree Form)
	[6789]  = "CC",		-- Death Coil
	[5782]  = "CC",		-- Fear
	[5484]  = "CC",		-- Howl of Terror
	[6358]  = "CC",		-- Seduction (Succubus)
	[30283] = "CC",		-- Shadowfury
	[24259] = "Silence",	-- Spell Lock (Felhunter)
	[18118] = "Snare",	-- Aftermath
	[18223] = "Snare",	-- Curse of Exhaustion
	-- Warrior
	[7922]  = "CC",		-- Charge Stun
	[12809] = "CC",		-- Concussion Blow
	[20253] = "CC",		-- Intercept (also Warlock Felguard ability)
	[5246]  = "CC",		-- Intimidating Shout
	[12798] = "CC",		-- Revenge Stun
	[46968] = "CC",		-- Shockwave
	[18498] = "Silence",	-- Silenced - Gag Order
	[676]   = "Disarm",	-- Disarm
	[58373] = "Root",	-- Glyph of Hamstring
	[23694] = "Root",	-- Improved Hamstring
	[1715]  = "Snare",	-- Hamstring
	[12323] = "Snare",	-- Piercing Howl
	-- Other
	[30217] = "CC",		-- Adamantite Grenade
	[67769] = "CC",		-- Cobalt Frag Bomb
	[30216] = "CC",		-- Fel Iron Bomb
	[20549] = "CC",		-- War Stomp
	[25046] = "Silence",	-- Arcane Torrent
	[39965] = "Root",	-- Frost Grenade
	[55536] = "Root",	-- Frostweave Net
	[13099] = "Root",	-- Net-o-Matic
	[29703] = "Snare",	-- Dazed
	-- Immunities
	[46924] = "Immune",	-- Bladestorm (Warrior)
	[642]   = "Immune",	-- Divine Shield (Paladin)
	[45438] = "Immune",	-- Ice Block (Mage)
	[34692] = "Immune",	-- The Beast Within (Hunter)
	-- PvE
	[28169] = "PvE",	-- Mutating Injection (Grobbulus)
	[28059] = "PvE",	-- Positive Charge (Thaddius)
	[28084] = "PvE",	-- Negative Charge (Thaddius)
	[27819] = "PvE",	-- Detonate Mana (Kel'Thuzad)
	[63024] = "PvE",	-- Gravity Bomb (XT-002 Deconstructor)
	[63018] = "PvE",	-- Light Bomb (XT-002 Deconstructor)
	[62589] = "PvE",	-- Nature's Fury (Freya, via Ancient Conservator)
	[63276] = "PvE",	-- Mark of the Faceless (General Vezax)
	[66770] = "PvE",	-- Ferocious Butt (Icehowl)
}
local controlSpellNames = {}
for k, v in pairs(controlSpellIds) do
	local name = GetSpellInfo(k)
	if name then
		controlSpellNames[name] = v
	else
		print("unknown spellId: " .. k)
	end
end

--local isCC, isRoot, isSilence, isSnare, isDisarmб isImmune, isPvE = GetControlState(unit)
function GetControlState(unit)
  if not unit then unit = 'player' end
  local isCC = false -- контроль
  local isRoot = false -- корни
  local isSilence = false -- сало
  local isSnare = false -- замедление
  local isDisarm = false -- обезоруживание
  local isImmune = false -- обезоруживание
  local isPvE = false -- обезоруживание
  for i = 1, 40 do
      local name = UnitDebuff(unit, i)
      if name then
        local controlType = controlSpellNames[name]
        if controlType then
          if not IsCC and controlType == "CC" then IsCC = name end
          if not IsRoot and controlType == "Root" then IsRoot = name end
          if not IsSilence and controlType == "Silence" then IsSilence = name end
          if not IsSnare and controlType == "Snare" then IsSnare = name end
          if not isDisarm and controlType == "Disarm" then isDisarm = name end
          if not isImmune and controlType == "Immune" then isImmune = name end
          if not isPvE and controlType == "PvE" then isPvE = name end
        end
      end
  end
  return isCC, isRoot, isSilence, isSnare, isDisarmб isImmune, isPvE
end
------------------------------------------------------------------------------------------------------------------
-- TODO: need review
ControlList = { -- > 4
"Ненасытная стужа", -- 10s
"Смерч", -- 6s
"Калечение", -- 5s max
"Сон", -- 20s
"Тайфун", -- 6s
"Эффект замораживающей стрелы", -- 20s
"Эффект замораживающей ловушки", -- 10s
"Глубокая заморозка", -- 5s
"Дыхание дракона", -- 5s
"Превращение", -- 20s
"Молот правосудия", -- 6s
"Покаяние", -- 6s
"Удар по почкам", -- 6s max
"Сглаз", -- 30s
"Соблазн", -- 30s
"Огненный шлейф", -- 5s
"Оглушающий удар", -- 5s
"Пронзительный вой", -- 6s
--"Головокружение", -- 6s
"Ошеломление", -- 20s
}
------------------------------------------------------------------------------------------------------------------
SilenceList = {
  "Удушение", --5s
  "Глушащий выстрел", --3s
  "Антимагия - немота", --2..
  "Немота - Щит храмовника",--3s
  "Безмолвие" ,--3s
  "Гаррота - немота", --3..5s
  "Пинок - немота", --2s
  "Запрет чар", --3s
  "Обет молчания - немота", -- 2s
  "Волшебный поток" --3s
}
------------------------------------------------------------------------------------------------------------------
RootList = {
  "Гнев деревьев", --5s
  "Звериная атака - эффект", --5s
  "Контратака", --5s
  "Удержание", --2s
  "Шип", --4s
  "Ядовитая паутина", --4s
  "Сеть", --4s
  "Холод", --8s
  "Кольцо льда", --8s
  "Обморожение", --5s
  "Разрушенная преграда", --8s
  "Хватка земли", --5s
  "Заморозка", --5s
  "Символ подрезанного сухожилия", --5s
  "Улучшенное подрезание сухожилий", --5s
  "Замораживающая граната", --5s
  "Сеть из ледяной ткани", --3s
  "Сетестрел" --20s
}
------------------------------------------------------------------------------------------------------------------
CanControlInfo = ""
-- Можно законтролить игрока
local imperviousList = {"Вихрь клинков", "Зверь внутри", "Незыблемость льда"} -- TODO: Незыблемость льда под вопросом
function CanControl(target)
    if nil == target then target = "target" end
    if not CanMagicAttack(target) then
      CanControlInfo = CanMagicAttackInfo
      return false
    end
    local aura = HasBuff(imperviousList, 0.1, target)
    if aura then
      CanControlInfo = aura
      return false
    end
    local aura = HasDebuff(ControlList, 3, target)
    if aura then
      CanControlInfo = aura
      return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
CanMagicAttackInfo = ""
-- можно использовать магические атаки против игрока
local magicList = {"Отражение заклинания", "Антимагический панцирь", "Рунический покров", "Эффект тотема заземления"}
function CanMagicAttack(target)
    if nil == target then target = "target" end
    if not CanAttack(target) then
      CanMagicAttackInfo = CanAttackInfo
      return false
    end
    local aura = HasBuff(magicList, 0.1, target)
    if aura then
      CanMagicAttackInfo = aura
      return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
-- можно атаковать игрока (в противном случае не имеет смысла просаживать кд))
CanAttackInfo = ""
local immuneList = {"Божественный щит", "Ледяная глыба", "Сдерживание"}
function CanAttack(target)
    CanAttackInfo = ""
    if nil == target then target = "target" end
    if not IsValidTarget(target) then
      CanAttackInfo = IsValidTargetInfo
      return false
    end
    if not UnitIsPlayer(target) then return true end
    local aura = HasBuff(immuneList, 0.01, target)
    if not aura then
      aura = HasDebuff("Смерч", 0.01, target)
    end
    if aura then
      CanAttackInfo = aura
      return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
HealList = {
    "Малая волна исцеления",
    "Волна исцеления",
    "Цепное исцеление",
    "Свет небес",
    "Вспышка Света",
    "Быстрое исцеление",
    "Исповедь",
    "Божественный гимн",
    "Связующее исцеление",
    "Молитва исцеления",
    "Исцеление",
    "Великое исцеление",
    "Покровительство Природы",
    "Спокойствие потоковое",
    "Восстановление",
    "Целительное прикосновение"
}
------------------------------------------------------------------------------------------------------------------
-- касты обязательные к сбитию в любом случае
InterruptList = {
    "Малая волна исцеления",
    "Волна исцеления",
    "Выброс лавы",
    "Сглаз",
    "Цепное исцеление",
    "Превращение",
    "Прилив сил",
    "Нестабильное колдовство",
    "Блуждающий дух",
    "Стрела Тьмы",
    "Сокрушительный бросок",
    "Стрела Хаоса",
    "Вой ужаса",
    "Страх",
    "Похищение жизни",
    "Похищение души",
    "Свет небес",
    "Вспышка Света",
    "Быстрое исцеление",
    "Исповедь",
    "Божественный гимн",
    "Связующее исцеление",
    "Массовое рассеивание",
    "Прикосновение вампира",
    "Сожжение маны",
    "Молитва исцеления",
    "Исцеление",
    "Контроль над разумом",
    "Великое исцеление",
    "Покровительство Природы",
    "Звездный огонь",
    "Смерч",
    "Спокойствие потоковое",
    "Восстановление",
    "Целительное прикосновение",
    "Изгнание зла",
    "Сковывание нежити",
}

ReflectList = {
    "Выброс лавы",
    "Сглаз",
    "Превращение",
    "Нестабильное колдовство",
    "Блуждающий дух",
    "Стрела Тьмы",
    "Стрела Хаоса",
    "Вой ужаса",
    "Страх",
    "Прикосновение вампира",
    "Контроль над разумом",
    "Звездный огонь",
    "Смерч"
}

------------------------------------------------------------------------------------------------------------------
-- касты обязательные к сбитию в любом случае
local AlertList = {
    "Божественный щит",
    "Вихрь клинков",
    "Стылая кровь",
    "Гнев карателя",
    "Призыв горгульи",
    "PvP-аксессуар",
    "Каждый за себя",
    "Озарение",
    "Святая клятва",
    "Питье",
    "Длань свободы",
    "Воля Отрекшихся",
    "Перерождение"
}

function InAlertList(spellName)
    return tContains(AlertList, spellName)
end
------------------------------------------------------------------------------------------------------------------
--[[ Interrupt + - хилка
SHAMAN|Малая волна исцеления +
SHAMAN|Волна исцеления +
SHAMAN|Выброс лавы
SHAMAN|Сглаз
SHAMAN|Цепное исцеление +
MAGE|Превращение
MAGE|Прилив сил, потоковое
WARLOCK|Нестабильное колдовство
WARLOCK|Блуждающий дух
WARLOCK|Стрела Тьмы
WARRIOR|Сокрушительный бросок
WARLOCK|Стрела Хаоса
WARLOCK|Вой ужаса
WARLOCK|Страх
WARLOCK|Похищение жизни
PALADIN|Свет небес +
PALADIN|Вспышка Света +
PRIEST|Быстрое исцеление  +
PRIEST|Исповедь, потоковое сразу сбивать +
PRIEST|Божественный гимн  +
PRIEST|Связующее исцеление, +
PRIEST|Массовое рассеивание
PRIEST|Прикосновение вампира
PRIEST|Сожжение маны
PRIEST|Молитва исцеления +
PRIEST|Исцеление +
PRIEST|Контроль над разумом
PRIEST|Великое исцеление +
DRUID|Покровительство Природы
DRUID|Звездный огонь
DRUID|Смерч
DRUID|Спокойствие потоковое +
DRUID|Восстановление +
DRUID|Целительное прикосновение +

диспел

Сглаз
Укус змеи
Укус гадюки
Проклятие стихий
Проклятие косноязычия
Проклятие агонии

остальное тотем яды и болезни


комунизм

Обновление
Слово силы: Щит
Дубовая кожа
Жажда крови
Вспышка Света
Священный щит
Святая клятва
Гнев карателя
Щит Бездны
Щит маны,
Жизнецвет
Щит земли, весь не состилишь
Милость,
Стылая кровь
Искусство войны
Буйный рост
Омоложение
Защита Пустоты
Лишнее время
Чародейское ускорение
Героизм
Призрачный волк
Быстрина
Частица Света
Улучшенный скачок
Божественная защита
Жизнь Земли
Восстановление
Покров Света
Хватка природы
Длань свободы
Ледяная преграда
Жертвоприношение
Мощь тайной магии
Незыблемость льда
Праведное неистовство
Быстрота хищника
Ускорение
Изничтожение
Стылая кровь
Обратный поток
Средоточие воли
Молитва восстановления

red list

Слово силы: Щит
Дубовая кожа
Жажда крови
Святая клятва
Гнев карателя
Щит Бездны
Щит маны,
Стылая кровь
Защита Пустоты
Чародейское ускорение
Героизм
Быстрина
Божественная защита
Длань свободы
Ледяная преграда
Жертвоприношение
Мощь тайной магии
Незыблемость льда
Быстрота хищника
Стылая кровь
]]
