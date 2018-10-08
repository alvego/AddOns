-- Druid Rotation Helper by Alex Tim
-----------------------------------------------------------------------------------------------------------------
SetCommand("defence",
    function()
      return DoSpell("Облик лютого медведя")
    end,
    function()
        Defence = true
        if IsAttack() and not AutoTaunt then
          chat('Зажата атака, остаемся в коте')
          return true
        end
        chat('Защищаемся')
        return HasBuff("Облик лютого медведя")
    end
)
-----------------------------------------------------------------------------------------------------------------
SetCommand("bearHeal",
    function()
      if not HasBuff("Инстинкты выживания") then
        if DoSpell("Инстинкты выживания") then return true end
        return false
      end
      local mana = UnitMana("player")
      if mana < 90 and not HasBuff("Исступление") and DoSpell("Исступление") then return true end
      if not HasBuff("Неистовое восстановление") then
        if DoSpell("Неистовое восстановление") then return true end
        return false
      end
    end,
    function()
        chat('Хилимся')
        return HasBuff("Неистовое восстановление")
    end,
    function()
      if not HasBuff("Облик лютого медведя") then
        chat('Не в мишке')
        return true
      end
      local mana = UnitMana("player")
      if mana < 60 and not IsReadySpell("Исступление") and not HasBuff("Исступление", 5) then
        chat('Раги всего ' .. mana .. ' и Исступление не готово')
        return true
      end
      if not IsReadySpell("Инстинкты выживания") and not HasBuff("Инстинкты выживания", 10) then
        chat('Инстинкты выживания не готово')
        return true
      end
      if not IsReadySpell("Неистовое восстановление") then
        chat('Неистовое восстановление не готово')
        return true
      end
      return false
    end
)

-----------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------
