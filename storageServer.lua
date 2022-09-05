require "utils"

local verifiedUsers = settings.get("verifiedUsers", {})
local db = {}
local dbIndeces = ""
local inChest = settings.get("inChest", "right")
local outChest = settings.get("outChest", "top")
local pw = settings.get("pw", "")
local modem = peripheral.find("modem", function(name, modem)
    return modem.isWireless()
end)

function setup()
    print("Enter storage name:\n")
    os.setComputerLabel(read())
    setPw()
    print("Enter In Chest side:\n")
    inChest = read()
    settings.set("inChest", inChest)
    print("Enter Out Chest side:\n")
    outChest = read()
    settings.set("outChest", outChest)
    settings.set("setupDone", 1)
end
function setPw()
    print("Enter Password:\n")
    pw = read("*")
    settings.set("pw", pw)
end

function goOnline()
    -- Signup channel
    modem.open(1510)

end
function listenModem()
    local event, _, channel, replyChannel, message, _ = os.pullEvent("modem_message")
    if channel == 1510 then
        modem.transmit(1510, 1511, os.computerLabel())
    else if channel == 1511 then
        
end


function scanStorage()
    print("Scanning...")
    storageChests = {peripheral.find("inventory", function(name, modem)
        return name ~= inChest and name ~= outChest
    end)}

    for i=1, #storageChests do
        for _, item in ipairs(storageChests[i].list()) do
            if db[item.name] == nil then
                db[item.name] = db[item.count]
                dbIndeces = dbIndeces .. " " .. item.name
            else
                db[item.name] = db[item.name] + db[item.count]
            end
        end
    end
    print("Complete!")
end

function getOptions(input)
    return buildList(string.gmatch(dbIndeces, "%S*"..input.."%S*"))
end

function search(input)
    --name, amount
end

-- START --
if settings.get("setupDone", 0) == 0 then
    setup()
end
scanStorage()

goOnline()
while true do listenModem() end