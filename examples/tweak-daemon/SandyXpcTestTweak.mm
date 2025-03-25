#import <CaptainHook/CaptainHook.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <libSandy.h>
#import <libSandyXpc.h>

#import "SandyXpcTestDaemon.h"

#define TAG "SandyXpcTestTweak : "

static void TestConnection(void) {
    static SandyXpcMessagingCenter *messagingCenter;
    messagingCenter = [SandyXpcMessagingCenter centerNamed:@SANDY_XPC_TEST_DAEMON_NAME];

    NSDictionary *msgBody = @{@"name" : [[NSBundle mainBundle] bundleIdentifier] ?: @"Sandy"};
    [messagingCenter sendMessageName:@SANDY_XPC_TEST_ONEWAY_MSG_NAME userInfo:msgBody];

    NSError *error = nil;
    NSDictionary *retVal = nil;

    retVal = [messagingCenter sendMessageAndReceiveReplyName:@SANDY_XPC_TEST_TWOWAY_MSG_NAME
                                                    userInfo:msgBody
                                                       error:&error];

    if (error) {
        NSLog(@TAG "Error occurred: %@", error);
        return;
    }

    if (!retVal[@"reply"]) {
        NSLog(@TAG "No reply received");
        return;
    }

    NSLog(@TAG "Received reply: %@", retVal[@"reply"]);
}

CHConstructor {
    @autoreleasepool {
        void *sandyHandle = dlopen("@rpath/libsandy.dylib", RTLD_LAZY);
        if (sandyHandle) {
            int (*__dyn_libSandy_applyProfile)(const char *profileName) =
                (int (*)(const char *))dlsym(sandyHandle, "libSandy_applyProfile");
            if (__dyn_libSandy_applyProfile) {
                int sandyStatus = __dyn_libSandy_applyProfile("SandyXpcTestTweak");
                if (sandyStatus == kLibSandyErrorXPCFailure) {
                    NSLog(@TAG "Failed to apply profile");
                } else {
                    NSLog(@TAG "Profile applied");
                }
            }
        }

        TestConnection();
    }
}
