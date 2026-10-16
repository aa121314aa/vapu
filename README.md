# Vape V4 风格 UI 仿制项目（Roblox Luau）

参考项目：[7GrandDadPGN/VapeV4ForRoblox](https://github.com/7GrandDadPGN/VapeV4ForRoblox)，按本次拉取的 `9e7828f` 版本的 `src/guis/new/` 界面结构制作。原仓库的代码和图标依 CC0 1.0 发布；随包保留 `REFERENCE_LICENSE_CC0.txt`。本项目是独立写的 **UI 外壳**，不是原项目的加载器或功能脚本。

## 内容

- `Main.lua` — 独立客户端 Luau 入口；仅创建本地 ScreenGui。
- `assets/*.png` — 取自参考仓库的界面图标和 mini logo；有 `getcustomasset`/`getsynasset` 时显示原图，无这类接口时使用文字回退。
- `REFERENCE_LICENSE_CC0.txt` — 参考项目许可证。

## 使用

1. 把整个 `VapeUIClone` 文件夹复制进执行器的脚本文件系统（保留 `VapeUIClone/assets/` 路径）。
2. 在 Roblox **客户端**运行：

```luau
loadstring(readfile("VapeUIClone/Main.lua"))()
```

也可以将 `Main.lua` 的源码粘贴到 Roblox Studio 的 `StarterPlayerScripts` 下的 `LocalScript`。Studio 中本地 PNG 不会自动加载，会显示文字图标回退；若追求图标相似度，应使用带 `getcustomasset`/`getsynasset` 的本地资源环境。无需网络请求。

## 范围与交互

- 六大主分类：Combat、Blatant、Render、Utility、World、Inventory；另有 Friends、Profiles、Targets、Overlays 和搜索框/Legit 入口。
- 220px 窄栏、独立拖拽分类窗、深色背景、青绿色主题、模块开关/右键设置、搜索定位、主题色切换、GUI 缩放、RightShift 显隐。
- 模块名称取自参考项目的通用模块目录作**视觉占位**；Inventory 在通用目录没有对应模块，因此保留空分类供后续游戏专属模块接入。
- 每个开关**只改变界面状态**：不修改角色、相机、武器、服务器或游戏网络请求；配置列表仅存于本次运行内存中。界面并未逐像素复刻参考项目所有子面板/动画，也不承诺 100% 像素一致。
- 重复执行入口会删除上一次的 `VapeUIClone` 界面后创建新界面。要彻底清理本次运行的全局按键监听，可保留脚本返回的 API 并调用 `api:Destroy()`（见下一节）。

## 可选接入接口

```luau
local api = loadstring(readfile("VapeUIClone/Main.lua"))()
api:SetVisible(true)  -- 显示界面
api:CreateModule("Combat", "YourModule")  -- 仅添加视觉占位模块
api:Destroy() -- 卸载界面和输入监听
```

该项目尚未在 Roblox/执行器中实际运行验证，仅通过 Luau 静态解析及源码检查。
