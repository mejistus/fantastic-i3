#!/bin/bash
# fantastic-i3 主题依赖一键安装
# 跑法：bash ~/Documents/fantastic-i3/install.sh（全程 yay，装包时会问 sudo 密码）
# 装完按 THEME.md 做配置映射 + 重载
set -u
cd "$(dirname "$0")"

echo "=== [1/2] AUR 包（Tahoe 家族 + Maple + 微信输入法皮肤） ==="
AUR_PKGS="mactahoe-gtk-theme mactahoe-icon-theme-git mactahoe-cursor-theme-git mactahoe-plasma-theme-git ttf-maple otf-apple-pingfang fcitx5-theme-wechat"
# shellcheck disable=SC2086
yay -S --needed --noconfirm $AUR_PKGS

echo "=== [2/2] 仓库包（Qt/输入法/栏/通知/字体/密钥环） ==="
REPO_PKGS="kvantum qt5ct qt6ct fcitx5 fcitx5-qt fcitx5-gtk fcitx5-configtool fcitx5-chinese-addons rofi kitty polybar xsettingsd clipit nwg-look dunst gnome-keyring inter-font noto-fonts noto-fonts-cjk ttf-dejavu"
# shellcheck disable=SC2086
yay -S --needed --noconfirm $REPO_PKGS

echo "=== DONE ==="
echo "下一步：按 THEME.md「文件映射」把本仓库配置拷到家目录，再按「改后重载」执行。"
echo "注意：/etc/environment 的 QT_QPA_PLATFORMTHEME 与 /root 的 GTK 配置需手动 sudo 处理，见 THEME.md。"
