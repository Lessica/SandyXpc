//
//  MachXPCConnection.h
//  MachXPC
//
//  Created by Jeremy on 11/18/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden")))
@interface MachXPCConnection : NSObject

+ (void)connectionFromMachXPCListener:(NSString *)identifier
                              handler:(void (^)(NSXPCConnection *connection))handler;

+ (void)connectionFromMachXPCListener:(NSString *)identifier
                     qualityOfService:(intptr_t)qos
         shouldCallHandlerInMainQueue:(BOOL)inMainQueue
                    connectionHandler:(void (^)(NSXPCConnection *connection))handler;

@end

NS_ASSUME_NONNULL_END
