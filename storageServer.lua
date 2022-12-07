require "utils"
require "cc.pretty"

settings.load(".leos-settings")
local verifiedUsers = settings.get("verifiedUsers", {})
db = {}
local dbIndeces = ""
local inChest = settings.get("inChest", nil)
local inChestWrapped
local outChest = settings.get("outChest", nil)
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
    settings.save(".leos-settings")
    term.clear()
end
function setPw()
    print("\nEnter Password:")
    pw = read("*")
    settings.set("pw", pw)
end

-- MODEM ..
function goOnline()
    modem.open(1510)
    modem.open(dbSigninChannel)
    modem.open(dbChannel)
end
function listenModem()
    while true do
        local _, _, channel, replyChannel, message, _ = os.pullEvent("modem_message")
        if channel == dbChannel then
            local action = unencrypt(message[1], secCode)
            if action == "pull" then
                extract(message[2], tonumber(message[3]))
            elseif action == "getdb" then
                modem.transmit(dbChannel, dbChannel, dbIndeces)
            end
        elseif channel == 1510 and type(message) ~= "table" and message == "list" then
            modem.transmit(1510, dbSigninChannel, os.computerLabel())
        elseif channel == dbSigninChannel then
            if message == "getCode" then
                term.clear()
                term.setCursorPos(1,1)
                print("Signup code: " .. secCode)
                settings.set("secCode", secCode)
                settings.save(".leos-settings")
                modem.transmit(dbSigninChannel, dbSigninChannel, "ready")
            else
                term.clear()
                if unencrypt(message, secCode) == pw then
                    modem.transmit(dbSigninChannel, dbChannel, "success")
                end
            end
        end
    end
end

function scanStorage()
    -- scans storage and builds db - a table of items and their quantities
    term.clear()
    term.setCursorPos(1,1)
    print("Scanning...")
    db = {}
    storageChests = {peripheral.find("inventory", function(name, modem)
        return name ~= inChest and name ~= outChest
    end)}

    for i=1, #storageChests do
        for slot, item in pairs(storageChests[i].list()) do
            if item ~= nil then
                if db[item.name] == nil then
                    db[item.name] = {[i]={slot}, ["c"]=item.count}
                else
                    if db[item.name][i] == nil then
                        db[item.name][i] = {slot}
                    else
                        table.insert(db[item.name][i], slot)
                    end
                    db[item.name]["c"] = db[item.name]["c"] + item.count
                end
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
    -- extract specific items from storage
    local extractedCount = 0
    local toRemove = {}
    for barrel, slots in pairs(db[name]) do
        if barrel ~= "c" then
            for i, slot in pairs(slots) do
                extractedCount = extractedCount + storageChests[barrel].pushItems(outChest, slot, count-extractedCount)
                if storageChests[barrel].getItemDetail(slot) == nil then
                    table.insert(toRemove, {barrel, i})
                end
                if extractedCount >= count then
                    db[name]["c"] = db[name]["c"] - extractedCount
                    if db[name]["c"] == 0 then
                        db[name] = nil
                    else
                        for _, t in pairs(toRemove) do
                            table.remove(db[name][t[1]], t[2])
                            if #db[name][t[1]] == 0 then
                                db[name][barrel] = nil
                                break
                            end
                        end
                    end
                    buildIndeces()
                    modem.transmit(dbChannel, dbChannel, dbIndeces)
                    return 1
                end
            end
        end
    end
    modem.transmit(dbChannel, dbChannel, "insufficient")
    return 0
end

function listenInput()
    -- listen for redstone input, if active insert new items into storage
    while true do
        os.pullEvent("redstone")
        if inChestWrapped == nil then
            inChestWrapped = peripheral.wrap(inChest)
        end
        while rs.getInput("bottom") == true do
            for slot, item in pairs(inChestWrapped.list()) do
                local transferredAmount = 0
                for i=1, #storageChests do
                    local contents = storageChests[i].list()
                    for j=1, 27 do
                        if contents[j] == nil or (contents[j].name == item.name and contents[j].count < 64) then
                            local newAmount = inChestWrapped.pushItems(peripheral.getName(storageChests[i]), slot, 65, j)
                            if newAmount > 0 then
                                transferredAmount = transferredAmount + newAmount
                                if db[item.name] == nil then
                                    db[item.name] = {[i]={j}, ["c"]=0}
                                else
                                    if db[item.name][i] == nil then
                                        db[item.name][i] = {j}
                                    else
                                        table.insert(db[item.name][i], j)
                                    end
                                end
                                if transferredAmount >= item.count then
                                    break
                                end
                            end
                        end
                    end
                    if transferredAmount >= item.count then
                        db[item.name]["c"] = db[item.name]["c"] + transferredAmount
                        buildIndeces()
                        modem.transmit(dbChannel, dbChannel, dbIndeces)
                        break
                    end
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
parallel.waitForAll(listenModem, listenInput)