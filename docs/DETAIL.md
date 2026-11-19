# 清新白绿皮肤（Fresh Green Skin）· 细节

给 DSH Web 界面加一层“白绿清新”外观：青竹绿品牌色、半透明的面板，背后铺一张壁纸（默认 4K 照片「山舍晴暮」）。壁纸也可以是自己的图片或一段循环视频；配色可以跟着壁纸走，也可以自己挑；满意的组合可存成命名主题并用快捷键切换。

## 组成

- **主题 token**：通过 Client `theme` 服务 `overrideTokens('dsh-fresh-green-skin', …)` 覆盖，浅/深两套同时给出，“跟随系统 / 深色模式”照常生效。
  - 背景：`--dsw-alias-bg-base` 完全透明，让壁纸铺满内容区；卡片层 `bg-layer-1/2/3` 保持 0.72–0.92 的白/暗绿，正文有底。
  - 外框：Windows 下应用框（`[data-windows-titlebar] .frame`）用 `--dsw-specific-sidebar-fill` 画，所以这个 token 也设成全透明；侧栏霜白改由 `body[data-fresh-skin='on'] [class*='_sidebarCol']` 单独补（CSS Modules 哈希前缀会变，`_sidebarCol` 后缀稳定）。
  - 品牌色：`brand-primary` / `state-business-primary` / `state-success-primary`；边框 `border-l1/l2/l3` 带绿调；文字 `label-primary/secondary/tertiary`。
  - **按壁纸取色**（`palette: 'image'`）时，用 canvas 把壁纸缩到 24×16 取平均色与亮度，推出一套主色 / 深色主色 / 气泡 / 文字色替换上面的品牌与文字 token；**自定义**（`palette: 'custom'`）则直接用用户挑的四个颜色覆盖主色、气泡（layer-2/3）、文字，侧栏走 `--fgw-sidebar`。
- **壁纸**：`body[data-fresh-skin='on']` 的 `background-image` = 一层纯色遮罩 + `--fgw-image`（`url("data:image/avif;base64,…")` 或纯 CSS 渐变），`cover` + `fixed` 铺满视口。遮罩 alpha 由 `--fgw-veil`（浅色）/ `--fgw-veil-dark`（深色）驱动。透明度 0% 时遮罩全透明，照片原样显示。
- **动态壁纸**：视频以 Blob 存进 IndexedDB（库 `fresh-green-skin`，store `media`，键 `video`），播放时插入 `<video class="fgw-video">`（`position: fixed`、`z-index: -2`、静音循环）与 `.fgw-video-veil`（`z-index: -1`）。此时 `body` 背景置透明、`<html>` 上底色 `#08120c`，视频才不会被 body 背景盖住。
- **自适应蒙版**：勾「跟随壁纸自动」时，`veil = clamp(0.7 − 平均亮度 × 0.55, 0.26, 0.74)`——亮的照片蒙得多、暗的照片蒙得少。
- **字体**：`--fgw-font` 写到 `body` 的 `font-family`，选项见 `FONTS`（默认 / 黑体 / 宋体 / 楷体 / 衬线英文 / 等宽）；默认值 `inherit` 保持 DSH 原样。
- **设置项**：注册到 `settings.general.item`（id `fresh-green-wallpaper`，order 20），分五行：
  1. 壁纸：画廊缩略图（内置图 / “我的图片” / “视频”块）+ 上传图片 / 上传视频 / 恢复默认
  2. 透明度：滑块 0–100%（默认 34%）+「跟随壁纸自动」
  3. 配色：默认绿 / 跟随壁纸 / 自定义 + 主色 / 侧栏 / 气泡 / 文字四个取色器
  4. 字体：下拉选择
  5. 主题：名字输入 + 保存主题 + 已存主题按钮（`⌃⌥n` 提示）+ `×` 删除
- **快捷键**：`Ctrl+Alt+1…9` 应用第 n 套已存主题，`Ctrl+Alt+0` 恢复默认（`installShortcuts` 里监听 keydown，忽略带 Shift 的组合）。
- **持久化**：
  - `fresh-green-skin:state`：`{ source, veil, autoVeil, palette, colors, font }`；`source` 为 `{kind:'preset',id}` / `{kind:'image',src}` / `{kind:'video',name}`，图片是 data URI。
  - `fresh-green-skin:themes`：`[{ name, value }]`，`value` 是上一条去掉视频外的一切（视频主题只记名字，播的还是上传的那段视频）。
  - 旧版键（`fresh-green-skin:wallpaper`、`fresh-green-skin:veil`）在首次读取时自动迁移。
  - 视频二进制在 IndexedDB，不占 localStorage 配额。
- **渲染顺序/防崩**：`apply()` 里 `ctx.effect(mountDom)` 注入样式并立即 `applyState`；`applyTokens()` 每次先 dispose 旧的 `overrideTokens` 再注册，避免叠加；取色是异步的，拿到结果后只在 `autoVeil` 或 `palette==='image'` 时重绘。

## 文件

| 文件 | 作用 |
| --- | --- |
| `client.js.tpl` | 可读模板（token、CSS、设置行组件、IndexedDB、快捷键），含 `__PRESETS__` 占位符 |
| `client.js` | 由模板 + 壁纸清单生成，实际被加载（约 985 KB，含内联壁纸，不要手改） |
| `assets/presets/manifest.json` | 内置壁纸清单：`file` 指向图片，`css` 为纯 CSS 渐变；**第一项是默认壁纸**（当前只有一张：山舍晴暮） |
| `assets/presets/meadow.jpg` | 默认壁纸原图（2730×1536，1.2 MB） |
| `assets/wallpaper.avif` | 默认照片压好的 AVIF（q60，约 713 KB，由脚本另存） |
| `tools/build-client.py` | 读清单、压图（AVIF q60，超过 3840 宽才缩）、把清单注入模板，生成 `client.js` |
| `tools/smoke-test.cjs` | 离线冒烟测试（假 DSH 客户端 + 真渲染设置行） |
| `screenshot/` | README 用的效果图 |

## 加一张内置壁纸

1. 把图片放进 `assets/presets/`。
2. 在 `assets/presets/manifest.json` 里加一条 `{ "id": "...", "label": "显示名", "file": "xxx.png" }`（第一项即默认）。
3. 在插件目录运行 `python tools/build-client.py`（需要 Python 3 和 Pillow）。
4. `node tools/smoke-test.cjs` 检查一遍。
5. `Ctrl+R` 刷新。

日常换图不用改文件：**设置 → 通用 → 壁纸** 里点缩略图、上传图片或上传视频。

## 关闭 / 卸载

- 插件管理里停用或移除 `dsh-fresh-green-skin`，壁纸、配色、设置项一起消失。
- 想清掉本机存过的图/视频：浏览器控制台执行 `localStorage.removeItem('fresh-green-skin:state'); localStorage.removeItem('fresh-green-skin:themes'); indexedDB.deleteDatabase('fresh-green-skin')`。

## 没做的部分

- 新会话页大鲸鱼图标、`DeepSeek Harness` 字样、输入框上方插件快捷图标：宿主没开放对应 slot/图标 API，插件无法安全替换，硬改 class 会在升级后失效。等宿主提供插槽再补。

## 备注

- 不注册新的 `ThemeDefinition`，“设置 → 通用 → 外观”仍是浅色/深色/跟随系统三档。
- 透明度越高照片越淡、正文越稳；默认 34% 是“照片看得清、文字也能读”的折中。
- 深色模式正文是浅色字，照片很亮时对比度会下降，建议保留 40% 以上或勾「跟随壁纸自动」。
- 若 DSH 以后改了 token 名或侧栏类名，未识别的部分会被忽略，不报错。
