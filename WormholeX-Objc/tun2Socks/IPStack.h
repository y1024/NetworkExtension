//
//  IPStack.h
//  tun2Socks
//
//  Created by 杜晓星 on 2017/11/15.
//  Copyright © 2017年 杜晓星. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "lwip.h"
#import "TCPSocket.h"

@protocol IPStackDelegate<NSObject>

- (void)didAcceptTCPSocket:(TCPSocket*)sock;

@end


@interface IPStack : NSObject

@property (nonatomic,weak)id <IPStackDelegate>delegate;

+ (instancetype)defaultTun2SocksIPStack;

- (err_t)didAcceptTCPSocket:(struct tcp_pcb*)pcb
                      error:(err_t)error;
- (void)writeOut:(struct pbuf*)pbuf;

@end
