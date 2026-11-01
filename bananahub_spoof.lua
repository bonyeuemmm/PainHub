-- lang: Lua, target: Delta X / Roblox executor
-- endpoint: banana-hub.xyz
-- notification hiện trong game thay vì log

local HttpService  = game:GetService("HttpService")
local StarterGui   = game:GetService("StarterGui")

-- ────────────────────────────────────────────
-- NOTIFY — hiện thông báo góc màn hình game
-- ────────────────────────────────────────────
local function notify(title, msg, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title or "BH-Spoof",
            Text     = msg   or "",
            Duration = duration or 4,
        })
    end)
end

-- ────────────────────────────────────────────
-- CONFIG
-- ────────────────────────────────────────────
local HWID_FILE   = "bananahub_hwid.txt"
local TARGET_HOST = "banana%-hub%.xyz"
local HWID_KEYS   = {"hwid", "HWID", "hardware_id", "device_id", "hid"}

-- ────────────────────────────────────────────
-- EXECUTOR COMPAT
-- ────────────────────────────────────────────
local req_fn = (syn and syn.request)
            or (typeof(request)  == "function" and request)
            or (http and http.request)

local read_fn  = readfile  or (syn and syn.readfile)  or nil
local write_fn = writefile or (syn and syn.writefile) or nil
local exist_fn = isfile    or (syn and syn.isfile)    or nil

if not req_fn then
    notify("BH-Spoof ✗", "Không tìm thấy hàm request!", 6)
    return
end

-- ────────────────────────────────────────────
-- GEN UUID
-- ────────────────────────────────────────────
local function gen_uuid()
    local SEED  = 0xDEADBEEF
    local rand  = Random.new(SEED)
    local hex   = "0123456789ABCDEF"
    local parts = {8, 4, 4, 4, 12}
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

-- ────────────────────────────────────────────
-- PERSISTENT SPOOFED HWID
-- ────────────────────────────────────────────
local SPOOF_HWID

if exist_fn and read_fn then
    pcall(function()
        if exist_fn(HWID_FILE) then
            SPOOF_HWID = read_fn(HWID_FILE):gsub("%s+", "")
        end
    end)
end

if not SPOOF_HWID or #SPOOF_HWID < 10 then
    SPOOF_HWID = gen_uuid()
    if write_fn then
        pcall(write_fn, HWID_FILE, SPOOF_HWID)
    end
    notify("BH-Spoof", "HWID mới: " .. SPOOF_HWID:sub(1,8) .. "...", 5)
else
    notify("BH-Spoof", "HWID đã lưu: " .. SPOOF_HWID:sub(1,8) .. "...", 5)
end

-- ────────────────────────────────────────────
-- REAL HWID
-- ────────────────────────────────────────────
local REAL_HWID = "UNKNOWN"
pcall(function()
    if syn and syn.crypto and syn.crypto.hash then
        REAL_HWID = tostring(syn.crypto.hash("sha256", tostring(os.time()):sub(1,8)))
    elseif typeof(HWID) == "string" then
        REAL_HWID = HWID
    end
end)

-- ────────────────────────────────────────────
-- PATCH HELPERS
-- ────────────────────────────────────────────
local function patch_url(url)
    for _, k in ipairs(HWID_KEYS) do
        local pattern = "([?&])(" .. k .. "=)([^&]+)"
        if url:match(pattern) then
            url = url:gsub(pattern, function(sep, key)
                return sep .. key .. SPOOF_HWID
            end)
        end
    end
    if REAL_HWID ~= "UNKNOWN" then
        url = url:gsub(REAL_HWID, SPOOF_HWID)
    end
    return url
end

local function patch_json_body(body)
    local ok, tbl = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok then return body end
    local changed = false
    for _, k in ipairs(HWID_KEYS) do
        if tbl[k] then tbl[k] = SPOOF_HWID; changed = true end
    end
    if REAL_HWID ~= "UNKNOWN" then
        for k, v in pairs(tbl) do
            if type(v) == "string" and v == REAL_HWID then
                tbl[k] = SPOOF_HWID; changed = true
            end
        end
    end
    return changed and HttpService:JSONEncode(tbl) or body
end

local function patch_form_body(body)
    for _, k in ipairs(HWID_KEYS) do
        local pattern = "([&^]?)(" .. k .. "=)([^&]+)"
        if body:match(pattern) then
            body = body:gsub(pattern, function(sep, key)
                return sep .. key .. SPOOF_HWID
            end)
        end
    end
    if REAL_HWID ~= "UNKNOWN" then
        body = body:gsub(REAL_HWID, SPOOF_HWID)
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

        local new_url = patch_url(url)
        if opts.Url then opts.Url = new_url else opts.url = new_url end

        local body = opts.Body or opts.body
        if body and type(body) == "string" and #body > 0 then
            local ct = (opts.Headers and (
                opts.Headers["Content-Type"] or
                opts.Headers["content-type"]
            )) or ""
            local new_body
            if ct:find("application/json") or body:sub(1,1) == "{" then
                new_body = patch_json_body(body)
            else
                new_body = patch_form_body(body)
            end
            if opts.Body then opts.Body = new_body else opts.body = new_body end
        end

        if opts.Headers and REAL_HWID ~= "UNKNOWN" then
            for hk, hv in pairs(opts.Headers) do
                if type(hv) == "string" and hv:find(REAL_HWID) then
                    opts.Headers[hk] = hv:gsub(REAL_HWID, SPOOF_HWID)
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
    pcall(function() syn.request = hooked_request; hooked = true end)
end

if not hooked then
    local ok = pcall(function() request = hooked_request; hooked = true end)
    if not ok then
        pcall(function()
            local env = getfenv(0)
            if env and env.request then
                rawset(env, "request", hooked_request)
                hooked = true
            end
        end)
    end
end

-- thông báo kết quả hook
if hooked then
    notify("BH-Spoof ✓", "Hook OK — đang load Banana Hub...", 4)
else
    notify("BH-Spoof ⚠", "Hook thất bại — thử chạy tiếp Banana Hub không spoof", 5)
end

-- ────────────────────────────────────────────
-- LOAD BANANA HUB
-- ────────────────────────────────────────────
task.wait(1) -- chờ notify hiện xong rồi mới load
loadstring(game:HttpGet("https://banana-hub.xyz/loader.lua"))()
