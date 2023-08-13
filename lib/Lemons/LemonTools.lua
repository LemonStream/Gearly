--Commons tools I use 
--v0.1
--local mq = require('mq')


slotArray = {
    [0] = "charm",
    [1] = "leftear",
    [2] = "head",
    [3] = "face",
    [4] = "rightear",
    [5] = "neck",
    [6] = "shoulder",
    [7] = "arms",
    [8] = "back",
    [9] = "leftwrist",
    [10] = "rightwrist",
    [11] = "ranged",
    [12] = "hands",
    [13] = "mainhand",
    [14] = "offhand",
    [15] = "leftfinger",
    [16] = "rightfinger",
    [17] = "chest",
    [18] = "legs",
    [19] = "feet",
    [20] = "waist",
    [21] = "powersource",
    [22] = "ammo"
}

goodTargets = {
    "NPC",
    "PET",

}

function inCombat()
    return mq.TLO.Me.CombatState() == "COMBAT"
end

function WithinRange(id)
    return mq.TLO.Spawn(id).Distance() <= CAMP_RADIUS
end
--Is the spawn ID an attackable thing. Add to goodTargets to expand
function goodTarget(id)
    local spawn = mq.TLO.Spawn(id)
    return tableHasValue(goodTargets,spawn.Type())
end

--Return spawn name from ID.
IDtoSpawn = function(id)
    if id == 0 then return 0 end
    return mq.TLO.Spawn(id)()
end

--Return clean name from ID.
IDtoCN = function(id)
    if id == 0 then return 0 end
    return mq.TLO.Spawn(id).CleanName()
end

--Check if it's nil, null, or empty
isNULL = function(var)
    return var == nil or var == "" or var == 'NULL' 
end

--Check if I'm connected to Dannet(future functionality/dependents)
connected = function(name)
    if not mq.TLO.Plugin("mq2DanNet")() then return false end
    if mq.TLO.DanNet.Peers.Find(name)() then
       return true
    else
        return false
    end
end

--Clear XTarget entries that have no AssistName (May have been added by mistake)This may cause some issues for mezzed stuff?
 clearXTar = function()
    local numSlots = mq.TLO.Me.XTargetSlots()
    for i= numSlots,1,-1 do
        local XT = mq.TLO.Me.XTarget(i)
        local XTi = mq.TLO.Me.XTarget(i).ID()
        local XTt = mq.TLO.Me.XTarget(i).TargetType()
        --Write.Debug(string.format("|%s| |%s| |%s| |%s|",i,XT,XTi,XTt))
        if XTi ~= 0 then
            --Write.Debug("XTi not 0")
            if (not XT.AssistName() and XT.ID() ~= 0 and XT.TargetType() ~= "Auto Hater") or (XT.Type() == "Corpse" and XT.TargetType() ~= "Auto Hater") then 
                mq.cmdf('/xtarget set %i autohater',i)
                if not XT.AssistName() then Write.Info("\ayRemoving XTarget \ao "..i.." \aysince it is \ao"..tostring(XT.AssistName())) end
                mq.delay(5000, XT.TargetType() == "Auto Hater" )
            end
        else 
            --Write.Debug(string.format("2nd: %s %s |%s| |%s|",i,XT,XTi,XTt))
            if XTt == "UNKNOWN" then
                mq.cmdf('/xtarget set %i autohater',i)
                Write.Info(string.format("Broken XTarget detected. Attempting to fix slot %s",i))
                mq.delay(5000, XT.TargetType() == "Auto Hater" )
                
            end
        end
    end
end

isEqual = function(eq,this)
    if not eq or not this then return false end
    print(eq:lower() == this:lower())
    return eq:lower() == this:lower()
end

function tobool(str)
    local bool = false
    if str == "true" then
        bool = true
    end
    return bool
end

function tableHasValue(tbl, value)
    for i = 1, #tbl do
      if tbl[i] == value then
        return true
      end
    end
    return false
  end

printTable = function(t) --for dictionary/nested
    print("Printing table ", t)
    if type(t) == "table" then
        for index, data in pairs(t) do
            printf("index is %s and data is %s",index,data)
            if type(data) == "table" then 
                for key, value in pairs(data) do
                    print('\t', key, value)
                end
            end
        end
    else print(t) end
end

printTablei = function(t) --for arrays
    print("Printing itable with length", #t)
    for key, value in ipairs(t) do
        print("key is ",key)
        print('\t', key, value)
    end
end

function printUserData(t)
    local ud = newproxy(true)
    local data = { 1, 2, 3 }
    debug.setmetatable(ud, {
    __index = function(_, key)
        if key == "getData" then
        return function()
            return data
        end
        end
    end
    })
    -- get the userdata data and print it
    local userData = t:getData()
    print(table.concat(userData, ", "))
end

function countString(this, str)
    local _, count = string.gsub(str, this, "")
    return count
end

--Can't get this to work
function table:isEmpty()
    print(self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

--Only accepts dictionary? Yes
function tableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end
  
function stringToTable(str,delim)
    local _, count = string.gsub(str, delim, "")
    local t ={}
    for i=1,count do
        table.insert(t,getArg(str,i,delim))
    end
    return t
end

  --For getting the nth argument from string arg as separate by s
getArg = function(arg,n,s)
    local count = 0
    if not string.gmatch(arg,"([^"..s.."]+)") then return "badstring" end
    for w in string.gmatch(arg,"([^"..s.."]+)") do 
        count = count + 1 
        if count == n then 
            return w
        end
    end
end

function splitString(inputString, delimiter)
    local result = {}
    
    local pattern = string.format("([^%s]+)", delimiter)
    for item in string.gmatch(inputString, pattern) do
      table.insert(result, item)
    end
    
    return result
  end

printArg = function(arg)
    print(arg)
    return
end

--Homogenize Target (checks the assist's MTID and sets it to the same)
Homogenize = function()
    assistName = mq.TLO.Macro.Variable("MainAssist")()
    currentTarget = mq.TLO.Macro.Variable("MyTargetID")()
    Write.Debug(string.format("MTID is currently %s",mq.TLO.Macro.Variable("MyTargetID")))
    mq.cmdf("/dquery %s -q MyTargetID",assistName)
    mq.delay(3000, mq.TLO.DanNet.Q() ~= 0 and mq.TLO.DanNet.Q() ~= currentTarget)
    if currentTarget ~= mq.TLO.DanNet.Q() then mq.cmdf("/varset MyTargetID %s",mq.TLO.DanNet.Q()) end
    Write.Debug(string.format("MTID is now %s",mq.TLO.Macro.Variable("MyTargetID")))
end

function upvalues()
    local variables = {}
    local idx = 1
    local func = debug.getinfo(2, "f").func
    while true do
        local ln, lv = debug.getupvalue(func, idx)
        if ln ~= nil then
        variables[ln] = lv
        else
        break
        end
        idx = 1 + idx
    end
return variables
end

function f(fmt, ...)
    return string.format(fmt, ...)
end

--To echo variables within a script since evals don't have access to it
function lecho(arg)
    if _G[arg] then print(_G[arg]) else printf("No variable named %s",arg) end return
end
mq.bind('/lecho', lecho)

--Change a variable on the fly
function lvarset(arg1,arg2)
    if _G[arg1] then _G[arg1] = arg2 else printf("No variable named %s",arg) end return
end
mq.bind('/lvarset', lvarset)

--Change write level
function WriteLevel(arg1)
    Write.loglevel = arg1
end
mq.bind('/writelevel', WriteLevel)