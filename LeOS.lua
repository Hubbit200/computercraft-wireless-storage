local w, h = term.getSize()
local modem = nil

-- Functions --

function centreWrite(text, y)
    term.setCursorPos(w/2 - #text/2, y)
    term.clearLine()
    term.write(term)
end
function write(text, y)
    term.setCursorPos(1, y)
    term.clearLine()
    term.write(text)
end
function clearLine(y)
    term.setCursorPos(1, y)
    term.clearLine()
end

function startup()
    term.clear()
    centreWrite(" ______", h/2-2)
    sleep(0.1)
    centreWrite("| LeOS |", h/2-1)
    sleep(0.1)
    centreWrite("|  __  |", h/2)
    sleep(0.1)
    centreWrite("|_|  |_|", h/2+1)
    sleep(1)
    centreWrite("——————", h/2-2)
    centreWrite("/  L OS  ∖", h/2-1)
    centreWrite("|   __   |", h/2)
    centreWrite("|_/    |_|", h/2+1)
    sleep(0.2)
    term.clear()
    centreWrite("— —— —", h/2-3)
    centreWrite("/    OS   ∖", h/2-1)
    centreWrite("|          |", h/2)
    centreWrite("| /   —  |_", h/2+1)
    sleep(0.2)
    term.clear()
    centreWrite("  —", h/2-3)
    centreWrite("    OS     ∖", h/2-1)
    centreWrite("           |", h/2)
    centreWrite("|     —    _", h/2+2)
    sleep(0.2)
    term.clear()
    centreWrite("      ", h/2-1)
    centreWrite("|          _", h/2+2)
    term.clear()
end

function startNetwork()
    modem = peripheral.find("modem")
    modem.open()
end

function storageSearchScreen()
    write("STORAGE SEARCH")
    write(string.rep("-", x))
end
function searchQuery(text)

end

-- START --
startup()

storageSearchScreen()
while true do
    read(nil, nil, function(text)
        if text ~= "" then
            pos = 3
            for _,i in pairs(getOptions(text)) do
                clearLine(pos)
                term.write(i)
                pos = pos + 1
            end
        end
    end)
end