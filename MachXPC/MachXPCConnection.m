//
//  MachXPCConnection.m
//  MachXPC
//
//  Created by Jeremy on 11/18/20.
//

#import "MachXPCConnection.h"
#import "MachXPC-Internal.h"

#import <bootstrap.h>
#import <mach/mach.h>

@interface MachXPCConnection ()
@property(strong) NSXPCConnection *connection;
@property(retain) NSString *listenerIdentifier;
@end

@implementation MachXPCConnection

- (instancetype)initWithListenerIdentifier:(NSString *)identifier {
    self = [super init];
    _listenerIdentifier = identifier;

    return self;
}

+ (void)connectionFromMachXPCListener:(NSString *)identifier 
                              handler:(void (^)(NSXPCConnection * _Nonnull))handler
{
    [self connectionFromMachXPCListener:identifier
                       qualityOfService:QOS_CLASS_UTILITY
           shouldCallHandlerInMainQueue:YES
                      connectionHandler:handler];
}

+ (void)connectionFromMachXPCListener:(NSString *)identifier
                     qualityOfService:(intptr_t)qos
         shouldCallHandlerInMainQueue:(BOOL)inMainQueue
                    connectionHandler:(void (^)(NSXPCConnection *connection))handler
{
    mach_port_t server_port = MACH_PORT_NULL;
    mach_port_t client_port = MACH_PORT_NULL;

    kern_return_t kr = bootstrap_look_up(bootstrap_port, identifier.UTF8String, &server_port);
    if (kr != KERN_SUCCESS) {
        handler(NULL);
        return;
    }

    kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &client_port);
    if (kr != KERN_SUCCESS) {
        handler(NULL);
        return;
    }

    dispatch_async(dispatch_get_global_queue(qos, 0), ^{
        kern_return_t kr;
        mach_msg_header_t header;

        header.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND);
        header.msgh_local_port = client_port;
        header.msgh_remote_port = server_port;
        header.msgh_size = sizeof(mach_msg_header_t);
        header.msgh_id = 888;

        kr = mach_msg(&header, MACH_SEND_MSG | MACH_SEND_TIMEOUT, header.msgh_size, 0, MACH_PORT_NULL, 5000, MACH_PORT_NULL);

        if (kr != KERN_SUCCESS) {
            if (inMainQueue) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(NULL);
                });
            } else {
                handler(NULL);
            }
            return;
        }

        msg_format_response_r_t recv_msg;
        mach_msg_header_t *recv_hdr;

        recv_hdr = &(recv_msg.header);
        recv_hdr->msgh_remote_port = server_port;
        recv_hdr->msgh_local_port = MACH_PORT_NULL;
        recv_hdr->msgh_size = sizeof(recv_msg);
        recv_msg.data.name = 0;

        kr = mach_msg(recv_hdr, MACH_RCV_MSG | MACH_RCV_TIMEOUT, 0, recv_hdr->msgh_size, client_port, 5000, MACH_PORT_NULL);

        if (kr != KERN_SUCCESS) {
            if (inMainQueue) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(NULL);
                });
            } else {
                handler(NULL);
            }
            return;
        }

        mach_port_t endpoint_port = recv_msg.data.name;
        xpc_endpoint_t xpcEndpoint = _xpc_endpoint_create(endpoint_port);
        NSXPCListenerEndpoint *listener = [[NSXPCListenerEndpoint alloc] init];
        [listener _setEndpoint:xpcEndpoint];

        if (inMainQueue) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler([[NSXPCConnection alloc] initWithListenerEndpoint:listener]);
            });
        } else {
            handler([[NSXPCConnection alloc] initWithListenerEndpoint:listener]);
        }
    });
}

@end
