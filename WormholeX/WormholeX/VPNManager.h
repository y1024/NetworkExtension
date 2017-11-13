//
//  VPNManager.h
//  WormholeX
//
//  Created by 杜晓星 on 2017/11/13.
//  Copyright © 2017年 杜晓星. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kProxyServiceVPNStatusNotification;

typedef NS_ENUM(NSUInteger, VPNManagerStatus) {
    off = 0,
    connecting,
    on,
    disconnecting,
};


@interface VPNManager : NSObject

@property (nonatomic,assign)VPNManagerStatus status;

- (void)connect;

- (void)disconnect;

+ (NSDictionary*)statusLocalizedDescriptionInfo;

@end
