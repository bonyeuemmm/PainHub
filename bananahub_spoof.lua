-- lang: Lua, target: Delta X / Roblox executor
-- script load từ GitHub raw, HWID spoof trước khi hit banana-hub.xyz

local HttpService = game:GetService("HttpService")
local StarterGui  = game:GetService("StarterGui")

local function notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = msg, Duration = dur or 5
        })
    end)
    task.wait(0.3)
end

-- ────────────────────────────────────────────
-- CONFIG
-- ────────────────────────────────────────────
local TARGET_HOST = "banana%-hub%.xyz"
local HWID_KEYS   = {"hwid", "HWID", "hardware_id", "device_id", "hid"}
local HWID_FILE   = "bananahub_hwid.txt"

-- URL thật của script (thử theo thứ tự)
local SCRIPT_URLS = {
    "https://raw.githubusercontent.com/Nghia11n/Banana-Hub/main/bananahub.lua",
    "https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua",
    "https://raw.githubusercontent.com/kimprobloxdz/Banana-Free/refs/heads/main/Protected_5609200582002947.lua.txt",
}

-- ────────────────────────────────────────────
-- EXECUTOR COMPAT
-- ────────────────────────────────────────────
local req_fn = (syn and syn.request)
            or (typeof(request) == "function" and request)
            or (http and http.request)

local read_fn  = readfile  or (syn and syn.readfile)  or nil
local write_fn = writefile or (syn and syn.writefile) or nil
local exist_fn = isfile    or (syn and syn.isfile)    or nil

if not req_fn then
    notify("BH-Spoof ✗", "Không có hàm request", 6)
    return
end

-- ────────────────────────────────────────────
-- SPOOFED HWID
-- ────────────────────────────────────────────
local function gen_uuid()
    local rand  = Random.new(0xDEADBEEF)
    local hex   = "0123456789ABCDEF"
    local parts = {8,4,4,4,12}
    local segs  = {}
    for _, len in ipairs(parts) do
        local seg = ""
        for _ = 1, len do
            seg = seg .. hex:sub(rand:NextInteger(1,16), rand:NextInteger(1,16))
        end
        table.insert(segs, seg)
    end
    return table.concat(segs, "-")
end

local SPOOF_HWID
if exist_fn and read_fn then
    pcall(function()
        if exist_fn(HWID_FILE) then
            SPOOF_HWID = read_fn(HWID_FILE):gsub("%s+","")
        end
    end)
end
if not SPOOF_HWID or #SPOOF_HWID < 10 then
    SPOOF_HWID = gen_uuid()
    if write_fn then pcall(write_fn, HWID_FILE, SPOOF_HWID) end
end

local REAL_HWID = "UNKNOWN"
pcall(function()
    if typeof(HWID) == "string" then REAL_HWID = HWID end
end)

notify("BH-Spoof", "HWID: " .. SPOOF_HWID:sub(1,8) .. "...", 4)

-- ────────────────────────────────────────────
-- PATCH HELPERS
-- ────────────────────────────────────────────
local function patch_url(url)
    for _, k in ipairs(HWID_KEYS) do
        url = url:gsub("([?&])(" .. k .. "=)([^&]+)", function(sep, key)
            return sep .. key .. SPOOF_HWID
        end)
    end
    if REAL_HWID ~= "UNKNOWN" then
        url = url:gsub(REAL_HWID, SPOOF_HWID)
    end
    return url
end

local function patch_body(body, ct)
    if not body or type(body) ~= "string" or #body == 0 then return body end
    if (ct and ct:find("application/json")) or body:sub(1,1) == "{" then
        local ok, tbl = pcall(HttpService.JSONDecode, HttpService, body)
        if ok then
            local changed = false
            for _, k in ipairs(HWID_KEYS) do
                if tbl[k] then tbl[k] = SPOOF_HWID; changed = true end
            end
            if REAL_HWID ~= "UNKNOWN" then
                for k, v in pairs(tbl) do
                    if type(v)=="string" and v==REAL_HWID then
                        tbl[k]=SPOOF_HWID; changed=true
                    end
                end
            end
            if changed then return HttpService:JSONEncode(tbl) end
        end
    else
        for _, k in ipairs(HWID_KEYS) do
            body = body:gsub("([&^]?)(" .. k .. "=)([^&]+)", function(sep, key)
                return sep .. key .. SPOOF_HWID
            end)
        end
        if REAL_HWID ~= "UNKNOWN" then
            body = body:gsub(REAL_HWID, SPOOF_HWID)
        end
    end
    return body
end

-- ────────────────────────────────────────────
-- REQUEST HOOK
-- ────────────────────────────────────────────
local function hooked_request(opts)
    pcall(function()
        local url = opts.Url or opts.url or ""
        if not url:find(TARGET_HOST) then return end
        local nu = patch_url(url)
        if opts.Url then opts.Url=nu else opts.url=nu end
        local ct = opts.Headers and (opts.Headers["Content-Type"] or opts.Headers["content-type"])
        local nb = patch_body(opts.Body or opts.body, ct)
        if opts.Body then opts.Body=nb else opts.body=nb end
        if opts.Headers and REAL_HWID ~= "UNKNOWN" then
            for hk,hv in pairs(opts.Headers) do
                if type(hv)=="string" and hv:find(REAL_HWID) then
                    opts.Headers[hk]=hv:gsub(REAL_HWID,SPOOF_HWID)
                end
            end
        end
    end)
    return req_fn(opts)
end

-- ────────────────────────────────────────────
-- INSTALL HOOK
-- ────────────────────────────────────────────
local hooked = false
if syn then
    pcall(function() syn.request=hooked_request; hooked=true end)
end
if not hooked then
    pcall(function() request=hooked_request; hooked=true end)
end
if not hooked then
    pcall(function()
        local env=getfenv(0)
        if env and env.request then rawset(env,"request",hooked_request); hooked=true end
    end)
end

if hooked then
    notify("BH-Spoof ✓", "Hook OK", 3)
else
    notify("BH-Spoof ⚠", "Hook không cài được", 4)
end

-- ────────────────────────────────────────────
-- LOAD SCRIPT — thử từng URL
-- ────────────────────────────────────────────
task.wait(1)
notify("BH-Spoof", "Đang tìm script...", 3)

local loaded = false
for _, url in ipairs(SCRIPT_URLS) do
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and res and #res > 50 and not res:find("404") and not res:find("<html") then
        local fn, lerr = loadstring(res)
        if fn then
            notify("BH-Spoof ✓", "Load OK — đang chạy...", 4)
            task.wait(0.5)
            pcall(fn)
            loaded = true
            break
        else
            notify("Parse ✗", tostring(lerr):sub(1,60), 5)
        end
    end
end

if not loaded then
    notify("BH-Spoof ✗", "Không load được — script có thể đã đổi URL", 7)
end
