require "LeOS-utils"

settings.load(".leosclient-settings")
local w, h = term.getSize()
local modem = peripheral.find("modem")
local connectedDB = settings.get("connectedDB", -1)
local connectedTurtles = settings.get("connectedTurtles", {})
local dbSecureCode = settings.get("dbSecureCode", -1)
local inExtendedMode = settings.get("inExtendedMode", false)
local dbIndeces = ""
local name, count
local mode = -1 -- -1=storage, 1=turtle list, 2=add turtles
local turtleList = {}

-- Storage Functions --

function checkDBConnection()
    if connectedDB == -1 then
        loadScreen()
        modem.open(1510)
        modem.transmit(1510, 1510, "list")

        y = 3
        dbList = {}
        while connectedDB == -1 do
            parallel.waitForAny(addDBOption, selectDBOption)
        end
        signIn()
        modem.close(1510)
    end
    modem.open(connectedDB)
end
function addDBOption()
    if y == 3 then
        term.clear()
        centreWrite("CHOOSE DB", 1)
        centreWrite(string.rep("-", w), 2)
    end
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
    write(message, y)
    y = y + 1
    dbList[#dbList+1] = replyChannel
end
function selectDBOption()
    local x2, y2
    repeat
        _, _, x2, y2 = os.pullEvent("mouse_click")
    until (y2 > 2 and y2 < #dbList+3)
    term.clear()
    connectedDB = dbList[y2-2]
    modem.open(connectedDB)
    modem.transmit(connectedDB, connectedDB, "getCode")
end
function signIn()
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
    if message == "ready" then
        centreWrite("LOGIN", 1)
        centreWrite(string.rep("-", w), 2)
        write("Password:", 3)
        term.setCursorPos(1, 4)
        local pswd = read("*")
        write("Signup code:", 6)
        term.setCursorPos(1, 7)
        dbSecureCode = read("*")
        modem.transmit(connectedDB, replyChannel, encrypt(pswd, dbSecureCode))
        local _, _, _, replyChannel2, message2, _ = os.pullEvent("modem_message")
        if message2 == "success" then
            modem.close(connectedDB)
            connectedDB = replyChannel2
            settings.set("connectedDB", replyChannel2)
            settings.set("dbSecureCode", dbSecureCode)
            settings.save(".leosclient-settings")
        else
            centreWrite("Incorrect credentials", h/2)
            modem.close(connectedDB)
            sleep(1)
            connectedDB = -1
            checkDBConnection()
        end
    else
        centreWrite("Server 503", h/2)
        modem.close(connectedDB)
        sleep(1)
        connectedDB = -1
        checkDBConnection()
    end
end

function storageSearchScreen()
    loadScreen()
    sleep(0.1)
    modem.transmit(connectedDB, connectedDB, {encrypt("getdb", dbSecureCode)})
    local _, _, _, _, message, _ = os.pullEvent("modem_message")
    dbIndeces = message
    term.clear()
    centreWrite("STORAGE SEARCH", 1)
    write(string.rep("-", w), 2)
    write(string.rep("-", w), h - 1)
    if searchWindow == nil then
        searchWindow = window.create(term.current(), 1,3,w,h-4)
    end
    term.setCursorPos(1, h)
end

function searchQuery(input)
    return buildList(string.gmatch(dbIndeces, "%S*"..input.."%S*"))
end
function searchInput()
    while true do
        read(nil, nil, function(text)
            if text ~= "" then
                local pos = 1
                searchWindow.clear()
                displayedItems = searchQuery(text)
                local a, b
                for _,i in pairs(displayedItems) do
                    a, b = i:match(":([^~]+)~([^~]+)")
                    searchWindow.setCursorPos(1, pos)
                    searchWindow.write(a)
                    searchWindow.setCursorPos(w-2, pos)
                    searchWindow.write("|" .. b .. " ")
                    pos = pos + 1
                    if pos > h-4 then
                        break
                    end
                end
            else
                searchWindow.clear()
            end
            term.setCursorPos(1, h)
        end)
        term.scroll(-1)
        centreWrite("STORAGE SEARCH", 1)
        clearLine(h)
    end
end
function selectItemClick()
    local x, y
    repeat
        _, _, x, y = os.pullEvent("mouse_click")
    until (y > 2 and displayedItems ~= nil and y < #displayedItems+3)
    itemInfo(y-2)
end
function keyPress()
    local key
    repeat
        _, key = os.pullEvent("key")
    until (key == keys.enter and #displayedItems > 0) or (key == keys.tab and inExtendedMode == true)
    if mode == -1 and key == keys.enter then
        itemInfo(1)
    else
        if mode < 0 then mode = 1 else mode = -1 end
        switchMode()
    end
end

function itemInfo(index)
    term.clear()
    name, count = displayedItems[index]:match("([^~]+)~([^~]+)")
    count = tonumber(count)
    centreWrite(name:match(":(.+)"), 1)
    write(string.rep("-", w), 2)
    write("Available: " .. count, 3)
    write("Enter 0 to return to list", h)
end

function dbUpdate()
    while true do
        repeat
            local _, _, _, _, message, _ = os.pullEvent("modem_message")
        until type(message) ~= "table"
        dbIndeces = message
    end
end

-- Other functions --
function switchMode()
    -- mode is already switched in keyPress
    if mode == -1 then
        for _, t in pairs(connectedTurtles) do
            modem.close(1511 + t)
        end
        returnNum = -1
        term.setCursorBlink(true)
        checkDBConnection()
    else
        modem.close(connectedDB)
        term.setCursorBlink(false)
        checkTurtleConnection()
    end
end

function checkTurtleConnection()
    if connectedTurtles == {} then
        addTurtles()
    end
    for _, t in pairs(connectedTurtles) do
        modem.open(1511 + t)
    end
end
function addTurtles()
    term.clear()
    centreWrite("OS ID: " .. os.getComputerID(), h/2)
    centreWrite("Click anywhere to continue", h)
    local _, _, _, _ = os.pullEvent("mouse_click")
    term.clear()
    loadScreen()
    modem.open(1510)
    modem.transmit(1510, 1510, {"list-turtles", os.getComputerID()})

    y = 3
    turtleList = {}
    local done = false
    while not done do
        parallel.waitForAny(addTurtleOption, selectTurtleOption, refreshTurtlesOptions)
    end
    modem.close(1510)
    mode = 1
    otherScreen()
end
function isTurtleInTable(turtle)
    for _, t in pairs(connectedTurtles) do
        if t == turtle then
            return true
        end
    end
    return false
end
function addTurtleOption()
    if y == 3 then
        term.clear()
        centreWrite("ADD TURTLES", 1)
        centreWrite(string.rep("-", w), 2)
        centreWrite(string.rep("-", w), h-1)
        centreWrite("DONE", h)
    end
    local _, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
    if not isTurtleInTable(message) then
        write("Turtle " .. message, y)
        y = y + 1
        turtleList[#turtleList+1] = message
    end
end
function selectTurtleOption()
    local x2, y2
    repeat
        _, _, x2, y2 = os.pullEvent("mouse_click")
    until (y2 == h) or (y2 > 2 and y2 < #turtleList+3 and turtleList[y2-2] ~= nil)
    if y2 == h then
        settings.set("connectedTurtles", connectedTurtles)
        settings.save(".leosclient-settings")
        done = true
    else
        write("- Added -", y2)
        connectedTurtles[#connectedTurtles+1] = turtleList[y2-2]
        turtleList[y2-2] = nil
    end
end

function otherScreen()
    loadScreen()
    sleep(0.1)
    term.clear()
    centreWrite("ACTIVE TURTLES", 1)
    write(string.rep("-", w), 2)
    write(string.rep("-", w), h - 1)
    centreWrite("Add turtles", h)
    for i, t in pairs(connectedTurtles) do
        write("- Turtle " .. t .. "---", 2*i+1)
        write("No data...", 2*i+2)
    end
end
function clickAddTurtles()
    sleep(0.5)
    while true do
        local _, _, x, y = os.pullEvent("mouse_click")
        if y == h then
            mode = 2
            addTurtles()
        end
    end
end
function turtleUpdate()
    for _, t in pairs(connectedTurtles) do
        modem.transmit(1511 + t, 1511 + t, "get-info")
    end
    while true do
        local message
        repeat
            _, _, _, _, message, _ = os.pullEvent("modem_message")
        until type(message) == "table"
        if mode == 1 then
            for i, t in pairs(connectedTurtles) do
                if message[1] == t then
                    write(message[2], 2*i + 2)
                end
            end
        end
    end
end

-- ERRORS --
function error(message)
    term.clear()
    centreWrite(string.rep("-", #message+2), h/2-2)
    centreWrite("ERROR", h/2-1)
    centreWrite(message, h/2)
    centreWrite(string.rep("-", #message+2), h/2+1)
    sleep(1.5)
    term.clear()
end

-- START --
readAnim("amogus.txt", 5, 6, h/3, 0.05)
checkDBConnection()

while true do
    if mode == -1 then
        storageSearchScreen()
        local displayedItems
        parallel.waitForAny(searchInput, selectItemClick, keyPress, dbUpdate)
        if mode == -1 then
            local selectedAmount = ""
            while tonumber(selectedAmount) == nil or tonumber(selectedAmount) > count or tonumber(selectedAmount) < 0 do
                term.setTextColour(colors.white)
                write("Amount to extract: ", 5)
                selectedAmount = read(nil, nil, function(text)
                    if tonumber(text) == nil or tonumber(text) > count or tonumber(text) < 0 then
                        term.setTextColour(colors.red)
                    else
                        term.setTextColour(colors.white)
                    end
                end)
            end
            if selectedAmount ~= 0 then
                modem.transmit(connectedDB, connectedDB, {encrypt("pull", dbSecureCode), name, selectedAmount})
                loadScreen()
                local _, _, _, _, message, _ = os.pullEvent("modem_message")
                if message == "insufficient" then
                    error("Insufficient")
                end
            end
        end
    else
        otherScreen()
        parallel.waitForAny(turtleUpdate, clickAddTurtles, keyPress)
    end
end