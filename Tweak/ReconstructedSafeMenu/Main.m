#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface KRMenu : NSObject
@property(nonatomic,strong) UIButton *floatingButton;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIStackView *contentStack;
@property(nonatomic,strong) NSArray<UIButton *> *tabButtons;
@property(nonatomic,assign) NSInteger selectedTab;
@end

@implementation KRMenu

+ (instancetype)shared {
    static KRMenu *obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ obj=[KRMenu new]; });
    return obj;
}

- (UIColor *)accent { return [UIColor colorWithRed:1.0 green:0.56 blue:0.03 alpha:1.0]; }
- (UIColor *)bg { return [UIColor colorWithRed:0.055 green:0.06 blue:0.07 alpha:0.985]; }
- (UIColor *)card { return [UIColor colorWithRed:0.12 green:0.125 blue:0.14 alpha:1.0]; }
- (UIColor *)muted { return [UIColor colorWithWhite:0.68 alpha:1.0]; }

- (UIWindow *)activeWindow {
    UIApplication *app=UIApplication.sharedApplication;
    if (@available(iOS 13.0,*)) {
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws=(UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) if (w.isKeyWindow) return w;
            for (UIWindow *w in ws.windows) if (!w.hidden && w.alpha>0.01) return w;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (app.keyWindow) return app.keyWindow;
    for (UIWindow *w in app.windows) if (!w.hidden && w.alpha>0.01) return w;
#pragma clang diagnostic pop
    return nil;
}

- (UILabel *)label:(NSString *)text size:(CGFloat)size bold:(BOOL)bold {
    UILabel *l=[UILabel new];
    l.text=text;
    l.textColor=UIColor.whiteColor;
    l.numberOfLines=0;
    l.font=bold?[UIFont boldSystemFontOfSize:size]:[UIFont systemFontOfSize:size];
    return l;
}

- (UIView *)toggleRow:(NSString *)title {
    UIView *row=[UIView new];
    row.backgroundColor=[self card];
    row.layer.cornerRadius=14;
    [row.heightAnchor constraintEqualToConstant:64].active=YES;

    UILabel *l=[self label:title size:16 bold:YES];
    l.translatesAutoresizingMaskIntoConstraints=NO;
    UISwitch *s=[UISwitch new];
    s.translatesAutoresizingMaskIntoConstraints=NO;
    s.onTintColor=[self accent];
    s.accessibilityLabel=title;
    NSString *key=[@"KingMenu." stringByAppendingString:title];
    s.on=[[NSUserDefaults standardUserDefaults] boolForKey:key];
    [s addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];

    [row addSubview:l]; [row addSubview:s];
    [NSLayoutConstraint activateConstraints:@[
        [l.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [l.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [l.trailingAnchor constraintLessThanOrEqualToAnchor:s.leadingAnchor constant:-10],
        [s.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [s.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]
    ]];
    return row;
}

- (UIView *)sliderRow:(NSString *)title min:(float)min max:(float)max value:(float)value {
    UIView *row=[UIView new];
    row.backgroundColor=[self card];
    row.layer.cornerRadius=14;
    [row.heightAnchor constraintEqualToConstant:88].active=YES;

    UILabel *l=[self label:title size:15 bold:YES];
    l.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *v=[self label:[NSString stringWithFormat:@"%.2f",value] size:13 bold:YES];
    v.textColor=[self accent];
    v.tag=991;
    v.translatesAutoresizingMaskIntoConstraints=NO;
    UISlider *sl=[UISlider new];
    sl.minimumValue=min; sl.maximumValue=max; sl.value=value;
    sl.minimumTrackTintColor=[self accent];
    sl.accessibilityLabel=title;
    sl.translatesAutoresizingMaskIntoConstraints=NO;
    [sl addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];

    [row addSubview:l]; [row addSubview:v]; [row addSubview:sl];
    [NSLayoutConstraint activateConstraints:@[
        [l.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [l.topAnchor constraintEqualToAnchor:row.topAnchor constant:11],
        [v.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [v.centerYAnchor constraintEqualToAnchor:l.centerYAnchor],
        [sl.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [sl.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [sl.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-9]
    ]];
    return row;
}

- (UIView *)infoCard:(NSString *)title subtitle:(NSString *)subtitle {
    UIView *v=[UIView new];
    v.backgroundColor=[self card];
    v.layer.cornerRadius=14;
    v.layer.borderWidth=1;
    v.layer.borderColor=[[self accent] colorWithAlphaComponent:.35].CGColor;
    [v.heightAnchor constraintEqualToConstant:86].active=YES;

    UILabel *t=[self label:title size:17 bold:YES];
    t.textColor=[self accent];
    t.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *s=[self label:subtitle size:13 bold:NO];
    s.textColor=[self muted];
    s.translatesAutoresizingMaskIntoConstraints=NO;
    [v addSubview:t]; [v addSubview:s];
    [NSLayoutConstraint activateConstraints:@[
        [t.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:16],
        [t.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-16],
        [t.topAnchor constraintEqualToAnchor:v.topAnchor constant:13],
        [s.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
        [s.trailingAnchor constraintEqualToAnchor:t.trailingAnchor],
        [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:7]
    ]];
    return v;
}

- (void)clearContent {
    for (UIView *v in self.contentStack.arrangedSubviews) {
        [self.contentStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)addSection:(NSString *)title {
    UILabel *l=[self label:title size:22 bold:YES];
    l.textColor=[self accent];
    [self.contentStack addArrangedSubview:l];
}

- (void)showTab:(NSInteger)idx {
    self.selectedTab=idx;
    [self clearContent];
    for (UIButton *b in self.tabButtons) {
        BOOL on=(b.tag==idx);
        b.backgroundColor=on?[[self accent] colorWithAlphaComponent:.18]:[UIColor colorWithWhite:1 alpha:.045];
        b.layer.borderColor=(on?[self accent]:[UIColor colorWithWhite:1 alpha:.08]).CGColor;
        [b setTitleColor:on?[self accent]:[UIColor colorWithWhite:.78 alpha:1] forState:UIControlStateNormal];
    }

    if (idx==0) {
        [self addSection:@"PREDICTION"];
        for (NSString *x in @[@"Prediction Lines",@"Opponent Lines",@"Table Outline",@"Pocket Rings",@"End Dots",@"Break % Overlay",@"Scratch Alert",@"Wrong Ball Alert",@"Stream Proof"]) {
            [self.contentStack addArrangedSubview:[self toggleRow:x]];
        }
    } else if (idx==1) {
        [self addSection:@"TUNING"];
        [self.contentStack addArrangedSubview:[self sliderRow:@"Shift X" min:-100 max:100 value:0]];
        [self.contentStack addArrangedSubview:[self sliderRow:@"Shift Y" min:-100 max:100 value:0]];
        [self.contentStack addArrangedSubview:[self sliderRow:@"Line Scale X" min:.2 max:3 value:1]];
        [self.contentStack addArrangedSubview:[self sliderRow:@"Line Scale Y" min:.2 max:3 value:1]];
        [self.contentStack addArrangedSubview:[self sliderRow:@"Line Thickness" min:.1 max:3 value:.6]];
        [self.contentStack addArrangedSubview:[self sliderRow:@"Line Opacity" min:.1 max:2 value:1]];
    } else if (idx==2) {
        [self addSection:@"AUTOMATION"];
        [self.contentStack addArrangedSubview:[self infoCard:@"UI reconstruction" subtitle:@"These controls are local demo settings only and do not control gameplay."]];
        for (NSString *x in @[@"Shortcut Button",@"Status Bar",@"Best-Shot Ghost",@"Auto Select Pocket",@"Multi-Pocket",@"Pause on Touch",@"Humanization"]) {
            [self.contentStack addArrangedSubview:[self toggleRow:x]];
        }
    } else if (idx==3) {
        [self addSection:@"AUTO QUEUE"];
        [self.contentStack addArrangedSubview:[self infoCard:@"UI reconstruction" subtitle:@"Queue settings are stored locally for interface testing only."]];
        [self.contentStack addArrangedSubview:[self toggleRow:@"Auto Queue"]];
        [self.contentStack addArrangedSubview:[self sliderRow:@"Queue Delay" min:0 max:10 value:3]];
        [self.contentStack addArrangedSubview:[self sliderRow:@"Bet Percent" min:0 max:100 value:25]];
    } else {
        [self addSection:@"ACCOUNT"];
        [self.contentStack addArrangedSubview:[self infoCard:@"KingMenu Reconstruction" subtitle:@"Standalone reconstructed UI • no license server • no signature check • no tamper protection"]];
        [self.contentStack addArrangedSubview:[self toggleRow:@"Remember Settings"]];
    }
}

- (UIButton *)tab:(NSString *)title tag:(NSInteger)tag {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    b.tag=tag;
    b.layer.cornerRadius=11;
    b.layer.borderWidth=1;
    b.titleLabel.font=[UIFont boldSystemFontOfSize:12];
    [b setTitle:title forState:UIControlStateNormal];
    [b addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
    [b.heightAnchor constraintEqualToConstant:40].active=YES;
    return b;
}

- (void)install {
    if (self.floatingButton) return;
    UIWindow *w=[self activeWindow];
    if (!w) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ [self install]; });
        return;
    }
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    self.floatingButton=b;
    CGFloat size=58;
    b.frame=CGRectMake(MAX(8,w.bounds.size.width-size-16),MAX(90,w.bounds.size.height*.42),size,size);
    b.backgroundColor=[UIColor colorWithWhite:.055 alpha:.98];
    b.layer.cornerRadius=size/2;
    b.layer.borderWidth=2;
    b.layer.borderColor=[self accent].CGColor;
    [b setTitle:@"K" forState:UIControlStateNormal];
    [b setTitleColor:[self accent] forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont boldSystemFontOfSize:26];
    [b addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
    [b addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];
    [w addSubview:b];
}

- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint t=[g translationInView:g.view.superview];
    g.view.center=CGPointMake(g.view.center.x+t.x,g.view.center.y+t.y);
    [g setTranslation:CGPointZero inView:g.view.superview];
}

- (void)open {
    UIWindow *w=[self activeWindow];
    if (!w) return;
    if (self.panel) { self.panel.hidden=NO; return; }

    UIView *p=[UIView new];
    self.panel=p;
    p.translatesAutoresizingMaskIntoConstraints=NO;
    p.backgroundColor=[self bg];
    p.layer.cornerRadius=22;
    p.layer.borderWidth=1;
    p.layer.borderColor=[UIColor colorWithWhite:1 alpha:.1].CGColor;
    p.clipsToBounds=YES;
    [w addSubview:p];

    CGFloat width=MIN(w.bounds.size.width-22,760);
    CGFloat height=MIN(w.bounds.size.height-28,620);
    [NSLayoutConstraint activateConstraints:@[
        [p.centerXAnchor constraintEqualToAnchor:w.centerXAnchor],
        [p.centerYAnchor constraintEqualToAnchor:w.centerYAnchor],
        [p.widthAnchor constraintEqualToConstant:width],
        [p.heightAnchor constraintEqualToConstant:height]
    ]];

    UILabel *title=[self label:@"KingMenu" size:24 bold:YES];
    title.textColor=[self accent];
    title.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *sub=[self label:@"Reconstructed test UI" size:13 bold:NO];
    sub.textColor=[self muted];
    sub.translatesAutoresizingMaskIntoConstraints=NO;
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints=NO;
    close.layer.cornerRadius=20;
    close.backgroundColor=[UIColor colorWithWhite:1 alpha:.06];
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:[self accent] forState:UIControlStateNormal];
    close.titleLabel.font=[UIFont boldSystemFontOfSize:22];
    [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [p addSubview:title]; [p addSubview:sub]; [p addSubview:close];

    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:20],
        [title.topAnchor constraintEqualToAnchor:p.topAnchor constant:16],
        [sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2],
        [close.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-16],
        [close.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:40],
        [close.heightAnchor constraintEqualToConstant:40]
    ]];

    NSArray *names=@[@"PREDICTION",@"TUNING",@"AUTOMATION",@"AUTO QUEUE",@"ACCOUNT"];
    NSMutableArray *buttons=[NSMutableArray array];
    for (NSInteger i=0;i<names.count;i++) [buttons addObject:[self tab:names[i] tag:i]];
    self.tabButtons=buttons;
    UIStackView *tabs=[[UIStackView alloc] initWithArrangedSubviews:buttons];
    tabs.axis=UILayoutConstraintAxisHorizontal;
    tabs.distribution=UIStackViewDistributionFillEqually;
    tabs.spacing=6;
    tabs.translatesAutoresizingMaskIntoConstraints=NO;
    [p addSubview:tabs];

    UIScrollView *scroll=[UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints=NO;
    [p addSubview:scroll];
    UIStackView *stack=[UIStackView new];
    self.contentStack=stack;
    stack.axis=UILayoutConstraintAxisVertical;
    stack.spacing=10;
    stack.translatesAutoresizingMaskIntoConstraints=NO;
    [scroll addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [tabs.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:16],
        [tabs.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-16],
        [tabs.topAnchor constraintEqualToAnchor:sub.bottomAnchor constant:16],
        [scroll.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:16],
        [scroll.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-16],
        [scroll.topAnchor constraintEqualToAnchor:tabs.bottomAnchor constant:12],
        [scroll.bottomAnchor constraintEqualToAnchor:p.bottomAnchor constant:-16],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];

    [self showTab:0];
}

- (void)close { self.panel.hidden=YES; }
- (void)tabTapped:(UIButton *)b { [self showTab:b.tag]; }

- (void)toggleChanged:(UISwitch *)s {
    if (!s.accessibilityLabel) return;
    NSString *key=[@"KingMenu." stringByAppendingString:s.accessibilityLabel];
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:key];
}

- (void)sliderChanged:(UISlider *)s {
    UILabel *v=[s.superview viewWithTag:991];
    if ([v isKindOfClass:UILabel.class]) v.text=[NSString stringWithFormat:@"%.2f",s.value];
    if (s.accessibilityLabel) {
        NSString *key=[@"KingMenu." stringByAppendingString:s.accessibilityLabel];
        [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:key];
    }
}

@end

__attribute__((constructor))
static void KingReconstructedInit(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
        [[KRMenu shared] install];
    });
}
