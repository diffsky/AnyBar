//
//  AppDelegate.m
//  AnyBar
//
//  Created by Nikita Prokopov on 14/02/15.
//  Copyright (c) 2015 Nikita Prokopov. All rights reserved.
//

#import "AppDelegate.h"

static NSString * const kAnyBarPortEnvironmentVariable = @"ANYBAR_PORT";
static NSString * const kAnyBarPortDefaultValue = @"1738";

@interface AppDelegate ()

@property (nonatomic) int udpPort;
@property (nonatomic) BOOL darkMode;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *imageName;
@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) GCDAsyncUdpSocket *udpSocket;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.udpPort = -1;
    
    self.imageName = @"white";
    self.text = @"";
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.font = [NSFont systemFontOfSize:12];
    self.statusItem.button.alternateImage = [NSImage imageNamed:@"black_alt"];
    self.statusItem.menu = [NSMenu new];
    [self refreshDarkMode];

    @try {
        self.udpPort = [self getUdpPort];
        self.udpSocket = [self initializeUdpSocket];
    }
    @catch (NSException *ex) {
        NSLog(@"Error: %@: %@", ex.name, ex.reason);
        self.statusItem.button.image = [NSImage imageNamed:@"exclamation"];
        [self.statusItem.menu addItemWithTitle:ex.name action:nil keyEquivalent:@""];
        [self.statusItem.menu addItemWithTitle:ex.reason action:nil keyEquivalent:@""];
        [self.statusItem.menu addItem:[NSMenuItem separatorItem]];
    }
    @finally {
        if (self.udpPort >= 0 && self.udpPort <= 65535) {
            NSString *portTitle = [NSString stringWithFormat:@"UDP port: %d", self.udpPort];
            [self.statusItem.menu addItemWithTitle:portTitle action:nil keyEquivalent:@""];
        }
        [self.statusItem.menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
    }

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDarkMode) name:@"AppleInterfaceThemeChangedNotification" object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [self.udpSocket close];
    self.udpSocket = nil;

    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    self.statusItem = nil;
}

- (int)getUdpPort
{
    int port = -1;

    NSString *envStr = [[[NSProcessInfo processInfo] environment] objectForKey:kAnyBarPortEnvironmentVariable];
    if (!envStr) {
        envStr = kAnyBarPortDefaultValue;
    }
    
    NSNumberFormatter *nFormatter = [NSNumberFormatter new];
    nFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *number = [nFormatter numberFromString:envStr];
    
    if (!number) {
        @throw([NSException exceptionWithName:@"Argument Exception" reason:[NSString stringWithFormat:@"Parsing int '%@' from env var '%@' failed", envStr, kAnyBarPortEnvironmentVariable] userInfo:@{ @"argument":envStr }]);
    }
    
    port = [number intValue];
    
    if (port < 0 || port > 65535) {
        @throw([NSException exceptionWithName:@"Argument Exception" reason:[NSString stringWithFormat:@"UDP port %d is invalid", port] userInfo:@{ @"argument":@(port) }]);
    }

    return port;
}

- (GCDAsyncUdpSocket *)initializeUdpSocket
{
    GCDAsyncUdpSocket *udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    NSError *error = nil;
    if ([udpSocket bindToPort:self.udpPort error:&error] == NO) {
        @throw([NSException exceptionWithName:@"UDP Exception" reason:[NSString stringWithFormat:@"Binding to port %d failed", self.udpPort] userInfo:@{ @"error":error }]);
    }

    if ([udpSocket beginReceiving:&error] == NO) {
        @throw([NSException exceptionWithName:@"UDP Exception" reason:[NSString stringWithFormat:@"Receiving from port %d failed", self.udpPort] userInfo:@{ @"error":error }]);
    }

    return udpSocket;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    message = [message stringByTrimmingCharactersInSet:whitespaceSet];

    if (message == nil || [message isEqualToString:@""]) {
        NSLog(@"Empty message received on port %d.", self.udpPort);
        return;
    }
    
    NSInteger locationOfFirstSpace = [message rangeOfString:@" "].location;
    NSString *imageName = message;
    NSString *text = @"";
    self.statusItem.button.imagePosition = NSImageOnly;
    
    if (locationOfFirstSpace != NSNotFound) {
        imageName = [message substringToIndex:locationOfFirstSpace];
        text = [message substringFromIndex:locationOfFirstSpace];
        text = [text stringByTrimmingCharactersInSet:whitespaceSet];
        self.statusItem.button.imagePosition = NSImageLeft;
    }
    
    if ([imageName isEqualToString:@"quit"]) {
        [[NSApplication sharedApplication] terminate:nil];
    }

    // Hack to make statusItem properly resize when a short text message
    // is set after a long one. Without this, statusItem will stay at the
    // wider size of the long message until the next time it is updated.
    [self.statusItem.button setAttributedAlternateTitle:nil];
    
    [self setImage:imageName];
    [self setText:text];
    [self.statusItem.button setTitle:text];
    [self.statusItem.button setAttributedAlternateTitle:[[NSAttributedString alloc] initWithString:text attributes:@{ NSForegroundColorAttributeName: NSColor.whiteColor, NSFontAttributeName: [NSFont systemFontOfSize:12] }]];
}

- (void)refreshDarkMode
{
    NSString *mode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    self.darkMode = [mode isEqualToString:@"Dark"] ? YES : NO;
    [self setImage:self.imageName];
}

- (NSString *)homedirImagePath:(NSString *)name
{
    return [NSString stringWithFormat:@"%@/%@/%@.png", NSHomeDirectory(), @".AnyBar", name];
}

- (void)setImage:(NSString *)name
{
    NSImage *image = nil;
    if (self.darkMode) {
        image = [NSImage imageNamed:[name stringByAppendingString:@"_alt"]];
    }
    if (!image) {
        image = [NSImage imageNamed:name];
    }
    if (self.darkMode && !image) {
        image = [[NSImage alloc] initWithContentsOfFile:[self homedirImagePath:[name stringByAppendingString:@"_alt@2x"]]];
    }
    if (self.darkMode && !image) {
        image = [[NSImage alloc] initWithContentsOfFile:[self homedirImagePath:[name stringByAppendingString:@"_alt"]]];
    }
    if (!image) {
        image = [[NSImage alloc] initWithContentsOfFile:[self homedirImagePath:[name stringByAppendingString:@"@2x"]]];
    }
    if (!image) {
        image = [[NSImage alloc] initWithContentsOfFile:[self homedirImagePath:name]];
    }
    if (!image) {
        NSString *questionImageName = self.darkMode ? @"question_alt" : @"question";
        image = [NSImage imageNamed:questionImageName];
        NSLog(@"Cannot find image '%@'", name);
    }
    
    self.statusItem.button.image = image;
    self.imageName = name;
}

- (id)osaImageBridge
{
    NSLog(@"OSA Event: %@ - %@", NSStringFromSelector(_cmd), self.imageName);
    return self.imageName;
}

- (void)setOsaImageBridge:(id)imgName
{
    NSLog(@"OSA Event: %@ - %@", NSStringFromSelector(_cmd), imgName);
    self.imageName = (NSString *)imgName;
    [self setImage:self.imageName];
}

- (id)osaTextBridge
{
    NSLog(@"OSA Event: %@ - %@", NSStringFromSelector(_cmd), self.text);
    return self.text;
}

- (void)setOsaTextBridge:(id)text
{
    NSLog(@"OSA Event: %@ - %@", NSStringFromSelector(_cmd), text);
    self.text = (NSString *)text;
    [self.statusItem.button setTitle:text];
}

@end
