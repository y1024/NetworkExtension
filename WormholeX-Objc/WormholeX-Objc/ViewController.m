//
//  ViewController.m
//  WormholeX-Objc
//
//  Created by 杜晓星 on 2017/11/14.
//  Copyright © 2017年 杜晓星. All rights reserved.
//

#import "ViewController.h"
#import "VPNManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property (nonatomic,strong)VPNManager *vpnManager;
@property (nonatomic,assign)VPNManagerStatus status;


@end

@implementation ViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.status = self.vpnManager.status;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.connectButton.layer.cornerRadius = 50;
    self.connectButton.layer.masksToBounds = true;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(vpnStatusDidChanged:) name:kProxyServiceVPNStatusNotification object:nil];
}

- (IBAction)connectButtonClick:(id)sender {
    VPNManagerStatus status = self.vpnManager.status;
    if (status == off) {
        [self.vpnManager connect];
    }
    else {
        [self.vpnManager disconnect];
    }
}
- (void)vpnStatusDidChanged:(NSNotification*)notification {
    self.status = self.vpnManager.status;
}
- (void)setStatus:(VPNManagerStatus)status {
    _status = status;
    NSDictionary *info = [VPNManager statusLocalizedDescriptionInfo];
    [self.connectButton setTitle:info[@(status)] forState:normal];
    
    if (status == on ||
        status == off) {
        self.connectButton.userInteractionEnabled = true;
    }else {
        self.connectButton.userInteractionEnabled = false;
    }
}

#pragma mark lazy load

- (VPNManager*)vpnManager {
    if (!_vpnManager) {
        _vpnManager = [[VPNManager alloc]init];
    }
    return _vpnManager;
}

@end
