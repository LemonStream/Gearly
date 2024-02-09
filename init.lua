--[[Companion to gear.mac v0.2
UI that shows your own stats and those connected to DNet
Only query upon request. Don't monitor/observe
Click on a slot to show the item for all connected chars (all db chars?)
Add in all stat fields since you can right click the headers and choose what to display

Click on a slot to put that slot only into a table data and display it on the right
Click a button to show all items in file in a table (no trees)

/gear show, /gear hide
/lua run gear once --This will just write to the ini and stop the script
ToDo:
Convert all to sql databases instead of inis

Update Notes:
1.23
Fixed string overflow crash if using a lot of observers. 
Slot mismatching/error fixed

]]

mq = require('mq')
require('ImGui')
Write = require("lib/Write")
dannet = require('lib/dannet/helpers')
LIP = require('lib/LIP')
LT = require('lib/Lemons/LemonTools')
gearData = require("gearData")
statsToDisplay = {}
Write.loglevel = 'Info'

local animItems = mq.FindTextureAnimation('A_DragItem')
local openGUI = true
local shouldDrawGUI = true
local blueBorder = mq.FindTextureAnimation('BlueIconBackground')
local animBox = mq.FindTextureAnimation('A_RecessedBox')
local loop = true
local current_sort_specs = nil
local currentFilters = nil
local listDone = nil
local itemWindowID = nil
local myName = mq.TLO.Me.CleanName.Lower()
local doRefresh = false
local useGroup = 1
local useGroupName = "all"
local beta = false
blueBorder:SetTextureCell(1)
dir = mq.luaDir
fileName = '/Gearly/Character Data/'..myName..'_'..mq.TLO.EverQuest.Server()..'.ini'
path = dir..fileName
imguiFlags = bit32.bor(ImGuiWindowFlags.None)
tableFlags = bit32.bor(ImGuiTableFlags.ScrollX,ImGuiTableFlags.Hideable,ImGuiTableFlags.NoBordersInBody,ImGuiTableFlags.SizingFixedSame,ImGuiTableFlags.Resizable,ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.BordersOuter,ImGuiTableFlags.Sortable, ImGuiTableFlags.Reorderable,ImGuiTableFlags.SortMulti)
settingsTableFlags = bit32.bor(ImGuiTableFlags.SizingFixedFit,ImGuiTableFlags.NoHostExtendX,ImGuiTableFlags.NoBordersInBody,ImGuiTableFlags.RowBg, ImGuiTableFlags.Sortable) --remove ImGuiTableFlags.Resizable to see if it fixes CTD
invT = {} --My character inventory used to make the ini
allInventories = {} --Full connected client ini data. This isn't manipulated and is only reloaded. Don't want to have to read from the files repeatedly. 
displayTable = {} --Data that's displayed in the window. May be filtered based by slot or autofilter
columnToRemove = {}
arg = {...}
writeToLog = false

--To just write to the ini file if started with /lua run gear once
if #arg > 0 then
    if arg[1]:lower() == "once" then justWrite = true end
    if arg[1]:lower() == "debug" then Write.loglevel = 'Debug' writeToLog = true end
    if arg[1]:lower() == "beta" then beta = true end
end

local itemT = {}

--Row, slot, slotname for the icons in inventory order
local displaySlotTable = {[0]= {8,7,n="leftear"},[1]= {0,7,n="head"},[2]= {0,7,n="face"},[3]= {0,7,n="rightear"},
[4]= {0,7,n="chest",d=true}, [5]= {0,115,n="neck"},
[6]= {0,7,n="arms",d=true}, [7]= {0,115,n="back"},
[8]= {0,7,n="waist",d=true}, [9]= {0,115,n="shoulder"},
[10]= {0,7,n="leftwrist",d=true}, [11]= {0,115,n="rightwrist"},
[12]= {0,7,n="legs",d=true}, [13]= {0,7,n="hands"}, [14]= {0,7,n="charm"}, [15]= {0,7,n="feet"},
[16]= {69,0,n="leftfinger",d=true}, [17]= {0,5,n="rightfinger"}, [18]= {0,8,n="powersource"},
[19]= {0,7,n="mainhand",d=true}, [20]= {0,7,n="offhand"}, [21]= {0,7,n="ranged"}, [22]={0,7,n="ammo"}
}

--Write the full table to the file
local function save_settings(set)
    LIP.save(path, set)
end

--Create the settings data for sorting in the settings window
local function checkIniSettings()
    itemTypesTable = {}
    iniDisplaySettings = {}
    iniDisplaySettings["Display Settings"] = {}
    iniDisplaySettings["Column Order"] = {}
    local tempFileName = '/Gearly/Gearly Settings.ini'
    local tempPath = dir..tempFileName
    Write.Debug(string.format("path is %s open is %s",tempPath,io.open(tempPath)))
    if writeToLog then mq.cmdf("/mqlog path is %s open is %s",tempPath,io.open(tempPath)) end
    if not io.open(tempPath) then --Doesnt exist. Default settings based on geatData.lua
        Write.Info("Please wait while we create your settings files")
        for k,v in pairs(gearData.itemTypesToDisplay) do
            table.insert(itemTypesTable,k)
            iniDisplaySettings["Display Settings"][k] = v
        end
        for k,v in pairs(gearData.selectedStats) do
            iniDisplaySettings["Column Order"][k] = v
        end
        LIP.save(tempPath,iniDisplaySettings)
        statsToDisplay = iniDisplaySettings["Column Order"]
    else --Load ini if it exists already (with a blank check)
        for k in pairs(gearData.itemTypesToDisplay) do
            table.insert(itemTypesTable,k)
        end
        iniDisplaySettings = LIP.load(tempPath)
        if not iniDisplaySettings["Display Settings"] or not iniDisplaySettings["Column Order"]then
            print("empty file")
            for k,v in pairs(gearData.itemTypesToDisplay) do
                iniDisplaySettings["Display Settings"][k] = v
            end
            for k,v in pairs(gearData.selectedStats) do
                iniDisplaySettings["Column Order"][k] = v
            end
        end
         statsToDisplay = iniDisplaySettings["Column Order"]--Load the columns to display from the ini
    end
end

--Get dannet groups for the dropdown
local function getComboItems()
    local groups = {}
    for group_idx = 1, mq.TLO.DanNet.GroupCount() do
        local group = mq.TLO.DanNet.Groups(group_idx)()
        Write.Debug('group %s idx %s _ %s match %s eval %s',group,group_idx,group:find('_'),group:match('%d', -1),(not group:find('_') or (group:find('_') and group:find('zone'))))
        if writeToLog then mq.cmdf('group %s idx %s _ %s match %s eval %s',group,group_idx,group:find('_'),group:match('%d', -1),(not group:find('_') or (group:find('_') and group:find('zone')))) end
        if (not group:find('_') or (group:find('_') and (group:find('zone') or group:find('group'))) and #group > 0) then --temp fix for adding blanks. Not sure what result from Groups is resulting in blanks
            Write.Debug('adding %s',group)
            if writeToLog then mq.cmdf('adding %s',group) end
            table.insert(groups, group)
        end
    end
    ComboBoxGroups = groups
end

--Read the entire ini file to allInventories. Changed to individual files and have to iterate over each person connected to dannet
local function loadAllCharactersTable(loadSettings)
    local numConnectedClients
    local allClients
    if useGroupName == "all" then
        numConnectedClients = mq.TLO.DanNet.PeerCount()
        allClients = mq.TLO.DanNet.Peers()
    else
        allClients = mq.TLO.DanNet.Peers(useGroupName)()
        numConnectedClients = mq.TLO.DanNet.PeerCount(useGroupName)()
    end
    Write.Debug(string.format("#connected is %s allClients list is %s useGroupName %s",numConnectedClients,allClients, useGroupName))
    if writeToLog then mq.cmdf("/mqlog #connected is %s allClients list is %s useGroupName %s",numConnectedClients,allClients, useGroupName) end
    allInventories = {}
    for i=1, numConnectedClients do --Iterate through 1-#of connected toons
        currentClient = getArg(allClients,i,"|")
        local _position = string.find(currentClient,"_")
        Write.Debug(string.format("pos: %s",_position))
        if writeToLog then mq.cmdf("/mqlog pos: %s",_position) end
        if _position then
            currentClient = string.sub(currentClient, _position + 1)
        end
        Write.Debug(string.format("current Client: %s",currentClient))
        if writeToLog then mq.cmdf("/mqlog current Client: %s",currentClient) end
        if not currentClient then Write.Error(string.format("CRITICAL ERROR. Please unload and reload DanNet (/plugin mq2dannet unload  /plugin mq2dannet)")) mq.exit() end
        --allInventories[currentClient] = {}
        local tempFileName = '/Gearly/Character Data/'..currentClient..'_'..mq.TLO.EverQuest.Server()..'.ini'
        local tempPath = dir..tempFileName
        Write.Debug(string.format("path is %s open is %s",tempPath,io.open(tempPath)))
        if writeToLog then mq.cmdf("/mqlog path is %s open is %s",tempPath,io.open(tempPath)) end
        allInventories[currentClient] ={}
        if io.open(tempPath) then
            allInventories[currentClient] = LIP.load(tempPath)
        else --If characters connected to dannet don't have their own ini yet
            Write.Error(string.format("No toon info for %s. Run /lua run gearly once on all characters or click the Update All Gear button",currentClient))
            allInventories[currentClient] = {}
        end
    end
    if loadSettings then checkIniSettings() end
end

--Create what we're displaying in the table
local function DtotheA(wipe)
    if not displayTable or wipe then displayTable = {} end
    if sort_specs then sort_specs.SpecsDirty = true end --To resort it after we update what we're sorting
    for toon, slotTable in pairs(allInventories) do --Toon table that has all the slots in another table 
        Write.Debug(string.format("current toon: %s",toon))
        if writeToLog then mq.cmdf("/mqlog current toon: %s",toon) end
        if allInventories[toon]["other"] then 
            local toonClass = allInventories[toon]["other"]["class"]
            local toonName = allInventories[toon]["other"]["Character"]
            for slot, valuesTable in pairs(allInventories[toon]) do --For each slot in the slot table which has a values table
                if slot ~= "other" then
                    local dataToInsert = {}
                    if currentFilters then
                        matchClass = string.match(currentFilters,toonClass) --used in AutoFilter
                        matchSlot = string.match(currentFilters,slot)
                        for statType, value in pairs(allInventories[toon][slot]) do
                            if matchSlot and not isAuto then
                                if not value or value == "NULL" then dataToInsert[statType] = "" else dataToInsert[statType] = value end
                                dataToInsert["Character"] = toonName --character name to display in the table
                                dataToInsert["ItemSlot"] = slot --Item slot name
                                dataToInsert["Class"] = toonClass --Item slot name
                            elseif matchSlot and matchClass then --matches | array to our 11th entry in value (class shortname) for AutoFilter
                                if not value or value == "NULL" then dataToInsert[statType] = "" else dataToInsert[statType] = value end
                                dataToInsert["Character"] = toonName --character name to display in the table
                                dataToInsert["ItemSlot"] = slot --Item slot name
                                dataToInsert["Class"] = toonClass --Item slot name
                            end
                        end
                        if matchSlot and not isAuto then table.insert(displayTable,dataToInsert) end
                        if matchSlot and matchClass then table.insert(displayTable,dataToInsert) end
                    else
                        for statType, value in pairs(allInventories[toon][slot]) do --For each stat and value in the current slot for the current toon
                            if not value or value == "NULL" then dataToInsert[statType] = "" else dataToInsert[statType] = value end
                        end
                        dataToInsert["Character"] = toonName --character name to display in the table
                        dataToInsert["ItemSlot"] = slot --Item slot name
                        dataToInsert["Class"] = toonClass --Item slot name
                        table.insert(displayTable,dataToInsert) --Insert into the next available row the data we want to display
                    end
                end
            end
        end
    end
end

--Fill table with my gear stats and write to ini if called for
local function createInventoryData(doWrite,reloadIni)
    for i=0,22,1 do --Writes my gear stats to the invT[myName] table.
        Inv = mq.TLO.Me.Inventory(i)
        --local slotName = mq.TLO.Me.Inventory(i).InvSlot.Name()
        local slotName = mq.TLO.InvSlot(i).Name()
        if Inv() then --If I have an item in the slot
            Write.Debug(string.format("i%s Inv%s slot%s",i,Inv(),slotName))
            if writeToLog then mq.cmdf("/mqlog i%s Inv%s slot%s",i,Inv(),slotName) end
            invT[slotName] = {}
            for j=1,#statsToDisplay do --For each stat we want to save and display
                invT[slotName][statsToDisplay[j]] = Inv[statsToDisplay[j]] --Put the stat and its value into the table
            end
        else
            slotName = gearData.slots[i] --Have to define slotName since it's empty and comes in as nil
            invT[slotName] = {}
            for j=1,#statsToDisplay do --For each stat we want to save and display
                if Inv[statsToDisplay[j]] then invT[slotName][statsToDisplay[j]] = " " end--Put the stat and its value into the table if it's a real item stat.
            end
        end
        if i == 22 then invT.other = {class = mq.TLO.Me.Class(), Character = mq.TLO.Me.CleanName.Lower()} end
    end
    if doWrite then --if updating the character ini, write each slot to the ini for the character running the script
        save_settings(invT)
        Write.Info("\agMy Gearly Data Updated")
    end
    if reloadIni then loadAllCharactersTable(reloadIni) end
end

--Populate the table and write to gear.ini if no ini exists
local function loadSettings()
    local s = io.open(path)
    Write.Info("Welcome to Gearly by Lemons")
    if s and not justWrite then --Character data file exists
        Write.Info("Ini already exists")
        checkIniSettings()
        createInventoryData(false,true) --Update the character ini file with inventory data, load 
    else
        Write.Info("Writing new data to your character file")
        checkIniSettings()
        createInventoryData(true,true)
    end
end

--Write all connected toons to the gear.ini file one at a time to avoid The Thing
--Don't need this anymore since it's all individual files.
local function refreshAll()
    Write.Info("\agRefreshing all connected character's gear data")
    local pn = mq.TLO.DanNet.Peers(1)
    mq.cmdf("/dgex /lua run gearly once")
    createInventoryData(true,false)
    if mq.TLO.DanNet.PeerCount() > 1 then
        mq.delay(500, function () return mq.TLO.DanNet(pn).O('"Lua.Script[gearly].Status"')() == "running" end ) 
        mq.delay(500, function () return mq.TLO.DanNet(pn).O('"Lua.Script[gearly].Status"')() == "exited"end )
        dannet.unobserve(pn,"Lua.Script[gearly].Status",1000)
    end
    loadAllCharactersTable(false) --Load character data from ini files but don't reload gearly ini settings
    Write.Info("\arDone refreshing gear data")
end

--GUI:Does clicky things. nm is name of the item that's passed in. Filters based on currentFilters
local function Click(nm)
    Write.Debug(string.format("Entering Click with %s", nm))
    if writeToLog then mq.cmdf("/mqlog Entering Click with %s", nm) end
    getComboItems()
    local clickedL = ImGui.IsMouseClicked(ImGuiMouseButton.Left)
    local clickedR = ImGui.IsMouseClicked(ImGuiMouseButton.Right)
    if ImGui.IsItemHovered() and clickedL and nm then --left click
        if string.match(nm,"wrist") == "wrist" then
            if currentFilters ~= "leftwristrightwrist" then currentFilters = "leftwristrightwrist" else currentFilters = nil end
        elseif string.match(nm,"ear") == "ear" then
            if currentFilters ~= "leftearrightear" then currentFilters = "leftearrightear" else currentFilters = nil end
        elseif string.match(nm,"finger") == "finger" then
            if currentFilters ~= "leftfingerrightfinger" then currentFilters = "leftfingerrightfinger" else currentFilters = nil end
        else
           if currentFilters == nm then currentFilters = nil else currentFilters = nm end
        end
        DtotheA(true) --recreate data to display
        return
    end
    if ImGui.IsItemHovered() and clickedR and nm then
        mq.cmdf("/itemnotify %s rightmouseheld",nm)
        mq.cmdf("/noparse /dge /dgtell ${Me.Inventory[%s].ItemLink[CLICKABLE]}",nm)
        return
    end
    if ImGui.IsItemHovered() and nm == "clear" then
        if not isAuto then currentFilters = nil end
        DtotheA(true)
        return
    end
    if ImGui.IsItemHovered() and nm == "refresh" then
        createInventoryData(true)
        DtotheA(true)
    end
    if ImGui.IsItemHovered() and nm == "refreshall" then
        if connected(mq.TLO.Me.CleanName()) then
            doRefresh = true
        else
            Write.Error("Dannet required. Make sure you have dannet running with other toons connected to the default group")
        end
    end
end

--Sort items from displayTable
local function CompareWithSortSpecs(a, b)
    for n = 1, current_sort_specs.SpecsCount, 1 do --for each header we're filtering by since we can filter by multiple at one time
        local sort_spec = current_sort_specs:Specs(n)
        local columnName = statsToDisplay[sort_spec.ColumnUserID]
        local delta = 0
        --Check if a is a number or not and then apply the sort. 
        local valueA = a[columnName]
        local valueB = b[columnName]
        if not valueA or not valueB then return false end
        if valueA == " "  and valueB == " " then return false end --If both blank entries, then return false (delta 0)
        if valueA == " "  and type(valueB) == "number" then --B isn't blank and is a num, set blank A to -1
            valueA = -1
        end
        if valueB == " "  and type(valueA) == "number" then --A isn't blank and is a num, set blank B to -1
            valueB = -1
        end
        if valueB == " " then tonumber(valueB) end
        if valueA == nil then valueA = -1 end
        if valueB == nil then valueB = -1 end
        if type(valueA) == "string" then --name
            if valueA < valueB then
                delta = -1
            elseif valueB < valueA then
                delta = 1
            else
                delta = 0
            end
        elseif type(valueA) == "number" then
            delta = valueA - valueB
        end
        if delta ~= 0 then
            if sort_spec.SortDirection == ImGuiSortDirection.Ascending then
                return delta < 0
            end
            return delta > 0
        end
    end
    return false
end

--GUI:Draw the item icons in the GUI. Slot #, name of item, dummy line for spacing, butt(unused)
local function drawInventory(t,name,dummy,butt)
    if not dummy then
        if not mq.TLO.Me.Inventory(name)() then ImGui.SameLine(displaySlotTable[t][1],displaySlotTable[t][2]) ImGui.DrawTextureAnimation(animBox, 52, 52) return end --For TLP with no powersource
        ImGui.SameLine(displaySlotTable[t][1],displaySlotTable[t][2])
        animItems:SetTextureCell(itemT[name]["itemIcon"]-500)
        local x, y = ImGui.GetCursorPos()
        ImGui.DrawTextureAnimation(animBox, 52, 52)
        ImGui.SetCursorPos(x, y)
        ImGui.DrawTextureAnimation(animItems, 48, 48)
    else
        ImGui.NewLine()
        if not mq.TLO.Me.Inventory(name)() then ImGui.SameLine(displaySlotTable[t][1],displaySlotTable[t][2]) ImGui.DrawTextureAnimation(animBox, 52, 52) return end --For TLP with no powersource
        animItems:SetTextureCell(itemT[name]["itemIcon"]-500) ImGui.SameLine(displaySlotTable[t][1],displaySlotTable[t][2]) --If it's nil I'm gonna break. Need to check for nil or handle it earlier. Default to display 0? not sure.
        local x, y = ImGui.GetCursorPos()
        ImGui.DrawTextureAnimation(animBox, 52, 52)
        ImGui.SetCursorPos(x, y)
        ImGui.DrawTextureAnimation(animItems, 48, 48)
    end
    if ImGui.IsItemClicked(ImGuiMouseButton.Right) or ImGui.IsItemClicked(ImGuiMouseButton.Left) then Click(name) end --handles left and right clicking the icon since it's not a button
end

--GUI:Table data for the gui item icons Makes the table that is used to create the inventory window
local function FillTable() 
    for i= 0,22,1 do
        local slotName = mq.TLO.InvSlot(i).Name()
        local icon = mq.TLO.Me.Inventory(i).Icon()
        if icon then
            itemT[slotName] = {itemName= mq.TLO.Me.Inventory(i).Name(), itemIcon= mq.TLO.Me.Inventory(i).Icon()} 
        else
            itemT[slotName] = {itemName= mq.TLO.Me.Inventory(i).Name(), itemIcon= nil}
        end
    end
end

--GUI:Name the columns in gui table
local function nameColumns()
    for i=1,#statsToDisplay,1 do --columns table will be populated when we set the settings so this shouldn't need to change
        local colName = statsToDisplay[i]
        ImGui.TableSetupColumn(colName,0,-1.0,i)
    end
end

--GUI:Draw table
local function drawTable()
    if ImGui.BeginTable('charInvTable', #statsToDisplay, tableFlags) then    --Start the table  
        nameColumns() --Name the columns
        ImGui.TableSetupScrollFreeze(0, 1) -- Make row always visible
        sort_specs = ImGui.TableGetSortSpecs()
        if sort_specs then
            if sort_specs.SpecsDirty then
                for n = 1, sort_specs.SpecsCount, 1 do --SpecsCount is how many columns are being sorted
                    local sort_spec = sort_specs:Specs(n)
                end
                if #displayTable > 1 then
                    current_sort_specs = sort_specs
                    table.sort(displayTable, CompareWithSortSpecs)
                    current_sort_specs = nil
                end
                sort_specs.SpecsDirty = false
            end
        end

        ImGui.TableHeadersRow() --Make the header with the names from nameColumns
        local clipper = ImGuiListClipper.new() -- Use clipper so we only display what's on the screen
            clipper:Begin(#displayTable)--The data table we're displaying
            while clipper:Step() do -- while it's actually showing
                for row_n = clipper.DisplayStart, clipper.DisplayEnd - 1, 1 do --for each row that is currently shown
                    local item = displayTable[row_n +1] --table item to display. Not sure why +1. 0 vs 1 index?
                    ImGui.PushID(item) --Not sure. Initialize it to access it?
                    for i=1,#statsToDisplay do --For each stat they want to see, display it on the table
                        if item[statsToDisplay[i]] == "Character" then else
                            ImGui.TableNextColumn()
                            ImGui.Text(string.format('%s', item[statsToDisplay[i]]))
                        end
                    end
                    ImGui.PopID()
                end
            end
        ImGui.EndTable()
    end
end

--Handle auto filter based on data in item window
local function autoFilter()
    local isOpen = mq.TLO.Window("ItemDisplayWindow").Open()
    if isOpen then
        getComboItems()
        local itemWindow = mq.TLO.Window("ItemDisplayWindow").Text() --Name of the item in the item window
        if itemWindow:match("(Augmented)") then itemWindow = itemWindow:sub(1,-13) end
        local numClasses = mq.TLO.DisplayItem(itemWindow).Item.Classes()
        if itemWindowID ~= itemWindow then itemWindowID = itemWindow end --So we don't run the operation on the same window multiple times
        if itemWindowID ~= listDone and numClasses > 0 then
            currentFilters = nil
            for cls=1, numClasses,1 do --Create classTxt (BRD WAR ENC). Item windows aren't uniform. Have to iterate through DisplayItem
                if not currentFilters then currentFilters = mq.TLO.DisplayItem(itemWindow).Item.Class(cls)() else currentFilters = currentFilters.."|"..mq.TLO.DisplayItem(itemWindow).Item.Class(cls)() end
            end
            listDone = itemWindowID
            local slots = nil
            for slt=1, mq.TLO.DisplayItem(itemWindow).Item.WornSlots(),1 do
                slotNum = tonumber(mq.TLO.DisplayItem(itemWindow).Item.WornSlot(slt)())
                local sltc = slotArray[slotNum]
                if not slots then
                    slots = sltc
                else
                    slots = slots.." "..sltc
                end
            end
            sort_specs.SpecsDirty = true
            if not slots then return end
            if string.match(slots,"wrist") then
                currentFilters = currentFilters.."|".."leftwristrightwrist"
                slots = slots:gsub("wrist","") --remove wrist from slots
            end
            if string.match(slots,"ear") then
                currentFilters = currentFilters.."|".."leftearrightear"
                slots = slots:gsub("ear","")
            end
            if string.match(slots,"fingers")then
                currentFilters = currentFilters.."|".."leftfingerrightfinger"
                slots = slots:gsub("fingers","")
            end
            if string.match(slots,"Primary") then
                currentFilters = currentFilters.."|".."mainhand"
                slots = slots:gsub("Primary","")
            end
            if string.match(slots,"Secondary") then
                currentFilters = currentFilters.."|".."offhand"
                slots = slots:gsub("Secondary","")
            end
            if string.match(slots,"Range") then
                currentFilters = currentFilters.."|".."ranged"
                slots = slots:gsub("Range","")
            end
            if slots then currentFilters = currentFilters.."|"..slots end
            Write.Debug("Filter to class "..currentFilters.." for item "..itemWindow)
            if writeToLog then mq.cmdf("/mqlog Filter to class "..currentFilters.." for item "..itemWindow) end
            displayTable = nil
            DtotheA()
        end
    elseif #displayTable and currentFilters and listDone then --If no window open but still filtering
        displayTable = nil
        listDone = nil
        itemWindowID = nil
        currentFilters = nil
        sort_specs.SpecsDirty = true
        DtotheA()
    end
end

--Sort items from settings table
local function settingsSort(a, b)
    for n = 1, current_sort_specs.SpecsCount, 1 do
        local sort_spec = current_sort_specs:Specs(n)
        local delta = 0
        local aVal = a:lower()
        local bVal = b:lower()
        if aVal < bVal then
            delta = -1
        elseif bVal < aVal then
            delta = 1
        else
            delta = 0
        end
        if delta ~= 0 then
            if sort_spec.SortDirection == ImGuiSortDirection.Ascending then
                return delta < 0
            end
            return delta > 0
        end
    end
end

local function settingsPopout()
    if not openSettings then return end
    openSettings, shouldDrawSettingsGUI = ImGui.Begin('Settings Popup', openSettings)
    if shouldDrawSettingsGUI then
        local tempStatsToDisplay = {}
        if ImGui.BeginTable("settingsList",1,settingsTableFlags) then
            sort_specs = ImGui.TableGetSortSpecs()
            if sort_specs then
                if sort_specs.SpecsDirty then
                    for n = 1, sort_specs.SpecsCount, 1 do --SpecsCount is how many columns are being sorted
                        local sort_spec = sort_specs:Specs(n)
                    end
                    if #itemTypesTable > 1 then
                        current_sort_specs = sort_specs
                        table.sort(itemTypesTable, settingsSort)
                        current_sort_specs = nil
                    end
                    sort_specs.SpecsDirty = false
                end
            end
            ImGui.TableSetupColumn("Item Stat",bit32.bor(ImGuiTableColumnFlags.WidthFixed))
            ImGui.TableHeadersRow()
            for _, stat in ipairs(itemTypesTable) do
                ImGui.TableNextColumn()
                is_checked = iniDisplaySettings["Display Settings"][stat] --Load the saved state from the lua file table
                checked, changed = ImGui.Checkbox(stat, is_checked)
                if changed then --Only update things if the user clicks on a button.
                    iniDisplaySettings["Display Settings"][stat] = checked --Update the table in memory for writing back to the settings file
                    if not checked then table.insert(columnToRemove,stat) end
                end
                if is_checked or checked then --Can I remove is_checked? Should be able to. 
                    table.insert(tempStatsToDisplay,stat) --Temp table to update statsToDisplay right now
                end
            end
            ImGui.EndTable()
        end
        ImGui.SetCursorPos(210, 25)
        if ImGui.Button("Save and close") then --Do all the updating if they hit save
            Write.Info("Settings Saved. Forcing all clients to update character data")
            for k,v in ipairs(columnToRemove) do
                for i=1, #statsToDisplay do
                    local tempStat = statsToDisplay[i]
                    if v == tempStat then table.remove(statsToDisplay,i) break end
                end
            end
            for j=1,#tempStatsToDisplay do --Insert instead of recreate so we retain our column order
                if tableHasValue(statsToDisplay,tempStatsToDisplay[j]) then else
                    table.insert(statsToDisplay,tempStatsToDisplay[j])
                end
            end
            iniDisplaySettings["Column Order"] = statsToDisplay
            LIP.save(dir..'/Gearly/Gearly Settings.ini', iniDisplaySettings)
            doRefresh = true
            DtotheA(true)
            openSettings = not openSettings
        end
    end
    ImGui.End()
end

local function groupSelector()
    ImGui.SetCursorPos(70, 200)
    ImGui.SetNextItemWidth(100)
    useGroup, changed = ImGui.Combo("##combo", useGroup, ComboBoxGroups, tableLength(ComboBoxGroups))
    if changed then
        useGroupName = ComboBoxGroups[useGroup]
        loadAllCharactersTable(false)
        DtotheA(true)
    end
end

--GUI:Draw radial buttons for toggles
local function optionsBoxes()
    ImGui.SetCursorPos(70, 90) --Location of the radial button
    isAuto, pressedAuto = ImGui.Checkbox('Auto Filter', isAuto)
    ImGui.SetCursorPos(70, 262) --Temp position, see comment below
    if ImGui.Button("Settings") then --Create the settings button. Should create an icon in the header bar eventually
        openSettings =  not openSettings
    end
end

--GUI:Main GUI function
local function Gear()
    if not openGUI then return end
    openGUI, shouldDrawGUI = ImGui.Begin('Gearly', openGUI)
    if shouldDrawGUI then
        --Create the buttons in the EQ layout
        local x, y = ImGui.GetCursorPos()
            for i= 0,#displaySlotTable,1 do
                if not displaySlotTable[i]["d"] then displaySlotTable[i]["d"] = false end
                if itemT[displaySlotTable[i]["n"]]["itemIcon"] ~= mq.TLO.Me.Inventory(name).Icon() then
                    FillTable()
                end
                drawInventory(i,displaySlotTable[i]["n"],displaySlotTable[i]["d"])
            end

        ImGui.SetCursorPos(x+7, 352) --Location of the clear button. It's offset on a different character. Not sure why. Need to investigate
        if ImGui.Button("Clear",50,48) then
            if ImGui.IsMouseReleased(ImGuiMouseButton.Left) then Click("clear") end
        end

        ImGui.SetCursorPos(70, 125) --Create refresh/update gear button 
        if ImGui.Button("Update my gear",0,0) then
            if ImGui.IsMouseReleased(ImGuiMouseButton.Left) then Click("refresh") end
        end

        ImGui.SetCursorPos(70, 160) --Create refresh all/update all gear button 
        if ImGui.Button("Update all gear",0,0) then
            if ImGui.IsMouseReleased(ImGuiMouseButton.Left) then Click("refreshall") end
        end

        optionsBoxes()
        settingsPopout()
        groupSelector()
        if isAuto then autoFilter() end
        if pressedAuto and not isAuto then --One time execution when ticking off Auto Filter checkbox
            if listDone then listDone = nil end
            if currentFilters then currentFilters = nil DtotheA(true) end
            if itemWindowID then itemWindowID = nil end
        end
        ImGui.SetCursorPos(242, y) --Location of the table
        drawTable()
    end
    ImGui.End()
end

--handles the /gear commands
local function gearCommand(args)
    if not args then Write.Info("Specify /gear show /gear hide or /gear refresh") return end
    Write.Debug(string.format("%s called in gearCommand",args))
    if writeToLog then mq.cmdf("/mqlog %s called in gearCommand",args) end
    argl = args:lower()
    if argl == "show" then openGUI = true end
    if argl == "hide" then openGUI = false end
    if argl == "refresh" then
        Write.Debug("Calling refresh command")
        if writeToLog then mq.cmdf("/mqlog Calling refresh command") end
        createInventoryData(true)
    end
    if argl == "refreshall" then
        if connected(myName) then
            refreshAll()
            DtotheA(true)
            Write.Debug("Done writing all clients")
            if writeToLog then mq.cmdf("/mqlog Done writing all clients") end
        else
            Write.Error("Dannet required. Make sure you have dannet running with other toons connected to the default group")
            if writeToLog then mq.cmdf("/mqlog Dannet required. Make sure you have dannet running with other toons connected to the default group") end
        end
    end
    if argl == "printtable" then
        printTable(displayTable)
    end
end

--Create the /gear command
mq.bind('/gear', gearCommand)

--Main
getComboItems()
if not justWrite then FillTable() end
loadSettings()
if justWrite then Write.Info("Finished updating character data in "..path) mq.exit() end

--initialize the GUI
mq.imgui.init('thing', Gear)

DtotheA(true) --initial loading of the data to display

while loop do
    if doRefresh then
        getComboItems()
        refreshAll()
        DtotheA(true)
        Write.Debug("Done writing all clients")
        if writeToLog then mq.cmdf("/mqlog Done writing all clients") end
        doRefresh = false
        sort_specs.SpecsDirty = true
    end

    mq.delay(100)
end