-- Vape V4-inspired UI layer. Downloads/caches icons; real Blatant/Overlay logic is delegated to upstream runtime when loaded.
-- Reference: https://github.com/7GrandDadPGN/VapeV4ForRoblox (CC0 1.0).
-- Upload this Main.lua and NativeBridgeLoader.lua to aa121314aa/vapu; execute the bridge for real modules.
-- Directly executing Main.lua without the bridge opens the UI but blocks unbacked Blatant/Overlay toggles.
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
-- Download local assets BEFORE placing menu images. Native asset IDs are used if an executor cannot mount local images.
local assetBase = "https://raw.githubusercontent.com/aa121314aa/vapu/main/assets/"
local iconIds = {
    blatant = "rbxassetid://126929923309265",
    close = "rbxassetid://121816018671466",
    combat = "rbxassetid://94762732349053",
    downexpand = "rbxassetid://94197751291504",
    edit = "rbxassetid://105801951237137",
    expandarrow = "rbxassetid://86360332526471",
    friends = "rbxassetid://92957214042038",
    inventory = "rbxassetid://93264756888499",
    notification = "rbxassetid://90300780458781",
    overlays = "rbxassetid://136535637407545",
    pin = "rbxassetid://92459145800579",
    profiles = "rbxassetid://126051451865127",
    render = "rbxassetid://125472576898654",
    search = "rbxassetid://115611852955611",
    settingdots = "rbxassetid://130896840048276",
    settings = "rbxassetid://73820177347303",
    theme = "rbxassetid://111525258317113",
    utility = "rbxassetid://108303206513893",
    v4mini = "rbxassetid://115213099001611",
    vapelogomini = "rbxassetid://109041903452149",
    world = "rbxassetid://118917453153459",
    targetinfo = "rbxassetid://121604266095276",
    textgui = "rbxassetid://99438663817412",
    radar = "rbxassetid://97983828696086",
 }
local boot = Instance.new("ScreenGui")
boot.Name = "VapeUIBoot"
boot.ResetOnSpawn = false
boot.DisplayOrder = 9001
boot.Parent = parent
local progress = Instance.new("TextLabel")
progress.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
progress.BackgroundTransparency = 0.16
progress.AnchorPoint = Vector2.new(0.5, 0.5)
progress.Position = UDim2.fromScale(0.5, 0.5)
progress.Size = UDim2.fromOffset(290, 52)
progress.TextColor3 = Color3.fromRGB(200, 200, 200)
progress.TextSize = 14
progress.Font = Enum.Font.Arial
progress.Text = "Vape UI · Initializing..."
progress.Parent = boot
local preloadedIcons = {}
local canWrite = type(writefile) == "function" and type(makefolder) == "function"
if canWrite then
    pcall(makefolder, "VapeUIClone")
    pcall(makefolder, "VapeUIClone/assets")
end
for index, name in ipairs({"blatant", "close", "combat", "downexpand", "edit", "expandarrow", "friends", "inventory", "notification", "overlays", "pin", "profiles", "render", "search", "settingdots", "settings", "theme", "utility", "v4mini", "vapelogomini", "world"}) do
    progress.Text = ("Vape UI · assets %d/%d"):format(index, 21)
    local path = "VapeUIClone/assets/" .. name .. ".png"
    if canWrite then
        local valid = false
        if type(readfile) == "function" then
            local ok, bytes = pcall(readfile, path)
            valid = ok and type(bytes) == "string" and bytes:sub(1, 8) == "\137PNG\r\n\26\n"
        end
        if not valid then
            local ok, bytes = pcall(function() return game:HttpGet(assetBase .. name .. ".png") end)
            if ok and type(bytes) == "string" and bytes:sub(1, 8) == "\137PNG\r\n\26\n" then
                pcall(writefile, path, bytes)
            end
        end
    end
    local getAsset = getcustomasset or getsynasset
    if type(getAsset) == "function" then
        local ok, result = pcall(getAsset, path)
        if ok and type(result) == "string" and result ~= "" then preloadedIcons[name] = result end
    end
    preloadedIcons[name] = preloadedIcons[name] or iconIds[name]
end
progress.Text = "Vape UI · Opening..."
boot:Destroy()

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
    language = "en", translated = {}, languageObservers = {}, panels = {},
    mobile = false, virtualW = 1280, virtualH = 720, opacity = 0, backgrounds = {},
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
    ['GUI Scale'] = "界面缩放", ['Language'] = "语言", ['UI Opacity'] = "界面透明度", misc = "其他",
    ['UI / Native Bridge'] = "界面 / 原版桥接",
    ['Blatant & Overlays use original runtime.'] = "暴力与悬浮窗依赖原版运行核心。",
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
-- NativeBridgeLoader populates the real upstream engine before this UI is created.
local native = type(shared) == "table" and shared.vape or nil
if type(native) == "table" and type(native.Modules) == "table" then
    state.native = native
end

local function make(className, properties, container)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = container
    if object:IsA("GuiObject") and properties and properties.BackgroundColor3
        and (properties.BackgroundTransparency or 0) < 1 then
        local base = properties.BackgroundTransparency or 0
        state.backgrounds[#state.backgrounds + 1] = {object = object, base = base}
        object.BackgroundTransparency = math.max(base, state.opacity)
    end
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
    local asset = preloadedIcons[name] or iconIds[name]
    if asset then
        local picture = make("ImageLabel", {BackgroundTransparency = 1, Image = asset,
            ImageColor3 = state.text, Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h)}, parentObject)
        -- Some executors return an unusable local ContentId without raising an error.
        -- Prefer a real image ID over an emoji if local loading has not succeeded.
        if iconIds[name] and asset ~= iconIds[name] then
            task.delay(3, function()
                if picture.Parent and not picture.IsLoaded then picture.Image = iconIds[name] end
            end)
        end
        return picture
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
local function clampFrame(frame, proposedX, proposedY)
    local width = frame.Size.X.Offset
    local height = frame.Size.Y.Offset
    local x = math.clamp(proposedX or frame.Position.X.Offset, 0, math.max(0, state.virtualW - width))
    local y = math.clamp(proposedY or frame.Position.Y.Offset, 0, math.max(0, state.virtualH - height))
    frame.Position = UDim2.fromOffset(x, y)
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
        clampFrame(frame, initial.X.Offset + delta.X / sc,
            initial.Y.Offset + delta.Y / sc)
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
    state.mobile = viewport.X < 850 or (UIS.TouchEnabled and viewport.X < 1200)
    local n
    if state.mobile then
        n = math.clamp(math.min(viewport.X / 390, viewport.Y / 690), 0.75, 1.1)
    else
        n = math.clamp(math.min(viewport.X / 1100, viewport.Y / 760), 0.62, 1)
    end
    state.scale = n * userScale
    state.virtualW = viewport.X / state.scale
    state.virtualH = viewport.Y / state.scale
    scale.Scale = state.scale
    surface.Size = UDim2.fromScale(1 / state.scale, 1 / state.scale)
    for _, frame in ipairs(state.panels) do
        if frame.Parent then
            if state.mobile and frame ~= state.mainFrame then
                clampFrame(frame, 14, 60)
            else
                clampFrame(frame)
            end
        end
    end
    if state.mobileBack then
        state.mobileBack.Visible = state.mobile and state.open
        state.mobileBack.Position = UDim2.fromOffset(math.max(4, state.virtualW - 53), 14)
    end
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
state.mainFrame = main
state.panels[#state.panels + 1] = main
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
closeButton.MouseButton1Click:Connect(function() api:SetVisible(false) end)

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
    state.panels[#state.panels + 1] = frame
    frame:GetPropertyChangedSignal("Size"):Connect(function()
        if frame.Parent then clampFrame(frame) end
    end)
    if state.mobile then clampFrame(frame, 14, 60) else clampFrame(frame) end
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
local overlayNames = {TextGUI = "Text GUI", TargetInfo = "Target Info", SessionInfo = "Session Info"}
local function overlayWindow(name)
    local native = state.native
    local scaledGui = native and native.gui and native.gui:FindFirstChild("ScaledGui")
    return scaledGui and scaledGui:FindFirstChild(name .. "Overlay")
end
local function nativeFor(module)
    local native = state.native
    if not native then return nil end
    if module.Category == "Overlays" then
        return native.Overlays and native.Overlays.Options
            and native.Overlays.Options[overlayNames[module.Name] or module.Name]
    end
    return native.Modules and native.Modules[module.Name]
end
local function openModuleSettings(module)
    if state.activeSettings and state.activeSettings.Close then state.activeSettings.Close() end
    local bridgedCategory = module.Category == "Blatant" or module.Category == "Overlays"
    local native = bridgedCategory and nativeFor(module) or nil
    local frame = panel(module.Name, state.mobile and 14 or 712, 60, 300, 395)
    frame.Visible = true
    local header = frame:FindFirstChildWhichIsA("TextLabel")
    if header then bindText(header, module.Name) end
    local close = btn(frame, "×", 265, 0, 33, 39)
    close.TextSize = 20
    local list, _ = scroll(frame, 42)
    local originalParents = {}
    local function closeSettings()
        for _, data in ipairs(originalParents) do
            if data.object and data.object.Parent then
                pcall(function()
                    data.object.Parent = data.parent
                    if data.layoutOrder ~= nil then data.object.LayoutOrder = data.layoutOrder end
                end)
            end
        end
        frame:Destroy()
        state.activeSettings = nil
    end
    close.MouseButton1Click:Connect(closeSettings)
    state.activeSettings = {Frame = frame, Close = closeSettings}
    if type(native) == "table" and type(native.Toggle) == "function" then
        -- Move the real option controls temporarily; retain upstream callbacks and slider logic.
        local objects = {}
        if module.Category == "Overlays" then
            local win = overlayWindow(overlayNames[module.Name] or module.Name)
            local originalList = win and win:FindFirstChild("Children")
            if originalList then
                for _, obj in ipairs(originalList:GetChildren()) do
                    if obj:IsA("GuiObject") then objects[#objects + 1] = obj end
                end
            end
        elseif type(native.Options) == "table" then
            local options = {}
            for _, option in pairs(native.Options) do
                if type(option) == "table" and typeof(option.Object) == "Instance"
                    and option.Object:IsA("GuiObject") then
                    options[#options + 1] = option
                end
            end
            table.sort(options, function(a, b) return (a.Index or 0) < (b.Index or 0) end)
            for _, option in ipairs(options) do objects[#objects + 1] = option.Object end
        end
        for index, obj in ipairs(objects) do
            originalParents[#originalParents + 1] = {
                object = obj, parent = obj.Parent, layoutOrder = obj.LayoutOrder,
            }
            obj.Parent = list
            obj.LayoutOrder = index
        end
        if #objects == 0 then
            label(list, state.language == "zh-CN" and "该模块没有额外设置" or "No additional settings", 12, 10, 270, 42, 12, state.dim)
        end
    else
        local message = bridgedCategory
            and (state.language == "zh-CN" and "需运行 NativeBridgeLoader，才能使用真实模块设置" or
                "Native module unavailable. Run NativeBridgeLoader.")
            or (state.language == "zh-CN" and "该分类为界面占位，没有原版设置" or
                "UI-only module; no native settings are available.")
        label(list, message, 12, 10, 270, 66, 12, state.dim)
    end
    clampFrame(frame)
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
    row.BackgroundTransparency = state.opacity
    state.backgrounds[#state.backgrounds + 1] = {object = row, base = 0}
    local dots = btn(slot, "⋮", 190, 0, 30, 40)
    dots.TextSize = 19
    local module = {Name = moduleName, Category = category, Enabled = false, Row = row, Slot = slot}
    state.modules[moduleName] = module
    function module:Toggle()
        local requiresNative = self.Category == "Blatant" or self.Category == "Overlays"
        local native = requiresNative and nativeFor(self) or nil
        if requiresNative then
            if type(native) ~= "table" or type(native.Toggle) ~= "function" then
                notify(state.language == "zh-CN" and "原生功能未加载，已阻止假开关" or
                    "Native module unavailable; toggle blocked")
                return
            end
            local ok, err = pcall(function() native:Toggle() end)
            if not ok then notify("Native module error: " .. tostring(err)); return end
            self.Enabled = native.Enabled == true
            if self.Category == "Overlays" then
                local win = overlayWindow(overlayNames[self.Name] or self.Name)
                if win then win.Visible = self.Enabled end
            end
        else
            self.Enabled = not self.Enabled -- Other categories retain their explicit visual-only state.
        end
        animate(row, {BackgroundColor3 = self.Enabled and state.accent or state.main,
            TextColor3 = self.Enabled and Color3.fromRGB(16, 23, 21) or state.dim})
        dots.TextColor3 = self.Enabled and Color3.fromRGB(16, 23, 21) or state.dim
        local suffix = requiresNative and " (native)" or " (UI only)"
        notify(translate(self.Name) .. " · " .. (self.Enabled and "ON" or "OFF") .. suffix)
    end
    function module:Expand()
        openModuleSettings(self)
    end
    row.MouseButton1Click:Connect(function() module:Toggle() end)
    row.MouseButton2Click:Connect(function() module:Expand() end)
    dots.MouseButton1Click:Connect(function() module:Expand() end)
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
        local opening = not window.Visible
        if state.mobile and opening then
            for _, frame in ipairs(state.panels) do if frame ~= main then frame.Visible = false end end
            clampFrame(window, 14, 60)
        end
        window.Visible = opening
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
        if state.mobile and not p.Visible then
            for _, frame in ipairs(state.panels) do if frame ~= main then frame.Visible = false end end
            clampFrame(p, 14, 60)
        end
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
if state.native and state.native.Overlays and state.native.Overlays.Options then
    for name in pairs(state.native.Overlays.Options) do
        local known = false
        for _, existingName in ipairs({"TextGUI", "TargetInfo", "Radar", "SessionInfo", "Spotify"}) do
            if name == (overlayNames[existingName] or existingName) then known = true; break end
        end
        if not known then createModule("Overlays", name, overlayList) end
    end
end
overlayBtn.MouseButton1Click:Connect(function()
    if state.mobile and not overlayPanel.Visible then
        for _, frame in ipairs(state.panels) do if frame ~= main then frame.Visible = false end end
        clampFrame(overlayPanel, 14, 60)
    end
    overlayPanel.Visible = not overlayPanel.Visible
end)
mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    main.Size = UDim2.fromOffset(220, 40 + mainLayout.AbsoluteContentSize.Y)
end)
main.Size = UDim2.fromOffset(220, 40 + mainLayout.AbsoluteContentSize.Y)
main:GetPropertyChangedSignal("Size"):Connect(function() clampFrame(main) end)

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
local settingsPanel = panel("Settings", 244, 60, 240, 625)
local settingsIcon = icon(settingsPanel, "settings", "⚙", 13, 13, 14, 14)
tint(settingsIcon, state.text)
local hideSettings = btn(settingsPanel, "×", 202, 0, 36, 40)
hideSettings.TextSize = 20
hideSettings.MouseButton1Click:Connect(function() settingsPanel.Visible = false end)
settingsButton.MouseButton1Click:Connect(function()
    if state.mobile and not settingsPanel.Visible then
        for _, frame in ipairs(state.panels) do if frame ~= main then frame.Visible = false end end
        clampFrame(settingsPanel, 14, 60)
    end
    settingsPanel.Visible = not settingsPanel.Visible
end)
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
local adaptSettings
local function updateScale(n)
    userScale = math.clamp(n, 0.7, 1.2)
    fit()
    if adaptSettings then adaptSettings() end
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
bindText(label(settingsPanel, "UI Opacity", 13, 468, 190, 25, 13), "UI Opacity")
local opacityAmount = label(settingsPanel, "0%", 171, 468, 54, 25, 12, state.dim)
local lessOpacity = btn(settingsPanel, "−", 135, 500, 35, 30)
local moreOpacity = btn(settingsPanel, "+", 179, 500, 35, 30)
for _, control in ipairs({lessOpacity, moreOpacity}) do
    control.BackgroundTransparency = 0
    control.BackgroundColor3 = Color3.fromRGB(37, 36, 37)
    corner(control, 3)
end
local function setOpacity(value)
    state.opacity = math.clamp(math.floor(value * 100 + 0.5) / 100, 0, 0.75)
    opacityAmount.Text = tostring(math.floor(state.opacity * 100 + 0.5)) .. "%"
    for _, entry in ipairs(state.backgrounds) do
        local obj = entry.object
        if obj.Parent then obj.BackgroundTransparency = math.max(entry.base, state.opacity) end
    end
end
lessOpacity.MouseButton1Click:Connect(function() setOpacity(state.opacity - 0.1) end)
moreOpacity.MouseButton1Click:Connect(function() setOpacity(state.opacity + 0.1) end)
line(settingsPanel, 554)
bindText(label(settingsPanel, "UI / Native Bridge", 13, 566, 200, 23, 11, state.accent), "UI / Native Bridge")
bindText(label(settingsPanel, "Blatant & Overlays use original runtime.", 13, 592, 217, 24, 11, state.dim),
    "Blatant & Overlays use original runtime.")
-- Only the settings body scrolls: the header stays visible on short phone screens.
local settingsScroll = make("ScrollingFrame", {BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 41), Size = UDim2.new(1, 0, 1, -41),
    CanvasSize = UDim2.fromOffset(0, 590), BorderSizePixel = 0,
    ScrollBarThickness = 2, ScrollBarImageTransparency = 0.7}, settingsPanel)
local settingsBody = make("Frame", {BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, -41), Size = UDim2.fromOffset(240, 625)}, settingsScroll)
for _, child in ipairs(settingsPanel:GetChildren()) do
    if child:IsA("GuiObject") and child ~= settingsScroll and child.Position.Y.Offset > 40 then
        child.Parent = settingsBody
    end
end
adaptSettings = function()
    settingsPanel.Size = UDim2.fromOffset(240, math.min(625, math.max(300, state.virtualH - 16)))
    clampFrame(settingsPanel)
end
adaptSettings()
onLanguageChange(function()
    if state.language == "zh-CN" then
        -- Real upstream modules are not translated by this shell.
        notify("暴力模块由原版运行核心执行，原版设置保留英文")
    end
end)
-- Update height when resolution/orientation changes.
if workspace.CurrentCamera then
    table.insert(state.connections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adaptSettings))
end
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
local launcher = btn(ui, "V4", 0, 0, 48, 48)
launcher.AnchorPoint = Vector2.new(1, 1)
launcher.Position = UDim2.new(1, -14, 1, -14)
launcher.BackgroundTransparency = 0.08
launcher.BackgroundColor3 = state.main
launcher.TextColor3 = state.accent
launcher.TextSize = 18
launcher.Visible = false
corner(launcher, 10); border(launcher)
launcher.MouseButton1Click:Connect(function() api:SetVisible(true) end)
local mobileBack = btn(surface, "☰", 0, 14, 40, 38)
mobileBack.BackgroundTransparency = 0.08
mobileBack.BackgroundColor3 = state.main
mobileBack.TextColor3 = state.accent
mobileBack.TextSize = 21
corner(mobileBack, 6); border(mobileBack)
state.mobileBack = mobileBack
mobileBack.MouseButton1Click:Connect(function()
    for _, frame in ipairs(state.panels) do
        if frame ~= main then frame.Visible = false end
    end
    main.Visible = true
end)
fit()
function api:SetVisible(visible)
    state.open = not not visible
    surface.Visible = state.open
    launcher.Visible = not state.open
end
function api:Destroy()
    if state.activeSettings and state.activeSettings.Close then state.activeSettings.Close() end
    for _, connection in ipairs(state.connections) do connection:Disconnect() end
    ui:Destroy()
    if environment.__VapeUIClone == self then environment.__VapeUIClone = nil end
end
-- Keep native overlay windows inside the actual viewport too (native GUI uses its own UIScale).
if state.native and state.native.gui then
    local nativeScaled = state.native.gui:FindFirstChild("ScaledGui")
    if nativeScaled then
        local nativeScale = nativeScaled:FindFirstChildOfClass("UIScale")
        for _, win in ipairs(nativeScaled:GetChildren()) do
            if win:IsA("GuiObject") and win.Name:sub(-7) == "Overlay" then
                local reentrant = false
                local function bound()
                    if reentrant or not win.Parent then return end
                    local camera = workspace.CurrentCamera
                    if not camera then return end
                    local sc = nativeScale and nativeScale.Scale or 1
                    local width, height = camera.ViewportSize.X / sc, camera.ViewportSize.Y / sc
                    local x = math.clamp(win.Position.X.Offset, 0, math.max(0, width - win.Size.X.Offset))
                    local y = math.clamp(win.Position.Y.Offset, 0, math.max(0, height - math.max(win.Size.Y.Offset, 41)))
                    if x ~= win.Position.X.Offset or y ~= win.Position.Y.Offset then
                        reentrant = true
                        win.Position = UDim2.fromOffset(x, y)
                        reentrant = false
                    end
                end
                table.insert(state.connections, win:GetPropertyChangedSignal("Position"):Connect(bound))
                bound()
            end
        end
    end
end
local shortcut = UIS.InputBegan:Connect(function(input, processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.RightShift then api:SetVisible(not state.open) end
end)
table.insert(state.connections, shortcut)
environment.__VapeUIClone = api
if state.native then
    task.spawn(function()
        while ui.Parent and state.native do
            for _, module in pairs(state.modules) do
                if module.Category == "Blatant" or module.Category == "Overlays" then
                    local original = nativeFor(module)
                    if original then
                        local enabled = original.Enabled == true
                        if module.Enabled ~= enabled then
                            module.Enabled = enabled
                            module.Row.BackgroundColor3 = enabled and state.accent or state.main
                        end
                        if module.Category == "Overlays" and enabled then
                            local win = overlayWindow(overlayNames[module.Name] or module.Name)
                            if win then win.Visible = true end
                        end
                    end
                end
            end
            task.wait(0.7)
        end
    end)
end

-- Preview two categories while keeping other windows closed; no module is enabled by default.
state.windows.Combat.Frame.Visible = not state.mobile
state.windows.Blatant.Frame.Visible = not state.mobile
if not state.mobile then
    state.windows.Combat.Nav.TextColor3 = state.accent
    state.windows.Blatant.Nav.TextColor3 = state.accent
end
notify(state.native and (state.language == "zh-CN" and "UI 已打开 · 原版模块已接入"
    or "UI opened · native modules connected")
    or (state.language == "zh-CN" and "UI 已打开 · 原版运行核心未加载"
    or "UI opened · native runtime unavailable"))
return api
