//
//  TCPSocket.m
//  tun2Socks
//
//  Created by 杜晓星 on 2017/11/15.
//  Copyright © 2017年 杜晓星. All rights reserved.
//

#import "TCPSocket.h"
#import "lwip.h"
#include <netinet/in.h>

@interface TCPSocket ()

@property (nonatomic,assign)struct tcp_pcb *pcb;

@property (nonatomic, assign) struct in_addr sourceAddress;

@property (nonatomic, assign) struct in_addr destinationAddress;

@property (nonatomic, assign) UInt16 sourcePort;

@property (nonatomic, assign) UInt16 destinationPort;


@property (nonatomic, assign) NSUInteger identity;

@property (nonatomic, assign) NSUInteger *identityArg;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic,assign)BOOL closedSignalSend;

@property (nonatomic,assign)BOOL isValid;

@property (nonatomic,assign)BOOL isConnected;

@end

static NSMutableDictionary<NSNumber *, TCPSocket *> *_socketDict;

@implementation TCPSocket


- (BOOL)isConnected {
    return self.isValid && self.pcb->state != CLOSED;
}

- (instancetype)initWith:(struct tcp_pcb*)pcb queue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        self.pcb = pcb;
        self.queue = queue;
        
        self.sourcePort = pcb->remote_port;
        self.destinationPort = pcb->local_port;
        
        struct in_addr sourceIP = {pcb->remote_ip.addr};
        self.sourceAddress = sourceIP;
        struct in_addr destinationIP = {pcb->local_ip.addr};
        self.destinationAddress = destinationIP;
        
        self.identity = [[self class] uniqueKey];
        self.identityArg = &_identity;
        
        [self class].socketDict[@(self.identity)] = self;
        
        tcp_arg(self.pcb, self.identityArg);
        tcp_recv(self.pcb, tcp_recv_callback);
        tcp_sent(self.pcb, tcp_sent_callback);
        tcp_err(self.pcb, tcp_err_callback);
    }
    
    return self;
}

- (void)errored:(err_t)error {
    [self _release];
    switch (error)
    {
        case ERR_RST:
        {
            if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidReset:)])
            {
                [self.delegate socketDidReset:self];
            }
            break;
        }
        case ERR_ABRT:
        {
            if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidReset:)])
            {
                [self.delegate socketDidAbort:self];
            }
            break;
        }
            
        default:
            break;
    }
    
}

- (void)_release {
    self.pcb = NULL;
    self.identityArg = NULL;
    [[self class].socketDict removeObjectForKey:@(self.identity)];
}


+ (TCPSocket *)socketForIdentityPointer:(NSUInteger *)identityPointer
{
    
    return [self.socketDict objectForKey:@(*identityPointer)];
}

- (void)recved:(struct pbuf *)pbuf
{
    if (pbuf == NULL)
    {
        if (nil != self.delegate && [self.delegate respondsToSelector:@selector(localDidClose:)])
        {
            [self.delegate localDidClose:self];
        }
    }
    else
    {
        uint16_t totalLength = pbuf->tot_len;
        NSMutableData *packetData = [NSMutableData dataWithLength:totalLength];
        void *dataptr = [packetData mutableBytes];
        pbuf_copy_partial(pbuf, dataptr, totalLength, 0);
        
        if (nil != self.delegate && [self.delegate respondsToSelector:@selector(didReadData:from:)])
        {
            [self.delegate didReadData:packetData from:self];
        }
        
        if ([self isValid])
        {
            tcp_recved(self.pcb, totalLength);
        }
        pbuf_free(pbuf);
        
    }
}

- (void)writeData:(NSData*)data {
    if (!self.isValid) {
        err_t err = tcp_write(self.pcb, [data bytes], [data length], TCP_WRITE_FLAG_COPY);
        if (err != ERR_OK) {
            [self close];
        }
        else {
            tcp_output(self.pcb);
        }
    }
}

- (void)close {
    if (!self.isValid) {
        
    }else {
        tcp_arg(self.pcb, NULL);
        tcp_recv(self.pcb, NULL);
        tcp_sent(self.pcb, NULL);
        tcp_err(self.pcb, NULL);
        [self _release];
        if ([self.delegate respondsToSelector:@selector(localDidClose:)]) {
            [self.delegate localDidClose:self];
        }
    }
}

- (void)reset {
    if (!self.isValid) {
        
    }else {
        tcp_arg(self.pcb, NULL);
        tcp_recv(self.pcb, NULL);
        tcp_sent(self.pcb, NULL);
        tcp_err(self.pcb, NULL);
        [self _release];
        if ([self.delegate respondsToSelector:@selector(localDidClose:)]) {
            [self.delegate localDidClose:self];
        }
    }
}

+ (TCPSocket *)socketForIdentity:(NSUInteger)identity
{
    return [self.socketDict objectForKey:@(identity)];
}

- (BOOL)isValid
{
    return self.pcb != nil;
}

- (void)sent:(NSUInteger)length
{
    if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidReset:)])
    {
        [self.delegate didWriteData:length from:self];
    }
}


/** Function prototype for tcp receive callback functions. Called when data has
 * been received.
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param tpcb The connection pcb which received data
 * @param p The received data (or NULL when the connection has been closed!)
 * @param err An error code if there has been an error receiving
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 */
static err_t tcp_recv_callback(void *arg, struct tcp_pcb *tpcb,
                               struct pbuf *p, err_t err)
{
    assert(err == ERR_OK);
    assert(arg != nil);
    TCPSocket *socket = [TCPSocket socketForIdentityPointer:arg];
    if (nil == socket)
    {
        // we do not know what this socket is, abort it
        tcp_abort(tpcb);
        return ERR_ABRT;
    }
    
    [socket recved:p];
    return ERR_OK;
}

/** Function prototype for tcp sent callback functions. Called when sent data has
 * been acknowledged by the remote side. Use it to free corresponding resources.
 * This also means that the pcb has now space available to send new data.
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param tpcb The connection pcb for which data has been acknowledged
 * @param len The amount of bytes acknowledged
 * @return ERR_OK: try to send some data by calling tcp_output
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 */
static err_t tcp_sent_callback(void *arg, struct tcp_pcb *tpcb,
                               u16_t len)
{
    assert(arg != nil);
    TCPSocket *socket = [TCPSocket socketForIdentityPointer:arg];
    if (nil == socket)
    {
        // we do not know what this socket is, abort it
        tcp_abort(tpcb);
        return ERR_ABRT;
    }
    
    [socket sent:len];
    return ERR_OK;
}

/** Function prototype for tcp error callback functions. Called when the pcb
 * receives a RST or is unexpectedly closed for any other reason.
 *
 * @note The corresponding pcb is already freed when this callback is called!
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param err Error code to indicate why the pcb has been closed
 *            ERR_ABRT: aborted through tcp_abort or by a TCP timer
 *            ERR_RST: the connection was reset by the remote host
 */
static void tcp_err_callback(void *arg, err_t err)
{
    assert(arg != nil);
    
    TCPSocket *socket = [TCPSocket socketForIdentityPointer:arg];
    if (nil != socket)
    {
        [socket errored:err];
    }
}

+ (NSMutableDictionary<NSNumber *,TCPSocket *> *)socketDict
{
    if (_socketDict == nil)
    {
        _socketDict = [NSMutableDictionary dictionaryWithCapacity:UINT32_MAX];
    }
    return _socketDict;
}

+ (NSInteger)uniqueKey
{
    UInt32 randomKey = arc4random();
    while ([self socketForIdentity:randomKey] != nil)
    {
        randomKey = arc4random();
    }
    return (NSInteger)randomKey;
}

- (void)dealloc {
    
}

@end
