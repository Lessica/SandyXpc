//
//  SandyXpcMessagingCenter.h
//  SandyXpc
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_VISIBLE
@interface SandyXpcMessagingCenter : NSObject

@property(nonatomic, copy, readonly) NSString *name;

+ (instancetype)centerNamed:(NSString *)name;
+ (instancetype)centerNamed:(NSString *)name callbackQueue:(dispatch_queue_t)callbackQueue;

- (instancetype)init NS_UNAVAILABLE;

/* dispatch_queue */
- (void)runServer;
- (void)runServerProtectedByEntitlement:(NSString *)entitlementKey;

/* NSRunLoop */
- (void)runServerOnCurrentThread;
- (void)runServerOnCurrentThreadProtectedByEntitlement:(NSString *)entitlementKey;

- (void)stopServer;

- (void)registerForMessageName:(NSString *)messageName target:(id)target selector:(SEL)selector;

- (void)ping;
- (BOOL)sendMessageName:(NSString *)messageName userInfo:(NSDictionary *)userInfo;

- (NSDictionary *_Nullable)sendMessageAndReceiveReplyName:(NSString *)messageName userInfo:(NSDictionary *)userInfo;
- (NSDictionary *_Nullable)sendMessageAndReceiveReplyName:(NSString *)messageName
                                                 userInfo:(NSDictionary *)userInfo
                                                    error:(NSError *__autoreleasing *_Nullable)error;

@end

#if DEBUG
    #define SandyXpcLog(fmt, ...) NSLog((@"%s:%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define SandyXpcLog(fmt, ...)
#endif

NS_ASSUME_NONNULL_END
