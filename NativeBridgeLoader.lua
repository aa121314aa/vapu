-- Optional bridge entry point. It starts the upstream Vape runtime, then this repo's UI.
-- This file downloads and executes remote Lua; only run it if you trust both repositories.
-- The upstream runtime is a dependency, not a local copy of its implementation.
local original = "https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua"
local ours = "https://raw.githubusercontent.com/aa121314aa/vapu/main/Main.lua"
local waitSeconds = 15

local function getNative()
    local current = type(shared) == "table" and shared.vape or nil
    if type(current) == "table" and type(current.Modules) == "table" then
        return current
    end
    return nil
end

local function runRemote(url)
    assert(type(loadstring) == "function", "loadstring is unavailable in this environment")
    local source = game:HttpGet(url)
    assert(type(source) == "string" and source ~= "", "empty response from " .. url)
    local fn, compileError = loadstring(source)
    assert(type(fn) == "function", compileError or "remote source did not compile")
    return fn()
end

local native = getNative()
if not native then
    local ok, err = pcall(function()
        runRemote(original)
    end)
    if not ok then
        warn("[Vapu] Original runtime failed to start: " .. tostring(err))
    end

    -- The upstream entry may initialize shared.vape asynchronously.
    for _ = 1, waitSeconds * 10 do
        native = getNative()
        if native then break end
        task.wait(0.1)
    end
    native = native or getNative()
end

local sharedEnv = type(shared) == "table" and shared or nil
if native then
    -- Keep the upstream HUD/overlays active but hide its ClickGui panel.
    local root = native.gui and native.gui:FindFirstChild("ScaledGui")
    local click = root and root:FindFirstChild("ClickGui")
    if sharedEnv and sharedEnv.__VapuClickConnection then
        pcall(function() sharedEnv.__VapuClickConnection:Disconnect() end)
        sharedEnv.__VapuClickConnection = nil
    end
    if click and sharedEnv then
        click.Visible = false
        sharedEnv.__VapuClickConnection = click:GetPropertyChangedSignal("Visible"):Connect(function()
            if click.Parent and click.Visible then
                click.Visible = false
            end
        end)
    end
else
    warn("[Vapu] Native runtime unavailable after waiting; Blatant/Overlay toggles will stay blocked.")
end

-- Load the UI even if the native runtime did not start; its bridge-only toggles fail closed.
return runRemote(ours)
