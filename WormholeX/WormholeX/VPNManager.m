//
//  VPNManager.m
//  WormholeX
//
//  Created by 杜晓星 on 2017/11/13.
//  Copyright © 2017年 杜晓星. All rights reserved.
//

#import "VPNManager.h"
#import <NetworkExtension/NetworkExtension.h>

NSString *const kProxyServiceVPNStatusNotification = @"kProxyServiceVPNStatusNotification";

@interface VPNManager ()

@property (nonatomic,assign)BOOL observerAdded;

@end

@implementation VPNManager

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak __typeof(self)ws = self;
        [self loadTunnelProviderManager:^(NETunnelProviderManager *tunnelProviderManager) {
            if (tunnelProviderManager) {
                [[NSNotificationCenter defaultCenter]addObserverForName:NEVPNStatusDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                    [ws updateVPNStatus:tunnelProviderManager];
                }];
                [self addNotifications];
                
            }else {
                
            }
        }];
        
    }
    return self;
}

- (void)setStatus:(VPNManagerStatus)status {
    _status = status;
    [[NSNotificationCenter defaultCenter]postNotificationName:kProxyServiceVPNStatusNotification object:nil];
    
}

- (void)connect {
    [self loadAndCreateTunnelProviderManager:^(NETunnelProviderManager *tunnelProviderManager) {
        NSError *startVPNTunnelError = nil;
        [tunnelProviderManager.connection startVPNTunnelWithOptions:nil andReturnError:&startVPNTunnelError];
        if (startVPNTunnelError) {
            NSLog(@"startVPNTunnelError:%@",startVPNTunnelError.localizedDescription);
        }}];
    
}

- (void)disconnect {
    [self loadTunnelProviderManager:^(NETunnelProviderManager *tunnelProviderManager) {
        [tunnelProviderManager.connection stopVPNTunnel];
    }];
}

- (void)loadTunnelProviderManager:(void (^)(NETunnelProviderManager * tunnelProviderManager))completionHandler {
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (error) {
            NSLog(@"loadAllFromPreferencesWithCompletionHandler error :%@",error.localizedDescription);
            completionHandler(nil);
        }
        else {
            completionHandler(managers.firstObject);
        }
    }];
}


- (void)loadAndCreateTunnelProviderManager:(void (^)(NETunnelProviderManager * tunnelProviderManager))completionHandler {
    __weak __typeof(self)ws = self;
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (error) {
            NSLog(@"loadAllFromPreferencesWithCompletionHandler error :%@",error.localizedDescription);
            completionHandler(nil);
        }
        else {
            NETunnelProviderManager * tunnelProviderManager = managers.firstObject ?:[ws defaultTunnelProviderManager];
            [tunnelProviderManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"saveToPreferencesWithCompletionHandler error:%@",error.localizedDescription);
                    completionHandler(nil);
                    
                }else {
                    [tunnelProviderManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"loadFromPreferencesWithCompletionHandler error:%@",error);
                            completionHandler(nil);
                        }
                        else {
                            completionHandler(tunnelProviderManager);
                            [ws addNotifications];
                        }
                    }];
                }
            }];
        }
    }];
}

- (NETunnelProviderManager*)defaultTunnelProviderManager {
    NETunnelProviderManager *tunnelProviderManager = [[NETunnelProviderManager alloc]init];
    NETunnelProviderProtocol *tunnelProviderProtocol = [[NETunnelProviderProtocol alloc]init];
    tunnelProviderProtocol.providerConfiguration = [self defaultProviderConfiguration];
    tunnelProviderProtocol.providerBundleIdentifier = @"com.developer.WormholeX.PacketTunnel";
    tunnelProviderProtocol.serverAddress = @"WormholeX";
    tunnelProviderProtocol.username = @"username";
    tunnelProviderManager.protocolConfiguration = tunnelProviderProtocol;
    tunnelProviderManager.localizedDescription = @"WormholeX VPN";
    tunnelProviderManager.enabled = true;
    return tunnelProviderManager;
}

- (void)addNotifications {
    if (self.observerAdded) {
        
    }else {
        self.observerAdded = true;
        __weak __typeof(self)ws = self;
        [self loadTunnelProviderManager:^(NETunnelProviderManager *tunnelProviderManager) {
            if (tunnelProviderManager) {
                [[NSNotificationCenter defaultCenter]addObserverForName:NEVPNStatusDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                    [ws updateVPNStatus:tunnelProviderManager];
                }];
            }
        }];
    }
}

- (void)updateVPNStatus:(NETunnelProviderManager*)tunnelProviderManager {
    NEVPNStatus status = tunnelProviderManager.connection.status;
    switch (status) {
        case  NEVPNStatusConnected:
            self.status = on;
            break;
        case NEVPNStatusConnecting:
            self.status = connecting;
            break;
        case NEVPNStatusReasserting:
            self.status = connecting;
            break;
        case NEVPNStatusDisconnecting:
            self.status = disconnecting;
            break;
        case NEVPNStatusInvalid:
            self.status = off;
            break;
        case NEVPNStatusDisconnected:
            self.status = off;
            break;

        default:
            break;
    }
}

/**
 过滤规则
 
 @return 默认 过滤规则
 */
- (NSString*)defaultRule {
    NSString *rule = nil;
    NSString *rulePath = [[NSBundle mainBundle]pathForResource:@"NEKitRule" ofType:@"conf"];
    rule = [[NSString alloc]initWithData:
            [NSData dataWithContentsOfFile:rulePath]
                                encoding:NSUTF8StringEncoding];
    
    
    return  rule;
}

/**
 默认线路配置
 
 @return 默认线路配置
 */
- (NSDictionary*)defaultProviderConfiguration {
    
    return @{
             @"ss_address":@"207.226.141.146",
             @"ss_port":@(8888),
             @"ss_method":@"AES256CFB",
             @"ss_password":@"Jir5k141k",
             @"ymal_conf":[self defaultRule],
             };
}

+ (NSDictionary*)statusLocalizedDescriptionInfo {
    NSDictionary *info = @{
                           @(off):@"Connect",
                           @(connecting):@"connecting",
                           @(on):@"Disconnect",
                           @(disconnecting):@"disconnect",
                           };
    return info;
}

@end


