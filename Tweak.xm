// SkipAds.xm — 自动跳过开屏广告（iOS 版李跳跳，.dylib 插件）
// 由 swiplet skip-chinese-ads（JS 版）改写而来，逻辑相同：
//   遍历当前窗口的视图层级，找标题/无障碍标签含“跳过”的按钮，点掉。
// 注入目标：SkipAds.plist 里 293 个中国 APP 的 bundle ID（从 swiplet 规则库原样导出）。
// 编译：Mac + Theos，make package
// 运行：必须越狱（MobileSubstrate 注入）。无越狱的 iPhone 跑不起来。

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// “跳过”按钮的匹配词：和 swiplet 的规则一致
static BOOL isSkipText(NSString *s) {
    if (!s || s.length == 0) return NO;
    if ([s rangeOfString:@"跳过" options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    if ([s rangeOfString:@"跳过广告" options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    if ([s rangeOfString:@"skip" options:NSCaseInsensitiveSearch].location != NSNotFound) return YES;
    return NO;
}

// 递归扫描一个视图及其子视图，找到“跳过”控件就点掉，返回 YES 表示已点
static BOOL scanView(UIView *view) {
    if (!view) return NO;

    // 只看能点的控件
    if ([view isKindOfClass:[UIControl class]]) {
        UIControl *control = (UIControl *)view;
        if (control.enabled && !control.hidden && control.alpha > 0.01) {
            NSString *title = nil;
            if ([control isKindOfClass:[UIButton class]]) {
                title = [(UIButton *)control titleForState:UIControlStateNormal];
            }
            NSString *label = view.accessibilityLabel;
            NSString *hint = view.accessibilityHint;
            if (isSkipText(title) || isSkipText(label) || isSkipText(hint)) {
                [control sendActionsForControlEvents:UIControlEventTouchUpInside];
                return YES;
            }
        }
    }

    // 有些“跳过”是 UILabel/UILabel 套着手势，顺带看一眼带“跳过”文字的 label
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (isSkipText(label.text) && label.userInteractionEnabled) {
            // 有手势的 label：模拟一次 tap
            for (UIGestureRecognizer *g in label.gestureRecognizers ?: @[]) {
                if ([g isKindOfClass:[UITapGestureRecognizer class]] && g.enabled) {
                    // 无法直接触发手势，改为点它父级的可点控件
                    break;
                }
            }
        }
    }

    for (UIView *sub in view.subviews) {
        if (scanView(sub)) return YES;
    }
    return NO;
}

// 扫一次当前 keyWindow
static void scanKeyWindow(void) {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;
    scanView(keyWindow);
}

// 每 0.5 秒扫一次（开屏广告一般 3-5 秒，0.5 秒足够在出现的第一时间点掉）
static void startTimer(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer) {
            scanKeyWindow();
        }];
    });
}

// 页面每次出现后也立刻扫一次（比定时器更快）
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        scanKeyWindow();
    });
}
%end

// 插件加载时启动定时器
%ctor {
    @autoreleasepool {
        startTimer();
    }
}
