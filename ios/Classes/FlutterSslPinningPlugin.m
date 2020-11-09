#import "FlutterSslPinningPlugin.h"
#if __has_include(<flutter_ssl_pinning/flutter_ssl_pinning-Swift.h>)
#import <flutter_ssl_pinning/flutter_ssl_pinning-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_ssl_pinning-Swift.h"
#endif

@implementation FlutterSslPinningPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterSslPinningPlugin registerWithRegistrar:registrar];
}
@end
