function concatIndeces(table)
    local t = {}
    for k, _ in pairs(table) do
        t[#t+1] = tostring(k)
    end
    return table.concat(t, " ")
end

function unencrypt(table, code)
    local out = ""
    for _, c in ipairs(table) do
        out = out .. string.char(c - code)
    end
    return out
end