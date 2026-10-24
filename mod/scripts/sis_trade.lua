local G=GLOBAL
if not SIS_CONFIG.octopus_no_cooldown then return end
local function active()
    local w=G.GetWorld()
    return w and w.components.sisland
end
local function permanent(item)
    return item and not item.components.perishable and not item.components.edible
end

-- The GIVE action must follow both the animation lock and the food allowance.
AddComponentPostInit("tradable",function(c)
    local old=c.CollectUseActions
    c.CollectUseActions=function(self,doer,target,actions,...)
        old(self,doer,target,actions,...)
        if not active() or not target or target.prefab~="octopusking" then return end
        local t=target.components.trader
        local allowed=t and t:CanAccept(self.inst,doer)
        if doer.components.rider and doer.components.rider:IsRiding() and
            not (target.components.inventoryitem and target.components.inventoryitem:IsGrandOwner(doer)) then allowed=false end
        for i=#actions,1,-1 do
            if actions[i]==G.ACTIONS.GIVE then table.remove(actions,i) end
        end
        if allowed then table.insert(actions,G.ACTIONS.GIVE) end
    end
end)

AddPrefabPostInit("octopusking",function(inst)
    local t=inst.components.trader
    local accept,canaccept,onaccept=t.AcceptGift,t.CanAccept,t.onaccept
    local save,load=t.OnSave,t.OnLoad
    local food_allowed=t.enabled
    local busy=false

    local function clear_sleep()
        if inst.sleepfn then
            inst:RemoveEventCallback("animover",inst.sleepfn)
            inst.sleepfn=nil
        end
    end
    local function sleep()
        clear_sleep()
        t:Disable()
        inst.AnimState:PlayAnimation("sleep_pre")
        inst.sleepfn=function(e)
            e.AnimState:PlayAnimation("sleep_loop")
            e.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/octopus_king/sleep")
        end
        inst:ListenForEvent("animover",inst.sleepfn)
    end
    local function query(self,item,giver)
        local enabled=self.enabled
        self.enabled=true
        local ok,result=G.pcall(canaccept,self,item,giver)
        self.enabled=enabled
        if not ok then G.error(result) end
        return result
    end

    t.CanAccept=function(self,item,giver)
        if not active() then return canaccept(self,item,giver) end
        if busy then return false end
        if permanent(item) then return query(self,item,giver) end
        return food_allowed and canaccept(self,item,giver) or false
    end
    t.AcceptGift=function(self,giver,item,...)
        if not active() then return accept(self,giver,item,...) end
        -- Reject even already-queued GIVE actions without playing a refusal
        -- animation that could interrupt the current grabchest sequence.
        if busy or (not permanent(item) and not food_allowed) then return false end
        local enabled=self.enabled
        if permanent(item) then self.enabled=true end
        local result={G.pcall(accept,self,giver,item,...)}
        if busy then self.enabled=false
        elseif permanent(item) then self.enabled=enabled end
        if not result[1] then G.error(result[2]) end
        return G.unpack(result,2)
    end
    t.onaccept=function(e,giver,item)
        if not active() then return onaccept(e,giver,item) end
        local no_daily_cooldown=permanent(item)
        if not no_daily_cooldown then food_allowed=false end
        busy=true
        e._sis_trade_busy=true
        clear_sleep()
        -- Keep every original sound, animation and the 109-frame chest throw.
        -- Only replace the five-second daily-sleep task, never the reward task.
        onaccept(e,giver,item)
        if e.endhappytask then e.endhappytask:Cancel();e.endhappytask=nil end
        local reward_due=G.GetTime()+110*G.FRAMES
        local function finished()
            if G.GetTime()<reward_due or not e.AnimState:IsCurrentAnimation("idle") then
                e.endhappytask=e:DoTaskInTime(G.FRAMES,finished)
                return
            end
            busy=false
            e._sis_trade_busy=false
            e.happy=false
            e.endhappytask=nil
            if no_daily_cooldown or food_allowed then
                clear_sleep()
                t:Enable()
            else
                sleep()
            end
        end
        e.endhappytask=e:DoTaskInTime(G.FRAMES,finished)
    end

    -- Day/night callbacks otherwise replace grabchest with sleep/wakeup.
    -- Preserve them while idle; while busy, update only the food daily gate.
    local w=G.GetWorld()
    local function phase(event,allowed)
        local callbacks={}
        local listening=inst.event_listening and inst.event_listening[event]
        for _,fn in ipairs(listening and listening[w] or {}) do callbacks[#callbacks+1]=fn end
        for _,fn in ipairs(callbacks) do inst:RemoveEventCallback(event,fn,w) end
        inst:ListenForEvent(event,function(source,data)
            if active() then
                food_allowed=allowed
                if busy then return end
            end
            for _,fn in ipairs(callbacks) do fn(source,data) end
        end,w)
    end
    if w then phase("daytime",true);phase("nighttime",false) end

    t.OnSave=function(self,...)
        local data=save(self,...)
        if active() then
            data.enabled=food_allowed
            data.sis_food_allowed=food_allowed
        end
        return data
    end
    t.OnLoad=function(self,data,...)
        local result=load(self,data,...)
        food_allowed=data and data.sis_food_allowed
        if food_allowed==nil then food_allowed=self.enabled end
        return result
    end
end)
