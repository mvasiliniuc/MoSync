/* Copyright (C) 2011 MoSync AB

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License, version 2, as published by
 the Free Software Foundation.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.

 You should have received a copy of the GNU General Public License
 along with this program; see the file COPYING.  If not, write to the Free
 Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
 */

#import "StreamPreviewWidget.h"
#include <helpers/cpp_defs.h>
#include <helpers/CPP_IX_WIDGET.h>
#include "Platform.h"
#include <base/Syscall.h>

#define BUFFERSIZE 1024

/**
 * Hidden functions/methods for StreamPreviewImage class.
 */
@interface StreamPreviewImage ()



/**
 * Show an image from a given path.
 * Setter for MAW_IMAGE_PATH.
 * @param path Image file path.
 * @return One of the following result codes:
 * - MAW_RES_OK if the image was shown.
 * - MAW_RES_INVALID_PROPERTY_VALUE if the path is invalid.
 */
- (int)setPropertyImagePath:(NSString*)path;

@end

@implementation StreamPreviewImage


- (id)init
{
    self = [super init];
    if (self)
    {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 60)];
        self.view = _imageView;
        _leftCapWidth = 0;
        _topCapHeight = 0;
        _address = @"127.0.0.1";
        _port = 80;
        self.autoSizeWidth = WidgetAutoSizeWrapContent;
        self.autoSizeHeight = WidgetAutoSizeWrapContent;
        self.view.contentMode = UIViewContentModeCenter;
    }
	return self;
}

/**
 * Set a widget property value.
 * @param key Widget's property name that should be set.
 * @param value Widget's proeprty value that should be set.
 * @return One of the following values:
 * - MAW_RES_OK if the property was set.
 * - MAW_RES_INVALID_PROPERTY_NAME if the property name was invalid.
 * - MAW_RES_INVALID_PROPERTY_VALUE if the property value was invalid.
 */
- (int)setPropertyWithKey:(NSString*)key toValue:(NSString*)value
{
    if([key isEqualToString:@"streamingServerAddress"])
    {
		_address = value;
	}
    else if([key isEqualToString:@"streamingServerPort"])
    {
		_port = [value intValue];
	}
    else if([key isEqualToString:@"streamEnabled"])
    {
        if ([value isEqualToString:@"true"]) {
            CFReadStreamRef readStream;
            CFWriteStreamRef writeStream;
            CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)_address, _port, &readStream, &writeStream);
            _inputStream = (__bridge_transfer NSInputStream *)readStream;
            [_inputStream setDelegate:self];
            [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_inputStream open];
            [self layout];
        }
        else
        {
            [_inputStream close];
        }
	}
	else if([key isEqualToString:@"leftCapWidth"])
    {
		int newLeftCapWidth = [value intValue];
		if (_imageView != nil)
        {
			UIImage* image = [_imageView.image stretchableImageWithLeftCapWidth:newLeftCapWidth
                                                                   topCapHeight:_topCapHeight];
			_imageView.image = image;
		}
		_leftCapWidth = newLeftCapWidth;
	}
	else if ([key isEqualToString:@"topCapHeight"])
    {
		int newTopCapHeight = [value intValue];
		if (_imageView != nil)
        {
			UIImage* image = [_imageView.image stretchableImageWithLeftCapWidth:_leftCapWidth
                                                                   topCapHeight:newTopCapHeight];
			_imageView.image = image;
		}
		_topCapHeight = newTopCapHeight;
	}
    else if ([key isEqualToString:@MAW_IMAGE_SCALE_MODE])
    {
        // none
        // scaleXY
        // scalePreserveAspect

        // maybe have these later?
        // scaleX
        // scaleY

        if([value isEqualToString:@"none"]) self.view.contentMode = UIViewContentModeCenter;
        else if([value isEqualToString:@"scaleXY"]) self.view.contentMode = UIViewContentModeScaleToFill;
        else if([value isEqualToString:@"scalePreserveAspect"]) self.view.contentMode = UIViewContentModeScaleAspectFit;
    }
	else
    {
		return [super setPropertyWithKey:key toValue:value];
	}
	return MAW_RES_OK;
}

/**
 * Get a widget property value.
 * @param key Widget's property name.
 * @return The property value, or nil if the property name is invalid.
 * The returned value should not be autoreleased. The caller will release the returned value.
 */
- (NSString*)getPropertyWithKey:(NSString*)key
{
		return [super getPropertyWithKey:key];
}

/**
 * Show an image from a given path.
 * Setter for MAW_IMAGE_PATH.
 * @param path Image file path.
 * @return One of the following result codes:
 * - MAW_RES_OK if the image was shown.
 * - MAW_RES_INVALID_PROPERTY_VALUE if the path is invalid.
 */
- (int)setPropertyImagePath:(NSString*)path
{
	UIImage* image = [[UIImage alloc] initWithContentsOfFile:path];
	if (!image)
	{
		return MAW_RES_INVALID_PROPERTY_VALUE;
	}

	_imageView.image = image;
	[image release];
	[self layout];
	return MAW_RES_OK;
}


/**
 * Dealloc method
 */
-(void) dealloc
{
    [_imageView release];
    [super dealloc];
}


- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
            //We probably need to send an event to the user from here
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == _inputStream) {
				if ([_inputStream hasBytesAvailable]) {
					NSMutableData *data = [NSMutableData data];
					if (mReadLeftover != nil) {
						[data appendData:mReadLeftover];
						[mReadLeftover release];
						mReadLeftover = nil;
					}

					NSInteger bytesRead;
					static uint8_t buffer[BUFFERSIZE];

					bytesRead = [_inputStream read:buffer maxLength:BUFFERSIZE];
					if (bytesRead == -1) {
						NSLog(@"Something wrong here");
						return;
					} else if (bytesRead > 0){
						[data appendBytes:buffer length:bytesRead];
						NSArray *dataPackets = [data splitTransferredPackets:&mReadLeftover];
						if (mReadLeftover) {
							[mReadLeftover retain];
						}
						for (NSData *onePacketData in dataPackets) {
							UIImage *image = [UIImage imageWithData:onePacketData];
							if (image) {

								[_imageView setImage:image];
                                //TODO make sure we need this
                                [image release];
							}
						}
					}

				}
			}
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"%s", _cmd);
			break;
		}

		case NSStreamEventEndEncountered:
		{
			UIAlertView	*alertView;
			alertView = [[UIAlertView alloc] initWithTitle:@"Peer Disconnected!" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			[alertView show];
			[alertView release];

			break;
		}
	}
}



@end
