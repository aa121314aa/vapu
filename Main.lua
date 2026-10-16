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
    language = "en", translated = {}, languageObservers = {},
}
-- Only the UI is translated; stable English category/module IDs remain unchanged.
local zh = {
    Combat = "战斗", Blatant = "暴力", Render = "渲染", Utility = "实用",
    World = "世界", Inventory = "背包", Friends = "好友", Profiles = "配置",
    Targets = "目标", Overlays = "悬浮窗", Legit = "常规", Settings = "设置",
    AimAssist = "辅助瞄准", AutoClicker = "自动点击", Reach = "攻击距离",
    SilentAim = "静默瞄准", TriggerBot = "自动扳机", AntiFall = "防坠落",
    Fly = "飞行", HighJump = "高跳", HitBoxes = "碰撞箱", Invisible = "隐身",
    Jesus = "水上行走", Killaura = "杀戮光环", LongJump = "远跳",
    MouseTP = "鼠标传送", Phase = "穿墙", Speed = "加速", Spider = "爬墙",
    SpinBot = "旋转", Swim = "游泳", TargetStrafe = "绕目标移动",
    Timer = "时间倍率", Arrows = "方向箭头", Chams = "实体着色",
    ESP = "透视标记", Fullbright = "全亮", GamingChair = "电竞椅",
    Health = "生命值", NameTags = "姓名标签", PlayerModel = "玩家模型",
    Search = "查找", Tracers = "追踪线", Waypoints = "路径点",
    AntiRagdoll = "防布娃娃", AutoRejoin = "自动重进", Blink = "瞬移缓存",
    ChatSpammer = "聊天刷屏", Disabler = "限制绕过", Panic = "紧急关闭",
    Rejoin = "重新加入", ServerHop = "切换服务器", StaffDetector = "管理检测",
    ['Anti-AFK'] = "防挂机", FastProxPrompt = "快速交互", Freecam = "自由镜头",
    Gravity = "重力", Parkour = "跑酷", SafeWalk = "安全行走",
    Wallhop = "贴墙跳", Xray = "方块透视", TextGUI = "文字悬浮",
    TargetInfo = "目标信息", Radar = "雷达", SessionInfo = "会话信息",
    Spotify = "音乐信息", Atmosphere = "环境氛围", Breadcrumbs = "行走轨迹",
    Cape = "披风", ChinaHat = "斗笠", Clock = "时钟", FOV = "视野",
    FPS = "帧率", Keystrokes = "按键显示", Memory = "内存", Ping = "延迟",
    Speedmeter = "速度表", TimeChanger = "时间调整",
    ['Game-specific modules appear here'] = "游戏专属模块将在此显示",
    ['Keybind: None'] = "快捷键：无", ['Keybind: unassigned (demo)'] = "快捷键：未设置（演示）",
    ['UI preview only · no gameplay effect'] = "仅界面演示 · 不影响游戏",
    ['Profile name'] = "配置名称", ['Roblox username'] = "Roblox 用户名",
    ['Search modules...'] = "搜索模块…", ['No matching modules'] = "没有匹配的模块",
    GENERAL = "通用设置", ['Rebind GUI'] = "界面热键", ['GUI Theme'] = "界面主题",
    ['GUI Scale'] = "界面缩放", ['Language'] = "语言", misc = "其他",
    ['UI DEMO ONLY'] = "仅界面演示", ['Modules change their visual state only.'] = "模块开关仅改变界面状态。",
}
local function translate(key)
    return state.language == "zh-CN" and (zh[key] or key) or key
end
local function bindText(object, key, prefix, property)
    local prop = property or "Text"
    local function update()
        if object.Parent then object[prop] = (prefix or "") .. translate(key) end
    end
    table.insert(state.translated, update)
    update()
    return object
end
local function onLanguageChange(callback)
    table.insert(state.languageObservers, callback)
end
local function readLanguage()
    local code = environment.__VapeUILanguage
    if type(readfile) == "function" then
        local ok, value = pcall(readfile, "VapeUIClone/language.txt")
        if ok then code = value end
    end
    if code == "zh-CN" then state.language = code end
end
readLanguage()
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
    bindText(label(frame, title, 34, 0, width - 70, 40, 13), title)
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
    bindText(row, moduleName, "   ")
    row.TextColor3 = state.dim
    row.BackgroundColor3 = state.main
    row.BackgroundTransparency = 0
    local dots = btn(slot, "⋮", 190, 0, 30, 40)
    dots.TextSize = 19
    local detail = make("Frame", {BackgroundColor3 = Color3.fromRGB(22, 21, 22),
        BorderSizePixel = 0, Position = UDim2.fromOffset(0, 40),
        Size = UDim2.fromOffset(220, 83), Visible = false}, slot)
    local key = bindText(btn(detail, "Keybind: None", 12, 8, 195, 30), "Keybind: None")
    key.TextXAlignment = Enum.TextXAlignment.Left
    local hint = bindText(label(detail, "UI preview only · no gameplay effect", 12, 42, 205, 25, 11, state.dim),
        "UI preview only · no gameplay effect")
    hint.TextTruncate = Enum.TextTruncate.AtEnd
    local module = {Name = moduleName, Category = category, Enabled = false, Expanded = false, Row = row, Slot = slot}
    state.modules[moduleName] = module
    function module:Toggle()
        self.Enabled = not self.Enabled
        animate(row, {BackgroundColor3 = self.Enabled and state.accent or state.main,
            TextColor3 = self.Enabled and Color3.fromRGB(16, 23, 21) or state.dim})
        dots.TextColor3 = self.Enabled and Color3.fromRGB(16, 23, 21) or state.dim
        local message = state.language == "zh-CN"
            and (self.Enabled and "已开启（仅界面）" or "已关闭（仅界面）")
            or (self.Enabled and "ON (UI only)" or "OFF (UI only)")
        notify(translate(self.Name) .. " · " .. message)
    end
    function module:Expand()
        self.Expanded = not self.Expanded
        detail.Visible = self.Expanded
        slot.Size = UDim2.fromOffset(220, self.Expanded and 123 or 40)
        row.BackgroundColor3 = self.Enabled and state.accent or state.main
        notify(translate(self.Name) .. (state.language == "zh-CN"
            and " 设置 · 仅界面演示" or " settings · visual only"))
    end
    row.MouseButton1Click:Connect(function() module:Toggle() end)
    row.MouseButton2Click:Connect(function() module:Expand() end)
    dots.MouseButton1Click:Connect(function() module:Expand() end)
    local keyClicked = false
    onLanguageChange(function()
        if keyClicked and key.Parent then key.Text = translate("Keybind: unassigned (demo)") end
    end)
    key.MouseButton1Click:Connect(function()
        keyClicked = true
        key.Text = translate("Keybind: unassigned (demo)")
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
    bindText(row, title, "       ")
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
        local empty = bindText(label(list, "Game-specific modules appear here", 12, 8, 196, 42, 11, state.dim),
            "Game-specific modules appear here")
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
bindText(label(divider, "misc", 15, 2, 70, 20, 11, Color3.fromRGB(105, 105, 105)), "misc")
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
    bindText(input, name == "Profiles" and "Profile name" or "Roblox username", nil, "PlaceholderText")
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
                    state.profile = textValue
                    notify((state.language == "zh-CN" and "配置 " or "Profile ") .. textValue
                        .. (state.language == "zh-CN" and " · 仅界面设置" or " · UI settings only"))
                    refresh()
                else
                    notify(textValue .. (state.language == "zh-CN" and " · 仅本地列表" or " · local list only"))
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
        input.Text = ""; refresh()
        notify(value .. (state.language == "zh-CN" and " 已添加 · 仅界面列表" or " added · visual list"))
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
bindText(label(overlayBar, "Overlays", 16, 0, 130, 38, 12, state.dim), "Overlays")
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
bindText(searchText, "Search modules...", nil, "PlaceholderText")
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
        if string.find(string.lower(module.Name), query, 1, true)
            or string.find(string.lower(translate(module.Name)), query, 1, true) then
            matches[#matches + 1] = module
        end
    end
    table.sort(matches, function(a, b) return a.Name < b.Name end)
    for _, module in ipairs(matches) do
        local entry = btn(result, "  " .. translate(module.Name) .. "  · " .. translate(module.Category), 0, 0, 220, 33)
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
        local none = btn(result, "  " .. translate("No matching modules"), 0, 0, 220, 33)
        none.TextXAlignment = Enum.TextXAlignment.Left
    end
end
searchText:GetPropertyChangedSignal("Text"):Connect(updateSearch)
onLanguageChange(updateSearch)
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
local settingsPanel = panel("Settings", 244, 60, 240, 535)
local settingsIcon = icon(settingsPanel, "settings", "⚙", 13, 13, 14, 14)
tint(settingsIcon, state.text)
local hideSettings = btn(settingsPanel, "×", 202, 0, 36, 40)
hideSettings.TextSize = 20
hideSettings.MouseButton1Click:Connect(function() settingsPanel.Visible = false end)
settingsButton.MouseButton1Click:Connect(function() settingsPanel.Visible = not settingsPanel.Visible end)
bindText(label(settingsPanel, "GENERAL", 13, 52, 210, 24, 11, Color3.fromRGB(119, 119, 119)), "GENERAL")
line(settingsPanel, 79)
bindText(label(settingsPanel, "Rebind GUI", 13, 89, 150, 27, 13), "Rebind GUI")
label(settingsPanel, "RightShift", 143, 89, 80, 27, 12, state.dim)
bindText(label(settingsPanel, "GUI Theme", 13, 132, 165, 24, 13), "GUI Theme")
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
        notify(state.language == "zh-CN" and "界面主题已更新" or "GUI theme updated")
    end)
end
line(settingsPanel, 212)
bindText(label(settingsPanel, "GUI Scale", 13, 223, 164, 25, 13), "GUI Scale")
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
bindText(label(settingsPanel, "Language", 13, 312, 190, 25, 13), "Language")
local languageSelect = btn(settingsPanel, "", 13, 342, 213, 32)
languageSelect.BackgroundTransparency = 0
languageSelect.BackgroundColor3 = Color3.fromRGB(37, 36, 37)
languageSelect.TextXAlignment = Enum.TextXAlignment.Left
corner(languageSelect, 3)
local languageMenu = make("Frame", {BackgroundColor3 = Color3.fromRGB(32, 31, 32),
    BorderSizePixel = 0, Position = UDim2.fromOffset(13, 378),
    Size = UDim2.fromOffset(213, 70), Visible = false}, settingsPanel)
corner(languageMenu, 3)
border(languageMenu)
local function updateLanguageButton()
    languageSelect.Text = state.language == "zh-CN" and "   简体中文       ▾" or "   English       ▾"
end
updateLanguageButton()
languageSelect.MouseButton1Click:Connect(function()
    languageMenu.Visible = not languageMenu.Visible
end)
for index, option in ipairs({{label = "English", code = "en"},
    {label = "简体中文", code = "zh-CN"}}) do
    local choice = btn(languageMenu, "   " .. option.label, 0, (index - 1) * 35, 213, 35)
    choice.TextXAlignment = Enum.TextXAlignment.Left
    choice.TextColor3 = state.text
    choice.MouseEnter:Connect(function() choice.BackgroundTransparency = 0; choice.BackgroundColor3 = Color3.fromRGB(44, 43, 44) end)
    choice.MouseLeave:Connect(function() choice.BackgroundTransparency = 1 end)
    choice.MouseButton1Click:Connect(function()
        api:SetLanguage(option.code)
        languageMenu.Visible = false
    end)
end
line(settingsPanel, 458)
bindText(label(settingsPanel, "UI DEMO ONLY", 13, 470, 200, 23, 11, state.accent), "UI DEMO ONLY")
bindText(label(settingsPanel, "Modules change their visual state only.", 13, 496, 217, 24, 11, state.dim),
    "Modules change their visual state only.")
function api:SetLanguage(code)
    if code ~= "en" and code ~= "zh-CN" then return false, "unsupported language" end
    state.language = code
    environment.__VapeUILanguage = code
    if type(writefile) == "function" then
        if type(makefolder) == "function" then pcall(makefolder, "VapeUIClone") end
        pcall(writefile, "VapeUIClone/language.txt", code)
    end
    for _, update in ipairs(state.translated) do update() end
    for _, update in ipairs(state.languageObservers) do update() end
    updateLanguageButton()
    notify(code == "zh-CN" and "语言已切换为简体中文" or "Language switched to English")
    return true
end

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
notify(state.language == "zh-CN" and "Vape V4 界面已加载 · 仅视觉演示"
    or "Vape V4 UI study loaded · visual-only shell")
return api
