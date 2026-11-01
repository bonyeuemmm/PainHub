-- lang: Lua, target: Roblox executor (Synapse X / KRNL / Fluxus / Celery)
-- endpoint: banana-hub.xyz
-- method: request hook → intercept → HWID swap before transmission

local HttpService = game:GetService("HttpService")

-- ────────────────────────────────────────────
-- CONFIG
-- ────────────────────────────────────────────
local HWID_FILE    = "bananahub_hwid.txt"
local TARGET_HOST  = "banana%-hub%.xyz"
local HWID_KEYS    = {"hwid", "HWID", "hardware_id", "device_id", "hid"}

-- ────────────────────────────────────────────
-- EXECUTOR COMPAT
-- ────────────────────────────────────────────
local req_fn  = syn and syn.request
             or (request ~= nil and request)
             or (http  and http.request)

local read_fn  = readfile  or (syn and syn.readfile)
local write_fn = writefile or (syn and syn.writefile)
local exist_fn = isfile    or (syn and syn.isfile)

assert(req_fn,   "[BH-Spoof] no HTTP request function found — check executor")
assert(write_fn, "[BH-Spoof] no writefile — executor too restricted")

-- ────────────────────────────────────────────
-- REAL HWID
-- ────────────────────────────────────────────
local function get_real_hwid()
    if syn and syn.crypto and syn.crypto.hash then
        return tostring(syn.crypto.hash("sha256", tostring(os.time()):sub(1,8)))
    end
    if typeof(HWID) == "string" then return HWID end
    if getexecutorname and getexecutorname():lower():find("flux") then
        return fluxus and fluxus.get_hwid and fluxus.get_hwid() or "UNKNOWN"
    end
    return "UNKNOWN"
end

-- ────────────────────────────────────────────
-- PERSISTENT SPOOFED HWID
-- ────────────────────────────────────────────
local function gen_uuid()
    local SEED   = 0xDEADBEEF
    local rand   = Random.new(SEED)
    local hex    = "0123456789ABCDEF"
    local parts  = {8, 4, 4, 4, 12}
    local segs   = {}
    for _, len in ipairs(parts) do
        local seg = ""
        for _ = 1, len do
            seg = seg .. hex:sub(rand:NextInteger(1, 16), rand:NextInteger(1, 16))
        end
        table.insert(segs, seg)
    end
    return table.concat(segs, "-")
end

local SPOOF_HWID
do
    local ok = pcall(function()
        if exist_fn(HWID_FILE) then
            SPOOF_HWID = read_fn(HWID_FILE):gsub("%s+", "")
        end
    end)
    if not SPOOF_HWID or #SPOOF_HWID < 10 then
        SPOOF_HWID = gen_uuid()
        pcall(write_fn, HWID_FILE, SPOOF_HWID)
        print("[BH-Spoof] new HWID generated → " .. SPOOF_HWID)
    else
        print("[BH-Spoof] loaded stored HWID → " .. SPOOF_HWID)
    end
end

local REAL_HWID = get_real_hwid()
print("[BH-Spoof] real HWID masked: " .. tostring(REAL_HWID):sub(1,8) .. "...")

-- ────────────────────────────────────────────
-- PATCH HELPERS
-- ────────────────────────────────────────────
local function patch_url(url)
    for _, k in ipairs(HWID_KEYS) do
        local pattern = "([?&])(" .. k .. "=)([^&]+)"
        if url:match(pattern) then
            url = url:gsub(pattern, function(sep, key, val)
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
        if tbl[k] then
            tbl[k]  = SPOOF_HWID
            changed = true
        end
    end
    if REAL_HWID ~= "UNKNOWN" then
        for k, v in pairs(tbl) do
            if type(v) == "string" and v == REAL_HWID then
                tbl[k]  = SPOOF_HWID
                changed = true
            end
        end
    end
    return changed and HttpService:JSONEncode(tbl) or body
end

local function patch_form_body(body)
    for _, k in ipairs(HWID_KEYS) do
        local pattern = "([&^]?)(" .. k .. "=)([^&]+)"
        if body:match(pattern) then
            body = body:gsub(pattern, function(sep, key, val)
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
    local url = opts.Url or opts.url or ""

    if url:find(TARGET_HOST) then
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
    end

    return req_fn(opts)
end

-- ────────────────────────────────────────────
-- INSTALL HOOK
-- ────────────────────────────────────────────
if syn then
    syn.request = hooked_request
elseif request then
    local ok = pcall(function() request = hooked_request end)
    if not ok then
        local env = getfenv(0)
        if env and env.request then
            pcall(function()
                rawset(env, "request", hooked_request)
            end)
        end
    end
end

print("[BH-Spoof] hook installed — HWID locked to " .. SPOOF_HWID)
print("[BH-Spoof] paste hoặc loadstring Banana Hub script bên dưới dòng này")

-- Bỏ comment dòng dưới nếu muốn tự load Banana Hub luôn sau khi hook cài xong:
loadstring(game:HttpGet("https://banana-hub.xyz/loader.lua"))()
