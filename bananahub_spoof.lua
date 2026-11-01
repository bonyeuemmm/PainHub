-- lang: Lua, target: Delta X
-- HWID + Key cố định, không hook request, không freeze

local StarterGui = game:GetService("StarterGui")

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification",{
            Title="BH-Spoof", Text=msg, Duration=3
        })
    end)
end

-- ────────────────────────────────────────────
-- HWID + KEY CỐ ĐỊNH
-- ────────────────────────────────────────────
local SPOOF_HWID = "2ee6fde30cee4bc6"
local SPOOF_KEY  = "1d1a8bc57e371c8d0d907a1b"

-- set toàn bộ global trước khi script đọc
getgenv().HWID        = SPOOF_HWID
getgenv().hwid        = SPOOF_HWID
getgenv().HardwareID  = SPOOF_HWID
getgenv().hardware_id = SPOOF_HWID
getgenv().Key         = SPOOF_KEY

-- override syn nếu có
if syn then
    pcall(function()
        if syn.get_hwid then
            syn.get_hwid = function() return SPOOF_HWID end
        end
    end)
end

-- hookfunction nếu Delta X hỗ trợ
if hookfunction and get_hwid then
    pcall(function()
        hookfunction(get_hwid, function() return SPOOF_HWID end)
    end)
end

notify("HWID + Key đã set")

-- ────────────────────────────────────────────
-- PATCH TRONG SOURCE
-- ────────────────────────────────────────────
repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

local source
pcall(function()
    source = game:HttpGet("https://banana-hub.xyz/loader/banana.lua")
end)

if not source or #source < 10 then
    notify("Tải thất bại")
    return
end

-- patch HWID và key thẳng trong source
local patched = source
patched = patched:gsub('syn%.get_hwid%(%)',       '"'..SPOOF_HWID..'"')
patched = patched:gsub('get_hwid%(%)',            '"'..SPOOF_HWID..'"')
patched = patched:gsub('(local%s+hwid%s*=%s*)[%w_%.%(%)]+',    '%1"'..SPOOF_HWID..'"')
patched = patched:gsub('(local%s+HWID%s*=%s*)[%w_%.%(%)]+',    '%1"'..SPOOF_HWID..'"')
patched = patched:gsub('(local%s+hid%s*=%s*)[%w_%.%(%)]+',     '%1"'..SPOOF_HWID..'"')
patched = patched:gsub('(local%s+key%s*=%s*)[%w_%.%(%)%[%]"\']+', '%1"'..SPOOF_KEY..'"')
patched = patched:gsub('(local%s+Key%s*=%s*)[%w_%.%(%)%[%]"\']+', '%1"'..SPOOF_KEY..'"')

notify("Đang chạy Banana Hub...")

getgenv().__BANANA_SCRIPT_ROUTE = "bf_main"

local fn, err = loadstring(patched)
if fn then
    fn()
else
    -- fallback chạy gốc với global đã set sẵn
    loadstring(source)()
end
