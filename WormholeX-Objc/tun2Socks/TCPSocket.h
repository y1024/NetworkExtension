//
//  TCPSocket.h
//  tun2Socks
//
//  Created by 杜晓星 on 2017/11/15.
//  Copyright © 2017年 杜晓星. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "lwip.h"

@class TCPSocket;

@protocol TCPSocketDelegate<NSObject>

- (void)localDidClose:(TCPSocket*)sock;
- (void)socketDidReset:(TCPSocket*)sock;
- (void)socketDidAbort:(TCPSocket*)sock;
- (void)socketDidClose:(TCPSocket*)sock;

- (void)didReadData:(NSData*)data from:(TCPSocket*)sock;

- (void)didWriteData:(NSInteger)length from:(TCPSocket*)sock;


@end


@interface TCPSocket : NSObject

@property (nonatomic, weak) id<TCPSocketDelegate> delegate;

- (instancetype)initWith:(struct tcp_pcb*)pcb queue:(dispatch_queue_t)queue;

@end
