# fantastic-i3-macOS

[English](README.md) · 属于 [fantastic-i3](https://github.com/mejistus/fantastic-i3/blob/main/README.zh-CN.md)，那边是 Linux 上的 i3 配置

macOS 上 i3 风格的平铺桌面。[yabai](https://github.com/asmvik/yabai) 平铺窗口，[skhd](https://github.com/asmvik/skhd) 管快捷键，[SketchyBar](https://github.com/FelixKratz/SketchyBar) 代替菜单栏。有 17 个工作区：1 … 10 和 Z X C B N M T，每个对应一个 macOS 桌面。

[安装](#安装) · [快捷键](#快捷键) · [固定工作区](#固定工作区) · [顶栏](#顶栏) · [瞬间切换](#瞬间切换) · [排错](#排错) · [文件](#文件)

## 安装

只支持 Apple Silicon。一行：

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mejistus/fantastic-i3-macOS/main/install.sh)"
```

已经克隆了仓库，就在里面运行 `bash install.sh`。脚本可以重复运行，它会：

1. 没有 Homebrew 就装上。会问开机密码，顺带装好 Xcode 命令行工具。
2. 把仓库克隆到 `~/Documents/fantastic-i3-macOS`，配置里写的就是这个路径。克隆在别处的（比如 fantastic-i3 的子模块 `macos`），在这个路径建一个链接。
3. 逐个检查 yabai、skhd、SketchyBar、jq 和字体，没装的装上。
4. 把配置链接到 `~/.config`，原来的文件会备份。
5. 关掉"根据最近的使用情况自动重新排列空间"，把菜单栏设为自动隐藏。
6. 编译 aero-helper（窗口切换器、顶栏数据），启动各项服务。

然后列出还要手动做的事：

- 系统设置 → 隐私与安全性 → 辅助功能：打开 yabai 和 skhd，再运行一次脚本。
- 在调度中心里把桌面加到 17 个。

最后打印一张快捷键表，建议截图保存；`install.sh --keys` 可以再打印一次。

## 快捷键

### 工作区

| 快捷键 | 作用 |
|---|---|
| <kbd>⌥1</kbd> … <kbd>⌥9</kbd> <kbd>⌥0</kbd> | 切到工作区 1 … 10 |
| <kbd>⌥Z</kbd> <kbd>⌥X</kbd> <kbd>⌥C</kbd> <kbd>⌥B</kbd> <kbd>⌥N</kbd> <kbd>⌥M</kbd> <kbd>⌥T</kbd> | 切到工作区 Z X C B N M T（桌面 11 … 17）。⌥T 要[脚本扩展](#瞬间切换)：macOS 只有切换到桌面 1 … 16 的快捷键 |
| <kbd>⌥</kbd> + <kbd>Caps Lock</kbd> | 也是工作区 10。Caps Lock 没改过、或改成了 🌐/fn 都能用 |
| <kbd>⌥⇧</kbd> + 上面的键 | 把窗口移到那个工作区，人也跟过去 |
| <kbd>⌃H</kbd> / <kbd>⌃L</kbd> | 上一个 / 下一个工作区：1 … 10，加上有窗口的字母工作区 |
| <kbd>⌥⇧⇥</kbd> | 把工作区挪到下一个显示器（要脚本扩展） |

### 窗口

| 快捷键 | 作用 |
|---|---|
| <kbd>⌥H</kbd> <kbd>⌥J</kbd> <kbd>⌥K</kbd> <kbd>⌥L</kbd> | 焦点移到左 / 下 / 上 / 右 |
| <kbd>⌥⇧H</kbd> <kbd>⌥⇧J</kbd> <kbd>⌥⇧K</kbd> <kbd>⌥⇧L</kbd> | 和那边的窗口交换 |
| <kbd>⌥</kbd> / <kbd>⌥⇧</kbd> + 方向键 | 同上，用方向键。系统里按词移动 / 选择的快捷键就被占掉了 |
| <kbd>⌥F</kbd> | 全屏 / 还原 |
| <kbd>⌥⇧F</kbd> | 平铺 ↔ 浮动 |
| <kbd>⌥-</kbd> / <kbd>⌥=</kbd> | 缩小 / 放大 |
| <kbd>⌥R</kbd> | 调大小模式：H J K L 或方向键调宽高，Esc 退出 |

### 切换和打开

| 快捷键 | 作用 |
|---|---|
| <kbd>⌥⇥</kbd> | 窗口列表，上一个用过的窗口已选中，⌥⇥ 再回车就回去了 |
| <kbd>⌘⇥</kbd> | 代替 macOS 的应用切换器。点一下：上一个应用；按住 ⌘：应用列表 |
| <kbd>⌘Space</kbd> | 直接打开应用列表，代替 Spotlight。再按一次关掉 |
| <kbd>⌥D</kbd> | 把一个 Finder 窗口拿到当前工作区，没有就新开 |
| <kbd>⌥G</kbd> | 工作区 1 的默认浏览器：那里有它的窗口就切过去，没有就新开 |

两个列表里都直接打字搜索。按键不经过输入法，输入法保持原样。中文名用拼音搜，全拼或首字母都行（天氣：`tianqi` 或 `tq`）。↑ ↓ 或再按列表自己的键（⌥⇥ / ⌘⇥，加 ⇧ 往上）选择，回车或单击切换，Esc 关闭，⌘+ / ⌘- 调字号。

- **窗口列表**：所有窗口，按工作区排。开着但没有窗口的应用排在最后，选它就像点 Dock 图标。
- **应用列表**：启动台里的所有应用，一个应用一行。有窗口的在最前，按最近使用排，选中就去它最近用的窗口；然后是开着但没窗口的；最后是其余的，按名字排，选中没开的就打开它。

### 服务模式：先按 <kbd>⌃S</kbd>，再按

| 快捷键 | 作用 |
|---|---|
| <kbd>M</kbd> | 记住当前应用平铺还是浮动，以后它新开的窗口照办。平铺只管标准窗口，对话框照样浮动。存在 `~/.config/fantastic-i3/layouts` |
| <kbd>W</kbd> | 记住当前应用的工作区：以后新开的窗口去那里，人也跟过去。盖过[固定工作区](#固定工作区)。存在 `~/.config/fantastic-i3/workspaces` |
| <kbd>F</kbd> | 当前工作区的窗口全部平铺 ↔ 全部浮动 |
| <kbd>J</kbd> / <kbd>H</kbd> / <kbd>V</kbd> | 切换分割方向 / 下一个窗口开在右边 / 开在下面 |
| <kbd>R</kbd> | 调大小模式 |
| <kbd>Esc</kbd> | 重新加载配置，不重启 yabai，窗口不动 |

想忘掉某个应用：删掉文件里那一行，再按 ⌃S Esc。

### 其它

| 快捷键 | 作用 |
|---|---|
| <kbd>⌥⇧↩</kbd> | 临时关掉顶栏，换回常显的系统菜单栏。再按一次（或重新加载 SketchyBar）换回来 |

## 固定工作区

大多数应用的新窗口开在当前工作区。少数几个有固定的工作区：

| 应用 | 工作区 |
|---|---|
| Microsoft Edge | 1，平铺 |
| iTerm2、kitty、终端 | 5 |
| 微信 | 10 |
| 用 ⌃S W 记住的应用 | 记住的那个 |

- 这些应用没有窗口时被激活（比如从 Dock 打开），会先切到它的工作区，新窗口不会先在当前工作区闪一下。之后的新窗口也会带你过去。
- 在 ⌥⇥、⌘⇥ 或 ⌘Space 列表里选它们，也会先切到它们的工作区再打开。
- 从 Dock、通知或链接激活任何应用时，如果它在当前工作区没有窗口，就会带你去它最近用的窗口。macOS 设置里"切换应用时跳到它窗口所在的空间"那一项虽然关着，点一次 Dock 也就够了。

写死的这几条在 [`yabai/yabairc`](yabai/yabairc) 里。

## 顶栏

仿照 i3 polybar 样式的 SketchyBar 顶栏（One Dark，Maple Mono NF），和菜单栏一样高（24 pt），一样是毛玻璃。鼠标移到屏幕最上面会出现系统菜单栏。

**左边**

-  菜单，就是真正的 macOS 菜单：关于本机、系统设置、App Store、睡眠、重新启动、关机、锁定屏幕、退出登录。重新启动、关机和退出登录会先确认。
- 工作区 1 … 10 和 Z … T，上面是各自的应用图标，点一下就切过去。空的字母工作区只在你待在那里时显示。
- skhd 模式（RESIZE / SERVICE），然后是当前应用和窗口标题。

**右边**

- 主题开关：彩色或黑白图标。警告色保持黄 / 红，面板保持彩色。
- GPU（Apple Silicon）和 CPU，各有曲线和百分比；然后是内存、磁盘（已用，算法和访达一样）。
- 网速、输入法（中 / EN）、音量（滚轮调）、电池（80 % 以上绿、30 % 起黄、更低红），以及按系统语言显示的日期时间（10月7日 週三 13:55）。

点右边任一项打开详情面板，再点一次或移开就关掉。面板标题里的 ↗ 打开对应的应用或设置页。

| 面板 | 内容 |
|---|---|
| GPU、CPU | 更长的历史曲线。CPU 还列出前 5 个进程 |
| 内存、磁盘 | 用量条和明细。内存还列出前 5 个进程 |
| 网络 | IP、路由器、Wi-Fi 信号、速率和信道 |
| 音量 | 当前输出设备的音量滑块，静音 |
| 电池 | 健康度、循环次数、温度 |
| 时钟 | 农历、周数 |

和系统的自动隐藏菜单栏一样，顶栏在窗口下面：平铺的窗口让开它，浮动的窗口可以盖住它。

<details>
<summary>实现</summary>

配置在 [`sketchybar/`](sketchybar)。GPU、CPU、内存、磁盘、网络、输入法和面板内容来自 `aero-helper bar-stats`（[`yabai/helper/bar.swift`](yabai/helper/bar.swift)）；前 5 个进程只在面板开着时才算。

背景是 `aero-helper bar-backdrop`（[`yabai/helper/backdrop.swift`](yabai/helper/backdrop.swift)）。和真正的菜单栏一样，它显示壁纸顶部、重度模糊再稍微压暗，后面的窗口透不过来。它只在普通桌面上，所以跟着桌面一起滑动，不会盖住原生全屏的应用（视频、幻灯片）。没有用原生全屏、但铺满整个屏幕的窗口（比如 PowerPoint 放映）会直接盖住它。

SketchyBar 自带的 `blur_radius` 在 macOS 15 上不起作用。macOS 15 还对没有定位权限的应用隐藏 Wi-Fi 名称，所以网络项显示的是连接类型。

</details>

## 瞬间切换

没有 yabai 的脚本扩展时，切换工作区有 macOS 的滑动动画，⌥T 和 ⌥⇧⇥ 也用不了。脚本扩展要部分关闭 SIP：

1. 在恢复模式里运行 `csrutil enable --without fs --without debug --without nvram`。
2. 运行 [`yabai/setup-sa`](yabai/setup-sa)，它要求时就重启。

加载之后，缺的桌面会自动补齐。每次升级 yabai 后要再运行一次 `setup-sa`。在 macOS 15 上它还会给 yabai 的加载器打补丁，让它能注入 Dock（[yabai#2686](https://github.com/asmvik/yabai/issues/2686)）。

## 排错

- `yabai/aero status` 显示快捷键模式、脚本扩展有没有加载，以及每个桌面对应的工作区和窗口数。
- ⌥⇧ 移窗口失败会记在 `/tmp/yabai-aero-$USER/aero.log`。
- ⌃S Esc 重新加载配置。

## 文件

| 路径 | 内容 |
|---|---|
| [`install.sh`](install.sh) | 安装脚本 |
| [`yabai/yabairc`](yabai/yabairc) | yabai 配置：规则、固定工作区、信号 |
| [`yabai/aero`](yabai/aero) | 快捷键调用的工作区和窗口命令 |
| [`yabai/helper/`](yabai/helper) | aero-helper（Swift）：切换列表、顶栏数据和背景 |
| [`yabai/setup-sa`](yabai/setup-sa) | 脚本扩展的安装 |
| [`skhd/`](skhd) | 快捷键 |
| [`sketchybar/`](sketchybar) | 顶栏 |
| [`window_switcher`](window_switcher) | ⌥⇥、⌘⇥ 和 ⌘Space |

这里的其它文件夹（`kitty/`、`nvim/`、`aerospace/`）是独立的配置，安装脚本不碰它们。
