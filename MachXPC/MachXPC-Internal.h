//
//  MachXPC-Internal.h
//  MachXPC
//
//  Created by Jeremy on 10/15/20.
//

#ifndef MachXPC_Internal_h
#define MachXPC_Internal_h

#import <Foundation/Foundation.h>
#import <xpc/xpc.h>

typedef struct {
    mach_msg_header_t header;
} msg_format_request_t;

// receive-side version of the request message (as seen by the server)
typedef struct {
    mach_msg_header_t header;
    mach_msg_trailer_t trailer;
} msg_format_request_r_t;

// send-side version of the response message (as seen by the server)
typedef struct {
    mach_msg_header_t header;
    mach_msg_body_t body;            // start of kernel processed data
    mach_msg_port_descriptor_t data; // end of kernel processed data
    mach_msg_ool_descriptor64_t ool;
} msg_format_response_t;

// receive-side version of the response message (as seen by the client)
typedef struct {
    mach_msg_header_t header;
    mach_msg_body_t body;
    mach_msg_port_descriptor_t data;
    mach_msg_ool_descriptor64_t ool;
    mach_msg_trailer_t trailer;
} msg_format_response_r_t;

@interface NSXPCListenerEndpoint (Private)
- (void)_setEndpoint:(xpc_endpoint_t)xpcEndpoint;
- (xpc_endpoint_t)_endpoint;
@end

OBJC_EXTERN xpc_endpoint_t (*_xpc_endpoint_create)(mach_port_t);

#if DEBUG
    #define MachLog(fmt, ...) NSLog((@"%s:%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define MachLog(fmt, ...)
#endif

#endif /* MachXPC_Internal_h */
