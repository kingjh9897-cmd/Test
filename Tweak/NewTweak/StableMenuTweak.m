#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static UIWindow *KingActiveWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws=(UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) if (w.isKeyWindow) return w;
            for (UIWindow *w in ws.windows) if (!w.hidden && w.alpha > 0.01) return w;
        }
    }
    return nil;
}

@interface KingStableMenu : NSObject
@property(nonatomic,strong) UIButton *menuButton;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIScrollView *scroll;
@end

@implementation KingStableMenu

+ (instancetype)shared {
    static KingStableMenu *obj;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ obj=[KingStableMenu new]; });
    return obj;
}

- (UIColor *)orange { return [UIColor colorWithRed:1.0 green:0.56 blue:0.0 alpha:1.0]; }
- (UIColor *)dark { return [UIColor colorWithRed:0.07 green:0.075 blue:0.085 alpha:0.98]; }
- (UIColor *)card { return [UIColor colorWithRed:0.12 green:0.125 blue:0.14 alpha:1.0]; }

- (void)start {
    if (self.menuButton) return;
    UIWindow *w=KingActiveWindow();
    if (!w) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self start]; });
        return;
    }

    CGFloat size=64.0;
    CGFloat x=MAX(8.0, w.bounds.size.width-size-18.0);
    CGFloat y=MAX(70.0, MIN(w.bounds.size.height-size-25.0, w.bounds.size.height*0.45));

    UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
    self.menuButton=b;
    b.frame=CGRectMake(x,y,size,size);
    b.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    b.backgroundColor=[self dark];
    b.layer.cornerRadius=size/2.0;
    b.layer.borderWidth=2.0;
    b.layer.borderColor=[UIColor colorWithRed:.55 green:.31 blue:.03 alpha:1.0].CGColor;
    [b addTarget:self action:@selector(openMenu) forControlEvents:UIControlEventTouchUpInside];

    UIView *logo=[[UIView alloc] initWithFrame:CGRectMake(17,17,30,30)];
    logo.userInteractionEnabled=NO;
    logo.backgroundColor=[self orange];
    logo.layer.cornerRadius=4.0;
    logo.clipsToBounds=YES;

    UIView *d1=[[UIView alloc] initWithFrame:CGRectMake(-3,7,38,5)];
    d1.backgroundColor=[self dark];
    d1.transform=CGAffineTransformMakeRotation(0.78539816339);
    UIView *d2=[[UIView alloc] initWithFrame:CGRectMake(-3,18,38,5)];
    d2.backgroundColor=[self dark];
    d2.transform=CGAffineTransformMakeRotation(0.78539816339);
    [logo addSubview:d1];
    [logo addSubview:d2];
    [b addSubview:logo];
    [w addSubview:b];
}

- (UILabel *)label:(NSString *)text frame:(CGRect)frame size:(CGFloat)size bold:(BOOL)bold {
    UILabel *l=[[UILabel alloc] initWithFrame:frame];
    l.text=text;
    l.textColor=UIColor.whiteColor;
    l.font=bold?[UIFont boldSystemFontOfSize:size]:[UIFont systemFontOfSize:size];
    return l;
}

- (UIView *)toggleRow:(NSString *)name y:(CGFloat)y on:(BOOL)on {
    UIView *row=[[UIView alloc] initWithFrame:CGRectMake(18,y,504,58)];
    row.backgroundColor=[self card];
    row.layer.cornerRadius=12;
    UILabel *lab=[self label:name frame:CGRectMake(16,0,360,58) size:16 bold:YES];
    UISwitch *sw=[[UISwitch alloc] initWithFrame:CGRectZero];
    sw.on=on;
    sw.onTintColor=[self orange];
    CGSize s=sw.bounds.size;
    sw.frame=CGRectMake(row.bounds.size.width-s.width-16,(58-s.height)/2,s.width,s.height);
    sw.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin;
    [row addSubview:lab];
    [row addSubview:sw];
    return row;
}

- (void)openMenu {
    UIWindow *w=KingActiveWindow();
    if (!w) return;
    if (self.panel) { self.panel.hidden=NO; [w bringSubviewToFront:self.panel]; return; }

    CGFloat pw=MIN(640.0, w.bounds.size.width-24.0);
    CGFloat ph=MIN(520.0, w.bounds.size.height-24.0);
    UIView *p=[[UIView alloc] initWithFrame:CGRectMake((w.bounds.size.width-pw)/2.0,(w.bounds.size.height-ph)/2.0,pw,ph)];
    self.panel=p;
    p.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    p.backgroundColor=[self dark];
    p.layer.cornerRadius=22;
    p.layer.borderWidth=1;
    p.layer.borderColor=[UIColor colorWithWhite:1 alpha:.12].CGColor;
    p.clipsToBounds=YES;

    UILabel *title=[self label:@"King Tweak" frame:CGRectMake(24,14,pw-120,34) size:24 bold:YES];
    UILabel *sub=[self label:@"8 Ball Pool custom overlay" frame:CGRectMake(24,47,pw-120,24) size:14 bold:NO];
    sub.textColor=[UIColor colorWithWhite:.65 alpha:1];

    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];
    close.frame=CGRectMake(pw-62,15,44,44);
    close.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:[self orange] forState:UIControlStateNormal];
    close.titleLabel.font=[UIFont boldSystemFontOfSize:22];
    close.backgroundColor=[UIColor colorWithWhite:1 alpha:.07];
    close.layer.cornerRadius=22;
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];

    UIView *line=[[UIView alloc] initWithFrame:CGRectMake(0,82,pw,1)];
    line.backgroundColor=[UIColor colorWithWhite:1 alpha:.1];

    UIScrollView *sc=[[UIScrollView alloc] initWithFrame:CGRectMake(0,83,pw,ph-83)];
    self.scroll=sc;
    sc.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    sc.backgroundColor=UIColor.clearColor;

    UILabel *section=[self label:@"PREDICTION" frame:CGRectMake(18,14,pw-36,42) size:18 bold:YES];
    section.textColor=[self orange];
    [sc addSubview:section];

    NSArray *names=@[@"Prediction Lines",@"Opponent Lines",@"Table Outline",@"Pocket Rings",@"End Dots",@"Precise Paths",@"Scratch Alert",@"Wrong Ball Alert",@"Stream Proof"];
    NSArray *defs=@[@YES,@NO,@YES,@YES,@YES,@YES,@YES,@YES,@NO];
    CGFloat y=62;
    for (NSInteger i=0;i<names.count;i++) {
        UIView *row=[self toggleRow:names[i] y:y on:[defs[i] boolValue]];
        row.frame=CGRectMake(18,y,pw-36,58);
        [sc addSubview:row];
        y+=68;
    }
    sc.contentSize=CGSizeMake(pw,y+18);

    [p addSubview:title];
    [p addSubview:sub];
    [p addSubview:close];
    [p addSubview:line];
    [p addSubview:sc];
    [w addSubview:p];
}

- (void)closeMenu { self.panel.hidden=YES; }

@end

__attribute__((constructor)) static void KingStableInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[KingStableMenu shared] start];
        });
    });
}
