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

goodTargetTypesTable = {
    ["NPC"] = true,
    ["PET"] = true,
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
    Write.Trace('goodtarget id %s type %s table %s ignore %s final %s',id,spawn.Type(),goodTargetTypesTable[spawn.Type()],myconfig.Ignore[spawn.CleanName()],(goodTargetTypesTable[spawn.Type()] or false) and (not myconfig.Ignore[spawn.CleanName()]))
    return (goodTargetTypesTable[spawn.Type()] or false) and (not myconfig.Ignore[spawn.CleanName()]) --The or actually does return either or instead of evaluating to true/false
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
    if str:lower() == "true" then
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
    if tableLength(t) then 
        print("printTable: Printing ", t)
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
    else print('printTable: Table is empty') end
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
   if not T then print('tableLength: No table provided') else
     local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
  end
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
function split(input,delimiter)
    local values = {}
    for value in input:gmatch("([^"..delimiter.."]+)") do
        table.insert(values, value)
        --print(value)
    end
    
    return values
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

function GroupRoles(cmd,name,roleNum)
    if mq.TLO.Me.AmIGroupLeader() then mq.cmdf('/grouprole %s %s %s',cmd,name,roleNum) end
end

--[[Usage
for key, value in sortTableByKey(tableName,Optional sort logic) do
    ...
    ]]
function sortTableByKey(t,sortLogic)
    local keys = {}
    for key in pairs(t) do table.insert(keys, key) end
    table.sort(keys, sortLogic)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if keys[i] == nil then return nil
        else return keys[i], t[keys[i]]
        end
    end
    return iter
end

--Return a sorted table
function getKeysSortedByValue(tbl, sortFunction) --Returns a new index table with only the keys in it an sorted
    local keys = {}
    for key in pairs(tbl) do
        table.insert(keys, key)
    end
    --For integers and a sort
    table.sort(keys, function(a, b)
        --printf("a b is %s %s %s",a,b,type(a))
        a=tonumber(a)
        b=tonumber(b)
        return sortFunction(a, b)
    end)
    return keys
end

--Moves a value from position starting to position ending within table t
function tableMove(t,starting,ending)
    local valueToMove = t[starting]
    table.remove(t,starting)
    table.insert(t,ending,valueToMove)
    return t
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
    Write.Info('Writelevel change to %s',Write.loglevel)
end
mq.bind('/writelevel', WriteLevel)

--Write a table to a user designated file name. See how data is being stored or to store settings
function pickleTable(tbl,name)
    dir = mq.luaDir
    fn = string.format("\\%s.lua",name)
    savePath = dir..fn --Saves to main lua folder
    mq.pickle(savePath,tbl)
    Write.Info(string.format('Pickled to file %s',savePath))
end

function searchNestedTables(t, searchString)
    if searchString then
        for k, v in pairs(t) do
            if type(v) == "table" then
                local result = searchNestedTables(v, searchString)
                if result then return result end
            elseif type(v) == "string" and v:match(searchString) then
                return true
            end
        end
    end
    return false
end

function getScriptName()
    local callerInfo = debug.getinfo(1,'S').short_src
    local name = callerInfo:match("\\([^\\]-)\\[^\\]-$")
    return name..".lua"
end

function writeDebug(format, ...)
    local message = string.format(format, ...)
    Write.Debug(message)
    if writeToLog then mq.cmdf("/mqlog %s", message) end
end



--[[Live table inspection tool
gearly = require('../init')
local checkboxStates = {}
local openTableWindows = {}
local tableToDisplay = gearly.displayedItemStatsTable --Point this at what table you want to inspect. Needs to be defined before running since we can't hook and get a list of all active tables if they're not defined as _G.Table


local function ShowTableData(tableName, tableData)
    -- Open a new tree node to display table data
    if type(tableName) == 'number' then tableName = tostring(tableName) end --TreeNode can't be an integer
    ImGui.SetNextItemOpen(true)
    if ImGui.TreeNode(tableName) then
        -- Display table data
        if type(tableData) == "table" then
            for key, value in pairs(tableData) do
                -- If the value is a table, recursively display it as a tree node
                if type(value) == "table" then
                    ShowTableData(key, value) -- Recursively call the function until no more need for trees, like the earth
                else
                    ImGui.Text(string.format("%s: %s", key, tostring(value)))
                end
            end
        else
            ImGui.Text(tableData)
        end

        ImGui.TreePop() -- Close tree node
    end
end


local function ShowTableList()
    -- Open a window to show the table list
    ImGui.Begin(tostring(tableToDisplay), true, ImGuiWindowFlags_AlwaysAutoResize)

    -- Iterate over each table in the _G environment (old)
    for tableName, tableData in pairs(tableToDisplay) do
        -- Display a checkbox for the current table
        local isChecked, changed = ImGui.Checkbox(tableName, checkboxStates[tableName] or false)
        if changed then
            -- Update the checkbox state
            checkboxStates[tableName] = isChecked
            if isChecked then
                openTableWindows[tableName] = true
            else
                openTableWindows[tableName] = nil
            end
        end
    end

    ImGui.End() -- End window
end

local function TableInspection()
    -- Open the main window
        ShowTableList()

        -- Open windows for each selected table
        for tableName, _ in pairs(openTableWindows) do
            local tableData = tableToDisplay[tableName]
            if tableData then
                ImGui.Begin("Table Data - " .. tableName, openTableWindows[tableName], ImGuiWindowFlags_AlwaysAutoResize)
                ShowTableData(tableName, tableData)
                ImGui.End() -- End window
            end
        end
end

-- Initialize the GUI
mq.imgui.init('thing', TableInspection)]]