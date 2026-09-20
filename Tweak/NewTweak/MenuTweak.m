#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

static UIWindow *JHWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive) continue;
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (w.isKeyWindow) return w;
        }
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (!w.hidden && w.alpha > 0.01) return w;
        }
    }
    return nil;
}

@interface JHTweakMenu : NSObject
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIButton *floating;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) UIStackView *stack;
@property(nonatomic,strong) UIStackView *sideStack;
@property(nonatomic,strong) NSArray<UIButton *> *sideButtons;
@property(nonatomic,assign) NSInteger selectedSection;
@end

@implementation JHTweakMenu

+ (instancetype)shared {
    static JHTweakMenu *x;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ x=[JHTweakMenu new]; });
    return x;
}

- (UIColor *)orange { return [UIColor colorWithRed:1.0 green:0.56 blue:0.0 alpha:1.0]; }
- (UIColor *)orangeDark { return [UIColor colorWithRed:.46 green:.25 blue:.02 alpha:1.0]; }
- (UIColor *)panelColor { return [UIColor colorWithRed:.055 green:.06 blue:.07 alpha:.985]; }
- (UIColor *)cardColor { return [UIColor colorWithRed:.115 green:.12 blue:.135 alpha:1.0]; }
- (UIColor *)cardOnColor { return [UIColor colorWithRed:.22 green:.16 blue:.08 alpha:1.0]; }
- (UIColor *)lineColor { return [UIColor colorWithWhite:1 alpha:.09]; }
- (UIColor *)muted { return [UIColor colorWithWhite:.64 alpha:1]; }

- (UILabel *)label:(NSString *)text size:(CGFloat)size bold:(BOOL)bold {
    UILabel *l=[UILabel new];
    l.text=text;
    l.textColor=UIColor.whiteColor;
    l.numberOfLines=0;
    l.font=bold?[UIFont boldSystemFontOfSize:size]:[UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    return l;
}

- (UIView *)separator {
    UIView *v=[UIView new];
    v.backgroundColor=[self lineColor];
    [v.heightAnchor constraintEqualToConstant:1].active=YES;
    return v;
}

- (UIView *)headerChip:(NSString *)text {
    UILabel *l=[self label:text size:13 bold:YES];
    l.textColor=[self orange];
    l.textAlignment=NSTextAlignmentCenter;
    l.layer.cornerRadius=16;
    l.layer.borderWidth=1;
    l.layer.borderColor=[self orangeDark].CGColor;
    l.clipsToBounds=YES;
    l.backgroundColor=[UIColor colorWithWhite:1 alpha:.025];
    [l.widthAnchor constraintGreaterThanOrEqualToConstant:64].active=YES;
    [l.heightAnchor constraintEqualToConstant:34].active=YES;
    return l;
}

- (UIButton *)sideButton:(NSString *)symbol tag:(NSInteger)tag {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:symbol forState:UIControlStateNormal];
    [b setTitleColor:[UIColor colorWithWhite:.75 alpha:1] forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont boldSystemFontOfSize:25];
    b.backgroundColor=[UIColor colorWithWhite:1 alpha:.06];
    b.layer.cornerRadius=29;
    b.layer.borderWidth=1;
    b.layer.borderColor=[UIColor clearColor].CGColor;
    b.tag=tag;
    [b.widthAnchor constraintEqualToConstant:58].active=YES;
    [b.heightAnchor constraintEqualToConstant:58].active=YES;
    [b addTarget:self action:@selector(sideTapped:) forControlEvents:UIControlEventTouchUpInside];
    return b;
}

- (void)selectSide:(NSInteger)idx {
    self.selectedSection=idx;
    for (UIButton *b in self.sideButtons) {
        BOOL on=(b.tag==idx);
        b.layer.borderColor=(on?[self orange]:UIColor.clearColor).CGColor;
        b.backgroundColor=on?[[self orange] colorWithAlphaComponent:.12]:[UIColor colorWithWhite:1 alpha:.06];
        [b setTitleColor:on?[self orange]:[UIColor colorWithWhite:.75 alpha:1] forState:UIControlStateNormal];
    }
}

- (UIView *)sectionHeader:(NSString *)icon title:(NSString *)title {
    UIView *v=[UIView new];
    v.backgroundColor=[self cardColor];
    v.layer.cornerRadius=14;
    v.layer.borderWidth=1;
    v.layer.borderColor=[UIColor colorWithWhite:1 alpha:.09].CGColor;
    [v.heightAnchor constraintEqualToConstant:58].active=YES;

    UILabel *ic=[self label:icon size:20 bold:YES];
    ic.textColor=[self orange];
    ic.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *t=[self label:title size:18 bold:YES];
    t.textColor=[self orange];
    t.translatesAutoresizingMaskIntoConstraints=NO;
    [v addSubview:ic]; [v addSubview:t];
    [NSLayoutConstraint activateConstraints:@[
        [ic.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:18],
        [ic.centerYAnchor constraintEqualToAnchor:v.centerYAnchor],
        [t.leadingAnchor constraintEqualToAnchor:ic.trailingAnchor constant:12],
        [t.centerYAnchor constraintEqualToAnchor:v.centerYAnchor]
    ]];
    return v;
}

- (UIView *)toggleRow:(NSString *)name on:(BOOL)on {
    UIView *card=[UIView new];
    card.backgroundColor=on?[self cardOnColor]:[self cardColor];
    card.layer.cornerRadius=14;
    card.layer.borderWidth=1;
    card.layer.borderColor=(on?[[self orange] colorWithAlphaComponent:.48]:[UIColor colorWithWhite:1 alpha:.08]).CGColor;
    card.translatesAutoresizingMaskIntoConstraints=NO;
    [card.heightAnchor constraintEqualToConstant:68].active=YES;

    UILabel *l=[self label:name size:16 bold:YES];
    l.translatesAutoresizingMaskIntoConstraints=NO;

    UISwitch *s=[UISwitch new];
    s.on=on;
    s.onTintColor=[self orange];
    s.tintColor=[UIColor colorWithWhite:.2 alpha:1];
    s.translatesAutoresizingMaskIntoConstraints=NO;
    s.accessibilityLabel=name;
    [s addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];

    [card addSubview:l];
    [card addSubview:s];
    [NSLayoutConstraint activateConstraints:@[
        [l.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [l.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [l.trailingAnchor constraintLessThanOrEqualToAnchor:s.leadingAnchor constant:-12],
        [s.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [s.centerYAnchor constraintEqualToAnchor:card.centerYAnchor]
    ]];
    return card;
}

- (UIView *)sliderRow:(NSString *)name value:(float)value min:(float)min max:(float)max {
    UIView *card=[UIView new];
    card.backgroundColor=[self cardColor];
    card.layer.cornerRadius=14;
    card.layer.borderWidth=1;
    card.layer.borderColor=[UIColor colorWithWhite:1 alpha:.07].CGColor;
    [card.heightAnchor constraintEqualToConstant:90].active=YES;

    UILabel *l=[self label:name size:15 bold:YES];
    l.translatesAutoresizingMaskIntoConstraints=NO;

    UILabel *v=[self label:[NSString stringWithFormat:@"%.2f",value] size:14 bold:YES];
    v.textColor=[UIColor colorWithWhite:.78 alpha:1];
    v.textAlignment=NSTextAlignmentRight;
    v.translatesAutoresizingMaskIntoConstraints=NO;
    v.tag=700;

    UISlider *sl=[UISlider new];
    sl.minimumValue=min; sl.maximumValue=max; sl.value=value;
    sl.minimumTrackTintColor=[self orange];
    sl.maximumTrackTintColor=[UIColor colorWithWhite:.26 alpha:1];
    sl.translatesAutoresizingMaskIntoConstraints=NO;
    sl.accessibilityLabel=name;
    [sl addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];

    [card addSubview:l]; [card addSubview:v]; [card addSubview:sl];
    [NSLayoutConstraint activateConstraints:@[
        [l.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [l.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
        [v.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [v.centerYAnchor constraintEqualToAnchor:l.centerYAnchor],
        [sl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [sl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [sl.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-10]
    ]];
    return card;
}

- (UIView *)segmentRow:(NSString *)name options:(NSArray<NSString *> *)options selected:(NSInteger)selected {
    UIView *card=[UIView new];
    card.backgroundColor=[self cardColor];
    card.layer.cornerRadius=14;
    card.layer.borderWidth=1;
    card.layer.borderColor=[UIColor colorWithWhite:1 alpha:.07].CGColor;
    [card.heightAnchor constraintEqualToConstant:86].active=YES;

    UILabel *l=[self label:name size:15 bold:YES];
    l.translatesAutoresizingMaskIntoConstraints=NO;

    UISegmentedControl *seg=[[UISegmentedControl alloc] initWithItems:options];
    seg.selectedSegmentIndex=selected;
    seg.selectedSegmentTintColor=[self orangeDark];
    seg.backgroundColor=[UIColor colorWithWhite:.1 alpha:1];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:.72 alpha:1],
                                  NSFontAttributeName:[UIFont boldSystemFontOfSize:12]}
                       forState:UIControlStateNormal];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor,
                                  NSFontAttributeName:[UIFont boldSystemFontOfSize:12]}
                       forState:UIControlStateSelected];
    seg.translatesAutoresizingMaskIntoConstraints=NO;
    seg.accessibilityLabel=name;
    [seg addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];

    [card addSubview:l]; [card addSubview:seg];
    [NSLayoutConstraint activateConstraints:@[
        [l.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [l.topAnchor constraintEqualToAnchor:card.topAnchor constant:11],
        [seg.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [seg.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [seg.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-10],
        [seg.heightAnchor constraintEqualToConstant:34]
    ]];
    return card;
}

- (UIView *)statusCard:(NSString *)title subtitle:(NSString *)subtitle {
    UIView *card=[UIView new];
    card.backgroundColor=[self cardColor];
    card.layer.cornerRadius=16;
    card.layer.borderWidth=1;
    card.layer.borderColor=[[self orange] colorWithAlphaComponent:.38].CGColor;
    [card.heightAnchor constraintEqualToConstant:96].active=YES;

    UILabel *t=[self label:title size:17 bold:YES];
    t.textColor=[self orange];
    t.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *s=[self label:subtitle size:13 bold:NO];
    s.textColor=[self muted];
    s.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *badge=[self label:@"UNLOCKED" size:11 bold:YES];
    badge.textColor=UIColor.whiteColor;
    badge.textAlignment=NSTextAlignmentCenter;
    badge.backgroundColor=[self orangeDark];
    badge.layer.cornerRadius=12;
    badge.clipsToBounds=YES;
    badge.translatesAutoresizingMaskIntoConstraints=NO;

    [card addSubview:t]; [card addSubview:s]; [card addSubview:badge];
    [NSLayoutConstraint activateConstraints:@[
        [t.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [t.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [s.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
        [s.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:8],
        [badge.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [badge.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [badge.widthAnchor constraintEqualToConstant:88],
        [badge.heightAnchor constraintEqualToConstant:25]
    ]];
    return card;
}

- (void)start {
    if (self.floating) return;
    UIWindow *w=JHWindow();
    if (!w) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,1*NSEC_PER_SEC),dispatch_get_main_queue(),^{ [self start]; });
        return;
    }

    UIButton *f=[UIButton buttonWithType:UIButtonTypeSystem];
    self.floating=f;
    CGFloat y=MAX(90, MIN(w.bounds.size.height-90, w.bounds.size.height*.46));
    f.frame=CGRectMake(MAX(8,w.bounds.size.width-76), y, 58, 58);
    f.backgroundColor=[UIColor colorWithRed:.075 green:.08 blue:.09 alpha:.97];
    f.layer.cornerRadius=29;
    f.layer.borderWidth=2;
    f.layer.borderColor=[self orangeDark].CGColor;
    [f setTitle:@"K" forState:UIControlStateNormal];
    [f setTitleColor:[self orange] forState:UIControlStateNormal];
    f.titleLabel.font=[UIFont boldSystemFontOfSize:27];
    [f addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
    [f addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];
    [w addSubview:f];
}

- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint t=[g translationInView:g.view.superview];
    CGPoint c=g.view.center;
    c.x+=t.x; c.y+=t.y;
    g.view.center=c;
    [g setTranslation:CGPointZero inView:g.view.superview];
}

- (void)open {
    if (self.panel) { self.panel.hidden=NO; return; }
    UIWindow *w=JHWindow(); if (!w) return;

    UIView *p=[UIView new];
    self.panel=p;
    p.translatesAutoresizingMaskIntoConstraints=NO;
    p.backgroundColor=[self panelColor];
    p.layer.cornerRadius=24;
    p.layer.borderWidth=1;
    p.layer.borderColor=[UIColor colorWithWhite:1 alpha:.12].CGColor;
    p.clipsToBounds=YES;
    [w addSubview:p];

    CGFloat width=MIN(MAX(640,w.bounds.size.width*.68), w.bounds.size.width-20);
    CGFloat height=MIN(MAX(420,w.bounds.size.height*.82), w.bounds.size.height-24);
    [NSLayoutConstraint activateConstraints:@[
        [p.centerXAnchor constraintEqualToAnchor:w.centerXAnchor],
        [p.centerYAnchor constraintEqualToAnchor:w.centerYAnchor],
        [p.widthAnchor constraintEqualToConstant:width],
        [p.heightAnchor constraintEqualToConstant:height]
    ]];

    UIView *head=[UIView new];
    head.translatesAutoresizingMaskIntoConstraints=NO;
    head.backgroundColor=[UIColor colorWithWhite:.045 alpha:1];
    [p addSubview:head];

    UIView *logo=[UIView new];
    logo.translatesAutoresizingMaskIntoConstraints=NO;
    logo.backgroundColor=[self orangeDark];
    logo.layer.cornerRadius=12;
    logo.layer.borderWidth=1;
    logo.layer.borderColor=[[self orange] colorWithAlphaComponent:.45].CGColor;
    [head addSubview:logo];
    UILabel *logoText=[self label:@"K" size:27 bold:YES];
    logoText.textColor=[self orange];
    logoText.textAlignment=NSTextAlignmentCenter;
    logoText.translatesAutoresizingMaskIntoConstraints=NO;
    [logo addSubview:logoText];

    UILabel *title=[self label:@"King Tweak" size:25 bold:YES];
    title.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *sub=[self label:@"8 Ball Pool custom overlay" size:14 bold:NO];
    sub.textColor=[self muted];
    sub.translatesAutoresizingMaskIntoConstraints=NO;

    UIView *version=[self headerChip:@"v1.0"];
    version.translatesAutoresizingMaskIntoConstraints=NO;

    UISegmentedControl *lang=[[UISegmentedControl alloc] initWithItems:@[@"EN",@"DE"]];
    lang.selectedSegmentIndex=0;
    lang.selectedSegmentTintColor=[self orangeDark];
    lang.translatesAutoresizingMaskIntoConstraints=NO;
    [lang setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor,NSFontAttributeName:[UIFont boldSystemFontOfSize:12]} forState:UIControlStateNormal];

    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:[self orange] forState:UIControlStateNormal];
    close.titleLabel.font=[UIFont boldSystemFontOfSize:24];
    close.backgroundColor=[UIColor colorWithWhite:1 alpha:.07];
    close.layer.cornerRadius=22;
    close.translatesAutoresizingMaskIntoConstraints=NO;
    [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];

    [head addSubview:title]; [head addSubview:sub]; [head addSubview:version]; [head addSubview:lang]; [head addSubview:close];

    [NSLayoutConstraint activateConstraints:@[
        [head.leadingAnchor constraintEqualToAnchor:p.leadingAnchor],
        [head.trailingAnchor constraintEqualToAnchor:p.trailingAnchor],
        [head.topAnchor constraintEqualToAnchor:p.topAnchor],
        [head.heightAnchor constraintEqualToConstant:100],

        [logo.leadingAnchor constraintEqualToAnchor:head.leadingAnchor constant:18],
        [logo.centerYAnchor constraintEqualToAnchor:head.centerYAnchor],
        [logo.widthAnchor constraintEqualToConstant:62],
        [logo.heightAnchor constraintEqualToConstant:62],
        [logoText.centerXAnchor constraintEqualToAnchor:logo.centerXAnchor],
        [logoText.centerYAnchor constraintEqualToAnchor:logo.centerYAnchor],

        [title.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:14],
        [title.topAnchor constraintEqualToAnchor:head.topAnchor constant:18],
        [sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:5],

        [close.trailingAnchor constraintEqualToAnchor:head.trailingAnchor constant:-16],
        [close.centerYAnchor constraintEqualToAnchor:head.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:44],
        [close.heightAnchor constraintEqualToConstant:44],

        [lang.trailingAnchor constraintEqualToAnchor:close.leadingAnchor constant:-10],
        [lang.centerYAnchor constraintEqualToAnchor:head.centerYAnchor],
        [lang.widthAnchor constraintEqualToConstant:112],
        [lang.heightAnchor constraintEqualToConstant:34],

        [version.trailingAnchor constraintEqualToAnchor:lang.leadingAnchor constant:-10],
        [version.centerYAnchor constraintEqualToAnchor:head.centerYAnchor]
    ]];

    UIView *side=[UIView new];
    side.translatesAutoresizingMaskIntoConstraints=NO;
    side.backgroundColor=[UIColor colorWithWhite:.08 alpha:1];
    [p addSubview:side];

    UIButton *b0=[self sideButton:@"◉" tag:0];
    UIButton *b1=[self sideButton:@"☷" tag:1];
    UIButton *b2=[self sideButton:@"▣" tag:2];
    UIButton *b3=[self sideButton:@"⟳" tag:3];
    UIButton *b4=[self sideButton:@"●" tag:4];
    self.sideButtons=@[b0,b1,b2,b3,b4];

    UIStackView *sideStack=[[UIStackView alloc] initWithArrangedSubviews:self.sideButtons];
    self.sideStack=sideStack;
    sideStack.axis=UILayoutConstraintAxisVertical;
    sideStack.alignment=UIStackViewAlignmentCenter;
    sideStack.spacing=18;
    sideStack.translatesAutoresizingMaskIntoConstraints=NO;
    [side addSubview:sideStack];

    UIScrollView *sc=[UIScrollView new];
    self.scroll=sc;
    sc.translatesAutoresizingMaskIntoConstraints=NO;
    sc.showsVerticalScrollIndicator=YES;
    [p addSubview:sc];

    UIStackView *stack=[UIStackView new];
    self.stack=stack;
    stack.axis=UILayoutConstraintAxisVertical;
    stack.spacing=10;
    stack.translatesAutoresizingMaskIntoConstraints=NO;
    [sc addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [side.leadingAnchor constraintEqualToAnchor:p.leadingAnchor],
        [side.topAnchor constraintEqualToAnchor:head.bottomAnchor],
        [side.bottomAnchor constraintEqualToAnchor:p.bottomAnchor],
        [side.widthAnchor constraintEqualToConstant:92],

        [sideStack.centerXAnchor constraintEqualToAnchor:side.centerXAnchor],
        [sideStack.topAnchor constraintEqualToAnchor:side.topAnchor constant:22],

        [sc.leadingAnchor constraintEqualToAnchor:side.trailingAnchor constant:18],
        [sc.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-18],
        [sc.topAnchor constraintEqualToAnchor:head.bottomAnchor constant:14],
        [sc.bottomAnchor constraintEqualToAnchor:p.bottomAnchor constant:-14],

        [stack.leadingAnchor constraintEqualToAnchor:sc.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:sc.contentLayoutGuide.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:sc.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:sc.contentLayoutGuide.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:sc.frameLayoutGuide.widthAnchor]
    ]];

    [self selectSide:0];
    [self showPrediction];
}

- (void)clearStack {
    for (UIView *v in self.stack.arrangedSubviews) {
        [self.stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)sideTapped:(UIButton *)b {
    [self selectSide:b.tag];
    switch (b.tag) {
        case 0: [self showPrediction]; break;
        case 1: [self showVisual]; break;
        case 2: [self showAutomation]; break;
        case 3: [self showQueue]; break;
        default: [self showAccount]; break;
    }
    [self.scroll setContentOffset:CGPointZero animated:NO];
}

- (BOOL)savedBool:(NSString *)name fallback:(BOOL)fallback {
    NSString *k=[@"king." stringByAppendingString:name];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:k]==nil) return fallback;
    return [[NSUserDefaults standardUserDefaults] boolForKey:k];
}

- (float)savedFloat:(NSString *)name fallback:(float)fallback {
    NSString *k=[@"king." stringByAppendingString:name];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:k]==nil) return fallback;
    return [[NSUserDefaults standardUserDefaults] floatForKey:k];
}

- (void)showPrediction {
    [self clearStack];
    [self.stack addArrangedSubview:[self sectionHeader:@"◉" title:@"PREDICTION"]];
    NSArray *items=@[@"Prediction Lines",@"Opponent Lines",@"Table Outline",@"Pocket Rings",@"End Dots",@"Precise Paths",@"Scratch Alert",@"Wrong Ball Alert",@"Stream Proof"];
    NSArray *defaults=@[@YES,@NO,@YES,@YES,@YES,@YES,@YES,@YES,@NO];
    for (NSInteger i=0;i<items.count;i++) {
        NSString *name=items[i];
        BOOL val=[self savedBool:name fallback:[defaults[i] boolValue]];
        [self.stack addArrangedSubview:[self toggleRow:name on:val]];
    }
}

- (void)showVisual {
    [self clearStack];
    [self.stack addArrangedSubview:[self sectionHeader:@"☷" title:@"VISUAL TUNING"]];
    [self.stack addArrangedSubview:[self segmentRow:@"Graphic" options:@[@"Light",@"High"] selected:1]];
    [self.stack addArrangedSubview:[self sliderRow:@"Shift Y" value:[self savedFloat:@"Shift Y" fallback:0] min:-100 max:100]];
    [self.stack addArrangedSubview:[self sliderRow:@"Shift X" value:[self savedFloat:@"Shift X" fallback:0] min:-100 max:100]];
    [self.stack addArrangedSubview:[self sliderRow:@"Line Scale X" value:[self savedFloat:@"Line Scale X" fallback:1] min:.2 max:3]];
    [self.stack addArrangedSubview:[self sliderRow:@"Line Scale Y" value:[self savedFloat:@"Line Scale Y" fallback:1] min:.2 max:3]];
    [self.stack addArrangedSubview:[self sliderRow:@"Line Thickness" value:[self savedFloat:@"Line Thickness" fallback:1] min:.1 max:3]];
    [self.stack addArrangedSubview:[self sliderRow:@"Line Opacity" value:[self savedFloat:@"Line Opacity" fallback:.9] min:.1 max:1]];
    [self.stack addArrangedSubview:[self sliderRow:@"End Ball Size" value:[self savedFloat:@"End Ball Size" fallback:1] min:.2 max:3]];
    [self.stack addArrangedSubview:[self sliderRow:@"Pocket Ring Size" value:[self savedFloat:@"Pocket Ring Size" fallback:1.2] min:.2 max:3]];
    [self.stack addArrangedSubview:[self sliderRow:@"Initial Pull" value:[self savedFloat:@"Initial Pull" fallback:.5] min:0 max:1]];
}

- (void)showAutomation {
    [self clearStack];
    [self.stack addArrangedSubview:[self sectionHeader:@"▣" title:@"AUTOMATION"]];
    [self.stack addArrangedSubview:[self statusCard:@"Automation Access" subtitle:@"Own tweak mode · no PRO gate · no ads"]];
    [self.stack addArrangedSubview:[self segmentRow:@"Setting Mode" options:@[@"Simple",@"Advanced"] selected:0]];
    [self.stack addArrangedSubview:[self segmentRow:@"Profile" options:@[@"Legit",@"Medium",@"Rage",@"Custom"] selected:0]];
    [self.stack addArrangedSubview:[self segmentRow:@"Aim Mode" options:@[@"Off",@"Suggest",@"Assist",@"Guide"] selected:1]];
    [self.stack addArrangedSubview:[self segmentRow:@"Humanization" options:@[@"Low",@"Med",@"High"] selected:2]];
    [self.stack addArrangedSubview:[self segmentRow:@"Skill Level" options:@[@"Casual",@"Pro",@"Stealth"] selected:1]];
    [self.stack addArrangedSubview:[self segmentRow:@"Break Mode" options:@[@"Single",@"Multi"] selected:1]];
    [self.stack addArrangedSubview:[self sliderRow:@"Aim Strength" value:[self savedFloat:@"Aim Strength" fallback:.8] min:0 max:1]];
    [self.stack addArrangedSubview:[self sliderRow:@"Max Aim Speed" value:[self savedFloat:@"Max Aim Speed" fallback:140] min:20 max:250]];

    NSArray *items=@[@"Shortcut Button",@"Best-Shot Ghost",@"Auto Select Pocket",@"Ball-in-Hand Skip",@"Pause on Touch",@"Spin Style"];
    NSArray *defs=@[@YES,@NO,@YES,@NO,@NO,@NO];
    for (NSInteger i=0;i<items.count;i++) {
        NSString *name=items[i];
        [self.stack addArrangedSubview:[self toggleRow:name on:[self savedBool:name fallback:[defs[i] boolValue]]]];
    }
}

- (void)showQueue {
    [self clearStack];
    [self.stack addArrangedSubview:[self sectionHeader:@"⟳" title:@"AUTO QUEUE"]];
    [self.stack addArrangedSubview:[self statusCard:@"Auto Queue Access" subtitle:@"Own tweak mode · available without subscription"]];
    [self.stack addArrangedSubview:[self toggleRow:@"Auto Queue" on:[self savedBool:@"Auto Queue" fallback:NO]]];
    [self.stack addArrangedSubview:[self toggleRow:@"Shortcut Button" on:[self savedBool:@"Shortcut Button" fallback:YES]]];
    [self.stack addArrangedSubview:[self sliderRow:@"Queue Delay" value:[self savedFloat:@"Queue Delay" fallback:3] min:0 max:10]];
    [self.stack addArrangedSubview:[self segmentRow:@"Queue Style" options:@[@"Safe",@"Fast",@"Custom"] selected:0]];
    UILabel *bal=[self label:@"Balance  1.0K" size:18 bold:YES];
    bal.textColor=[self orange];
    bal.textAlignment=NSTextAlignmentRight;
    [self.stack addArrangedSubview:bal];
}

- (void)showAccount {
    [self clearStack];
    [self.stack addArrangedSubview:[self sectionHeader:@"●" title:@"ACCOUNT"]];
    [self.stack addArrangedSubview:[self statusCard:@"King Tweak" subtitle:@"Local configuration · all own modules available"]];
    UILabel *txt=[self label:@"No subscription, ad or license screen is used in this custom build. Settings are stored locally on the device." size:14 bold:NO];
    txt.textColor=[self muted];
    [self.stack addArrangedSubview:txt];
}

- (void)toggleChanged:(UISwitch *)s {
    if (!s.accessibilityLabel) return;
    NSString *k=[@"king." stringByAppendingString:s.accessibilityLabel];
    [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:k];
    UIView *card=s.superview;
    card.backgroundColor=s.on?[self cardOnColor]:[self cardColor];
    card.layer.borderColor=(s.on?[[self orange] colorWithAlphaComponent:.48]:[UIColor colorWithWhite:1 alpha:.08]).CGColor;
}

- (void)sliderChanged:(UISlider *)s {
    UILabel *v=[s.superview viewWithTag:700];
    if ([v isKindOfClass:UILabel.class]) {
        if ([s.accessibilityLabel containsString:@"Speed"] || [s.accessibilityLabel containsString:@"Shift"] || [s.accessibilityLabel containsString:@"Delay"])
            v.text=[NSString stringWithFormat:@"%.0f",s.value];
        else
            v.text=[NSString stringWithFormat:@"%.2f",s.value];
    }
    if (s.accessibilityLabel) {
        NSString *k=[@"king." stringByAppendingString:s.accessibilityLabel];
        [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:k];
    }
}

- (void)segmentChanged:(UISegmentedControl *)s {
    if (!s.accessibilityLabel) return;
    NSString *k=[@"king.segment." stringByAppendingString:s.accessibilityLabel];
    [[NSUserDefaults standardUserDefaults] setInteger:s.selectedSegmentIndex forKey:k];
}

- (void)close { self.panel.hidden=YES; }

@end

__attribute__((constructor)) static void JHInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[JHTweakMenu shared] start];
        });
    });
}
