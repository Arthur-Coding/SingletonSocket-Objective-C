//
//  SingletonSocket.h
//
//  Created by ArthurShuai on 16-12-07.
//  Copyright (c) ArthurShuai. All rights reserved.
//

#import <Foundation/Foundation.h>

enum{
    SocketOfflineByServer,
    SocketOfflineByUser,
};

@class AsyncSocket;
@interface SingletonSocket : NSObject

/**
 * socketHost socket的Host
 * socketPort socket的prot
 * defaultLongConnectTime socket的心跳连接时间，默认为30s
 * longConnectData  socket的心跳连接发送数据
 */
@property (nonatomic, copy  ) NSString       *socketHost;
@property (nonatomic, assign) UInt16         socketPort;
@property (nonatomic, assign) NSTimeInterval defaultLongConnectTime;
@property (nonatomic, strong) NSData         *longConnectData;

/**
 创建socket处理单例对象

 @return 单例对象
 */
+ (SingletonSocket *)sharedInstance;

/**
 socket连接
 */
+ (void)socketConnectHost;
/**
 断开socket连接
 */
+ (void)cutOffSocket;

/**
 发送到服务器数据

 @param data 发送数据
 @param timeput 超时时间
 @param tag tag标记
 */
+ (void)sendData:(NSData *)data withTimeout:(NSTimeInterval)timeput tag:(NSInteger)tag;

/**
 处理接收到的数据

 @param action action
 */
+ (void)processingReceivedData:(void(^)(NSData *data,AsyncSocket *socket))action;

@end
