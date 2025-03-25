//
//  NSXPCConnection+Private.h
//  SandyXpc
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSXPCConnection (Private)

- (id)valueForEntitlement:(NSString *)entitlementKey;

@end

NS_ASSUME_NONNULL_END
