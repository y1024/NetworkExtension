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

    /*
    NSError *tunnelInterface = [TunnelInterface setupWithPacketTunnelFlow:self.packetFlow];
    if (tunnelInterface) {
        completionHandler(tunnelInterface);
        exit(1);
        return;
    }
    */
    /*
    NETunnelProviderProtocol *tunnelProviderProtocol = (NETunnelProviderProtocol*)self.protocolConfiguration;
    NSDictionary *providerConfiguration = tunnelProviderProtocol.providerConfiguration;
    NSString *ss_address = providerConfiguration[@"ss_address"];
    NSInteger ss_port = [providerConfiguration[@"ss_port"]integerValue];
    NSString *ss_method = providerConfiguration[@"ss_method"];
    NSString *ymal_conf = providerConfiguration[@"ymal_conf"];
     
    */
    NEPacketTunnelNetworkSettings *tunnelNetworkSettings = [self defaultPacketTunnelNetworkSettings];
    [self setTunnelNetworkSettings:tunnelNetworkSettings completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"setTunnelNetworkSettings:%@",error);
            completionHandler(error);
        }
        else {
            NSLog(@"startTunnelWithOptions success");
            completionHandler(nil);
        }
    }];
    
}

- (void)processPackets {
    __weak __typeof(self)ws = self;
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols) {
        NSInteger total = packets.count;
        for (int packet_index = 0; packet_index < total; packet_index ++) {
            
            NSNumber *protocol = protocols[packet_index];
            // ipV4协议
            if (protocol.integerValue == AF_INET) {
            
            }
            // ipV6协议
            else if (protocol.integerValue == AF_INET6) {

            }
            else {
                
            }
            
            NSData *packet = packets[packet_index];

            NSData *ip_version = [packet subdataWithRange:NSMakeRange(0, 1)];
            NSUInteger ip_version_len = [ip_version length];
            Byte *ip_version_bytes = (Byte*)malloc(ip_version_len);
            memcpy(ip_version_bytes, [ip_version bytes], ip_version_len);

            NSLog(@"%s",ip_version_bytes);
            free(ip_version_bytes);
            
            
        }
        [ws processPackets];
    }];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"stopTunnelWithReason:%ld",(long)reason);
	completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler
{
    NSLog(@"handleAppMessage:%@",[[NSString alloc]initWithData:messageData encoding:NSUTF8StringEncoding]);
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler
{
    NSLog(@"sleepWithCompletionHandler");
	completionHandler();
}

- (void)wake
{
    NSLog(@"wake");
}


#pragma mark default

- (NEPacketTunnelNetworkSettings*)defaultPacketTunnelNetworkSettings {
    NEIPv4Settings *iPv4Settings = [self defaultIPv4Settings];
    NEPacketTunnelNetworkSettings *tunnelNetworkSettings = [[NEPacketTunnelNetworkSettings alloc]initWithTunnelRemoteAddress:@"192.0.2.2"];
    tunnelNetworkSettings.MTU = @(1500);
    tunnelNetworkSettings.IPv4Settings = iPv4Settings;
    tunnelNetworkSettings.proxySettings = [self defaultProxySettings];
    return tunnelNetworkSettings;
}


- (NEProxySettings*)defaultProxySettings {
    NEProxySettings *proxySettings = [[NEProxySettings alloc]init];
    proxySettings.HTTPEnabled = true;
    proxySettings.HTTPSEnabled = true;
    
    NSString  *proxyServerAddress = @"localhost";
    NSInteger proxyServerPort = 80;
    proxySettings.HTTPServer = ({
        NEProxyServer *server = [[NEProxyServer alloc]initWithAddress:proxyServerAddress port:proxyServerPort];
        server;
    });
    proxySettings.HTTPServer = ({
        NEProxyServer *server = [[NEProxyServer alloc]initWithAddress:proxyServerAddress port:proxyServerPort];
        server;
    });
    proxySettings.excludeSimpleHostnames = true;
    return proxySettings;
}


- (NEIPv4Settings*)defaultIPv4Settings {
    NEIPv4Settings *iPv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.0.2.1"] subnetMasks:@[@"255.255.255.0"]];
    iPv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
    return iPv4Settings;
}


- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    
}


@end
