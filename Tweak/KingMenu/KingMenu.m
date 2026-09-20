#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface KMMenuController : NSObject
@property(nonatomic,strong) UIButton *button;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UILabel *statusLabel;
@end

@implementation KMMenuController

+ (instancetype)shared {
    static KMMenuController *obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ obj = [KMMenuController new]; });
    return obj;
}

- (UIWindow *)targetWindow {
    UIApplication *app = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
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
- (UIColor *)dark { return [UIColor colorWithRed:0.055 green:0.06 blue:0.07 alpha:0.97]; }

- (void)installWhenReady {
    if (self.button) return;
    UIWindow *w = [self targetWindow];
    if (!w) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self installWhenReady];
        });
        return;
    }

    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    self.button = b;
    CGFloat size = 58.0;
    CGFloat x = MAX(8.0, CGRectGetWidth(w.bounds) - size - 16.0);
    CGFloat y = MAX(90.0, MIN(CGRectGetHeight(w.bounds) - size - 40.0, CGRectGetHeight(w.bounds) * 0.36));
    b.frame = CGRectMake(x, y, size, size);
    b.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    b.backgroundColor = [self dark];
    b.layer.cornerRadius = size / 2.0;
    b.layer.borderWidth = 2.0;
    b.layer.borderColor = [self accent].CGColor;
    [b setTitle:@"K" forState:UIControlStateNormal];
    [b setTitleColor:[self accent] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:25.0];
    [b addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [w addSubview:b];
}

- (UIView *)rowWithTitle:(NSString *)title {
    UIView *row = [UIView new];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.055];
    row.layer.cornerRadius = 12.0;
    [row.heightAnchor constraintEqualToConstant:58.0].active = YES;

    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = title;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];

    UISwitch *sw = [UISwitch new];
    sw.translatesAutoresizingMaskIntoConstraints = NO;
    sw.onTintColor = [self accent];
    sw.accessibilityLabel = title;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

    [row addSubview:label];
    [row addSubview:sw];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16.0],
        [label.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [sw.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16.0],
        [sw.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-12.0]
    ]];
    return row;
}

- (void)buildPanelInWindow:(UIWindow *)w {
    if (self.panel) return;

    UIView *p = [UIView new];
    self.panel = p;
    p.translatesAutoresizingMaskIntoConstraints = NO;
    p.backgroundColor = [self dark];
    p.layer.cornerRadius = 22.0;
    p.layer.borderWidth = 1.0;
    p.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.12].CGColor;
    p.clipsToBounds = YES;
    [w addSubview:p];

    CGFloat maxWidth = MAX(280.0, CGRectGetWidth(w.bounds) - 28.0);
    CGFloat width = MIN(430.0, maxWidth);
    CGFloat maxHeight = MAX(330.0, CGRectGetHeight(w.bounds) - 50.0);
    CGFloat height = MIN(520.0, maxHeight);

    [NSLayoutConstraint activateConstraints:@[
        [p.centerXAnchor constraintEqualToAnchor:w.centerXAnchor],
        [p.centerYAnchor constraintEqualToAnchor:w.centerYAnchor],
        [p.widthAnchor constraintEqualToConstant:width],
        [p.heightAnchor constraintEqualToConstant:height]
    ]];

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"KingMenu";
    title.textColor = [self accent];
    title.font = [UIFont boldSystemFontOfSize:24.0];

    UILabel *sub = [UILabel new];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.text = @"Eigene Tweak • keine Werbung • kein PRO-System";
    sub.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    sub.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightMedium];
    sub.numberOfLines = 2;

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:[self accent] forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:22.0];
    [close addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10.0;

    UILabel *status = [UILabel new];
    self.statusLabel = status;
    status.text = @"Bereit";
    status.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    status.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];

    [stack addArrangedSubview:[self rowWithTitle:@"Prediction UI"]];
    [stack addArrangedSubview:[self rowWithTitle:@"Visual Tuning UI"]];
    [stack addArrangedSubview:[self rowWithTitle:@"Automation UI"]];
    [stack addArrangedSubview:[self rowWithTitle:@"Auto Queue UI"]];
    [stack addArrangedSubview:status];

    [p addSubview:title];
    [p addSubview:sub];
    [p addSubview:close];
    [p addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:20.0],
        [title.topAnchor constraintEqualToAnchor:p.topAnchor constant:18.0],
        [sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [sub.trailingAnchor constraintLessThanOrEqualToAnchor:close.leadingAnchor constant:-10.0],
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4.0],
        [close.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-18.0],
        [close.topAnchor constraintEqualToAnchor:p.topAnchor constant:15.0],
        [close.widthAnchor constraintEqualToConstant:38.0],
        [close.heightAnchor constraintEqualToConstant:38.0],
        [stack.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-18.0],
        [stack.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:20.0],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:p.bottomAnchor constant:-18.0]
    ]];
}

- (void)toggleMenu {
    UIWindow *w = [self targetWindow];
    if (!w) return;
    [self buildPanelInWindow:w];
    self.panel.hidden = !self.panel.hidden;
    if (self.panel.hidden) self.panel.hidden = NO;
    [w bringSubviewToFront:self.panel];
    [w bringSubviewToFront:self.button];
}

- (void)hideMenu {
    self.panel.hidden = YES;
}

- (void)switchChanged:(UISwitch *)sender {
    NSString *name = sender.accessibilityLabel ?: @"Option";
    self.statusLabel.text = [NSString stringWithFormat:@"%@ %@", name, sender.isOn ? @"AN" : @"AUS"];
}

@end

__attribute__((constructor))
static void KingMenuInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:NSOperationQueue.mainQueue
                                                      usingBlock:^(__unused NSNotification *note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[KMMenuController shared] installWhenReady];
            });
        }];

        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[KMMenuController shared] installWhenReady];
            });
        }
    });
}
