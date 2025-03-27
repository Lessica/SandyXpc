//
//  SandyXpcConnection.h
//  SandyXpc
//

#import "SandyXpcProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface SandyXpcConnection : NSObject <SandyXpcServer>

@property(nonatomic, weak, readonly) NSXPCConnection *connection;
@property(nonatomic, strong) NSDictionary<NSString *, NSInvocation *> *messageHandlers;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConnection:(NSXPCConnection *)connection
                     callbackQueue:(dispatch_queue_t)callbackQueue
                   callbackRunLoop:(NSRunLoop *_Nullable)callbackRunLoop;

@end

NS_ASSUME_NONNULL_END
