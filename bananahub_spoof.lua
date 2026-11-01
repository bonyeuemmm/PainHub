-- lang: Lua, target: Delta X
-- spoof HWID ở tầng getter, không đụng request

local StarterGui = game:GetService("StarterGui")

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification",{
            Title="BH-Spoof", Text=msg, Duration=3
        })
    end)
end

-- ────────────────────────────────────────────
-- HWID cố định
-- ────────────────────────────────────────────
local read_fn  = readfile  or nil
local write_fn = writefile or nil
local exist_fn = isfile    or nil

local function gen_uuid()
    local rand  = Random.new(0xDEADBEEF)
    local hex   = "0123456789ABCDEF"
    local parts = {8,4,4,4,12}
    local segs  = {}
    for _,len in ipairs(parts) do
        local seg=""
        for _=1,len do
            seg=seg..hex:sub(rand:NextInteger(1,16),rand:NextInteger(1,16))
        end
        table.insert(segs,seg)
    end
    return table.concat(segs,"-")
end

local SPOOF_HWID
if exist_fn and read_fn then
    pcall(function()
        if exist_fn("bh_hwid.txt") then
            SPOOF_HWID=read_fn("bh_hwid.txt"):gsub("%s+","")
        end
    end)
end
if not SPOOF_HWID or #SPOOF_HWID<10 then
    SPOOF_HWID=gen_uuid()
    if write_fn then pcall(write_fn,"bh_hwid.txt",SPOOF_HWID) end
end

notify("HWID: "..SPOOF_HWID:sub(1,8).."...")

-- ────────────────────────────────────────────
-- OVERRIDE HWID GETTERS — trước khi script đọc
-- ────────────────────────────────────────────

-- set global phổ biến
getgenv().HWID        = SPOOF_HWID
getgenv().hwid        = SPOOF_HWID
getgenv().HardwareID  = SPOOF_HWID
getgenv().hardware_id = SPOOF_HWID

-- syn
if syn then
    pcall(function()
        if syn.get_hwid then
            syn.get_hwid = function() return SPOOF_HWID end
        end
    end)
end

-- hookfunction nếu executor hỗ trợ
if hookfunction then
    -- hook hàm get_hwid nếu tồn tại global
    if get_hwid then
        pcall(function()
            hookfunction(get_hwid, function() return SPOOF_HWID end)
        end)
    end
end

-- replaceclosure nếu có
if replaceclosure then
    if get_hwid then
        pcall(function()
            replaceclosure(get_hwid, function() return SPOOF_HWID end)
        end)
    end
end

notify("Hook OK — loading BH...")

-- ────────────────────────────────────────────
-- LOAD BANANA HUB — không thay đổi gì
-- ────────────────────────────────────────────
repeat wait() until game:IsLoaded() and game.Players.LocalPlayer
getgenv().Key=""
getgenv().__BANANA_SCRIPT_ROUTE="bf_main"
loadstring(game:HttpGet("https://banana-hub.xyz/loader/banana.lua"))()
