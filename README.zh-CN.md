<div align="center">

# fantastic-i3

Linux 和 macOS 上 i3 风格的平铺桌面

[Linux: i3-wm](#linux-i3-wm) · [macOS: yabai](#macos-yabai) · [English](README.md)

</div>

## Linux: i3-wm

X11 上的 i3，配 polybar、rofi、kitty、picom、dunst、conky 和 NvChad，统一成 MacTahoe 深色主题。从 GitHub 上收集来，再改得顺手一些。X11 不时髦，但简单、稳定。

<table>
  <tr>
    <td width="33%"><img src="image/README/1751285307483.png" alt="桌面"></td>
    <td width="33%"><img src="image/README/1751285369831.png" alt="ncmpcpp"></td>
    <td width="33%"><img src="image/README/1751285528523.png" alt="btop 和 fastfetch"></td>
  </tr>
  <tr>
    <td align="center">桌面</td>
    <td align="center">ncmpcpp</td>
    <td align="center">btop · fastfetch</td>
  </tr>
  <tr>
    <td><img src="image/README/1751285594846.png" alt="kitty"></td>
    <td><img src="image/README/1751285791836.png" alt="polybar 样式"></td>
    <td><img src="image/README/1751286279192.png" alt="NvChad"></td>
  </tr>
  <tr>
    <td align="center">kitty</td>
    <td align="center">polybar 样式</td>
    <td align="center">NvChad</td>
  </tr>
</table>

- **主题**：GTK 2/3/4、Qt 5/6、fcitx5、rofi 统一成 MacTahoe 深色。`install.sh` 装依赖（Arch，用 yay）。文件放哪、改完怎么重载、踩过的坑见 [THEME.md](THEME.md)。
- **Polybar**：有好几种样式。`python ~/.config/polybar/scripts/change.py --select 2` 换成带 CPU 监视的 2 号。
- **Neovim**：基于 [NvChad](https://nvchad.com/)，键位改在 `nvim/lua/mappings.lua`。配合 qutebrowser，手不用碰鼠标，脖子也轻松。代码悬浮提示在 `F` 上：按两次 ⇧F 查看。和整体主题最搭的是 OneDark；我自己用 Dracula。
- **其它**：conky 来自 [slate-conky-theme](https://github.com/CrispyKSP/slate-conky-theme)。登录界面可以试试 [slick-greeter](https://github.com/linuxmint/slick-greeter)。

## macOS: yabai

在 macOS 上沿用同一套习惯：yabai 平铺窗口，skhd 管快捷键，SketchyBar 代替菜单栏。有 17 个工作区、能用拼音搜索的窗口切换器，还能按应用记住布局和工作区。它是单独的仓库 [fantastic-i3-macOS](https://github.com/mejistus/fantastic-i3-macOS/blob/main/README.zh-CN.md)，在这里是子模块 `macos`。

Apple Silicon 上一行装好全部（包括 Homebrew），fantastic-i3-macOS 会克隆到 `~/Documents/fantastic-i3-macOS`：

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mejistus/fantastic-i3-macOS/main/install.sh)"
```

可以重复运行。最后会列出还要手动做的事，再打印一张快捷键表，建议截图保存。已经克隆了本仓库的话，先 `git submodule update --init macos` 取下子模块，再运行 `bash macos/install.sh`。

| 快捷键 | 作用 |
|---|---|
| <kbd>⌥1</kbd> … <kbd>⌥0</kbd> | 切到工作区 1 … 10 |
| <kbd>⌥Z</kbd> <kbd>⌥X</kbd> <kbd>⌥C</kbd> <kbd>⌥B</kbd> <kbd>⌥N</kbd> <kbd>⌥M</kbd> <kbd>⌥T</kbd> | 切到工作区 Z … T |
| <kbd>⌥⇧</kbd> + 工作区键 | 把窗口移过去，人也跟过去 |
| <kbd>⌃H</kbd> / <kbd>⌃L</kbd> | 上一个 / 下一个工作区 |
| <kbd>⌥H</kbd> <kbd>⌥J</kbd> <kbd>⌥K</kbd> <kbd>⌥L</kbd> | 焦点移到左 / 下 / 上 / 右（⌥ + 方向键也行） |
| <kbd>⌥⇧H</kbd> <kbd>⌥⇧J</kbd> <kbd>⌥⇧K</kbd> <kbd>⌥⇧L</kbd> | 和那边的窗口交换（⌥⇧ + 方向键也行） |
| <kbd>⌥F</kbd> / <kbd>⌥⇧F</kbd> | 全屏 / 平铺 ↔ 浮动 |
| <kbd>⌥-</kbd> / <kbd>⌥=</kbd> | 缩小 / 放大（<kbd>⌥R</kbd>：调大小模式） |
| <kbd>⌘⇥</kbd> | 窗口列表，打字搜索，支持拼音 |
| <kbd>⌥⇥</kbd> / <kbd>⌘Space</kbd> | 应用列表，启动台里的应用都在（点一下 ⌥⇥：上一个应用） |
| <kbd>⌃S</kbd> <kbd>M</kbd> / <kbd>⌃S</kbd> <kbd>W</kbd> | 记住当前应用的布局 / 工作区 |
| <kbd>⌃S</kbd> <kbd>Esc</kbd> | 重新加载配置 |
| <kbd>⌥⇧↩</kbd> | 在顶栏和系统菜单栏之间切换 |
| <kbd>⌥D</kbd> / <kbd>⌥⇧D</kbd> | 在这里开 Finder / 新开 Finder 窗口打开文稿 |
| <kbd>⌥G</kbd> | 工作区 1 的浏览器 |

全部快捷键、固定工作区、顶栏、瞬间切换和排错：**[fantastic-i3-macOS](https://github.com/mejistus/fantastic-i3-macOS/blob/main/README.zh-CN.md)**。

## 致谢

用到了 [NvChad](https://nvchad.com/)、[slate-conky-theme](https://github.com/CrispyKSP/slate-conky-theme)、[MacTahoe](https://github.com/vinceliuice/MacTahoe-gtk-theme)、[yabai](https://github.com/asmvik/yabai)、[skhd](https://github.com/asmvik/skhd)、[SketchyBar](https://github.com/FelixKratz/SketchyBar) 等等。向这些优秀的开源项目致敬。

Neovim 配置大部分由 Claude Code 编写。Linux 主题借助 Muse Spark 1.3 Free 和 DeepSeek 4.1 Flash 修好。感谢自由软件，也感谢免费的模型。
