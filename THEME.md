# 主题仓库（2026-09-24 快照）：macOS Tahoe 深色统一

目标：i3/X11 下 GTK2/3/4 + Qt5/6 + fcitx5 + rofi 全暗色 Tahoe 风。

## 上游来源（本仓库不收二进制，只收配置）

| 组件 | 上游 | 包 |
|---|---|---|
| GTK 主题 | vinceliuice/MacTahoe-gtk-theme | AUR `mactahoe-gtk-theme`（只要 `-Dark-solid` 变体） |
| Kvantum 主题 | vinceliuice/MacTahoe-kde `Kvantum/` | AUR `mactahoe-plasma-theme-git`（本仓库已收一份 `Kvantum/MacTahoe/`） |
| 图标/光标 | vinceliuice/MacTahoe-icon-theme | AUR `mactahoe-icon-theme-git`（已装，未启用，见下） |
| fcitx5 基准主题 | 系统 `/usr/share/fcitx5/themes/wechat-dark` | fcitx5 自带 |
| rofi 主题 | lr-tech/rofi-themes-collection（spotlight-dark 改 Inter 字体） | 手工改 |

## 本仓库自制（含）

- `fcitx5/themes/wechat-dark-menu/`：wechat-dark 的面板原样保留，`[Menu*]` 六处改暗（底 `#2d2d2d`、高亮微信绿 `#07c160`）。因原版菜单白底白字高亮不可读。

## 文件映射（仓库 → 家目录）

```
Kvantum/kvantum.kvconfig            → ~/.config/Kvantum/kvantum.kvconfig
Kvantum/MacTahoe/                   → ~/.config/Kvantum/Themes/MacTahoe/
qt5ct/qt5ct.conf                    → ~/.config/qt5ct/qt5ct.conf
qt6ct/qt6ct.conf                    → ~/.config/qt6ct/qt6ct.conf
rofi/themes/spotlight-dark.rasi     → ~/.config/rofi/themes/spotlight-dark.rasi
gtk-3.0/settings.ini                → ~/.config/gtk-3.0/settings.ini
gtk-4.0/settings.ini                → ~/.config/gtk-4.0/settings.ini
gtk-2.0/gtkrc-2.0                   → ~/.gtkrc-2.0
xsettingsd/xsettingsd.conf          → ~/.config/xsettingsd/xsettingsd.conf
fcitx5/conf/classicui.conf          → ~/.config/fcitx5/conf/classicui.conf
fcitx5/themes/wechat-dark-menu/     → ~/.local/share/fcitx5/themes/wechat-dark-menu/
fontconfig/fonts.conf               → ~/.config/fontconfig/fonts.conf（已一致，monospace=Maple）
kitty/kitty.conf                    → ~/.config/kitty/kitty.conf（font Maple Mono）
```

## 需要 sudo 的系统侧（仓库不收，手动做）

```bash
# Qt 走 qt6ct（/etc/environment）
QT_QPA_PLATFORMTHEME=qt6ct
# root 的 GTK（给 timeshift 等）：/root/.config/gtk-{3,4}.0/settings.ini 同样写 MacTahoe-Dark-solid
# GNOME keyring / icon 主题等见各节
```

## 改后重载（免注销清单）

```bash
pkill -HUP xsettingsd          # XSETTINGS 广播重载（nwg-look 改完必须做，否则只落盘不生效）
fcitx5-remote -r               # 输入法主题热重载；换主题名则需重启 fcitx5
i3-msg reload                  # i3 相关
# Qt 程序重开才吃新配置；改 /etc/environment 必须重登录
```

## 已知坑

1. `MacTahoe-Dark`（非 solid）盘上不存在，GTK 指向它会回退亮色 Adwaita——必须用 `MacTahoe-Dark-solid`。
2. Kvantum 1.x 无 Qt5 后端，Qt5 老程序回退 Fusion，无解（`kvantum-qt5-git` 已无人维护）。
3. `~/.gtkrc-2.0` 头写着会被 nwg-look 覆盖，点了 Apply 要重改。
4. 图标 `breeze` / 光标 `breeze_cursors` 尚未切 Tahoe（包已装），切完要重登录。
5. 本仓库其他文件（如 ZSHRC）含私钥 token，公开前必须清理。
