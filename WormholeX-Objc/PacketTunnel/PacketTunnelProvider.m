//
//  PacketTunnelProvider.m
//  PacketTunnel
//
//  Created by 杜晓星 on 2017/11/14.
//Copyright © 2017年 杜晓星. All rights reserved.
//

#import <NetworkExtension/NetworkExtension.h>
#import "PacketTunnelProvider.h"

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler
{
    NETunnelProviderProtocol *tunnelProviderProtocol = (NETunnelProviderProtocol*)self.protocolConfiguration;
    
    // 读取配置信息
    NSDictionary *providerConfiguration = tunnelProviderProtocol.providerConfiguration;
    NSString *ss_address = providerConfiguration[@"ss_address"];
    NSInteger ss_port = [providerConfiguration[@"ss_port"]integerValue];
    NSString *ss_method = providerConfiguration[@"ss_method"];
    NSString *ymal_conf = providerConfiguration[@"ymal_conf"];
    
    
    
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler
{
	// Add code here to start the process of stopping the tunnel.
	completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler
{
	// Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler
{
	// Add code here to get ready to sleep.
	completionHandler();
}

- (void)wake
{
	// Add code here to wake up.
}

@end
