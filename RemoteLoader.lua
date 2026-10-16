-- Convenience entry for the remote bridge. This downloads and executes remote Lua.
-- Review the linked sources and run only if you trust them.
local bridgeUrl = "https://raw.githubusercontent.com/aa121314aa/vapu/main/NativeBridgeLoader.lua"
local source = game:HttpGet(bridgeUrl)
assert(type(source) == "string" and source ~= "", "empty response from " .. bridgeUrl)
local fn, compileError = loadstring(source)
assert(type(fn) == "function", compileError or "bridge source did not compile")
return fn()
