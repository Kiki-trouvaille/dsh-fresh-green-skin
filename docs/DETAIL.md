# 清新白绿皮肤（Fresh Green Skin）

给 DSH Web 界面加一层“白绿清新”外观：青竹绿品牌色、半透明的面板，背后铺一张照片壁纸（默认是阿尔卑斯草甸），并在 **设置 → 通用 → 壁纸** 里提供**上传自己的图片**和**透明度滑块**。

## 组成

- **主题 token**：通过 Client `theme` 服务的 `overrideTokens('dsh-fresh-green-skin', …)` 覆盖，浅色/深色两套同时给出，“跟随系统 / 深色模式”照常生效。
  - 背景：`--dsw-alias-bg-base` 设为完全透明，让壁纸真正铺满窗口；卡片层 `bg-layer-1/2/3` 保持 0.72–0.92 的白/暗绿，正文有底。
  - 品牌色：`--dsw-alias-brand-primary`、`state-business-primary`、`state-success-primary` → `#2e8b57`（深色 `#7ed7a6`、`#6fcf97`）。
  - 边框与文字：`border-l1/l2/l3` 带绿调，`label-primary` 墨绿 `#0f1c14`。
  - 侧边栏：`--dsw-specific-sidebar-fill` 半透明薄荷白。
- **壁纸**：`body[data-fresh-skin='on']` 的 `background-image` = 一层纯色遮罩 + 照片，`cover` + `fixed` 铺满视口。遮罩 alpha 由 `--fgw-veil`（浅色）/ `--fgw-veil-dark`（深色）驱动，滑块实时改这两个变量。透明度 0% 时遮罩完全透明，照片原样显示。
- **设置项**：注册到 `settings.general.item`（id `fresh-green-wallpaper`，order 20），在 **设置 → 通用** 里显示“壁纸”一行：
  - 缩略图（当前壁纸）
  - “透明度”滑块 0–100%（默认 34%）
  - “上传图片”（`<input type=file accept="image/*">`，选中后用 canvas 缩到最长边 1920、转 JPEG 0.86）
  - “恢复默认”
- **持久化**：`localStorage`（`fresh-green-skin:wallpaper`、`fresh-green-skin:veil`），只作用于当前浏览器 origin，不写 Host 配置、不跨设备同步。滑块拖动时只重写 veil 字段，避免每次重写大字符串。

## 文件

| 文件 | 作用 |
| --- | --- |
| `client.js.tpl` | 可读模板（token、CSS、设置行组件），含 `__WALL_B64__` 占位符 |
| `client.js` | 由模板 + 默认壁纸生成，实际被加载（约 215 KB，不要手改） |
| `assets/wallpaper-src.png` | 默认壁纸原图 |
| `assets/wallpaper.webp` | 压好的 WebP（q78，约 152 KB） |
| `tools/build-client.py` | 把 WebP 编码进 `client.js` |
| `screenshot/` | README 用的效果图 |

## 换默认壁纸（改插件自带那张）

1. 覆盖 `assets/wallpaper-src.png`。
2. 在插件目录运行 `python tools/build-client.py`（需要 Python 3 和 Pillow）。
3. `Ctrl+R` 刷新；若本机已存过自定义壁纸，先在设置里点“恢复默认”。

日常换图不用改文件：直接在 **设置 → 通用 → 壁纸 → 上传图片**。

## 关闭 / 卸载

- 插件管理里停用或移除 `dsh-fresh-green-skin`，壁纸、配色、设置项一起消失。
- 只想关壁纸、保留配色：`client.js.tpl` 里删掉 `ctx.effect(mountStyle, …)`，重新生成。

## 备注

- 不注册新的 `ThemeDefinition`，“设置 → 通用 → 外观”仍是浅色/深色/跟随系统三档。
- 透明度越高，照片越淡、正文越稳；默认 34% 是“照片看得清、文字也能读”的折中。
- 深色模式正文是浅色字，照片很亮时对比度会下降，建议保留 40% 以上。
- 若 DSH 以后改了 token 名，未识别的变量会被忽略，不报错。
