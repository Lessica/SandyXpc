//
//  SandyXpcConnection.m
//  SandyXpc
//

#import "SandyXpcConnection.h"

#define TAG "SandyXpcConnection : "

@interface SandyXpcConnection ()

@property(nonatomic, strong) id<SandyXpcClient> clientProxy;

@end

@implementation SandyXpcConnection {
    dispatch_queue_t mCallbackQueue;
}

- (instancetype)initWithConnection:(NSXPCConnection *)connection callbackQueue:(nonnull dispatch_queue_t)callbackQueue {
    self = [super init];
    if (self) {
        _connection = connection;
        _clientProxy = (id<SandyXpcClient>)connection.remoteObjectProxy;
        mCallbackQueue = callbackQueue;
    }
    return self;
}

#pragma mark - SandyXpcServer

- (void)ping {
    __weak typeof(self) weakSelf = self;
    dispatch_async(mCallbackQueue, ^(void) {
        [weakSelf.clientProxy pong];
    });
}

- (void)sendMessageWithName:(NSString *)name arguments:(NSArray *)arguments {
    NSInvocation *handler = self.messageHandlers[name];
    NSAssert(handler, @"unable to select handler for message %@", name);

    // + self, _cmd
    NSAssert(handler.methodSignature.numberOfArguments == arguments.count + 2,
             @"invalid number of arguments for message %@", name);

    NSInteger argumentIndex = 2;
    for (NSObject *argument in arguments) {
        void *argumentPtr = (__bridge void *)(argument);
        [handler setArgument:&argumentPtr atIndex:argumentIndex];
        argumentIndex++;
    }

    NSArray *retainedArguments = [arguments copy];
    dispatch_async(mCallbackQueue, ^(void) {
        [handler invoke];

        // just here to retain the arguments
        (void)retainedArguments;

        if ([handler.methodSignature methodReturnLength] > 0) {
            id __unsafe_unretained retVal;
            [handler getReturnValue:&retVal];

            id safeReturnValue = retVal;
            if (safeReturnValue) {
                [self.clientProxy receiveMessageWithName:name
                                               arguments:[NSArray arrayWithObjects:name, safeReturnValue, nil]];
            } else {
                [self.clientProxy receiveMessageWithName:name arguments:[NSArray arrayWithObjects:name, nil]];
            }
        }
    });
}

@end
