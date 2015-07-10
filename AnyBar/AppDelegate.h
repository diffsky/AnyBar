//
//  AppDelegate.h
//  AnyBar
//
//  Created by Nikita Prokopov on 14/02/15.
//  Copyright (c) 2015 Nikita Prokopov. All rights reserved.
//
//  Modified by Sanjay Madan on 7-Jun-2015

#import <Cocoa/Cocoa.h>
#import "GCDAsyncUdpSocket.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

//
// OSA Scripting bridge
// @see AnyBarApp.h
//
- (id)osaMessageBridge;
- (void)setOsaMessageBridge:(id)message;

@end

