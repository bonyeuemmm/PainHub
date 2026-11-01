-- lang: Lua, target: Delta X / Roblox executor
-- HWID spoof cho banana-hub.xyz — fail-safe, không block request

local HttpService = game:GetService("HttpService")
local StarterGui  = game:GetService("StarterGui")

local function notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{
            Title=title, Text=msg, Duration=dur or 4
        })
    end)
end

-- ────────────────────────────────────────────
-- CONFIG
-- ────────────────────────────────────────────
local TARGET_HOST = "banana%-hub%.xyz"
local HWID_KEYS   = {"hwid","HWID","hardware_id","device_id","hid"}
local HWID_FILE   = "bananahub_hwid.txt"

-- ────────────────────────────────────────────
-- GIỮ REQUEST GỐC TRƯỚC KHI HOOK
-- ────────────────────────────────────────────
local original_request = syn and syn.request
                      or (typeof(request)=="function" and request)
                      or (http and http.request)

if not original_request then
    notify("BH-Spoof ✗","Không có request function",6)
    return
end

-- ────────────────────────────────────────────
-- HWID
-- ────────────────────────────────────────────
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

local read_fn  = readfile  or (syn and syn.readfile)  or nil
local write_fn = writefile or (syn and syn.writefile) or nil
local exist_fn = isfile    or (syn and syn.isfile)    or nil

local SPOOF_HWID
if exist_fn and read_fn then
    pcall(function()
        if exist_fn(HWID_FILE) then
            SPOOF_HWID=read_fn(HWID_FILE):gsub("%s+","")
        end
    end)
end
if not SPOOF_HWID or #SPOOF_HWID<10 then
    SPOOF_HWID=gen_uuid()
    if write_fn then pcall(write_fn,HWID_FILE,SPOOF_HWID) end
end

notify("BH-Spoof","HWID: "..SPOOF_HWID:sub(1,8).."...",3)

-- ────────────────────────────────────────────
-- PATCH — chỉ sửa nếu target, lỗi thì bỏ qua
-- ────────────────────────────────────────────
local function try_patch(opts)
    local url = opts.Url or opts.url or ""
    if not url:find(TARGET_HOST) then return end

    -- patch URL
    for _,k in ipairs(HWID_KEYS) do
        url=url:gsub("([?&])("..k.."=)([^&]+)",function(sep,key)
            return sep..key..SPOOF_HWID
        end)
    end
    if opts.Url then opts.Url=url else opts.url=url end

    -- patch body
    local body=opts.Body or opts.body
    if body and type(body)=="string" and #body>0 then
        local ct=(opts.Headers and(
            opts.Headers["Content-Type"] or
            opts.Headers["content-type"]
        )) or ""
        if ct:find("application/json") or body:sub(1,1)=="{" then
            local ok,tbl=pcall(HttpService.JSONDecode,HttpService,body)
            if ok then
                local changed=false
                for _,k in ipairs(HWID_KEYS) do
                    if tbl[k] then tbl[k]=SPOOF_HWID;changed=true end
                end
                if changed then
                    local nb=pcall(function()
                        return HttpService:JSONEncode(tbl)
                    end)
                    if nb then
                        if opts.Body then opts.Body=nb else opts.body=nb end
                    end
                end
            end
        else
            for _,k in ipairs(HWID_KEYS) do
                body=body:gsub("([&^]?)("..k.."=)([^&]+)",function(sep,key)
                    return sep..key..SPOOF_HWID
                end)
            end
            if opts.Body then opts.Body=body else opts.body=body end
        end
    end
end

-- ────────────────────────────────────────────
-- HOOK — luôn gọi original_request dù patch có lỗi
-- ────────────────────────────────────────────
local function hooked_request(opts)
    -- patch trong pcall riêng — lỗi không ảnh hưởng request
    pcall(try_patch, opts)
    -- luôn gọi request gốc
    return original_request(opts)
end

-- ────────────────────────────────────────────
-- INSTALL
-- ────────────────────────────────────────────
local hooked=false
if syn then
    pcall(function() syn.request=hooked_request;hooked=true end)
end
if not hooked then
    pcall(function() request=hooked_request;hooked=true end)
end
if not hooked then
    pcall(function()
        local env=getfenv(0)
        if env and env.request then
            rawset(env,"request",hooked_request);hooked=true
        end
    end)
end

notify("BH-Spoof "..(hooked and "✓" or "⚠"),
       hooked and "Hook OK" or "Hook thất bại — vẫn load BH",3)

-- ────────────────────────────────────────────
-- LOAD BANANA HUB — script gốc
-- ────────────────────────────────────────────
repeat wait() until game:IsLoaded() and game.Players.LocalPlayer
getgenv().Key=""
getgenv().__BANANA_SCRIPT_ROUTE="bf_main"
loadstring(game:HttpGet("https://banana-hub.xyz/loader/banana.lua"))()
