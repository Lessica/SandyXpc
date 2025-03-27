//
//  SandyXpcMessagingCenter.m
//  SandyXpc
//

#import "SandyXpcMessagingCenter.h"
#import "SandyXpcConnection.h"

#import <MachXPC/MachXPCConnection.h>
#import <MachXPC/MachXPCListener.h>
#import <NSXPCConnection+Private.h>

#define TAG "SandyXpcMessagingCenter : "

@interface SandyXpcMessagingCenter () <NSXPCListenerDelegate, SandyXpcClient>
@end

@implementation SandyXpcMessagingCenter {
    /* Server */
    NSRunLoop *mServerRunLoop;
    MachXPCListener *mListener;
    NSMutableArray<NSXPCConnection *> *mConnections;
    NSString *mProtectedEntitlementKey;
    NSMutableDictionary<NSString *, NSInvocation *> *mMessageHandlers;

    /* Client */
    dispatch_queue_t mClientQueue;
    NSXPCConnection *mClientConnection;
    NSMutableDictionary<NSString *, dispatch_semaphore_t> *mMessageBlockers;
    NSMutableDictionary<NSString *, id> *mMessageReplies;
}

+ (instancetype)centerNamed:(NSString *)name {
    return [[self alloc] initWithName:name];
}

+ (instancetype)centerNamed:(NSString *)name callbackQueue:(dispatch_queue_t)callbackQueue {
    return [[self alloc] initWithName:name callbackQueue:callbackQueue];
}

- (instancetype)initWithName:(NSString *)name {
    return [self initWithName:name
                callbackQueue:dispatch_queue_create([NSString stringWithFormat:@"%@/machXPC_client_q", name].UTF8String,
                                                    DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL)];
}

- (instancetype)initWithName:(NSString *)name callbackQueue:(dispatch_queue_t)callbackQueue {
    self = [super init];
    if (self) {
        _name = [name copy];
        mClientQueue = callbackQueue;
        mConnections = [[NSMutableArray alloc] init];
        mMessageBlockers = [[NSMutableDictionary alloc] init];
        mMessageHandlers = [[NSMutableDictionary alloc] init];
        mMessageReplies = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self stopServer];
    [mClientConnection invalidate];

    for (NSXPCConnection *connection in mConnections) {
        [connection invalidate];
    }
}

#pragma mark - Server

- (void)runServer {
    [self runServerProtectedByEntitlement:@""];
}

- (void)runServerProtectedByEntitlement:(NSString *)entitlementKey {
    mProtectedEntitlementKey = [entitlementKey copy];

    if (!mListener) {
        mListener = [[MachXPCListener alloc] initWithObject:self identifier:self.name];
    }

    NSAssert(mListener, @"invalid listener");

    [mListener resume];
}

- (void)runServerOnCurrentThread {
    [self runServerOnCurrentThreadProtectedByEntitlement:@""];
}

- (void)runServerOnCurrentThreadProtectedByEntitlement:(NSString *)entitlementKey {
    mServerRunLoop = [NSRunLoop currentRunLoop];
    NSAssert(mServerRunLoop, @"invalid run loop");

    [self runServerProtectedByEntitlement:entitlementKey];
}

- (void)stopServer {
    [mListener suspend];
}

- (void)registerForMessageName:(NSString *)messageName target:(id)target selector:(SEL)selector {
    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    NSAssert(signature, @"invalid method signature");

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    NSAssert(invocation, @"invalid invocation");

    [invocation setTarget:target];
    [invocation setSelector:selector];

    mMessageHandlers[messageName] = invocation;
}

#pragma mark - Client

- (BOOL)sendMessageName:(NSString *)messageName userInfo:(NSDictionary *)userInfo {

    __block BOOL success = NO;
    __block NSError *error = nil;

    dispatch_sync(mClientQueue, ^{
        NSAssert(!mListener, @"you cannot send messages from a server");

        id<SandyXpcServer> serverProxy = [self establishConnectionWithErrorHandler:^(NSError *_Nonnull err) {
            NSLog(@TAG "remote proxy error occurred: %@", err);
            error = err;
        }];

        if (!serverProxy) {
            return;
        }

        /* One-way message */
        [serverProxy sendMessageWithName:messageName arguments:[NSArray arrayWithObjects:messageName, userInfo, nil]];

        success = YES;
    });

    return success && !error;
}

- (NSDictionary *)sendMessageAndReceiveReplyName:(NSString *)messageName userInfo:(NSDictionary *)userInfo {
    return [self sendMessageAndReceiveReplyName:messageName userInfo:userInfo error:nil];
}

- (NSDictionary *)sendMessageAndReceiveReplyName:(NSString *)messageName
                                        userInfo:(NSDictionary *)userInfo
                                           error:(NSError **)errorPtr {

    __block id reply = nil;
    __block NSError *error = nil;

    dispatch_sync(mClientQueue, ^{
        NSAssert(!mListener, @"you cannot send messages from a server");

        id<SandyXpcServer> serverProxy = [self establishConnectionWithErrorHandler:^(NSError *_Nonnull err) {
            NSLog(@TAG "remote proxy error occurred: %@", err);
            error = err;
        }];

        if (!serverProxy) {
            return;
        }

        /* Two-way message */
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        mMessageBlockers[messageName] = semaphore;

        [serverProxy sendMessageWithName:messageName arguments:[NSArray arrayWithObjects:messageName, userInfo, nil]];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        reply = mMessageReplies[messageName];
        mMessageReplies[messageName] = nil;
    });

    if (error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        return nil;
    }

    return reply;
}

- (void)receiveMessageWithName:(NSString *)name arguments:(NSArray *)arguments {
    NSAssert(arguments.count > 0, @"invalid arguments");

    NSString *messageName = arguments[0];
    dispatch_semaphore_t semaphore = mMessageBlockers[messageName];

    if (semaphore) {
        if (arguments.count > 1) {
            id reply = arguments[1];
            mMessageReplies[messageName] = reply;
        }

        dispatch_semaphore_signal(semaphore);
    }
}

- (id<SandyXpcServer>)establishConnectionWithErrorHandler:(void (^)(NSError *_Nonnull))errorHandler {
    if (!mClientConnection) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        __weak typeof(self) weakSelf = self;
        void (^handler)(NSXPCConnection *_Nonnull) = ^(NSXPCConnection *_Nonnull connection) {
            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (!connection) {
                dispatch_semaphore_signal(semaphore);
                return;
            }

            connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SandyXpcServer)];
            connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SandyXpcClient)];
            connection.exportedObject = strongSelf; // <-- avoid retain cycle

            connection.invalidationHandler = connection.interruptionHandler = ^{
                NSLog(@TAG "connection invalidated");
                strongSelf->mClientConnection = nil;
                [[strongSelf->mMessageBlockers allValues]
                    enumerateObjectsUsingBlock:^(dispatch_semaphore_t _Nonnull semaphore, NSUInteger idx,
                                                 BOOL *_Nonnull stop) {
                        dispatch_semaphore_signal(semaphore);
                    }];
                [strongSelf->mMessageBlockers removeAllObjects];
            };

            [connection resume];

            mClientConnection = connection;
            dispatch_semaphore_signal(semaphore);
        };

        [MachXPCConnection connectionFromMachXPCListener:self.name
                                        qualityOfService:QOS_CLASS_USER_INTERACTIVE
                            shouldCallHandlerInMainQueue:NO
                                       connectionHandler:handler];

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }

    return [mClientConnection remoteObjectProxyWithErrorHandler:errorHandler];
}

#pragma mark - NSXPCListener (Server)

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    if (mProtectedEntitlementKey.length > 0) {
        if (![newConnection respondsToSelector:@selector(valueForEntitlement:)]) {
            return NO;
        }

        id entitlementValue = [newConnection valueForEntitlement:mProtectedEntitlementKey];
        if (!entitlementValue || ![entitlementValue isKindOfClass:[NSNumber class]]) {
            NSLog(@TAG "refusing connection due to missing entitlement %@", mProtectedEntitlementKey);
            return NO;
        }

        BOOL hasEntitlement = [entitlementValue boolValue];
        if (!hasEntitlement) {
            return NO;
        }
    }

    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SandyXpcClient)];
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(SandyXpcServer)];

    SandyXpcConnection *connectionProxy = [[SandyXpcConnection alloc] initWithConnection:newConnection
                                                                           callbackQueue:mClientQueue
                                                                         callbackRunLoop:mServerRunLoop];
    [connectionProxy setMessageHandlers:[mMessageHandlers copy]];

    newConnection.exportedObject = connectionProxy;

    [newConnection resume];

    [mConnections addObject:newConnection];
    __weak NSXPCConnection *weakConnection = newConnection;
    newConnection.invalidationHandler = newConnection.interruptionHandler = ^{
        [mConnections removeObject:weakConnection];
    };

    return YES;
}

#pragma mark - Ping Pong

- (void)pong {
    NSLog(@TAG "pong");
}

- (void)ping {
    dispatch_sync(mClientQueue, ^{
        NSAssert(!mListener, @"you cannot send messages from a server");

        id<SandyXpcServer> serverProxy = [self establishConnectionWithErrorHandler:^(NSError *_Nonnull err) {
            NSLog(@TAG "remote proxy error occurred: %@", err);
        }];

        if (!serverProxy) {
            return;
        }

        [serverProxy ping];
    });
}

@end
