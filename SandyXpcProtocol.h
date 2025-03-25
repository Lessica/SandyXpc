//
//  SandyXpcProtocol.h
//  SandyXpc
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SandyXpcClient <NSObject>

- (void)pong;
- (void)receiveMessageWithName:(NSString *)name arguments:(NSArray *)arguments;

@end

@protocol SandyXpcServer <NSObject>

- (void)ping;
- (void)sendMessageWithName:(NSString *)name arguments:(NSArray *)arguments;

@end

NS_ASSUME_NONNULL_END
