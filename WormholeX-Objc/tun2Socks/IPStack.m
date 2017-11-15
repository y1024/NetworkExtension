//
//  IPStack.m
//  tun2Socks
//
//  Created by 杜晓星 on 2017/11/15.
//  Copyright © 2017年 杜晓星. All rights reserved.
//

#import "IPStack.h"
#import <sys/socket.h>

@interface IPStack ()

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) dispatch_queue_t processQueue;
@property (nonatomic, assign) struct tcp_pcb *listenPcb;
@property (nonatomic,strong)NSMutableDictionary *outputBlock;
@property (nonatomic, assign) struct netif *interface;
@end

static IPStack *stack = nil;

err_t tcpAcceptFn(void *arg,struct tcp_pcb *pcb,err_t error ) {
    [[IPStack defaultTun2SocksIPStack] didAcceptTCPSocket:pcb error:error];
    return (err_t)ERR_OK;
}

err_t outputPCB(struct netif *interface,struct pbuf *buf ,struct ip_addr *ipaddr) {
    [[IPStack defaultTun2SocksIPStack] writeOut:buf];
    return (err_t)ERR_OK;
}

@implementation IPStack

+ (instancetype)defaultTun2SocksIPStack {
    return [[self alloc] init];
}

- (instancetype)init {
    
    if (!stack) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            stack = [super init];
            stack.processQueue = dispatch_queue_create("tun2socks.IPStackQueue", DISPATCH_QUEUE_SERIAL);
            [self commonInit];
        });
        
    }
    return stack;
}

- (err_t)tcpAcceptFn:(void *)arg
                 pcb:(struct tcp_pcb*)pcb
               error:(err_t)error {
    return [self didAcceptTCPSocket:pcb error:error];
}

- (void)commonInit {
    lwip_init();
    struct tcp_pcb* pcb = tcp_new();
    tcp_bind(pcb, IP_ADDR_ANY, 0);
    pcb = tcp_listen_with_backlog(pcb, TCP_DEFAULT_LISTEN_BACKLOG);
    tcp_accept(pcb, tcpAcceptFn);
    netif_list->output = outputPCB;
}

- (void)checkTimeouts {
    sys_check_timeouts();
}

- (void)restartTimeouts {
    sys_restart_timeouts();
}

- (void)suspendTimer {
    self.timer = nil;
}


- (void)resumeTimer {
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.processQueue);
    // note the default tcp_tmr interval is 250 ms.
    uint64_t defaultInterval = 250;
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, defaultInterval * NSEC_PER_MSEC, 1 * NSEC_PER_MSEC);
    
    __weak __typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.timer, ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf checkTimeouts];
    });
    [self restartTimeouts];
    dispatch_resume(self.timer);
    
}

- (void)received:(NSData*)packet {
    struct pbuf * buf = pbuf_alloc(PBUF_RAW, packet.length, PBUF_RAM);
    buf->payload = (void*)[packet bytes];
    self.interface->input(buf,self.interface);
}

- (void)writeOut:(struct pbuf*)pbuf {
    uint16_t tot_len = pbuf->tot_len;
    uint8_t *bytes = malloc(sizeof(uint8_t) * tot_len);
    pbuf_copy_partial(pbuf, bytes, tot_len, 0);
    NSData *packet = [[NSData alloc] initWithBytesNoCopy:bytes length:tot_len freeWhenDone:YES];
    [self.outputBlock setObject:packet forKey:@(AF_INET)];
    
}

- (err_t)didAcceptTCPSocket:(struct tcp_pcb*)pcb
                      error:(err_t)error {
    tcp_accepted_c(self.listenPcb);
    if ([self.delegate respondsToSelector:@selector(didAcceptTCPSocket:)]) {
        TCPSocket *tcpSocket = [[TCPSocket alloc]initWith:pcb queue:self.processQueue];
        [self.delegate didAcceptTCPSocket:tcpSocket];
    }
    return ERR_OK;
}


#pragma mark lazy load
- (NSMutableDictionary*)outputBlock {
    if (!_outputBlock) {
        _outputBlock = [NSMutableDictionary dictionary];
    }
    return _outputBlock;
}

- (struct netif*)interface {
    if (!self.interface) {
        _interface = netif_list;
    }
    return _interface;
    
}

@end
