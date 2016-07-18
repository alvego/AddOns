-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
CanControlInfo = ""
local imperviousList = {"Вихрь клинков", "Зверь внутри"}
local physicsList = {"Незыблемость льда", "Длань защиты"} --Перерождение
function CanControl(target, magic, physic)
    CanControlInfo = ""
    if nil == target then target = "target" end
    if not (magic and CanMagicAttack or CanAttack)(target) then
        CanControlInfo = (magic and CanMagicAttackInfo or CanAttackInfo)
        return false
    end
    local aura =  HasBuff(imperviousList, 0.1, target) or (physic and HasBuff(physicsList, 0.1, target))
    if aura then
        CanControlInfo = aura
        return false
    end
    return true
end
------------------------------------------------------------------------------------------------------------------
-- можно использовать магические атаки против игрока
CanMagicAttackInfo = ""
local magicList = {"Антимагический панцирь", "Плащ Теней", "Символ ледяной глыбы" } --Символ ледяной глыбы ?
local magicReflectList = {"Отражение заклинания", "Рунический покров", "Эффект тотема заземления"}
function CanMagicAttack(target)
    CanMagicAttackInfo = ""
    if nil == target then target = "target" end
    if not CanAttack(target) then
        CanMagicAttackInfo = CanAttackInfo
        return false
    end
    local aura = HasBuff(magicList, 0.1, target)
    if not aura and not IsAttack() then
        aura = HasBuff(magicReflectList, 0.1, target)
    end
    if aura then
        CanMagicAttackInfo = aura
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
-- можно атаковать игрока (в противном случае не имеет смысла просаживать кд))
local immuneList = {"Божественный щит", "Ледяная глыба", "Сдерживание", "Смерч", "Слияние с Тьмой", "Развоплощение"}
CanAttackInfo = ""
function CanAttack(target)
    CanAttackInfo = ""
    if nil == target then target = "target" end
    if not IsValidTarget(target) then
        CanAttackInfo = IsValidTargetInfo
        return false
    end
    if not IsVisible(target) then
        CanAttackInfo = "Цель в лосе."
        return false
    end

    local aura = HasAura(immuneList, 0.01, target)
    if aura then
        CanAttackInfo = "Цель имунна: " .. aura
        return false
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
local nointerruptBuffs = {"Мастер аур", "Дубовая кожа"}
function IsInterruptImmune(target, t)
    if target == nil then target = "target" end
    if t == nil then t = 0.1 end
    return HasBuff(nointerruptBuffs, t , target)
end

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

function InControl(target, t)
  if target == nil then target = "target" end
  if t == nil then t = 0.1 end
  return HasDebuff(ControlList, t, target)
end
