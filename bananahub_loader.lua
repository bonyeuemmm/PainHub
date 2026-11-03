local ROUTE = getgenv().BH_ROUTE
           or getgenv().__BANANA_SCRIPT_ROUTE
           or "bf_main"

local mt = getrawmetatable(game)
local old_namecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    if method == "HttpGet" then
        local args = {...}
        local url = args[1] or ""
        if url:find("banana%-hub%.xyz") and url:find("hwid") then
            args[1] = url:gsub("hwid=[^&]+", "hwid=2ee6fde30cee4bc6")
            return old_namecall(self, table.unpack(args))
        end
    end
    return old_namecall(self, ...)
end

setreadonly(mt, true)

repeat wait() until game:IsLoaded() and game.Players.LocalPlayer
getgenv().Key = "1d1a8bc57e371c8d0d907a1b"
getgenv().__BANANA_SCRIPT_ROUTE = ROUTE
return loadstring(game:HttpGet("https://banana-hub.xyz/loader/banana.lua"))()
