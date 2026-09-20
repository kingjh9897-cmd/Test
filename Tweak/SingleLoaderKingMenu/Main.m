#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface KMRoot : NSObject
@property(nonatomic,strong) UIButton *button;
@property(nonatomic,strong) UIView *panel;
@end

@implementation KMRoot

+ (instancetype)shared {
    static KMRoot *obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ obj = [KMRoot new]; });
    return obj;
}

- (UIWindow *)window {
    UIApplication *app = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) if (w.isKeyWindow) return w;
            for (UIWindow *w in ws.windows) if (!w.hidden && w.alpha > 0.01) return w;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (app.keyWindow) return app.keyWindow;
    for (UIWindow *w in app.windows) if (!w.hidden && w.alpha > 0.01) return w;
#pragma clang diagnostic pop
    return nil;
}

- (UIColor *)accent { return [UIColor colorWithRed:1.0 green:0.55 blue:0.05 alpha:1.0]; }

- (void)install {
    if (self.button) return;
    UIWindow *w = [self window];
    if (!w) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self install]; });
        return;
    }

    CGFloat size = 58.0;
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    self.button = b;
    b.frame = CGRectMake(MAX(8.0, CGRectGetWidth(w.bounds)-size-16.0), MAX(90.0, CGRectGetHeight(w.bounds)*0.36), size, size);
    b.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    b.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.97];
    b.layer.cornerRadius = size/2.0;
    b.layer.borderWidth = 2.0;
    b.layer.borderColor = [self accent].CGColor;
    [b setTitle:@"K" forState:UIControlStateNormal];
    [b setTitleColor:[self accent] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:25.0];
    [b addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
    [w addSubview:b];
}

- (void)toggle {
    UIWindow *w = [self window];
    if (!w) return;
    if (!self.panel) {
        UIView *p = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,230)];
        self.panel = p;
        p.center = CGPointMake(CGRectGetMidX(w.bounds), CGRectGetMidY(w.bounds));
        p.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        p.backgroundColor = [UIColor colorWithWhite:0.055 alpha:0.98];
        p.layer.cornerRadius = 20.0;
        p.layer.borderWidth = 1.0;
        p.layer.borderColor = [self accent].CGColor;

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20,18,240,32)];
        title.text = @"KingMenu";
        title.textColor = [self accent];
        title.font = [UIFont boldSystemFontOfSize:24.0];
        [p addSubview:title];

        UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(20,58,280,60)];
        sub.text = @"Eigene Tweak\nKeine Werbung • kein PRO-System";
        sub.numberOfLines = 2;
        sub.textColor = UIColor.whiteColor;
        sub.font = [UIFont systemFontOfSize:15.0];
        [p addSubview:sub];

        UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
        close.frame = CGRectMake(20,155,280,48);
        close.backgroundColor = [[self accent] colorWithAlphaComponent:0.16];
        close.layer.cornerRadius = 12.0;
        [close setTitle:@"Schließen" forState:UIControlStateNormal];
        [close setTitleColor:[self accent] forState:UIControlStateNormal];
        close.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        [close addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [p addSubview:close];
        [w addSubview:p];
    } else {
        self.panel.hidden = NO;
    }
    [w bringSubviewToFront:self.panel];
    [w bringSubviewToFront:self.button];
}

- (void)hide { self.panel.hidden = YES; }

@end

__attribute__((constructor))
static void KingMenuInit(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[KMRoot shared] install];
    });
}

// The working libloader exports this exact symbol and forwards the app start to UIApplicationMain.
__attribute__((visibility("default")))
int KingAppEntry(int argc, char **argv, NSString *principalClassName, NSString *delegateClassName) __asm__("iBWuJnPubwtWJIGVxT");

int KingAppEntry(int argc, char **argv, NSString *principalClassName, NSString *delegateClassName) {
    return UIApplicationMain(argc, argv, principalClassName, delegateClassName);
}
