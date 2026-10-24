local G=GLOBAL
AddPrefabPostInit("twister",function(inst)
    local v=inst.components.vacuum
    if not v then return end
    local old=v.OnUpdate
    v.OnUpdate=function(self,dt,...)
        old(self,dt,...)
        local w=G.GetWorld()
        if not w or not w.components.sisland then return end
        local exclude={}
        for _,tag in ipairs(self.noTags) do
            if tag~="irreplaceable" then exclude[#exclude+1]=tag end
        end
        local pt=self.inst:GetPosition()
        local bones=G.TheSim:FindEntities(pt.x,pt.y,pt.z,math.max(self.vacuumradius,self.consumeradius),{"packim_fishbone"},exclude)
        for _,item in ipairs(bones) do
            if item.Physics and item.components.inventoryitem and not item.components.inventoryitem:IsHeld() then
                local x,y,z=item.Transform:GetWorldPosition()
                if (x-pt.x)^2+(z-pt.z)^2<=self.consumeradius^2 then
                    if not self.inst.components.inventory:GiveItem(item) then self:SpitItem(item) end
                elseif G.CheckLOSFromPoint(pt,item:GetPosition()) then
                    item.Physics:Teleport(x,.1,z)
                    local angle=math.atan2(pt.z-z,pt.x-x)
                    item.Physics:SetVel(math.cos(angle)*self.vacuumspeed,0,math.sin(angle)*self.vacuumspeed)
                end
            end
        end
    end
    -- A twister can also leave the world without dying. Release its fishbone
    -- before inventory cleanup; keep the unique-item tags and follower linkage.
    inst:ListenForEvent("onremove",function(e)
        local inv=e.components.inventory
        if inv then
            for _,item in pairs(inv.itemslots) do
                if item.prefab=="packim_fishbone" then inv:DropItem(item,true,true) end
            end
        end
    end)
end)
