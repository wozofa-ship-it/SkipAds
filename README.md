# SkipAds — 自动跳过开屏广告（iOS 版李跳跳）

APP 打开时出现开屏广告，插件自动找到“跳过”按钮并点掉。

## 它干什么

`Tweak.xm`（Logos 源码）：hook `UIViewController.viewDidAppear`，每 0.5 秒扫一次当前 keyWindow 的视图层级；找到标题/无障碍标签含“跳过”/“Skip”的按钮就点掉。

## 怎么装（LiveContainer，不越狱）

LiveContainer 的模块系统不读 MobileSubstrate 的过滤 plist，按文件夹决定注入哪个 App。装法：

1. 到 Actions 产物里下载 `SkipAds.dylib`（见下“编译”）。
2. LiveContainer → 模块页 → 新建文件夹 `SkipAds` → 点进去 → 导入 `SkipAds.dylib`。
3. 每个想开的 App：App 设置 → 模块文件夹 → 勾上 `SkipAds` → 重启这个 App。
4. 没勾的 App 不注入。想全开就每个 App 都勾一次；想关掉某个 App 就取消它的勾（或把 dylib 改名加 `.disabled` 后缀是全局关，不建议）。

注意：dylib 直接放在模块根目录会注入所有 App、且无法按 App 关；所以必须放在 `SkipAds` 文件夹里、按 App 勾选。

导入后 LiveContainer 会在启动客 App 前自动签名，dylib 本身不用提前签名。

## 关于过滤名单（SkipAds.plist）

老版有个 293 个中国 App bundle ID 的过滤 plist（从 swiplet 规则库导出），但源文件已丢失、找不回来，这里没有编造名单。本仓库不带 plist，原因：

- LiveContainer 的 TweakLoader 根本不读过滤 plist（代码实证：只按文件夹加载），plist 对这条路没用。
- 按 App 开关由上面的文件夹勾选实现，不需要名单。

越狱机走 deb 的话需要过滤 plist，自行补一份再 `make package`。

## 编译

push 到 main 即触发 GitHub Actions（macOS + Theos），产物是 `SkipAds.dylib`（Actions → Artifacts → `SkipAds-dylib` 下载）。

本地编译（Mac + Theos）：

```bash
make          # 只编 .dylib，在 .theos/obj/ 下
make package  # 打 deb（需要 control，越狱机用）
```

## 已知注意点

- 取 keyWindow 已改走 `connectedScenes`（老 `UIApplication.keyWindow` 在 iOS 13+ 已废弃，Theos 默认 `-Werror` 编不过；多场景 App 下老写法也可能取不到窗口）。
- 0.5 秒定时器 + `viewDidAppear` 后 0.3 秒各扫一次，开屏广告一般 3–5 秒，足够在出现的第一时间点掉。
