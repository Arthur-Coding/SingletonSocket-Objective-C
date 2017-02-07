//
//  SingletonSocket.m
//
//  Created by ArthurShuai on 16-12-07.
//  Copyright (c) ArthurShuai. All rights reserved.
//

#import "SingletonSocket.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "AsyncSocket.h"

@interface SingletonSocket ()<AsyncSocketDelegate>

@property (nonatomic, strong) AsyncSocket    *socket;       // socket
@property (nonatomic, strong) NSTimer        *connectTimer; // 计时器
@property (nonatomic, copy)   void(^action)(NSData *,AsyncSocket *);

@end

@implementation SingletonSocket

- (AsyncSocket *)socket {
    if (_socket == nil) {
        self.socket = [[AsyncSocket alloc] initWithDelegate:nil];//先不设置代理
    }
    return _socket;
}
- (NSTimeInterval)defaultLongConnectTime {
    if (_defaultLongConnectTime == 0) {
        _defaultLongConnectTime = 30;
    }
    return _defaultLongConnectTime;
}

+ (SingletonSocket *)sharedInstance {
    static SingletonSocket *sharedInstace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstace = [[SingletonSocket alloc] init];
        //初始化时先进行手动断开
        sharedInstace.socket.userData = SocketOfflineByUser;
        [sharedInstace.connectTimer invalidate];
        [sharedInstace.socket disconnect];
        //确保连接已断开，防止对正处于连接状态的socket进行连接出现崩溃
        sharedInstace.socket.userData = SocketOfflineByServer;
        sharedInstace.socket.delegate = sharedInstace;
    });
    return sharedInstace;
}
// socket连接
+ (void)socketConnectHost{
    [[SingletonSocket sharedInstance].socket connectToHost:[SingletonSocket sharedInstance].socketHost onPort:[SingletonSocket sharedInstance].socketPort withTimeout:3 error:nil];
}
// 断开socket连接
+ (void)cutOffSocket{
    [SingletonSocket sharedInstance].socket.userData = SocketOfflineByUser;
    [[SingletonSocket sharedInstance].connectTimer invalidate];
    [[SingletonSocket sharedInstance].socket disconnect];
}

+ (void)sendData:(NSData *)data withTimeout:(NSTimeInterval)timeput tag:(NSInteger)tag {
    [self.socket writeData:data withTimeout:timeput tag:tag];
}

#pragma mark - AsyncSocketDelegate
// 连接成功回调
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    __weak typeof(self) weakSelf = self;
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:self.defaultLongConnectTime repeats:YES block:^(NSTimer * _Nonnull timer) {
        //心跳连接
        [weakSelf.socket writeData:weakSelf.longConnectData withTimeout:1 tag:1];
    }];
    [self.connectTimer fire];
}
// 连接断开回调
- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    if (sock.userData == SocketOfflineByServer) {
        //服务器掉线，重连
        [SingletonSocket socketConnectHost];
    }else if (sock.userData == SocketOfflineByUser) {
        //如果由用户断开，不进行重连
        return;
    }
}
//接收到数据
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    // 对得到的data值进行解析与转换即可
    [self.socket readDataWithTimeout:30 tag:0];
    if (self.action) {
        self.action(data,self.socket);
    }
}

+ (void)processingReceivedData:(void (^)(NSData *, AsyncSocket *))action {
    [SingletonSocket sharedInstance].action = action;
}

@end
