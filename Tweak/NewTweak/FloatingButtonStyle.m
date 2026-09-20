#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface JHTweakMenu : NSObject
+ (instancetype)shared;
@end

static void StyleKingFloatingButton(void) {
    Class cls=NSClassFromString(@"JHTweakMenu");
    if (!cls || ![cls respondsToSelector:@selector(shared)]) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id menu=[cls performSelector:@selector(shared)];
#pragma clang diagnostic pop
    UIButton *button=nil;
    @try { button=[menu valueForKey:@"floating"]; } @catch (__unused NSException *e) { return; }
    if (![button isKindOfClass:UIButton.class] || !button.superview) return;

    UIView *host=button.superview;
    CGFloat size=64.0;
    CGFloat x=MAX(8.0, host.bounds.size.width-size-18.0);
    CGFloat y=MAX(80.0, MIN(host.bounds.size.height-size-30.0, host.bounds.size.height*0.45));
    button.frame=CGRectMake(x,y,size,size);
    button.layer.cornerRadius=size/2.0;
    button.layer.borderWidth=2.0;
    button.layer.borderColor=[UIColor colorWithRed:.55 green:.31 blue:.03 alpha:1.0].CGColor;
    button.backgroundColor=[UIColor colorWithRed:.075 green:.08 blue:.09 alpha:.98];
    [button setTitle:@"" forState:UIControlStateNormal];

    for (UIGestureRecognizer *g in [button.gestureRecognizers copy]) {
        if ([g isKindOfClass:UIPanGestureRecognizer.class]) [button removeGestureRecognizer:g];
    }

    UIView *old=[button viewWithTag:9901];
    [old removeFromSuperview];

    UIView *logo=[[UIView alloc] initWithFrame:CGRectMake(17,17,30,30)];
    logo.tag=9901;
    logo.userInteractionEnabled=NO;
    logo.backgroundColor=[UIColor colorWithRed:1.0 green:.56 blue:0 alpha:1.0];
    logo.layer.cornerRadius=4.0;
    logo.layer.masksToBounds=YES;

    UIView *slash1=[[UIView alloc] initWithFrame:CGRectMake(-5,8,40,5)];
    slash1.userInteractionEnabled=NO;
    slash1.backgroundColor=[UIColor colorWithRed:.08 green:.08 blue:.09 alpha:1.0];
    slash1.transform=CGAffineTransformMakeRotation((CGFloat)M_PI_4);
    UIView *slash2=[[UIView alloc] initWithFrame:CGRectMake(-5,18,40,5)];
    slash2.userInteractionEnabled=NO;
    slash2.backgroundColor=[UIColor colorWithRed:.08 green:.08 blue:.09 alpha:1.0];
    slash2.transform=CGAffineTransformMakeRotation((CGFloat)M_PI_4);
    [logo addSubview:slash1];
    [logo addSubview:slash2];
    [button addSubview:logo];

    [host bringSubviewToFront:button];
}

__attribute__((constructor)) static void KingFloatingButtonStyleInit(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(3.0*NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
            StyleKingFloatingButton();
        });
    });
}
