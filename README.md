# Vapu：手机 / PC 自适应 Vape 风格 UI 与原版桥接

这是一个 Roblox Luau 客户端 UI 项目，参考 [7GrandDadPGN/VapeV4ForRoblox](https://github.com/7GrandDadPGN/VapeV4ForRoblox) 的 `src/guis/new/` 界面风格。图标和参考代码的许可信息见 [`REFERENCE_LICENSE_CC0.txt`](REFERENCE_LICENSE_CC0.txt)。本项目并非原项目的官方发行版。

## 文件

- `Main.lua`：自适应界面、搜索、主题/语言/缩放/透明度设置，以及可选的原版模块适配。
- `NativeBridgeLoader.lua`：先尝试启动上游运行核心，再加载本项目界面；模块实现仍来自上游，不是本仓库内置副本。
- `RemoteLoader.lua`：远程启动 `NativeBridgeLoader.lua` 的便捷入口。
- `assets/`：界面 PNG 图标。

## 启动

发布到仓库 `main` 分支后，可从客户端执行以下入口：

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/aa121314aa/vapu/main/RemoteLoader.lua"))()
```

也可直接调用桥接入口：

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/aa121314aa/vapu/main/NativeBridgeLoader.lua"))()
```

桥接会尝试从上游下载并运行 `NewMainScript.lua`，最多等待 15 秒让 `shared.vape.Modules` 初始化，然后隐藏原版 ClickGui、保留原版运行核心并加载本仓库的 `Main.lua`。如果运行核心没有成功初始化，界面仍会打开，但 Blatant 与 Overlays 的原版开关会保持禁用并提示；不会显示假启用状态。默认远程链接指向 `main`，发布到其他分支时需相应修改脚本中的 raw URL。

只运行视觉界面时，可将 `Main.lua` 和 `assets/` 放在执行器文件系统的 `VapeUIClone/` 目录，再运行：

```luau
loadstring(readfile("VapeUIClone/Main.lua"))()
```

此模式不主动加载原版运行核心。能够写入文件的环境会尝试缓存 PNG；否则会回退到 Roblox 图片资源 ID。除 Blatant / Overlays 外，其余分类仍是界面占位，不执行游戏功能。也可将 `Main.lua` 放入 Roblox Studio 的客户端 `LocalScript` 中进行界面测试；执行器专用 API 和原版桥接在 Studio 中不可用。

## 界面与桥接范围

- 自动识别手机和桌面视口；手机分类窗口单页展示，拖动窗口会限制在可见范围内。
- 最小化后可用右下角 **V4** 按钮恢复；`RightShift` 可显隐界面。
- 支持中英文、主题色、缩放、透明度、本地列表/配置界面，以及模块搜索。
- 桥接 16 个通用 Blatant 模块及上游存在的 Overlay 开关/控件。其余 Combat、Render、Utility、World、Inventory 等分类仅为 UI 占位。
- 重复运行会清理上一份自定义界面；配置和列表仅保存在当前运行内存中，语言可写入 `VapeUIClone/language.txt`。

## 安全与验证

**远程桥接会使用 `game:HttpGet` 和 `loadstring` 下载并执行代码**：包括上游仓库的 `NewMainScript.lua`，以及本仓库 `main` 分支上的 `Main.lua`。上游代码及远程分支内容可能变化；运行前请自行检查来源和代码，只在你信任且获准的环境中使用。使用游戏修改工具可能违反 Roblox 或具体游戏的规则。

本项目不是自包含的游戏功能实现。上游 API 变化、执行器兼容性、手机实际操作和游戏内效果均未在 Roblox 客户端中验证；请勿将静态源码检查视为运行验证。
