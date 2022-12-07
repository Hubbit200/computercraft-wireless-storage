local w, h = term.getSize()

function buildList(...)
    local list = {}
    local i = 1
    for v in ... do
        list[i] = v
        i = i + 1
    end
    return list
end

function encrypt(text, key)
    out = {string.byte(text, 1, #text)}
    for i = 1, #out do
        out[i] = out[i] + key
    end
    return out
end

-- Writing functions

function centreWrite(text, y)
    term.setCursorPos(w/2 - #text/2 + 1, y)
    term.clearLine()
    term.write(text)
end
function write(text, y)
    term.setCursorPos(1, y)
    term.clearLine()
    term.write(text)
end
function writeSpec(text, x, y)
    term.setCursorPos(x, y)
    term.clearLine()
    term.write(text)
end
function clearLine(y)
    term.setCursorPos(1, y)
    term.clearLine()
end
function divider(y)
    term.setCursorPos(1, y)
    term.clearLine()
    term.write(string.rep("-", w))
end
function loadScreen()
    term.clear()
    centreWrite("----------", h/2-1)
    centreWrite("Loading...", h/2)
    centreWrite("----------", h/2+1)
end

function readAnim(file, h, offset, yPos, speed)
    term.clear()
    local lines = {}
    for line in io.lines(file) do 
      lines[#lines + 1] = line
    end
    local len = #lines
    for i=1, len, h+1 do
        for j=0, h-1, 1 do
            writeSpec(lines[i+j], offset, yPos+j)
        end
        sleep(tonumber(lines[i+h])*speed)
    end
    term.clear()
end