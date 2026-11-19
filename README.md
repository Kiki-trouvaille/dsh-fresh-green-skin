# 清新白绿皮肤（Fresh Green Skin）

给 DSH Web 界面加一层“白绿清新”外观：青竹绿品牌色、半透明的面板，背后铺一张 4K 照片壁纸（默认「山舍晴暮」）。壁纸以画廊形式出现，点缩略图即可切换，也可以**上传自己的图片**、用**透明度滑块**决定壁纸露多少。

![浅色模式](screenshot/light.jpg)

## 特性

- 浅色 / 深色 / 跟随系统 三档照常可用，两套配色同时覆盖。
- **壁纸画廊**：设置行左侧的缩略图直接点选；内置壁纸随插件加载（4K 照片以 AVIF 内联，约 713 KB），不联网、不依赖外部图床。
- **透明度 0% = 壁纸完全显示，100% = 壁纸完全遮住**，拖动即时生效；Windows 下应用外框也会真正让位给壁纸。
- **上传图片**：任意 JPG/PNG/WebP，自动缩到最长边 1920 并转成 JPEG 存储，避免体积过大。
- 偏好存在浏览器 `localStorage`，不写 Host 配置，也不跨设备同步。

| 设置项（壁纸画廊） | 深色模式 |
| --- | --- |
| ![设置项](screenshot/settings.jpg) | ![深色模式](screenshot/dark.jpg) |

## 安装

需要支持 client 插件（`dsh.client`）的 DSH Web 版本。

### 方式一：从 GitHub 安装（推荐）

打开侧栏 **插件 → 添加插件**，把仓库地址填进输入框：

```
https://github.com/Kiki-trouvaille/dsh-fresh-green-skin
```

安装完成后点 **立即启用**（或到插件列表里打开），然后 `Ctrl+R` 刷新页面。

### 方式二：本地目录

1. 下载本仓库（Code → Download ZIP 后解压，或 git clone https://github.com/Kiki-trouvaille/dsh-fresh-green-skin.git）。
2. **插件 → 添加插件 → 本地目录**，选择解压出来的文件夹（含 `package.json` 的那一层）。
3. 启用后 `Ctrl+R`。

### 方式三：压缩包

把仓库打成的 `.zip` 直接拖进 **添加插件**（或填绝对路径），效果同方式二。

## 使用

- **换壁纸**：设置 → 通用 → 壁纸 → 点左侧缩略图选内置壁纸，或 **上传图片** 用自己的一张。
- **调透明度**：同一行的滑块；0% 看整张照片，100% 只剩配色。
- **回到默认壁纸**：**恢复默认**（回到第一张内置壁纸 + 默认透明度）。
- 卸载：插件列表里移除 `dsh-fresh-green-skin`，配色、壁纸、设置项一起消失。

## 内置壁纸 / 二次开发

壁纸清单在 `assets/presets/manifest.json`：`file` 指向 `assets/presets/` 里的图片，`css` 则是一段纯 CSS 渐变；**数组第一项就是默认壁纸**。目前清单里只有一张 4K 照片：

```json
[
  { "id": "meadow", "label": "山舍晴暮", "file": "meadow.jpg" }
]
```

加一张内置壁纸：把图片放进 `assets/presets/`，在 manifest 里加一条（可以让 `file` 指向照片，也可以用 `css` 写纯渐变），重新生成 `client.js`（需要 Python 3 + Pillow）：

```bash
python tools/build-client.py
```

脚本会：读 manifest 里每张图片 → 超过 3840 宽才缩 → 压成 AVIF q60（Pillow 不带 AVIF 时回落 WebP q82）→ 以 `url("data:image/avif;base64,…")` 的形式把整份清单注入 `client.js.tpl` 的 `__PRESETS__` → 写出 `client.js`（默认那张同时另存为 `assets/wallpaper.avif`）。
4K 原图不缩、质量给足的代价是 bundle 变大：现在 `client.js` 约 964 KB，其中壁纸约 713 KB。

`client.js` 是生成物，改逻辑请改 `client.js.tpl`。改完跑一遍离线冒烟测试（不需要浏览器）：它会用一套假的 DSH 客户端加载 `client.js`，检查服务注入、token 覆盖、设置行注册，并把“壁纸”那一行**真的渲染一次**——渲染报错是这里唯一会静默失败的环节（设置里的整行会直接消失）。

```bash
node tools/smoke-test.cjs
```

## 兼容性

- 只作用于 Web 端（`dsh.client.platform: 'web'`）。
- 通过 `theme.overrideTokens()` 覆盖 token，未识别的 token 名会被忽略，不会报错；DSH 改版后若某些颜色不再生效，对照 `client.js.tpl` 的 `TOKENS` 补名字即可。
- 壁纸能透到内容区的前提是 Windows 下应用外框用的是 `--dsw-specific-sidebar-fill`：本插件把它设成全透明，再用 `[class*='_sidebarCol']` 给侧栏单独补一层霜白。若某个 DSH 版本改了类名，侧栏会跟着变透明，其余不受影响。
- 深色模式下正文是浅色字，透明度拉得很低（照片很亮）时对比度会下降，建议深色模式保留 40% 以上。

## 许可

MIT
