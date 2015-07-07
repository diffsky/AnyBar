//
//  AppDelegate.m
//  AnyBar
//
//  Created by Nikita Prokopov on 14/02/15.
//  Copyright (c) 2015 Nikita Prokopov. All rights reserved.
//

#import "AppDelegate.h"

static NSString * const kAnyBarPortEnvironmentVariable = @"ANYBAR_PORT";
static const int kAnyBarDefaultPort = 1738;

NSImage* TintImage(NSImage *baseImage, CGFloat r, CGFloat g, CGFloat b)
{
    return [NSImage imageWithSize:NSMakeSize(19, 19) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        CGContextRef ctx = [NSGraphicsContext.currentContext CGContext];
        CGContextSetRGBFillColor(ctx, r, g, b, 1);
        CGContextSetBlendMode(ctx, kCGBlendModeSourceAtop);
        [baseImage drawInRect:dstRect];
        CGContextFillRect(ctx, dstRect);
        return YES;
    }];
}

@implementation AppDelegate
{
    int _udpPort;
    BOOL _darkMode;
    NSString *_text;
    NSString *_imageName;
    NSStatusItem *_statusItem;
    GCDAsyncUdpSocket *_udpSocket;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _udpPort = -1;
    
    _imageName = @"white";
    _text = @"";
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.button.font = [NSFont systemFontOfSize:12];
    _statusItem.menu = [NSMenu new];

    @try {
        _udpPort = [self getUdpPort];
        _udpSocket = [self initializeUdpSocket];
    }
    @catch (NSException *ex) {
        NSLog(@"Error: %@: %@", ex.name, ex.reason);
        _imageName = @"exclamation";
        [_statusItem.menu addItemWithTitle:ex.name action:nil keyEquivalent:@""];
        [_statusItem.menu addItemWithTitle:ex.reason action:nil keyEquivalent:@""];
        [_statusItem.menu addItem:[NSMenuItem separatorItem]];
    }
    @finally {
        if (_udpPort >= 0 && _udpPort <= 65535) {
            [_statusItem.menu addItemWithTitle:[NSString stringWithFormat:@"UDP port: %d", _udpPort] action:nil keyEquivalent:@""];
        }
        [_statusItem.menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
    }

    [self refreshDarkMode];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshDarkMode) name:@"AppleInterfaceThemeChangedNotification" object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [_udpSocket close];
    _udpSocket = nil;

    [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
    _statusItem = nil;
}

- (int)getUdpPort
{
    NSString *envStr = [[[NSProcessInfo processInfo] environment] objectForKey:kAnyBarPortEnvironmentVariable];
    
    if (!envStr) { return kAnyBarDefaultPort; }
    
    int port = -1;
    NSScanner *scanner = [NSScanner scannerWithString:envStr];

    if (![scanner scanInt:&port]) {
        @throw([NSException exceptionWithName:@"Argument Exception" reason:[NSString stringWithFormat:@"Parsing int '%@' from env var '%@' failed", envStr, kAnyBarPortEnvironmentVariable] userInfo:@{ @"argument":envStr }]);
    }
    if (port < 0 || port > 65535) {
        @throw([NSException exceptionWithName:@"Argument Exception" reason:[NSString stringWithFormat:@"UDP port %d is invalid", port] userInfo:@{ @"argument":@(port) }]);
    }
    return port;
}

- (GCDAsyncUdpSocket *)initializeUdpSocket
{
    GCDAsyncUdpSocket *udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    NSError *error = nil;
    if ([udpSocket bindToPort:_udpPort error:&error] == NO) {
        @throw([NSException exceptionWithName:@"UDP Exception" reason:[NSString stringWithFormat:@"Binding to port %d failed", _udpPort] userInfo:@{ @"error":error }]);
    }
    if ([udpSocket beginReceiving:&error] == NO) {
        @throw([NSException exceptionWithName:@"UDP Exception" reason:[NSString stringWithFormat:@"Receiving from port %d failed", _udpPort] userInfo:@{ @"error":error }]);
    }
    return udpSocket;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    message = [message stringByTrimmingCharactersInSet:whitespaceSet];

    if (message == nil || [message isEqualToString:@""]) {
        NSLog(@"Empty message received on port %d.", _udpPort);
        return;
    }
    
    NSInteger locationOfFirstSpace = [message rangeOfString:@" "].location;
    NSString *imageName = message;
    _text = @"";
    _statusItem.button.imagePosition = NSImageOnly;
    
    if (locationOfFirstSpace != NSNotFound) {
        imageName = [message substringToIndex:locationOfFirstSpace];
        _text = [message substringFromIndex:locationOfFirstSpace];
        _text = [_text stringByTrimmingCharactersInSet:whitespaceSet];
        _statusItem.button.imagePosition = NSImageLeft;
    }
    
    if ([imageName isEqualToString:@"quit"]) {
        [[NSApplication sharedApplication] terminate:nil];
    }

    // Hack to make statusItem properly resize when a short text message
    // is set after a long one. Without this, statusItem will stay at the
    // wider size of the long message until the next time it is updated.
    [_statusItem.button setAttributedAlternateTitle:nil];
    
    [self setImage:imageName];
    [_statusItem.button setTitle:_text];
    [_statusItem.button setAttributedAlternateTitle:[[NSAttributedString alloc] initWithString:_text attributes:@{ NSForegroundColorAttributeName: NSColor.whiteColor, NSFontAttributeName: [NSFont systemFontOfSize:12] }]];
}

- (void)refreshDarkMode
{
    NSString *mode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    _darkMode = [mode isEqualToString:@"Dark"] ? YES : NO;
    [self setImage:_imageName];
}

- (NSString *)homedirImagePath:(NSString *)name
{
    return [NSString stringWithFormat:@"%@/%@/%@.png", NSHomeDirectory(), @".AnyBar", name];
}

- (void)setImage:(NSString *)name
{
    NSImage *image = nil;
    
    image = [self dotForBuiltIn:name];
    if (!image) {
        image = [self dotForHex:name];
    }
    if (_darkMode && !image) {
        image = [[NSImage alloc] initWithContentsOfFile:[self homedirImagePath:[name stringByAppendingString:@"_alt@2x"]]];
    }
    if (_darkMode && !image) {
        image = [[NSImage alloc] initWithContentsOfFile:[self homedirImagePath:[name stringByAppendingString:@"_alt"]]];
    }
    if (!image) {
        image = [[NSImage alloc] initWithContentsOfFile:[self homedirImagePath:[name stringByAppendingString:@"@2x"]]];
    }
    if (!image) {
        image = [[NSImage alloc] initWithContentsOfFile:[self homedirImagePath:name]];
    }
    if (!image) {
        image = [NSImage imageNamed:@"question"];
        [image setTemplate:YES];
        NSLog(@"Cannot find image '%@'", name);
    }
    
    // Certain images are template images so they work automatically in dark mode.
    if ([name isEqualToString:@"white"] || [name isEqualToString:@"black"] ||
        [name isEqualToString:@"question"] || [name hasSuffix:@"Template"]) {
        [image setTemplate:YES];
    }
    
    _statusItem.button.image = image;
    _statusItem.button.alternateImage = TintImage(image, 1, 1, 1);
    _imageName = name;
}

- (NSImage *)dotForBuiltIn:(NSString *)name
{
    if ([name isEqualToString:@"white"] || [name isEqualToString:@"black"] ||
        [name isEqualToString:@"question"] || [name isEqualToString:@"exclamation"]) {
        return [NSImage imageNamed:name];
    }
    if ([name isEqualToString:@"red"])    { return TintImage([NSImage imageNamed:@"black"], 0.81, 0.03, 0.00); }
    if ([name isEqualToString:@"green"])  { return TintImage([NSImage imageNamed:@"black"], 0.50, 0.92, 0.05); }
    if ([name isEqualToString:@"blue"])   { return TintImage([NSImage imageNamed:@"black"], 0.30, 0.60, 0.92); }
    if ([name isEqualToString:@"orange"]) { return TintImage([NSImage imageNamed:@"black"], 1.00, 0.62, 0.00); }
    if ([name isEqualToString:@"cyan"])   { return TintImage([NSImage imageNamed:@"black"], 0.15, 0.95, 0.80); }
    if ([name isEqualToString:@"purple"]) { return TintImage([NSImage imageNamed:@"black"], 0.56, 0.07, 1.00); }
    if ([name isEqualToString:@"yellow"]) { return TintImage([NSImage imageNamed:@"black"], 1.00, 0.90, 0.00); }
    
    return nil;
}

- (NSImage *)dotForHex:(NSString *)hexStr
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#[0-9a-fA-F]{6}" options:0 error:NULL];
    
    if ([regex firstMatchInString:hexStr options:0 range:NSMakeRange(0, [hexStr length])]) {
        UInt32 hexInt = 0;
        NSScanner *scanner = [NSScanner scannerWithString:[hexStr substringFromIndex:1]]; // skip #
        [scanner scanHexInt:&hexInt];
        CGFloat r = ((CGFloat)((hexInt & 0xFF0000) >> 16))/255;
        CGFloat g = ((CGFloat)((hexInt & 0x00FF00) >>  8))/255;
        CGFloat b = ((CGFloat)((hexInt & 0x0000FF)      ))/255;
        return TintImage([NSImage imageNamed:@"black"], r, g, b);
    }
    return nil;
}

- (id)osaImageBridge
{
    NSLog(@"OSA Event: %@ - %@", NSStringFromSelector(_cmd), _imageName);
    return _imageName;
}

- (void)setOsaImageBridge:(id)imgName
{
    NSLog(@"OSA Event: %@ - %@", NSStringFromSelector(_cmd), imgName);
    _imageName = (NSString *)imgName;
    [self setImage:_imageName];
}

- (id)osaTextBridge
{
    NSLog(@"OSA Event: %@ - %@", NSStringFromSelector(_cmd), _text);
    return _text;
}

- (void)setOsaTextBridge:(id)text
{
    NSLog(@"OSA Event: %@ - %@", NSStringFromSelector(_cmd), text);
    _text = (NSString *)text;
    [_statusItem.button setTitle:text];
}

@end
