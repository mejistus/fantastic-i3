import os
config.load_autoconfig()

# ========== 常规设置 ==========
c.auto_save.session = True # 自动保存会话
c.downloads.location.directory = os.path.expanduser('~/Downloads')  # 下载目录
c.downloads.location.prompt = False  # 下载时不询问位置
c.editor.command = ['nvim', '-f', '{file}']  # 编辑器的命令

# ========== 外观设置 ==========
c.colors.webpage.darkmode.enabled = False # 启用暗黑模式
c.fonts.default_family = 'Noto Sans CJK SC'  # 默认字体
c.fonts.default_size = '12pt'

# 标签栏设置
c.tabs.position = 'top'
c.tabs.show = 'multiple'
c.tabs.title.format = '{audio}{current_title}'

# ========== 内容设置 ==========
c.content.javascript.enabled = True  # 启用 JavaScript
c.content.pdfjs = True  # 使用内置 PDF 查看器
c.content.geolocation = False  # 禁用地理位置

# ========== 搜索引擎 ==========
c.url.searchengines = {
    'DEFAULT': 'https://www.google.com/search?q={}',
    # 'd': 'https://duckduckgo.com/?q={}',
    # 'w': 'https://en.wikipedia.org/wiki/Special:Search/{}',
    # 'gh': 'https://github.com/search?q={}',
}

# ========== 快捷键绑定 ==========
config.bind('M', 'hint links spawn mpv {hint-url}')  # Alt+m 用 mpv 播放视频
config.bind('xb', 'config-cycle statusbar.show always never')  # 切换状态栏显示
config.bind('xt', 'config-cycle tabs.show always never')  # 切换标签栏显示

# ========== 隐私设置 ==========
c.content.cookies.accept = 'no-3rdparty'  # 仅接受首方 Cookie
c.content.headers.user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'

# ========== 高级设置 ==========
c.qt.highdpi = True  # 启用 HiDPI 支持
# c.url.start_pages = ['https://www.google.com']  # 启动页面

# 统一 Alt 键作为全局修饰键示例
# ========== 标签页管理快捷键 (Alt 修饰键) ==========

# 切换标签页
config.bind('<Alt+Left>', 'tab-prev')
config.bind('<Alt+Right>', 'tab-next')
config.bind('<Alt+j>', 'tab-prev')
config.bind('<Alt+k>', 'tab-next')
config.bind('<Alt+1>', 'tab-focus 1')
config.bind('<Alt+2>', 'tab-focus 2')
config.bind('<Alt+3>', 'tab-focus 3')
config.bind('<Alt+4>', 'tab-focus 4')
config.bind('<Alt+5>', 'tab-focus 5')
config.bind('<Alt+6>', 'tab-focus 6')
config.bind('<Alt+7>', 'tab-focus 7')
config.bind('<Alt+8>', 'tab-focus 8')
config.bind('<Alt+9>', 'tab-focus 9')
config.bind('<Alt+0>', 'tab-focus -1')  # 切换到最后一个标签页

# 新建/关闭标签页
config.bind('<Alt+t>', 'open -t')  # 新建标签页
config.bind('<Alt+w>', 'tab-close')  # 关闭当前标签页

# 移动标签页
config.bind('<Alt+Shift+Left>', 'tab-move -')
config.bind('<Alt+Shift+Right>', 'tab-move +')
config.bind('<Alt+Shift+j>', 'tab-move -')
config.bind('<Alt+Shift+k>', 'tab-move +')

# 固定标签页
config.bind('<Alt+p>', 'tab-pin')

# 恢复关闭的标签页
config.bind('<Alt+Shift+w>', 'undo')

# 标签页静音
config.bind('<Alt+m>', 'tab-mute')

# 绑定快捷键临时禁用 f 键（进入 passthrough 模式）
config.bind('<Ctrl+Shift+p>', 'mode-enter passthrough', mode='normal')  # 进入穿透模式
config.bind('<Escape>', 'mode-leave', mode='passthrough')  # 按 Esc 退出穿透模式

config.bind(';;', 'spawn --userscript blur-page')
