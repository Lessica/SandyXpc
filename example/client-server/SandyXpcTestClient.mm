#import <Foundation/Foundation.h>
#import <libSandyXpc.h>

#import "SandyXpcTestServer.h"

#define TAG "SandyXpcTestClient : "

int main(int argc, const char *argv[]) {

    @autoreleasepool {
        static SandyXpcMessagingCenter *messagingCenter;
        messagingCenter = [SandyXpcMessagingCenter centerNamed:@SANDY_XPC_TEST_SERVER_NAME];

        NSDictionary *msgBody = @{@"name" : [[NSProcessInfo processInfo] processName]};
        [messagingCenter sendMessageName:@SANDY_XPC_TEST_ONEWAY_MSG_NAME userInfo:msgBody];

        NSError *error = nil;
        NSDictionary *retVal = nil;

        retVal = [messagingCenter sendMessageAndReceiveReplyName:@SANDY_XPC_TEST_TWOWAY_MSG_NAME
                                                        userInfo:msgBody
                                                           error:&error];

        if (error) {
            NSLog(@TAG "Error occurred: %@", error);
            return EXIT_FAILURE;
        }

        if (!retVal[@"reply"]) {
            NSLog(@TAG "No reply received");
            return EXIT_FAILURE;
        }

        printf("%s\n", [retVal[@"reply"] UTF8String]);
    }

    return EXIT_SUCCESS;
}
