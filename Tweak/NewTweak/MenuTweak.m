#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static UIWindow *JHWindow(void) {
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (!w.hidden && w.alpha > 0.01 && w.windowLevel == UIWindowLevelNormal) return w;
    }
    return UIApplication.sharedApplication.keyWindow ?: UIApplication.sharedApplication.windows.firstObject;
}

@interface JHTweakMenu : NSObject
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIButton *floating;
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) UIStackView *stack;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) NSString *section;
@end

@implementation JHTweakMenu

+ (instancetype)shared { static JHTweakMenu *x; static dispatch_once_t once; dispatch_once(&once, ^{ x=[JHTweakMenu new]; }); return x; }

- (UIColor *)orange { return [UIColor colorWithRed:1.0 green:0.55 blue:0.0 alpha:1.0]; }
- (UIColor *)panelColor { return [UIColor colorWithRed:0.075 green:0.085 blue:0.10 alpha:0.98]; }
- (UIColor *)cardColor { return [UIColor colorWithRed:0.13 green:0.14 blue:0.16 alpha:1.0]; }

- (UILabel *)label:(NSString *)text size:(CGFloat)size bold:(BOOL)bold {
    UILabel *l=[UILabel new]; l.text=text; l.textColor=UIColor.whiteColor; l.numberOfLines=0;
    l.font=bold?[UIFont boldSystemFontOfSize:size]:[UIFont systemFontOfSize:size]; return l;
}

- (UIView *)separator {
    UIView *v=[UIView new]; v.backgroundColor=[UIColor colorWithWhite:1 alpha:.08];
    [v.heightAnchor constraintEqualToConstant:1].active=YES; return v;
}

- (UIView *)toggleRow:(NSString *)name on:(BOOL)on {
    UIView *card=[UIView new]; card.backgroundColor=[self cardColor]; card.layer.cornerRadius=14;
    card.translatesAutoresizingMaskIntoConstraints=NO; [card.heightAnchor constraintEqualToConstant:66].active=YES;
    UILabel *l=[self label:name size:17 bold:YES]; l.translatesAutoresizingMaskIntoConstraints=NO;
    UISwitch *s=[UISwitch new]; s.on=on; s.onTintColor=[self orange]; s.translatesAutoresizingMaskIntoConstraints=NO;
    s.accessibilityLabel=name; [s addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:l]; [card addSubview:s];
    [NSLayoutConstraint activateConstraints:@[[l.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],[l.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],[s.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],[s.centerYAnchor constraintEqualToAnchor:card.centerYAnchor]]];
    return card;
}

- (UIView *)sliderRow:(NSString *)name value:(float)value min:(float)min max:(float)max {
    UIView *card=[UIView new]; card.backgroundColor=[self cardColor]; card.layer.cornerRadius=14;
    card.translatesAutoresizingMaskIntoConstraints=NO; [card.heightAnchor constraintEqualToConstant:88].active=YES;
    UILabel *l=[self label:name size:16 bold:YES]; l.translatesAutoresizingMaskIntoConstraints=NO;
    UISlider *sl=[UISlider new]; sl.minimumValue=min; sl.maximumValue=max; sl.value=value; sl.minimumTrackTintColor=[self orange]; sl.translatesAutoresizingMaskIntoConstraints=NO; sl.accessibilityLabel=name;
    UILabel *v=[self label:[NSString stringWithFormat:@"%.2f",value] size:14 bold:YES]; v.textColor=[self orange]; v.translatesAutoresizingMaskIntoConstraints=NO; v.tag=700;
    [sl addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:l]; [card addSubview:sl]; [card addSubview:v];
    [NSLayoutConstraint activateConstraints:@[[l.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],[l.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],[v.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],[v.centerYAnchor constraintEqualToAnchor:l.centerYAnchor],[sl.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],[sl.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],[sl.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-10]]];
    return card;
}

- (UIButton *)tabButton:(NSString *)title action:(SEL)action {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[self orange] forState:UIControlStateNormal]; b.titleLabel.font=[UIFont boldSystemFontOfSize:13];
    b.layer.cornerRadius=12; b.layer.borderWidth=1; b.layer.borderColor=[self orange].CGColor; b.backgroundColor=[UIColor colorWithWhite:1 alpha:.04];
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside]; [b.heightAnchor constraintEqualToConstant:42].active=YES; return b;
}

- (void)start {
    if (self.floating) return;
    UIWindow *w=JHWindow(); if (!w) { dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2*NSEC_PER_SEC),dispatch_get_main_queue(),^{[self start];}); return; }
    UIButton *f=[UIButton buttonWithType:UIButtonTypeSystem]; self.floating=f; f.frame=CGRectMake(w.bounds.size.width-76, w.bounds.size.height*0.45, 58, 58);
    f.backgroundColor=[UIColor colorWithRed:.08 green:.08 blue:.09 alpha:.95]; f.layer.cornerRadius=29; f.layer.borderWidth=2; f.layer.borderColor=[self orange].CGColor;
    [f setTitle:@"◩" forState:UIControlStateNormal]; [f setTitleColor:[self orange] forState:UIControlStateNormal]; f.titleLabel.font=[UIFont boldSystemFontOfSize:27];
    [f addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]; [f addGestureRecognizer:pan];
    [w addSubview:f];
}

- (void)pan:(UIPanGestureRecognizer *)g { CGPoint t=[g translationInView:g.view.superview]; g.view.center=CGPointMake(g.view.center.x+t.x,g.view.center.y+t.y); [g setTranslation:CGPointZero inView:g.view.superview]; }

- (void)open {
    if (self.panel) { self.panel.hidden=NO; return; }
    UIWindow *w=JHWindow(); if (!w) return;
    UIView *p=[UIView new]; self.panel=p; p.translatesAutoresizingMaskIntoConstraints=NO; p.backgroundColor=[self panelColor]; p.layer.cornerRadius=24; p.layer.borderWidth=1; p.layer.borderColor=[UIColor colorWithWhite:1 alpha:.12].CGColor;
    [w addSubview:p];
    CGFloat width=MIN(w.bounds.size.width-24, 820);
    [NSLayoutConstraint activateConstraints:@[[p.centerXAnchor constraintEqualToAnchor:w.centerXAnchor],[p.centerYAnchor constraintEqualToAnchor:w.centerYAnchor],[p.widthAnchor constraintEqualToConstant:width],[p.heightAnchor constraintEqualToConstant:MIN(w.bounds.size.height-30,650)]]];

    UIView *head=[UIView new]; head.translatesAutoresizingMaskIntoConstraints=NO; [p addSubview:head];
    UILabel *title=[self label:@"i3rby Store" size:24 bold:YES]; title.translatesAutoresizingMaskIntoConstraints=NO; [head addSubview:title];
    UILabel *sub=[self label:@"8 ball pool mod by i3rby · test UI" size:14 bold:NO]; sub.textColor=[UIColor colorWithWhite:.68 alpha:1]; sub.translatesAutoresizingMaskIntoConstraints=NO; [head addSubview:sub];
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem]; [close setTitle:@"✕" forState:UIControlStateNormal]; [close setTitleColor:[self orange] forState:UIControlStateNormal]; close.titleLabel.font=[UIFont boldSystemFontOfSize:25]; close.translatesAutoresizingMaskIntoConstraints=NO; [close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside]; [head addSubview:close];
    [NSLayoutConstraint activateConstraints:@[[head.leadingAnchor constraintEqualToAnchor:p.leadingAnchor],[head.trailingAnchor constraintEqualToAnchor:p.trailingAnchor],[head.topAnchor constraintEqualToAnchor:p.topAnchor],[head.heightAnchor constraintEqualToConstant:92],[title.leadingAnchor constraintEqualToAnchor:head.leadingAnchor constant:24],[title.topAnchor constraintEqualToAnchor:head.topAnchor constant:18],[sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],[sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:5],[close.trailingAnchor constraintEqualToAnchor:head.trailingAnchor constant:-22],[close.centerYAnchor constraintEqualToAnchor:head.centerYAnchor]]];

    UIStackView *tabs=[[UIStackView alloc] initWithArrangedSubviews:@[[self tabButton:@"PREDICTION" action:@selector(showPrediction)],[self tabButton:@"VISUAL TUNING" action:@selector(showVisual)],[self tabButton:@"AUTOMATION" action:@selector(showAutomation)],[self tabButton:@"AUTO QUEUE" action:@selector(showQueue)]]];
    tabs.axis=UILayoutConstraintAxisHorizontal; tabs.distribution=UIStackViewDistributionFillEqually; tabs.spacing=8; tabs.translatesAutoresizingMaskIntoConstraints=NO; [p addSubview:tabs];

    UIScrollView *sc=[UIScrollView new]; self.scroll=sc; sc.translatesAutoresizingMaskIntoConstraints=NO; [p addSubview:sc];
    UIStackView *stack=[UIStackView new]; self.stack=stack; stack.axis=UILayoutConstraintAxisVertical; stack.spacing=10; stack.translatesAutoresizingMaskIntoConstraints=NO; [sc addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[[tabs.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:20],[tabs.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-20],[tabs.topAnchor constraintEqualToAnchor:head.bottomAnchor constant:4],[sc.leadingAnchor constraintEqualToAnchor:p.leadingAnchor constant:20],[sc.trailingAnchor constraintEqualToAnchor:p.trailingAnchor constant:-20],[sc.topAnchor constraintEqualToAnchor:tabs.bottomAnchor constant:12],[sc.bottomAnchor constraintEqualToAnchor:p.bottomAnchor constant:-18],[stack.leadingAnchor constraintEqualToAnchor:sc.contentLayoutGuide.leadingAnchor],[stack.trailingAnchor constraintEqualToAnchor:sc.contentLayoutGuide.trailingAnchor],[stack.topAnchor constraintEqualToAnchor:sc.contentLayoutGuide.topAnchor],[stack.bottomAnchor constraintEqualToAnchor:sc.contentLayoutGuide.bottomAnchor],[stack.widthAnchor constraintEqualToAnchor:sc.frameLayoutGuide.widthAnchor]]];
    [self showPrediction];
}

- (void)clearStack { for (UIView *v in self.stack.arrangedSubviews) { [self.stack removeArrangedSubview:v]; [v removeFromSuperview]; } }
- (void)sectionTitle:(NSString *)t { UILabel *l=[self label:t size:22 bold:YES]; l.textColor=[self orange]; [self.stack addArrangedSubview:l]; }

- (void)showPrediction { [self clearStack]; [self sectionTitle:@"PREDICTION"]; NSArray *items=@[@"Prediction Lines",@"Opponent Lines",@"Table Outline",@"Pocket Rings",@"End Dots",@"Follow Moving Balls",@"Break % Overlay",@"Pot Burst",@"Contact Burst",@"Cushion Burst",@"Strike Burst",@"Ball Trails",@"Scratch Alert",@"Wrong Ball Alert",@"Stream Proof"]; for (NSString *x in items) [self.stack addArrangedSubview:[self toggleRow:x on:NO]]; }
- (void)showVisual { [self clearStack]; [self sectionTitle:@"VISUAL TUNING"]; [self.stack addArrangedSubview:[self toggleRow:@"High Graphic" on:YES]]; [self.stack addArrangedSubview:[self sliderRow:@"Shift Y" value:0 min:-100 max:100]]; [self.stack addArrangedSubview:[self sliderRow:@"Shift X" value:0 min:-100 max:100]]; [self.stack addArrangedSubview:[self sliderRow:@"Line Scale X" value:1 min:.2 max:3]]; [self.stack addArrangedSubview:[self sliderRow:@"Line Scale Y" value:1 min:.2 max:3]]; [self.stack addArrangedSubview:[self sliderRow:@"Line Thickness" value:.6 min:.1 max:3]]; [self.stack addArrangedSubview:[self sliderRow:@"Line Opacity" value:2 min:.1 max:2]]; [self.stack addArrangedSubview:[self sliderRow:@"End Ball Size" value:1 min:.2 max:3]]; [self.stack addArrangedSubview:[self sliderRow:@"Initial Pull" value:.5 min:0 max:1]]; }
- (void)showAutomation { [self clearStack]; [self sectionTitle:@"AUTOMATION"]; [self.stack addArrangedSubview:[self toggleRow:@"Automation" on:NO]]; [self.stack addArrangedSubview:[self toggleRow:@"Auto Select Pocket" on:NO]]; [self.stack addArrangedSubview:[self toggleRow:@"Auto Play" on:NO]]; UILabel *n=[self label:@"Access / PRO controls intentionally are not implemented in this new test UI." size:14 bold:NO]; n.textColor=[UIColor colorWithWhite:.7 alpha:1]; [self.stack addArrangedSubview:n]; }
- (void)showQueue { [self clearStack]; [self sectionTitle:@"AUTO QUEUE"]; [self.stack addArrangedSubview:[self toggleRow:@"Auto Queue" on:NO]]; [self.stack addArrangedSubview:[self toggleRow:@"Shortcut Button" on:NO]]; [self.stack addArrangedSubview:[self sliderRow:@"Queue Delay" value:3 min:0 max:10]]; UILabel *b=[self label:@"Balance: 1.0K" size:18 bold:YES]; b.textColor=[self orange]; [self.stack addArrangedSubview:b]; }

- (void)toggleChanged:(UISwitch *)s { if (s.accessibilityLabel) [[NSUserDefaults standardUserDefaults] setBool:s.on forKey:[@"jh." stringByAppendingString:s.accessibilityLabel]]; }
- (void)sliderChanged:(UISlider *)s { UILabel *v=[s.superview viewWithTag:700]; if ([v isKindOfClass:UILabel.class]) v.text=[NSString stringWithFormat:@"%.2f",s.value]; if (s.accessibilityLabel) [[NSUserDefaults standardUserDefaults] setFloat:s.value forKey:[@"jh." stringByAppendingString:s.accessibilityLabel]]; }
- (void)close { self.panel.hidden=YES; }
@end

__attribute__((constructor)) static void JHInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [[JHTweakMenu shared] start]; });
    });
}
