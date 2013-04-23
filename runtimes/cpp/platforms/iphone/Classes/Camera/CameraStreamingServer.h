//
//  TCPServer.h
//  MoSync
//
//  Created by Mircea Vasiliniuc on 4/22/13.
//
//

#import <Foundation/Foundation.h>

@interface CameraStreamingServer : NSObject <NSStreamDelegate>
{
    NSData *writeLeftover;
    NSMutableArray *packetQueue;
}

@property(nonatomic, assign) CFSocketRef mIpv4cfsock;
@property(nonatomic, retain) NSOutputStream *outStream;

- (void) startCameraStreamingServer;
- (void) stopCameraStreamingServer;
- (void) sendThisData:(NSData*)aData;

- (NSString *)GetOurIpAddress;

- (void)writeData;
- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ost;

@property(nonatomic, assign) bool hasCustomer;

@end
