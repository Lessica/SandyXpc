#import <Foundation/Foundation.h>
#import <libSandyXpc.h>

#import "SandyXpcTestDaemon.h"

#define TAG "SandyXpcTestServer : "

@interface SandyXpcTestServer : NSObject
- (void)onOneWayMessage:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (NSDictionary *)onTwoWayMessage:(NSString *)message userInfo:(NSDictionary *)userInfo;
@end

@implementation SandyXpcTestServer

- (void)onOneWayMessage:(NSString *)message userInfo:(NSDictionary *)userInfo {
    NSLog(@"Received one-way message %@ from %@", message, userInfo[@"name"]);
}

- (NSDictionary *)onTwoWayMessage:(NSString *)message userInfo:(NSDictionary *)userInfo {
    NSLog(@"Received two-way message %@ from %@", message, userInfo[@"name"]);
    return @{
        @"reply" : [NSString
            stringWithFormat:@"Hello, %@! I am %@.", userInfo[@"name"], [[NSProcessInfo processInfo] processName]]
    };
}

@end

int main(int argc, const char *argv[]) {

    @autoreleasepool {
        static SandyXpcTestServer *server;
        server = [[SandyXpcTestServer alloc] init];

        static SandyXpcMessagingCenter *messagingCenter;
        messagingCenter = [SandyXpcMessagingCenter centerNamed:@SANDY_XPC_TEST_DAEMON_NAME];

        [messagingCenter registerForMessageName:@SANDY_XPC_TEST_ONEWAY_MSG_NAME
                                         target:server
                                       selector:@selector(onOneWayMessage:userInfo:)];

        [messagingCenter registerForMessageName:@SANDY_XPC_TEST_TWOWAY_MSG_NAME
                                         target:server
                                       selector:@selector(onTwoWayMessage:userInfo:)];

        [messagingCenter runServer];

        NSLog(@TAG "Daemon is running...");
        CFRunLoopRun();
    }

    return EXIT_SUCCESS;
}
