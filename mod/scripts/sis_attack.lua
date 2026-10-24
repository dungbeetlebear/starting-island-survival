local G=GLOBAL

-- Scope the filter to keyboard/controller target searches. Explicit mouse
-- attacks use the original combat rules, including force-clicking a wall.
AddComponentPostInit("playercontroller",function(c)
    local old=c.GetAttackTarget
    if not old then return end
    c.GetAttackTarget=function(self,...)
        local w=G.GetWorld()
        if not w or not w.components.sisland then return old(self,...) end
        local previous=self.inst._sis_autoattack
        self.inst._sis_autoattack=true
        local ok,target=G.pcall(old,self,...)
        self.inst._sis_autoattack=previous
        if not ok then G.error(target) end
        return target
    end
end)

AddComponentPostInit("combat",function(c)
    local old=c.CanBeAttacked
    if not old then return end
    c.CanBeAttacked=function(self,attacker,...)
        if attacker and attacker._sis_autoattack and self.inst:HasTag("wall") then return false end
        return old(self,attacker,...)
    end
end)
