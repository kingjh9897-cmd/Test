#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Exact exported symbol used by the working libloader.
// ABI recovered from the original arm64 function:
//   w0 = argc
//   x1 = argv
//   x2 = principalClassName
//   x3 = delegateClassName
// Return value is UIApplicationMain's int result in w0.
__attribute__((visibility("default")))
int KingCompatibilityUIApplicationMain(int argc,
                                       char * _Nullable argv[],
                                       NSString * _Nullable principalClassName,
                                       NSString * _Nullable delegateClassName)
    __asm__("iBWuJnPubwtWJIGVxT");

int KingCompatibilityUIApplicationMain(int argc,
                                       char * _Nullable argv[],
                                       NSString * _Nullable principalClassName,
                                       NSString * _Nullable delegateClassName) {
    return UIApplicationMain(argc, argv, principalClassName, delegateClassName);
}
