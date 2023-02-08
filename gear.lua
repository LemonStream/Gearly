--[[Companion to gear.mac v0.2
UI that shows your own stats and those connected to DNet
Only query upon request. Don't monitor/observe
Tab per char? Meh
Table view that's sortable?
Click on a slot to show the item for all connected chars (all db chars?)
Right click a name in the list to filter to just that name
Add in all stat fields since you can right click the headers and choose what to display

Click on a slot to put that slot only into a table data and display it on the right
Click a button to show all items in file in a table (no trees)
Display total inventory slots left open (both category)

Only saves to ini file using /gear refresh or /gear refreshall or if there is no ini file
/gear show, /gear hide
/lua run gear once --This will just write to the ini and stop the script
]]

local mq = require('mq')
require('ImGui')
local Write = require("lib/Write")
local dannet = require('lib/dannet/helpers')
local LIP = require('lib/LIP')
local LT = require('lib/Lemons/LemonTools')

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
blueBorder:SetTextureCell(1)
dir = mq.TLO.MacroQuest.Path():gsub('\\', '/')
fileName = '/lua/Gearly/Character Data/'..mq.TLO.Me.CleanName()..'_'..mq.TLO.EverQuest.Server()..'.ini'
path = dir..fileName
imguiFlags = bit32.bor(ImGuiWindowFlags.None)
tableFlags = bit32.bor(ImGuiTableFlags.Hideable,ImGuiTableFlags.NoBordersInBody,ImGuiTableFlags.SizingFixedSame,ImGuiTableFlags.Resizable,ImGuiTableFlags.RowBg, ImGuiTableFlags.ScrollY, ImGuiTableFlags.BordersOuter,ImGuiTableFlags.Sortable, ImGuiTableFlags.Reorderable,ImGuiTableFlags.SortMulti)
local columns = {"Name","ItemSlot","ItemName","HP","Mana","AC","End","Haste","Attack","ManaRegen","HPRegen","Class"}
numColumns = #columns
invT = {}
arg = {...}

--To just write to the ini file if started with /lua run gear once
if #arg > 0 then
    if arg[1] == "once" then justWrite = true end
end

local itemT = {}

--Row, slot, slotname for the icons in inventory order
local pT = {[0]= {8,7,n="leftear"},[1]= {0,7,n="head"},[2]= {0,7,n="face"},[3]= {0,7,n="rightear"},
[4]= {0,7,n="chest",d=true}, [5]= {0,115,n="neck"},
[6]= {0,7,n="arms",d=true}, [7]= {0,115,n="back"},
[8]= {0,7,n="waist",d=true}, [9]= {0,115,n="shoulder"},
[10]= {0,7,n="leftwrist",d=true}, [11]= {0,115,n="rightwrist"}, 
[12]= {0,7,n="legs",d=true}, [13]= {0,7,n="hands"}, [14]= {0,7,n="charm"}, [15]= {0,7,n="feet"}, 
[16]= {69,0,n="leftfinger",d=true}, [17]= {0,5,n="rightfinger"}, [18]= {0,8,n="powersource"}, 
[19]= {0,7,n="mainhand",d=true}, [20]= {0,7,n="offhand"}, [21]= {0,7,n="ranged"}, [22]={0,7,n="ammo"}
}

--Write the full table to the file
local save_settings = function(set) 
    LIP.save(path, invT) 
end
--Read the entire ini file to invT
local loadini = function()
    Write.Debug(string.format("Opening path %s",path))
    if io.open(path) then invT = LIP.load(path) end 
    if io.open(dir..'/lua/Gearly/Character Data/Mrmezzy_'..mq.TLO.EverQuest.Server()..'.ini') then invT = LIP.load(dir..'/lua/Gearly/Character Data/Mrmezzy_'..mq.TLO.EverQuest.Server()..'.ini') end
end

--Create what we're displaying in the table
local DtotheA = function(wipe)
    if not invA or wipe then invA = {} end
    if sort_specs then sort_specs.SpecsDirty = true end --To resort it after we update what we're sorting= true --To resort it after we update what we're sorting
    -- Create item list
    for toon, section in pairs(invT) do --toon is just a number here now I think. For each [ToonName] in gear.ini
        Write.Debug(string.format("Entering toon %s in section %s",toon,section))
        a = string.match(toon,"(.+)_(.+)") --a is everything before _ in the ini    
        Write.Debug(string.format("%s %s %s|%s|",not mq.TLO.DanNet.Peers.Find(toon)(),mq.TLO.DanNet.Peers.Find(toon)(),mq.TLO.DanNet.Peers(),toonOnly))
        if not mq.TLO.DanNet.Peers.Find(a)() then Write.Debug(string.format("\arCan't find %s in DanNet, skipping",a)) else --Only display connected toons
            for key, value in pairs(invT[toon]) do
                local entry = {}
                local val = {}
                for w in string.gmatch(value,"([^|]+)") do  --for each argument separate by | 
                    if currentFilters then --For when filtering to a single slot or class/slot
                        local matchClass = string.match(currentFilters,getArg(value,11,"|"))
                        local matchSlot = string.match(currentFilters,getArg(value,1,"|"))
                        if not listDone and not matchClass and matchSlot then table.insert(val,w) end --If it finds a match in currentFilters with the first entry (which is slot name) then add it to end of val list.
                        if matchClass and matchSlot then table.insert(val,w) end --matches | array to our 11th entry in value (class shortname) for AutoFilter. string.match(texttosearch,match,index)
                    elseif key ~= 21 then --for all non PS slots. This lets us display empty slots that exist
                        table.insert(val,w)
                    elseif mq.TLO.Me.HaveExpansion("the buried sea")() then --Only display PS if we have TBS
                        --print("w is powersource and key ",key ~= 21,key)
                        table.insert(val,w)
                    end
                end
                if val[1] then
                    entry = {
                        Name = toon,
                        ItemSlot = val[1],
                        ItemName =val[2],
                        HP =val[3],
                        Mana =val[4],   
                        AC =val[5],
                        End = val[6],
                        Haste = val[7],
                        Attack = val[8],
                        ManaRegen = val[9],
                        HPRegen = val[10],
                        Class = val[11]
                    }
                    table.insert(invA,entry)
                end
            end
        end
    end
end

--Fill table with my gear stats and write to ini if called for
local Setup = function(doWrite)
    myName = mq.TLO.Me.CleanName()
    loadini()
    invT[myName] = {} --Blanks our current nested table. Means you can't hand edit the ini. No reason to. 
    for i=0,22,1 do
        Inv = mq.TLO.Me.Inventory(i)
        if Inv() then 
            table.insert(invT[myName],i,mq.TLO.InvSlot(i).Name().."|"..Inv().."|"..Inv.HP().."|"..Inv.Mana().."|"..Inv.AC().."|"..Inv.Endurance()
            .."|"..Inv.Haste().."|"..Inv.Attack().."|"..Inv.ManaRegen().."|"..Inv.HPRegen().."|"..mq.TLO.Me.Class().."|") 
        elseif not Inv() then
            table.insert(invT[myName],i,string.format("%s|No Item|0|0|0|0|0|0|0|0|%s|",mq.TLO.InvSlot(i).Name(),mq.TLO.Me.Class())) --powersource or empty slots        
        end 
    end
    if doWrite then 
        save_settings(invT) 
        Write.Debug("\agDone writing to gear.ini") 
        loadini() --Loads the other entries from the ini file into the dictionary
        DtotheA(true)
    else 
        loadini() --Loads the other entries from the ini file into the dictionary
        DtotheA()
    end
end

--Populate the table and write to gear.ini if no ini exists
local loadSettings = function()
    local s = io.open(path)
    Write.Info("Welcome to Gearly by Lemons")
    if s and not justWrite then
        Setup(false)
    else
        Write.Debug("Writing new data to gear.ini")
        Setup(true)
    end
end

--Write all connected toons to the gear.ini file one at a time to avoid the hulk
local refreshAll = function()
    local me = mq.TLO.Me.CleanName():lower()
    for i=1,mq.TLO.DanNet.PeerCount() do
        local pn = mq.TLO.DanNet.Peers.Arg(i,"|")()
        Write.Debug("Generating inventory on "..pn)
        if me == pn:lower() then Setup(true)
        else
            dannet.observe(pn,"Lua.Script[gear].Status",5000)
            mq.cmdf("/dex %s /lua run gear once",pn)
            mq.delay(2000, function () return mq.TLO.DanNet(pn).O('"Lua.Script[gear].Status"')():lower() == "running"end )
            mq.delay(10000, function () return mq.TLO.DanNet(pn).O('"Lua.Script[gear].Status"')():lower() == "exited"end )
            dannet.unobserve(pn,"Lua.Script[gear].Status",1000)
        end
    end
    loadini()
end

--GUI:Does clicky things. nm is name of the item that's passed in. Filters based on currentFilters
local Click = function (nm)
    clickedL = ImGui.IsMouseClicked(ImGuiMouseButton.Left)
    clickedR = ImGui.IsMouseClicked(ImGuiMouseButton.Right)
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
        invA = nil
        DtotheA() 
        return
    end
    if ImGui.IsItemHovered() and clickedR and nm then
        mq.cmdf("/itemnotify %s rightmouseheld",nm)
        mq.cmdf("/noparse /dge /dgtell ${Me.Inventory[%s].ItemLink[CLICKABLE]}",nm)
        return
    end
    if ImGui.IsItemHovered() and nm == "clear" then
        currentFilters = nil 
        invA = nil
        DtotheA() 
        return
    end
end

--GUI:Does clicky things on the table. nm is name of the char that's passed in. Filters based on currentFilters
local ClickTable = function (nm)
    Write.Debug("1Clicked table on "..nm)
    clickedR = ImGui.IsMouseClicked(ImGuiMouseButton.Right)
    if ImGui.IsItemHovered() and clickedR and nm then
        Write.Debug("2Clicked table on "..nm)
        if currentFilters == nm then currentFilters = nil else currentFilters = nm Write.Info(currentFilters) end --Currently crashes due to nil at 345. currentFitlers probably only can deal with slot name instead of any data
        invA = nil
        DtotheA() 
        return
    end
end

--Sort items from invA
local function CompareWithSortSpecs(a, b)
    for n = 1, current_sort_specs.SpecsCount, 1 do
        local sort_spec = current_sort_specs:Specs(n)
        local delta = 0
        if sort_spec.ColumnUserID == 1 then --name
            if a.Name < b.Name then
                delta = -1
            elseif b.Name < a.Name then
                delta = 1
            else
                delta = 0
            end
        elseif sort_spec.ColumnUserID == 2 then
            if a.ItemSlot < b.ItemSlot then
                delta = -1
            elseif b.ItemSlot < a.ItemSlot then
                delta = 1
            else
                delta = 0
            end
        elseif sort_spec.ColumnUserID == 3 then
            if a.ItemName < b.ItemName then
                delta = -1
            elseif b.ItemName < a.ItemName then
                delta = 1
            else
                delta = 0
            end
        elseif sort_spec.ColumnUserID == 4 then
            delta = a.HP - b.HP
        elseif sort_spec.ColumnUserID == 5 then
            delta = a.Mana - b.Mana
        elseif sort_spec.ColumnUserID == 6 then
            delta = a.AC - b.AC
        elseif sort_spec.ColumnUserID == 7 then
            delta = a.End - b.End
        elseif sort_spec.ColumnUserID == 8 then
            delta = a.Haste - b.Haste
        elseif sort_spec.ColumnUserID == 9 then
            delta = a.Attack - b.Attack
        elseif sort_spec.ColumnUserID == 10 then
            delta = a.ManaRegen - b.ManaRegen
        elseif sort_spec.ColumnUserID == 11 then
            delta = a.HPRegen - b.HPRegen
        elseif sort_spec.ColumnUserID == 12 then
            if a.Class < b.Class then
                delta = -1
            elseif b.Class < a.Class then
                delta = 1
            else
                delta = 0
            end
        end
        if delta ~= 0 then
            if sort_spec.SortDirection == ImGuiSortDirection.Ascending then
                return delta < 0
            end
            return delta > 0
        end
    end
    if not b.HP then b.HP = tostring(0) end
    if not a.HP then a.HP = tostring(0) end
    -- Always return a way to differentiate items.
    return a.HP < b.HP
end

--GUI:Draw the item icons in the GUI. Slot #, name of item, dummy line for spacing, butt(unused)
local drawInventory = function (t,name,dummy,butt)
    if not dummy then 
        if not mq.TLO.Me.Inventory(name)() then ImGui.SameLine(pT[t][1],pT[t][2]) ImGui.DrawTextureAnimation(animBox, 52, 52) return end --For TLP with no powersource
        ImGui.SameLine(pT[t][1],pT[t][2]) 
        animItems:SetTextureCell(itemT[name]["itemIcon"]-500) 
        local x, y = ImGui.GetCursorPos()
        ImGui.DrawTextureAnimation(animBox, 52, 52)
        ImGui.SetCursorPos(x, y)
        ImGui.DrawTextureAnimation(animItems, 48, 48)
    else
        ImGui.NewLine()
        if not mq.TLO.Me.Inventory(name)() then ImGui.SameLine(pT[t][1],pT[t][2]) ImGui.DrawTextureAnimation(animBox, 52, 52) return end --For TLP with no powersource
        animItems:SetTextureCell(itemT[name]["itemIcon"]-500) ImGui.SameLine(pT[t][1],pT[t][2]) --If it's nil I'm gonna break. Need to check for nil or handle it earlier. Default to display 0? not sure.
        local x, y = ImGui.GetCursorPos()
        ImGui.DrawTextureAnimation(animBox, 52, 52)
        ImGui.SetCursorPos(x, y)
        ImGui.DrawTextureAnimation(animItems, 48, 48)
    end
    if ImGui.IsItemClicked(ImGuiMouseButton.Right) or ImGui.IsItemClicked(ImGuiMouseButton.Left) then Click(name) end --handles left and right clicking the icon since it's not a button
end

--GUI:Table data for the gui item icons
local FillTable = function() --Makes the table that is used to create the inventory window
    for i= 0,22,1 do
        slotName = mq.TLO.InvSlot(i).Name()
        itemT[slotName] = {itemName= mq.TLO.Me.Inventory(i).Name(), itemIcon= mq.TLO.Me.Inventory(i).Icon()}
    end
end

--GUI:Name the columns in gui table
local nameColumns = function()
    for i=1,numColumns,1 do
        ImGui.TableSetupColumn(columns[i],0,-1.0, i) --Don't call next column cause it will crash. The unqieness of this is fine
    end
end

--GUI:Draw table
local drawTable = function()
    if ImGui.BeginTable('charInvTable', numColumns, tableFlags) then    --Start the table  
        nameColumns() --Name the columns
        ImGui.TableSetupScrollFreeze(0, 1) -- Make row always visible
        sort_specs = ImGui.TableGetSortSpecs()
        if sort_specs then
            if sort_specs.SpecsDirty then
                --print(string.format('Sort %d items:', #invA))
                for n = 1, sort_specs.SpecsCount, 1 do --SpecsCount is how many columns are being sorted
                    local sort_spec = sort_specs:Specs(n)
                end
                if #invA > 1 then
                    current_sort_specs = sort_specs
                    table.sort(invA, CompareWithSortSpecs)
                    current_sort_specs = nil
                end
                sort_specs.SpecsDirty = false
            end
        end 

        ImGui.TableHeadersRow() --Make the header with the names from nameColumns
        local clipper = ImGuiListClipper.new() -- Use clipper so we only display what's on the screen
            clipper:Begin(#invA)--The data table we're displaying
            while clipper:Step() do -- while it's actually showing
                for row_n = clipper.DisplayStart, clipper.DisplayEnd - 1, 1 do --for each row that is currently shown
                    local item = invA[row_n + 1] --table item to display. Not sure why +1. 0 vs 1 index?
                    if item.ItemSlot then -- Because we store empty powersource slot as || we need to see if the third variable exists before we try to display it (nil check)
                        ImGui.PushID(item) --Not sure. Initialize it to access it?
                        ImGui.TableNextRow()
                        ImGui.TableNextColumn()
                        ImGui.Text(item.Name)
                        if ImGui.IsItemClicked(ImGuiMouseButton.Right) then ClickTable(item.Name) end --handles right clicking the name on the table.
                        ImGui.TableNextColumn()
                        ImGui.Text(item.ItemSlot)
                        ImGui.TableNextColumn()
                        ImGui.Text(item.ItemName)
                        ImGui.TableNextColumn()
                        ImGui.Text(string.format('%d', item.HP)) -- Better to display as string?
                        ImGui.TableNextColumn()
                        ImGui.Text(string.format('%d', item.Mana))
                        ImGui.TableNextColumn()
                        ImGui.Text(string.format('%d', item.AC))
                        ImGui.TableNextColumn()
                        ImGui.Text(string.format('%d', item.End))
                        ImGui.TableNextColumn()
                        ImGui.Text(string.format('%d', item.Haste))
                        ImGui.TableNextColumn()
                        ImGui.Text(string.format('%d', item.Attack))
                        ImGui.TableNextColumn()
                        ImGui.Text(string.format('%d', item.ManaRegen))
                        ImGui.TableNextColumn()
                        ImGui.Text(string.format('%d', item.HPRegen))
                        ImGui.TableNextColumn()
                        ImGui.Text(item.Class)
                        ImGui.PopID() --Loaded the data now let show it? Not sure
                    end
                end
            end
        ImGui.EndTable()
    end
end

--Handle auto filter based on data in item window
local autoFilter = function()
    local isOpen = mq.TLO.Window("ItemDisplayWindow").Open()
    if isOpen then 
        local itemWindow = mq.TLO.Window("ItemDisplayWindow").Text() --Name of the item in the item window
        if itemWindow:match("(Augmented)") then itemWindow = itemWindow:sub(1,-13) end
        local numClasses = mq.TLO.DisplayItem(itemWindow).Item.Classes()
        if itemWindowID ~= itemWindow then itemWindowID = itemWindow end --So we don't run the operation on the same window multiple times
        if itemWindowID ~= listDone and numClasses > 0 then
            currentFilters = nil
            for cls=1, numClasses,1 do --Create classTxt (BRD WAR ENC). Item windows aren't uniform. Have to iterate through DisplayItem
                if not currentFilters then currentFilters = mq.TLO.DisplayItem(itemWindow).Item.Class(cls)().."|" else currentFilters = currentFilters.."|"..mq.TLO.DisplayItem(itemWindow).Item.Class(cls)() end
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
            print("Slots is ",slots)
            print("currentFilters is ",currentFilters)
            if not slots then return end
            --Primary vs mainhand etc. 
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
            if slots then currentFilters = currentFilters..slots.."|" end
            Write.Debug("Filter to class "..currentFilters.." for item "..itemWindow)
            invA = nil
            DtotheA() 
        end
    elseif #invA and currentFilters and listDone then --If no window open but still filtering
        invA = nil
        listDone = nil
        itemWindowID = nil
        currentFilters = nil
        DtotheA()
    end
end
--GUI:Draw radial buttons for toggles
local optionsBoxes = function()
    ImGui.SetCursorPos(70, 90) --Location of the radial button
    isAuto, pressed = ImGui.Checkbox('Auto Filter', isAuto)
end

--GUI:Main GUI function
local Gear = function()
    if not openGUI then return end
    openGUI, shouldDrawGUI = ImGui.Begin('Gearly', openGUI)
    if shouldDrawGUI then
        --Create the buttons in the EQ layout
        local x, y = ImGui.GetCursorPos()
            for i= 0,#pT,1 do
                if not pT[i]["d"] then pT[i]["d"] = false end
                drawInventory(i,pT[i]["n"],pT[i]["d"])
            end
        ImGui.SetCursorPos(x+7, 344) --Location of the clear button. It's offset on a different character. Not sure why. Need to investigate
        if ImGui.Button("Clear",52,50) then 
            if ImGui.IsMouseReleased(ImGuiMouseButton.Left) then Click("clear") end
        end
        optionsBoxes()
        if isAuto then autoFilter() end
        if pressed and not isAuto then --One time execution when ticking off Auto Filter checkbox
            if listDone then listDone = nil end
            if currentFilters then currentFilters = nil DtotheA() end
            if itemWindowID then itemWindowID = nil end
        end
        ImGui.SetCursorPos(242, y) --Location of the table
        drawTable()
    end
    ImGui.End()
end

--handles the /gear commands
local gearCommand = function(args)
    argl = args:lower()
    if argl == "show" then openGUI = true end
    if argl == "hide" then openGUI = false end
    if argl == "refresh" then
        Setup(true)
        save_settings(invT)
    end
    if argl == "refreshall" then
        if connected(mq.TLO.Me.CleanName()) then 
            refreshAll()
            save_settings(invT)
            DtotheA(true)
            Write.Debug("Done writing all clients to gear.ini")
        else 
            Write.Error("Dannet required. Make sure you have dannet running with other toons connected to the default group")
        end
    end
    if argl == "printtable" then
        loadini()
        printTable(invT)
    end
end

--Create the /gear command
mq.bind('/gear', gearCommand)

--Main
if not justWrite then FillTable() end
loadSettings()
if justWrite then Write.Info("Finished updating gear.ini in "..path) mq.exit() end

--initialize the GUI
mq.imgui.init('thing', Gear)

while loop do 
    mq.delay(1000)   
end