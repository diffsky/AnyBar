//
//  AnyBarApp.h
//  AnyBar
//
//  Created by Nikita Prokopov on 04/03/15.
//  Copyright (c) 2015 Nikita Prokopov. All rights reserved.
//

#import "AnyBarApp.h"

@implementation AnyBarApp

- (id)osaMessage
{
    AppDelegate *delegate = (AppDelegate *)self.delegate;
    return [delegate osaMessageBridge];
}

- (void)setOsaMessage:(id)message
{
    AppDelegate *delegate = (AppDelegate *)self.delegate;
    [delegate setOsaMessageBridge:message];
}

@end
