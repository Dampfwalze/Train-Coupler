---@param x number
---@param min number
---@param max number
---@return number
function math.clamp(x, min, max)
    return math.min(max, math.max(min, x))
end

---@param x number
---@return number
function math.sign(x)
    return (x > 0 and 1) or (x == 0 and 0) or -1
end

---@param x number
---@return number
function math.smoothStep(x)
    return x * x * (3 - 2 * x)
end

---@param i number
---@param a number
---@param b number
---@return number
function math.lerp(a, b, i)
    return a + (b - a) * i
end

---@param x number
---@param in_min number
---@param in_max number
---@param out_min number
---@param out_max number
---@return number
function math.map(x, in_min, in_max, out_min, out_max)
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end
