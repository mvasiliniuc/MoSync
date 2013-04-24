//
//  TCPServer.m
//  MoSync
//
//  Created by Mircea Vasiliniuc on 4/22/13.
//
//

#import "CameraStreamingServer.h"

#include <sys/socket.h>
#include <netinet/in.h>

#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation CameraStreamingServer

@synthesize mIpv4cfsock = _mIpv4cfsock;
@synthesize outStream = _outStream;
@synthesize hasCustomer = _hasCustomer;

- (id)init {
    //NSLog(@"CameraStreamingServer init");
    self = [super init];
    if ( self )
    {
        packetQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    //NSLog(@"CameraStreamingServer dealloc");
    [self stopCameraStreamingServer];
    [super dealloc];
}


// This function is called by CFSocket when a new connection comes in.
static void CameraStreamingServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    //NSLog(@"CameraStreamingServer CameraStreamingServerAcceptCallBack");
    CameraStreamingServer *server = (CameraStreamingServer *)info;

    if (kCFSocketAcceptCallBack == type)
    {
        // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        uint8_t name[SOCK_MAXADDRLEN];
        socklen_t namelen = sizeof(name);
        NSData *peer = nil;

        if (0 == getpeername(nativeSocketHandle, (struct sockaddr *)name, &namelen))
        {
            peer = [NSData dataWithBytes:name length:namelen];
        }

        CFReadStreamRef readStream = NULL;
		CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);

        if (readStream && writeStream)
        {
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            [server handleNewConnectionFromAddress:peer inputStream:(NSInputStream *)readStream outputStream:(NSOutputStream *)writeStream];
            server.hasCustomer = true;
        }
        else
        {
            // on any failure, need to destroy the CFSocketNativeHandle
            // since we are not going to use it any more
            close(nativeSocketHandle);
        }
        if (readStream) CFRelease(readStream);
        if (writeStream) CFRelease(writeStream);
    }
}

- (void) startCameraStreamingServer
{
    //NSLog(@"CameraStreamingServerAcceptCallBack startCameraStreamingServer");
    CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
    _mIpv4cfsock = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&CameraStreamingServerAcceptCallBack, &socketCtxt);

    if (NULL == _mIpv4cfsock) {
        NSLog(@"startCameraStreamingServer error");
        if (_mIpv4cfsock) CFRelease(_mIpv4cfsock);
        _mIpv4cfsock = NULL;
    }

    int yes = 1;
    setsockopt(CFSocketGetNative(_mIpv4cfsock), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));

    // set up the IPv4 endpoint; use port 0, so the kernel will choose an arbitrary port for us, which will be advertised using Bonjour
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(80);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];

    if (kCFSocketSuccess != CFSocketSetAddress(_mIpv4cfsock, (CFDataRef)address4))
    {
        NSLog(@"startCameraStreamingServer error");
        if (_mIpv4cfsock) CFRelease(_mIpv4cfsock);
        _mIpv4cfsock = NULL;
    }

    // debugging purposes
    NSData *addr = [(NSData *)CFSocketCopyAddress(_mIpv4cfsock) autorelease];
    memcpy(&addr4, [addr bytes], [addr length]);
    NSLog(@"startCameraStreamingServer port %hu", ntohs(addr4.sin_port));

    // set up the run loop sources for the sockets
    CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _mIpv4cfsock, 0);
    CFRunLoopAddSource(cfrl, source4, kCFRunLoopCommonModes);
    CFRelease(source4);

    // For debuging purposes
    [self GetOurIpAddress];
}

// Get IP Address
- (NSString *)GetOurIpAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    NSLog(@"GetOurIpAddress address:%@", address);
    return address;
}

- (void) stopCameraStreamingServer
{
//    NSLog(@"CameraStreamingServerAcceptCallBack stopCameraStreamingServer");
    if (_mIpv4cfsock)
    {
        CFSocketInvalidate(_mIpv4cfsock);
        CFRelease(_mIpv4cfsock);
        _mIpv4cfsock = nil;
    }
}

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
//    NSLog(@"CameraStreamingServerAcceptCallBack handleNewConnectionFromAddress");
    _outStream = ostr;
	[_outStream retain];

    _outStream.delegate = self;
    [_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outStream open];
}

- (void) sendThisData:(NSData*)aData
{
    if ( aData )
    {
        [packetQueue addObject:aData];
    }

    if ( [_outStream hasSpaceAvailable] )
    {
        [self writeData];
    }

}

-(NSData *)contentsForTransfer:(NSArray*)array
{
    NSMutableData *ret = [NSMutableData data];
    try {
        for (NSData *oneData in array) {
            if (![oneData isKindOfClass:[NSData class]])
            {
                NSLog(@"contentsForTransfer error");
                return nil;
            }
            uint64_t dataSize[1];
            dataSize[0] = [oneData length];
            [ret appendBytes:dataSize length:sizeof(uint64_t)];
            [ret appendBytes:[oneData bytes] length:[oneData length]];
        }
    }
    catch (NSException* excep)
    {
        NSLog(@"contentsForTransfer exception");
    }
	return ret;
}

- (void)writeData {
    if (writeLeftover == nil && [packetQueue count]==0) {
        return; //Nothing to send
    }
    NSMutableData *dataToSend = [NSMutableData data];
    if (writeLeftover != nil) {
        [dataToSend appendData:writeLeftover];
        [writeLeftover release];
        writeLeftover = nil;
    }

    [dataToSend appendData: [self contentsForTransfer:packetQueue]];
    [packetQueue removeAllObjects];

    NSUInteger sendLength = [dataToSend length];
    NSUInteger written = [_outStream write:(const uint8_t*)[dataToSend bytes] maxLength:sendLength];

    if (written == -1) {
        NSLog(@"writeData error");
    }

    if (written != sendLength) {
        NSRange leftoverRange = NSMakeRange(written, [dataToSend length] - written);
        writeLeftover = [[dataToSend subdataWithRange:leftoverRange] retain];
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            //NSLog(@"CameraStreamingServerAcceptCallBack NSStreamEventOpenCompleted");
            break;
        case NSStreamEventHasBytesAvailable:
            //NSLog(@"CameraStreamingServerAcceptCallBack NSStreamEventHasBytesAvailable");
            break;
        case NSStreamEventHasSpaceAvailable:
            //NSLog(@"CameraStreamingServerAcceptCallBack NSStreamEventHasSpaceAvailable");
            if ( aStream == _outStream )
            {
                [self writeData];
            }
            break;
        case NSStreamEventErrorOccurred:
            //NSLog(@"CameraStreamingServerAcceptCallBack NSStreamEventErrorOccurred");
            break;
        case NSStreamEventEndEncountered:
            _hasCustomer = false;
            //NSLog(@"CameraStreamingServerAcceptCallBack NSStreamEventEndEncountered");
            break;
        default:
            //NSLog(@"CameraStreamingServerAcceptCallBack default");
            break;
    }
}

@end
