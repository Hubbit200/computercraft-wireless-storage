function buildList(...)
    local list = {}
    local i = 1
    for v in ... do
        list[i] = v
        i = i + 1
    end
    return list
end

function concatIndeces(table)
    local t = {}
    for k, _ in pairs(table) do
        t[#t+1] = tostring(k)
    end
    return table.concat(t, " ")
end