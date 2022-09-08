require "LeOS-utils"

local w, h = term.getSize()
local modem = peripheral.find("modem")
local connectedDB = settings.get("connectedDB", -1)
local dbSecureCode = settings.get("dbSecureCode", -1)
local dbIndeces = ""

-- Functions --

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
    else
        modem.open(connectedDB)
    end
end
function addDBOption()
    if y == 3 then
        term.clear()
        centreWrite("CHOOSE DB", 1)
        centreWrite(string.rep("-", w), 2)
    end
    local event, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
    write(message, y)
    y = y + 1
    dbList[#dbList+1] = replyChannel
end
function selectDBOption()
    local event, _, x2, y2
    repeat
        event, _, x2, y2 = os.pullEvent("mouse_click")
    until (y2 > 2 and y2 < #dbList+3)
    term.clear()
    connectedDB = dbList[y2-2]
    modem.open(connectedDB)
    modem.transmit(connectedDB, connectedDB, "getCode")
end
function signIn()
    local event, _, _, replyChannel, message, _ = os.pullEvent("modem_message")
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
        local event2, _, _, replyChannel2, message2, _ = os.pullEvent("modem_message")
        if message2 == "success" then
            modem.close(connectedDB)
            connectedDB = replyChannel2
            settings.set("connectedDB", replyChannel2)
            settings.set("dbSecureCode", dbSecureCode)
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
    modem.transmit(connectedDB, connectedDB, encrypt("getdb", dbSecureCode))
    local event, _, _, _, message, _ = os.pullEvent("modem_message")
    dbIndeces = message
    term.clear()
    centreWrite("STORAGE SEARCH", 1)
    write(string.rep("-", w), 2)
    write(string.rep("-", w), h - 1)
    searchWindow = window.create(term.current(), 1,3,w,h-4)
    term.setCursorPos(1, h)
end

function searchQuery(input)
    return buildList(string.gmatch(dbIndeces, "%S*"..input.."%S*"))
end

-- START --
readAnim("amogus.txt", 5, 6, h/3, 0.05)
checkDBConnection()

storageSearchScreen()
while true do
    read(nil, nil, function(text)
        if text ~= "" then
            local pos = 1
            searchWindow.clear()
            for _,i in pairs(searchQuery(text)) do
                searchWindow.setCursorPos(1, pos)
                searchWindow.write(i)
                pos = pos + 1
            end
        else
            searchWindow.clear()
        end
        term.setCursorPos(1, h)
    end)
end