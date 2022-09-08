require "utils"

local verifiedUsers = settings.get("verifiedUsers", {})
local db = {}
local dbIndeces = ""
local inChest = settings.get("inChest", "")
local inChestWrapped
local outChest = settings.get("outChest", "")
local pw = settings.get("pw", "")
math.randomseed(os.time())
local secCode = settings.get("secCode", math.random(1000,9999))
local modem = peripheral.find("modem", function(name, modem)
    return modem.isWireless()
end)
local dbChannel = 1511 + os.computerID()
local dbSigninChannel = 1509 - os.computerID()

function setup()
    term.clear()
    term.setCursorPos(1,1)
    print("Enter storage name:")
    os.setComputerLabel(read())
    setPw()
    print("\nEnter In Chest name:")
    inChest = read()
    settings.set("inChest", inChest)
    print("\nEnter Out Chest name:")
    outChest = read()
    settings.set("outChest", outChest)
    settings.set("setupDone", 1)
    term.clear()
end
function setPw()
    print("\nEnter Password:")
    pw = read("*")
    settings.set("pw", pw)
end

function goOnline()
    modem.open(1510)
    modem.open(dbSigninChannel)
    modem.open(dbChannel)
end
function listenModem()
    local _, _, channel, replyChannel, message, _ = os.pullEvent("modem_message")
    if channel == dbChannel then
        if type(message) == table then
            print(message[1])
            if unencrypt(message[1], secCode) == "pull" then
                extract(message[2], message[3])
            end
        else
            if unencrypt(message, secCode) == "getdb" then
                modem.transmit(dbChannel, dbChannel, dbIndeces)
            end
        end
    elseif channel == 1510 then
        modem.transmit(1510, dbSigninChannel, os.computerLabel())
    elseif channel == dbSigninChannel then
        if message == "getCode" then
            term.clear()
            term.setCursorPos(1,1)
            print("Signup code: " .. secCode)
            settings.set("secCode", secCode)
            modem.transmit(dbSigninChannel, dbSigninChannel, "ready")
        else
            term.clear()
            if unencrypt(message, secCode) == pw then
                modem.transmit(dbSigninChannel, dbChannel, "success")
            end
        end
    end
end

function scanStorage()
    term.setCursorPos(1,1)
    print("Scanning...")
    storageChests = {peripheral.find("inventory", function(name, modem)
        return name ~= inChest and name ~= outChest
    end)}

    for i=1, #storageChests do
        for slot, item in pairs(storageChests[i].list()) do
            if item.name ~= nil and db[item.name] == nil then
                db[item.name] = {[i]={slot}, ["c"]=item.count}
            elseif item.name ~= nil then
                db[item.name][i].insert(slot)
                db[item.name]["c"] = db[item.name]["c"] + db[item.count]
            end
        end
    end
    buildIndeces()
    print("Complete!")
end
function buildIndeces()
    -- build string with all item names and amounts
    dbIndeces = ""
    for i, d in pairs(db) do
        dbIndeces = dbIndeces .. " " .. i .. "~" .. d["c"]
    end
end

function extract(name, count)
    local extractedCount = 0
    for s, slots in db[name] do
        if s ~= "c" then
            for slot in slots do
                extractedCount = extractedCount + storageChests[s].pushItems(outChest, slot, count)
                if extractedCount >= count then
                    return 1
                end
            end
        end
    end
end

function listenInput()
    os.pullEvent("redstone")
    while rs.getInput("back") == true do
        for slot, item in pairs(inChestWrapped.list()) do
            if item.name ~= nil then
                local transferredAmount = 0
                while transferredAmount < item.count do
                    inChestWrapped.pushItems()
                end
                if db[item.name] == nil then
                    db[item.name] = {[i]={slot}, ["c"]=item.count}
                else
                    db[item.name][i].insert(slot)
                    db[item.name]["c"] = db[item.name]["c"] + db[item.count]
                end
            end
        end
    end
end

-- START --
if settings.get("setupDone", 0) == 0 then
    setup()
end
inChestWrapped = peripheral.wrap(inChest)
scanStorage()

goOnline()
while true do parallel.waitForAny(listenModem, listenInput) end