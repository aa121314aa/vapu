-- Vape V4 UI study / standalone visual shell. No gameplay modules, network calls, hooks, or remote firing.
-- Reference: https://github.com/7GrandDadPGN/VapeV4ForRoblox (CC0 1.0).
-- Place this file AND assets/ in the executor filesystem at VapeUIClone/, then run:
-- loadstring(readfile("VapeUIClone/Main.lua"))()
-- In Studio: paste this source into a LocalScript under StarterPlayerScripts (icons fall back to text).

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer
if not localPlayer then error("VapeUIClone requires a client LocalScript") end
local parent = localPlayer:WaitForChild("PlayerGui")
local environment = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then environment = result end
end
if type(environment.__VapeUIClone) == "table" and type(environment.__VapeUIClone.Destroy) == "function" then
    pcall(function() environment.__VapeUIClone:Destroy() end)
end
local existing = parent:FindFirstChild("VapeUIClone")
if existing then existing:Destroy() end

local ui = Instance.new("ScreenGui")
ui.Name = "VapeUIClone"
ui.IgnoreGuiInset = true
ui.ResetOnSpawn = false
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.DisplayOrder = 9000
ui.Parent = parent

local state = {
    accent = Color3.fromHSV(0.46, 0.96, 0.52),
    main = Color3.fromRGB(26, 25, 26),
    text = Color3.fromRGB(200, 200, 200),
    dim = Color3.fromRGB(166, 166, 166),
    windows = {}, modules = {}, connections = {},
    profiles = {default = {}}, profile = "default", lists = {Friends = {}, Targets = {}},
    open = true, scale = 1,
}
local api = {Gui = ui, State = state}

local function make(className, properties, container)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = container
    return object
end
local function corner(obj, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 4)}, obj)
end
local function border(obj)
    return make("UIStroke", {Color = Color3.fromRGB(85, 85, 85), Transparency = 0.8, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, obj)
end
local function line(parentObject, y)
    return make("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.93,
        BorderSizePixel = 0, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 1)}, parentObject)
end
local font = Font.fromEnum(Enum.Font.Arial)
local function label(parentObject, content, x, y, w, h, size, color)
    return make("TextLabel", {BackgroundTransparency = 1, FontFace = font, Text = content,
        TextColor3 = color or state.text, TextSize = size or 14, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h)}, parentObject)
end
local function btn(parentObject, content, x, y, w, h)
    return make("TextButton", {AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = content, TextColor3 = state.dim, TextSize = 14, FontFace = font,
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h)}, parentObject)
end
local function icon(parentObject, name, fallback, x, y, w, h)
    local asset = nil
    local getAsset = getcustomasset or getsynasset
    if type(getAsset) == "function" then
        local ok, result = pcall(getAsset, "VapeUIClone/assets/" .. name .. ".png")
        if ok and type(result) == "string" then asset = result end
    end
    if asset then
        return make("ImageLabel", {BackgroundTransparency = 1, Image = asset,
            ImageColor3 = state.text, Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h)}, parentObject)
    end
    return label(parentObject, fallback or "·", x, y - 2, w + 3, h + 4, 15, state.text)
end
local function tint(obj, color)
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then obj.ImageColor3 = color
    else obj.TextColor3 = color end
end
local function animate(obj, props)
    Tween:Create(obj, TweenInfo.new(0.16, Enum.EasingStyle.Linear), props):Play()
end
local function drag(frame, handle)
    local active, start, initial = false, nil, nil
    table.insert(state.connections, handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        active, start, initial = true, input.Position, frame.Position
    end))
    table.insert(state.connections, UIS.InputChanged:Connect(function(input)
        if not active then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - start
        local sc = math.max(state.scale, 0.1)
        frame.Position = UDim2.new(initial.X.Scale, initial.X.Offset + delta.X / sc,
            initial.Y.Scale, initial.Y.Offset + delta.Y / sc)
    end))
    table.insert(state.connections, UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then active = false end
    end))
end
local scaled = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, ui)
local scale = make("UIScale", {Scale = 1}, scaled)
local userScale = 1
local surface = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, scaled)
local function fit()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local viewport = cam.ViewportSize
    local n = math.clamp(math.min(viewport.X / 1220, viewport.Y / 760), 0.6, 1)
    state.scale = n * userScale
    scale.Scale = state.scale
    surface.Size = UDim2.fromScale(1 / state.scale, 1 / state.scale)
end
fit()
table.insert(state.connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(fit))
if workspace.CurrentCamera then
    table.insert(state.connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
end

local toast = make("TextLabel", {BackgroundColor3 = state.main, BackgroundTransparency = 0.06,
    TextColor3 = state.text, FontFace = font, TextSize = 13, Text = "", Visible = false,
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -20),
    Size = UDim2.fromOffset(310, 38), ZIndex = 50}, surface)
corner(toast)
border(toast)
local toastSequence = 0
local function notify(message)
    toastSequence += 1
    local sequence = toastSequence
    toast.Text = message
    toast.Visible = true
    task.delay(2.8, function() if toastSequence == sequence and toast.Parent then toast.Visible = false end end)
end

local main = make("Frame", {Name = "MainWindow", BackgroundColor3 = state.main,
    Position = UDim2.fromOffset(14, 60), Size = UDim2.fromOffset(220, 485),
    BorderSizePixel = 0}, surface)
corner(main)
border(main)
local mainHeader = btn(main, "", 0, 0, 220, 39)
drag(main, mainHeader)
local brand = icon(main, "vapelogomini", "vape", 12, 11, 55, 16)
if brand:IsA("TextLabel") then brand.TextSize = 21; brand.TextColor3 = Color3.new(1, 1, 1) end
local v4 = icon(main, "v4mini", "v4", 68, 11, 23, 16)
tint(v4, state.accent)
local settingsButton = btn(main, "⚙", 173, 0, 39, 39)
settingsButton.TextSize = 20
settingsButton.TextColor3 = Color3.fromRGB(125, 125, 125)
local closeButton = btn(main, "−", 149, 0, 24, 39)
closeButton.TextSize = 20
closeButton.MouseButton1Click:Connect(function() surface.Visible = false; state.open = false end)

local mainList = make("Frame", {Name = "Navigation", BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 37), Size = UDim2.new(1, 0, 1, -37)}, main)
local mainLayout = make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, mainList)
local categoryData = {
    {"Combat", "combat", "⚔", {"AimAssist", "AutoClicker", "Reach", "SilentAim", "TriggerBot"}},
    {"Blatant", "blatant", "✦", {"AntiFall", "Fly", "HighJump", "HitBoxes", "Invisible", "Jesus", "Killaura", "LongJump", "MouseTP", "Phase", "Speed", "Spider", "SpinBot", "Swim", "TargetStrafe", "Timer"}},
    {"Render", "render", "◉", {"Arrows", "Chams", "ESP", "Fullbright", "GamingChair", "Health", "NameTags", "PlayerModel", "Search", "Tracers", "Waypoints"}},
    {"Utility", "utility", "✧", {"AntiRagdoll", "AutoRejoin", "Blink", "ChatSpammer", "Disabler", "Panic", "Rejoin", "ServerHop", "StaffDetector"}},
    {"World", "world", "◇", {"Anti-AFK", "FastProxPrompt", "Freecam", "Gravity", "Parkour", "SafeWalk", "Wallhop", "Xray"}},
    {"Inventory", "inventory", "▣", {}},
}
local function panel(title, x, y, width, height)
    local frame = make("Frame", {Name = title .. "Panel", BackgroundColor3 = state.main,
        BorderSizePixel = 0, Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height), Visible = false}, surface)
    corner(frame); border(frame)
    local header = btn(frame, "", 0, 0, width, 40)
    drag(frame, header)
    label(frame, title, 34, 0, width - 70, 40, 13)
    line(frame, 40)
    return frame
end
local function scroll(frame, top)
    local view = make("ScrollingFrame", {Name = "Content", BackgroundTransparency = 1,
        BorderSizePixel = 0, Position = UDim2.fromOffset(0, top),
        Size = UDim2.new(1, 0, 1, -top), CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 2, ScrollBarImageColor3 = state.text,
        ScrollBarImageTransparency = 0.7}, frame)
    local layout = make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, view)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        view.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
    end)
    return view, layout
end
local moduleCounter = 0
local function createModule(category, moduleName, content)
    moduleCounter += 1
    local slot = make("Frame", {Name = moduleName .. "Slot", BackgroundTransparency = 1,
        Size = UDim2.fromOffset(220, 40), LayoutOrder = moduleCounter}, content)
    local row = btn(slot, moduleName, 0, 0, 220, 40)
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Text = "   " .. moduleName
    row.TextColor3 = state.dim
    row.BackgroundColor3 = state.main
    row.BackgroundTransparency = 0
    local dots = btn(slot, "⋮", 190, 0, 30, 40)
    dots.TextSize = 19
    local detail = make("Frame", {BackgroundColor3 = Color3.fromRGB(22, 21, 22),
        BorderSizePixel = 0, Position = UDim2.fromOffset(0, 40),
        Size = UDim2.fromOffset(220, 83), Visible = false}, slot)
    local key = btn(detail, "Keybind: None", 12, 8, 195, 30)
    key.TextXAlignment = Enum.TextXAlignment.Left
    local hint = label(detail, "UI preview only · no gameplay effect", 12, 42, 205, 25, 11, state.dim)
    hint.TextTruncate = Enum.TextTruncate.AtEnd
    local module = {Name = moduleName, Category = category, Enabled = false, Expanded = false, Row = row, Slot = slot}
    state.modules[moduleName] = module
    function module:Toggle()
        self.Enabled = not self.Enabled
        animate(row, {BackgroundColor3 = self.Enabled and state.accent or state.main,
            TextColor3 = self.Enabled and Color3.fromRGB(16, 23, 21) or state.dim})
        dots.TextColor3 = self.Enabled and Color3.fromRGB(16, 23, 21) or state.dim
        notify(self.Name .. " · " .. (self.Enabled and "ON (UI only)" or "OFF (UI only)"))
    end
    function module:Expand()
        self.Expanded = not self.Expanded
        detail.Visible = self.Expanded
        slot.Size = UDim2.fromOffset(220, self.Expanded and 123 or 40)
        row.BackgroundColor3 = self.Enabled and state.accent or state.main
        notify(self.Name .. " settings · visual only")
    end
    row.MouseButton1Click:Connect(function() module:Toggle() end)
    row.MouseButton2Click:Connect(function() module:Expand() end)
    dots.MouseButton1Click:Connect(function() module:Expand() end)
    key.MouseButton1Click:Connect(function()
        key.Text = "Keybind: unassigned (demo)"
    end)
    row.MouseEnter:Connect(function() if not module.Enabled then row.BackgroundColor3 = Color3.fromRGB(31, 30, 31) end end)
    row.MouseLeave:Connect(function() if not module.Enabled then row.BackgroundColor3 = state.main end end)
    return module
end
local navIndex = 0
local function navRow(title, iconName, glyph, callback)
    navIndex += 1
    local row = btn(mainList, "   " .. title, 0, 0, 220, 40)
    row.LayoutOrder = navIndex
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextColor3 = state.dim
    row.Text = "       " .. title
    local symbol = icon(row, iconName, glyph, 16, 13, 15, 14)
    tint(symbol, state.dim)
    local arrow = icon(row, "expandarrow", "›", 201, 16, 5, 8)
    tint(arrow, Color3.fromRGB(102, 102, 102))
    row.MouseEnter:Connect(function() row.BackgroundTransparency = 0; row.BackgroundColor3 = Color3.fromRGB(32, 31, 32) end)
    row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)
    row.MouseButton1Click:Connect(function() callback(row, symbol) end)
    return row
end
for index, item in ipairs(categoryData) do
    local name, image, glyph, moduleNames = item[1], item[2], item[3], item[4]
    local screenX = 244 + (index - 1) % 5 * 230
    local screenY = 60 + math.floor((index - 1) / 5) * 190
    local window = panel(name, screenX, screenY, 220, 41)
    window.Name = name .. "Category"
    local ci = icon(window, image, glyph, 12, 13, 15, 14)
    tint(ci, state.text)
    local expand = btn(window, "⌄", 188, 0, 31, 40)
    expand.TextSize = 17
    local list, layout = scroll(window, 41)
    local function resize()
        window.Size = UDim2.fromOffset(220, math.min(41 + layout.AbsoluteContentSize.Y, 601))
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
    local category = {Name = name, Frame = window, Content = list, Layout = layout,
        Expanded = true, Modules = {}}
    state.windows[name] = category
    if #moduleNames == 0 then
        local empty = label(list, "Game-specific modules appear here", 12, 8, 196, 42, 11, state.dim)
        empty.Size = UDim2.fromOffset(196, 56)
    end
    for _, moduleName in ipairs(moduleNames) do
        category.Modules[#category.Modules + 1] = createModule(name, moduleName, list)
    end
    local row
    row = navRow(name, image, glyph, function()
        window.Visible = not window.Visible
        row.TextColor3 = window.Visible and state.accent or state.dim
        if window.Visible and name == "Inventory" then resize() end
    end)
    category.Nav = row
    expand.MouseButton1Click:Connect(function()
        category.Expanded = not category.Expanded
        list.Visible = category.Expanded
        window.Size = UDim2.fromOffset(220, category.Expanded and math.min(41 + layout.AbsoluteContentSize.Y, 601) or 41)
        expand.Text = category.Expanded and "⌄" or "⌃"
    end)
end
local divider = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(220, 26), LayoutOrder = 8}, mainList)
label(divider, "misc", 15, 2, 70, 20, 11, Color3.fromRGB(105, 105, 105))
line(divider, 25)
navIndex = 8

local function createListPanel(name)
    local p = panel(name, 244, 130, 220, 280)
    icon(p, name == "Profiles" and "profiles" or "friends", "◇", 12, 13, 16, 14)
    local input = make("TextBox", {BackgroundColor3 = Color3.fromRGB(37, 36, 37),
        PlaceholderText = name == "Profiles" and "Profile name" or "Roblox username",
        PlaceholderColor3 = state.dim, Text = "", TextColor3 = state.text, FontFace = font,
        TextSize = 12, ClearTextOnFocus = false, Position = UDim2.fromOffset(9, 49),
        Size = UDim2.fromOffset(155, 28)}, p)
    corner(input, 3)
    local plus = btn(p, "+", 169, 49, 40, 28)
    plus.BackgroundTransparency = 0; plus.BackgroundColor3 = Color3.fromRGB(37, 36, 37)
    corner(plus, 3)
    local list, _ = scroll(p, 84)
    local function refresh()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local items = name == "Profiles" and state.profiles or state.lists[name]
        for textValue in pairs(items) do
            local cell = btn(list, "  " .. textValue .. (name == "Profiles" and state.profile == textValue and "   ✓" or ""), 0, 0, 220, 35)
            cell.TextXAlignment = Enum.TextXAlignment.Left
            cell.LayoutOrder = 2
            cell.MouseButton1Click:Connect(function()
                if name == "Profiles" then
                    state.profile = textValue; notify("Profile " .. textValue .. " · UI settings only")
                    refresh()
                else
                    notify(textValue .. " · local list only")
                end
            end)
            cell.MouseButton2Click:Connect(function()
                if name ~= "Profiles" or textValue ~= "default" then items[textValue] = nil; refresh() end
            end)
        end
    end
    plus.MouseButton1Click:Connect(function()
        local value = input.Text:match("^%s*(.-)%s*$")
        if value == "" then return end
        if name == "Profiles" then state.profiles[value] = state.profiles[value] or {}
        else state.lists[name][value] = true end
        input.Text = ""; refresh(); notify(value .. " added · visual list")
    end)
    refresh()
    return p
end
for _, listName in ipairs({"Friends", "Profiles", "Targets"}) do
    local p = createListPanel(listName)
    local row
    row = navRow(listName, listName == "Profiles" and "profiles" or "friends", "♧", function()
        p.Visible = not p.Visible
        row.TextColor3 = p.Visible and state.accent or state.dim
    end)
end

local overlayBar = make("Frame", {BackgroundColor3 = state.main, Size = UDim2.fromOffset(220, 38), LayoutOrder = 13}, mainList)
line(overlayBar, 0)
label(overlayBar, "Overlays", 16, 0, 130, 38, 12, state.dim)
local overlayBtn = btn(overlayBar, "▧", 176, 0, 44, 38)
overlayBtn.TextSize = 19
local overlayPanel = panel("Overlays", 244, 60, 220, 242)
local overlayList = scroll(overlayPanel, 41)
for _, moduleName in ipairs({"TextGUI", "TargetInfo", "Radar", "SessionInfo", "Spotify"}) do
    createModule("Overlays", moduleName, overlayList)
end
overlayBtn.MouseButton1Click:Connect(function() overlayPanel.Visible = not overlayPanel.Visible end)
mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    main.Size = UDim2.fromOffset(220, 40 + mainLayout.AbsoluteContentSize.Y)
end)
main.Size = UDim2.fromOffset(220, 40 + mainLayout.AbsoluteContentSize.Y)

-- Search, inspired by the original floating search box and Legit switch.
local search = make("Frame", {BackgroundColor3 = Color3.fromRGB(22, 21, 22),
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 13),
    Size = UDim2.fromOffset(220, 37)}, surface)
corner(search); border(search)
local legit = btn(search, "◉", 8, 0, 35, 37)
legit.TextColor3 = state.accent
make("Frame", {BackgroundColor3 = Color3.fromRGB(68, 68, 68), BorderSizePixel = 0,
    Position = UDim2.fromOffset(43, 12), Size = UDim2.fromOffset(2, 13)}, search)
local searchText = make("TextBox", {BackgroundTransparency = 1, Text = "",
    PlaceholderText = "Search modules...", PlaceholderColor3 = Color3.fromRGB(106, 106, 106),
    ClearTextOnFocus = false, TextColor3 = state.text, FontFace = font, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(51, 0),
    Size = UDim2.fromOffset(139, 37)}, search)
local si = icon(search, "search", "⌕", 197, 12, 14, 14)
tint(si, Color3.fromRGB(114, 114, 114))
local result = make("ScrollingFrame", {BackgroundColor3 = Color3.fromRGB(22, 21, 22),
    BorderSizePixel = 0, Position = UDim2.fromOffset(0, 36), Size = UDim2.fromOffset(220, 0),
    CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 2,
    Visible = false}, search)
corner(result); border(result)
local resultLayout = make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, result)
resultLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    result.CanvasSize = UDim2.fromOffset(0, resultLayout.AbsoluteContentSize.Y)
    result.Size = UDim2.fromOffset(220, math.min(resultLayout.AbsoluteContentSize.Y, 270))
end)
local function updateSearch()
    for _, child in ipairs(result:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local query = string.lower(searchText.Text)
    result.Visible = query ~= ""
    if query == "" then return end
    local matches = {}
    for _, module in pairs(state.modules) do
        if string.find(string.lower(module.Name), query, 1, true) then matches[#matches + 1] = module end
    end
    table.sort(matches, function(a, b) return a.Name < b.Name end)
    for _, module in ipairs(matches) do
        local entry = btn(result, "  " .. module.Name .. "  · " .. module.Category, 0, 0, 220, 33)
        entry.TextXAlignment = Enum.TextXAlignment.Left
        entry.TextSize = 12
        entry.MouseButton1Click:Connect(function()
            local cat = state.windows[module.Category]
            if cat then
                cat.Frame.Visible = true; cat.Content.Visible = true
                cat.Expanded = true
                cat.Frame.Size = UDim2.fromOffset(220, math.min(41 + cat.Layout.AbsoluteContentSize.Y, 601))
                if cat.Nav then cat.Nav.TextColor3 = state.accent end
            elseif module.Category == "Overlays" then overlayPanel.Visible = true end
            module:Toggle()
        end)
    end
    if #matches == 0 then
        local none = btn(result, "  No matching modules", 0, 0, 220, 33)
        none.TextXAlignment = Enum.TextXAlignment.Left
    end
end
searchText:GetPropertyChangedSignal("Text"):Connect(updateSearch)
local legitPanel = panel("Legit", 476, 60, 220, 250)
local legitList = scroll(legitPanel, 41)
for _, moduleName in ipairs({"Atmosphere", "Breadcrumbs", "Cape", "ChinaHat", "Clock", "FOV", "FPS", "Keystrokes", "Memory", "Ping", "Speedmeter", "TimeChanger"}) do
    createModule("Legit", moduleName, legitList)
end
legit.MouseButton1Click:Connect(function()
    legitPanel.Visible = not legitPanel.Visible
    legit.TextColor3 = legitPanel.Visible and state.accent or state.text
end)

-- General settings drawer: local display settings only.
local settingsPanel = panel("Settings", 244, 60, 240, 392)
local settingsIcon = icon(settingsPanel, "settings", "⚙", 13, 13, 14, 14)
tint(settingsIcon, state.text)
local hideSettings = btn(settingsPanel, "×", 202, 0, 36, 40)
hideSettings.TextSize = 20
hideSettings.MouseButton1Click:Connect(function() settingsPanel.Visible = false end)
settingsButton.MouseButton1Click:Connect(function() settingsPanel.Visible = not settingsPanel.Visible end)
label(settingsPanel, "GENERAL", 13, 52, 210, 24, 11, Color3.fromRGB(119, 119, 119))
line(settingsPanel, 79)
label(settingsPanel, "Rebind GUI", 13, 89, 150, 27, 13)
label(settingsPanel, "RightShift", 143, 89, 80, 27, 12, state.dim)
label(settingsPanel, "GUI Theme", 13, 132, 165, 24, 13)
local colorSwatches = {}
for i, c in ipairs({
    Color3.fromHSV(0.46, 0.96, 0.52), Color3.fromRGB(80, 156, 231),
    Color3.fromRGB(172, 109, 212), Color3.fromRGB(231, 111, 145),
    Color3.fromRGB(227, 169, 76), Color3.fromRGB(238, 238, 238)
}) do
    local swatch = btn(settingsPanel, "", 13 + (i - 1) * 36, 168, 27, 27)
    swatch.BackgroundTransparency = 0; swatch.BackgroundColor3 = c
    corner(swatch, 4)
    colorSwatches[#colorSwatches + 1] = swatch
    swatch.MouseButton1Click:Connect(function()
        state.accent = c; tint(v4, c); legit.TextColor3 = c
        for _, category in pairs(state.windows) do
            if category.Nav and category.Frame.Visible then category.Nav.TextColor3 = c end
        end
        for _, module in pairs(state.modules) do
            if module.Enabled then module.Row.BackgroundColor3 = c end
        end
        notify("GUI theme updated")
    end)
end
line(settingsPanel, 212)
label(settingsPanel, "GUI Scale", 13, 223, 164, 25, 13)
local scaleLabel = label(settingsPanel, "100%", 170, 223, 55, 25, 12, state.dim)
local down = btn(settingsPanel, "−", 135, 259, 35, 30)
local up = btn(settingsPanel, "+", 179, 259, 35, 30)
for _, control in ipairs({down, up}) do
    control.BackgroundTransparency = 0; control.BackgroundColor3 = Color3.fromRGB(37, 36, 37)
    corner(control, 3)
end
local function updateScale(n)
    userScale = math.clamp(n, 0.7, 1.2)
    fit()
    surface.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
    scaleLabel.Text = tostring(math.floor(userScale * 100)) .. "%"
end
down.MouseButton1Click:Connect(function() updateScale(userScale - 0.1) end)
up.MouseButton1Click:Connect(function() updateScale(userScale + 0.1) end)
line(settingsPanel, 303)
label(settingsPanel, "UI DEMO ONLY", 13, 315, 190, 23, 11, state.accent)
label(settingsPanel, "Modules change their visual state only.", 13, 340, 217, 24, 11, state.dim)

function api:CreateModule(categoryName, name)
    local category = state.windows[categoryName]
    if not category then return nil, "unknown category" end
    return createModule(categoryName, name, category.Content)
end
function api:SetVisible(visible)
    state.open = not not visible
    surface.Visible = state.open
end
function api:Destroy()
    for _, connection in ipairs(state.connections) do connection:Disconnect() end
    ui:Destroy()
    if environment.__VapeUIClone == self then environment.__VapeUIClone = nil end
end
local shortcut = UIS.InputBegan:Connect(function(input, processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.RightShift then api:SetVisible(not state.open) end
end)
table.insert(state.connections, shortcut)
environment.__VapeUIClone = api

-- Preview two categories while keeping other windows closed; no module is enabled by default.
state.windows.Combat.Frame.Visible = true
state.windows.Blatant.Frame.Visible = true
state.windows.Combat.Nav.TextColor3 = state.accent
state.windows.Blatant.Nav.TextColor3 = state.accent
notify("Vape V4 UI study loaded · visual-only shell")
return api
