-- Shaman Rotation Helper by Timofeev Alexey

SetCommand("hero", 
    function() 
        if DoSpell("Героизм") then
            print("Гера!")
        end
    end, 
    function() 
        return not InCombatLockdown() or HasDebuff("Изнеможение", 1, "player") or (not InGCD() and not IsReadySpell("Героизм")) 
    end
)
SetCommand("hex", 
    function() 
--[[        if HasSpell("Природная стремительность") then 
            DoSpell("Природная стремительность") 
        end]]
        if DoSpell("Сглаз") then
            print("Сглаз")
        end
    end, 
    function() 
        if not CanControl() or (not InGCD() and not IsReadySpell("Сглаз"))  then return true end
        if not UnitIsPlayer("target") then
            local creatureType = UnitCreatureType("target")
            if creatureType ~= "Гуманоид" or creatureType ~= "Животное" then return true end
        end
        return false
    end
)

SetCommand("freedom", 
    function() return UseEquippedItem("Медальон Альянса") end, 
    function() local item = "Медальон Альянса" return IsPlayerCasting() or not IsEquippedItem(item) or (not InGCD() and not IsReadyItem(item)) end
)

local tryMount = false
SetCommand("mount", 
    function() 
        if (IsLeftControlKeyDown() or IsSwimming()) and not HasBuff("Хождение по воде", 1, "player") and DoSpell("Хождение по воде", "player") then return end
        if InCombatLockdown() or IsArena() or not PlayerInPlace() then
            return DoSpell("Призрачный волк") 
        end
        if InGCD() or IsPlayerCasting() or InCombatLockdown() or not IsOutdoors() then return false end
        local mount = "Стремительный белый рысак"
        if IsFlyableArea() and not IsLeftControlKeyDown() then mount = "Черный дракон" end
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then tryMount = true return end
    end, 
    function() 
        if (HasBuff("Призрачный волк") or IsMounted() or CanExitVehicle()) then return true end
        if tryMount then
            tryMount = false
            return true
        end
        return false 
    end
)

SetCommand("dismount", 
    function() 
        if HasBuff("Призрачный волк") then RunMacroText("/cancelaura Призрачный волк") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end, 
    function() 
        return not (HasBuff("Призрачный волк") or IsMounted() or CanExitVehicle())
    end
)

TotemTime, NeedTotems = GetTime(), false
SetCommand("totems", 
    function() 
        if TryTotems(true) then
            print("Тотемы!")
            return true
        end
        return false
    end, 
    function() 
        if InCombatLockdown() and not NeedTotems then 
            NeedTotems = true
            print("Тотемы! not NeedTotems", not NeedTotems)
            return true
        end
        if GetTime() - TotemTime < 0.5  then
            print("Тотемы! TryTotems is DONE!")
            return true
        end
        return false
    end
)
