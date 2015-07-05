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

@property (nonatomic) BOOL darkMode;
@property (nonatomic) NSString *imageName;
@property (nonatomic) NSString *alertMessage;
@property (nonatomic) NSString *alertReason;
@property (nonatomic) NSStatusItem *statusItem;
@property (nonatomic) GCDAsyncUdpSocket *udpSocket;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    int udpPort = -1;
    self.imageName = @"white";
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.alternateImage = [NSImage imageNamed:@"black_alt"];
    [self refreshDarkMode];

    self.alertMessage = nil;
    self.alertReason  = nil;
    
    @try {
        udpPort = [self getUdpPort];
        self.udpSocket = [self initializeUdpSocket:udpPort];
    }
    @catch (NSException *ex) {
        NSLog(@"Error: %@: %@", ex.name, ex.reason);
        self.statusItem.button.image = [NSImage imageNamed:@"exclamation"];
        self.alertMessage = ex.name;
        self.alertReason  = ex.reason;
    }
    @finally {
        self.statusItem.menu = [NSMenu new];
        if (self.alertMessage != nil) {
            [self.statusItem.menu addItemWithTitle:@"Show Error" action:@selector(showErrorAlert:) keyEquivalent:@""];
        }
        else {
            NSString *portTitle = [NSString stringWithFormat:@"UDP port: %d", udpPort];
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

- (void)showErrorAlert:(NSNotification *)note
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    self.alertMessage = (self.alertMessage != nil) ? self.alertMessage : @"Unknown Error";
    self.alertReason  = (self.alertReason  != nil) ? self.alertReason  : @"";
    
    NSAlert *alert = [NSAlert new];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert setMessageText:self.alertMessage];
    [alert setInformativeText:self.alertReason];
    [alert runModal];
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
        @throw([NSException exceptionWithName:@"Argument Exception" reason:[NSString stringWithFormat:@"Parsing integer '%@' from environment variable '%@' failed.", envStr, kAnyBarPortEnvironmentVariable] userInfo:@{ @"argument":envStr }]);
    }
    
    port = [number intValue];
    
    if (port < 0 || port > 65535) {
        @throw([NSException exceptionWithName:@"Argument Exception" reason:[NSString stringWithFormat:@"UDP port %d is invalid.", port] userInfo:@{ @"argument":@(port) }]);
    }

    return port;
}

- (GCDAsyncUdpSocket *)initializeUdpSocket:(int)port
{
    GCDAsyncUdpSocket *udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    NSError *error = nil;
    if ([udpSocket bindToPort:port error:&error] == NO) {
        @throw([NSException exceptionWithName:@"UDP Exception" reason:[NSString stringWithFormat:@"Binding to port %d failed.", port] userInfo:@{ @"error":error }]);
    }

    if ([udpSocket beginReceiving:&error] == NO) {
        @throw([NSException exceptionWithName:@"UDP Exception" reason:[NSString stringWithFormat:@"Receiving from port %d failed.", port] userInfo:@{ @"error":error }]);
    }

    return udpSocket;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([message isEqualToString:@"quit"]) {
        [[NSApplication sharedApplication] terminate:nil];
    }
    else {
        [self setImage:message];
    }
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

@end
