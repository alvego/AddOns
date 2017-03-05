﻿-- Rotation Helper Library by Alex Tim
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
"Головокружение", -- 6s
"Ошеломление", -- 20s
"Соблазн"
}
------------------------------------------------------------------------------------------------------------------
-- Можно законтролить игрока
local imperviousList = {"Вихрь клинков", "Зверь внутри", "Незыблемость льда"} -- TODO: Незыблемость льда под вопросом
function CanControl(target)
    if nil == target then target = "target" end
    return CanMagicAttack(target) and not HasBuff(imperviousList, 0.1, target)
        and not HasDebuff(ControlList, 3, target)
end

------------------------------------------------------------------------------------------------------------------
-- можно использовать магические атаки против игрока
local magicList = {"Отражение заклинания", "Антимагический панцирь", "Рунический покров", "Эффект тотема заземления"}
function CanMagicAttack(target)
    if nil == target then target = "target" end
    return CanAttack(target)
        and not HasBuff(magicList, 0.1, target)
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
