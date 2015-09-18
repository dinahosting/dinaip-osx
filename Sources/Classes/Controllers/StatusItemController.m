/////////////////////////////////////////////////////////////////////////////////
//
//  StatusItemController.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "StatusItemController.h"
#import "PreferencesWindowController.h"
#import "DinaIPAppDelegate.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface StatusItemController()
	@property (nonatomic, assign) BOOL monitoring;
- (void)scheduleIPUpdate:(id)aSender;
- (void)updateStatusIcon:(NSTimer *)aTimer;
- (void)empowerUpdateTimerWithLastUpdateDate:(NSDate *)aDate;
- (void)cleanup;
- (void)updateMenu;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation StatusItemController
	@synthesize monitoring;

//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super init];
    if (nil != self)
    {
    	// icons to be shown in loop during IP check
    	icons = [[NSArray alloc] initWithObjects:[NSImage imageNamed:@"ico01"],
        	[NSImage imageNamed:@"ico02"], [NSImage imageNamed:@"ico03"], nil];
        buffer = [NSMutableData new];
    }
    return self;
}

#pragma mark -
//===============================================================================
- (void)showStatusItem:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (nil == menuIcon)
	{
		// request new menubar status item ...
		NSStatusBar *theBar = [NSStatusBar systemStatusBar];
		menuIcon = [theBar statusItemWithLength:NSVariableStatusItemLength];
        [menuIcon setHighlightMode:YES];

		// ... set its length according to image width
		const CGFloat kPadding = 4.;
		NSImage *theIcon = [icons objectAtIndex:0];
		[menuIcon setLength:[theIcon size].width + 2.*kPadding];
        [menuIcon setImage:theIcon];
        
        // menu for commands and IP demo
		NSMenu *theMenu = [NSMenu new];
        [theMenu addItemWithTitle:[NSLocalizedString(@"StatusIPKey", @"") 
        	stringByAppendingString:NSLocalizedString(@"NotDeterminedKey", @"")] 
            action:NULL keyEquivalent:@""];
        [theMenu addItemWithTitle:NSLocalizedString(@"StopCheckingIPKey", @"") 
        	action:@selector(toggleCheckingIP:) keyEquivalent:@""];        
        [theMenu addItem:[NSMenuItem separatorItem]];
        [theMenu addItemWithTitle:NSLocalizedString(@"ShowDinaIPKey", @"") 
        	action:@selector(showMainWindow:) keyEquivalent:@""];        
        [menuIcon setMenu:theMenu];
        [theMenu release];

		[menuIcon retain]; // this is a member, so hold it
		// icon is shown automatically in next even loop
	}
}

//===============================================================================
- (void)startMonitoring:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (!self.monitoring)
    {
        self.monitoring = YES;
        [self scheduleIPUpdate:aSender];
    }
}

//===============================================================================
- (void)updateMenu
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // reset status item & menu from defaults
    PreferencesWindowController *thePreferences = [[NSApp delegate] preferencesController];
    [[[[menuIcon menu] itemArray] objectAtIndex:0] setTitle:
        [NSLocalizedString(@"StatusIPKey", @"") stringByAppendingString:
        thePreferences.lastIP]];
    [menuIcon setToolTip:[NSLocalizedString(@"StatusIPKey", @"") 
        stringByAppendingString:thePreferences.lastIP]];
}

//===============================================================================
- (void)stopMonitoring:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (self.monitoring)
    {
    	// invalidate everything on stop
        [updateTimer invalidate];
        [updateTimer release], updateTimer = nil;
        [iconTimer invalidate];
        [iconTimer release], iconTimer = nil;
        
        [connection cancel];
        [connection autorelease], connection = nil;
        
        menuIcon.image = [icons objectAtIndex:0];

        self.monitoring = NO;
    }
}

//===============================================================================
- (void)scheduleIPUpdate:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [updateTimer release], updateTimer = nil;
    // empower animation timer...
	iconTimer = [[NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateStatusIcon:) 
    	userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:iconTimer forMode:NSRunLoopCommonModes];
    
    DevLog(@"D: Connecting with main DNS");
    [buffer setData:nil];
    // ... and send request to a server
    connection = [[NSURLConnection connectionWithRequest:[NSURLRequest 
    	requestWithURL:[NSURL URLWithString:@"http://dinadns01.dinaserver.com/"]] 
        delegate:self] retain];
}

//===============================================================================
- (void)updateStatusIcon:(NSTimer *)aTimer
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSInteger theIndex = [icons indexOfObject:menuIcon.image];
	// just show next icon
    theIndex += 1;
    if (theIndex == icons.count)
    {
    	theIndex = 0;
    }
    menuIcon.image = [icons objectAtIndex:theIndex];
}

//===============================================================================
- (void)empowerUpdateTimerWithLastUpdateDate:(NSDate *)aDate
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [self cleanup];
    
	// schedule next udpate depending on preferences
    PreferencesWindowController *thePreferences = [[NSApp delegate] preferencesController];
    NSInteger thePeriod = 0;
    if (thePreferences.shouldUseMinutes)
    {
    	thePeriod += thePreferences.minutes*60;
    }
    if (thePreferences.shouldUseHours)
    {
    	thePeriod += thePreferences.hours*60*60;
    }
    if (thePreferences.shouldUseDays)
    {
    	thePeriod += thePreferences.days*24*60*60;
    }
    if (0 == thePeriod)
    {
    	// all is turned of so use minimal
        thePeriod = thePreferences.minimalIPUpdateInterval*60;
    }
    DevLog(@"I: Reschedule update IP with period: %lu", thePeriod);

    thePeriod = [[aDate dateByAddingTimeInterval:thePeriod] timeIntervalSinceDate:[NSDate date]];
    if (thePeriod < 0)
    {
    	thePeriod = 0;
    }
	updateTimer = [[NSTimer timerWithTimeInterval:thePeriod target:self 
    	selector:@selector(scheduleIPUpdate:) userInfo:nil repeats:NO] retain];
    [[NSRunLoop currentRunLoop] addTimer:updateTimer forMode:NSRunLoopCommonModes];
}

#pragma mark -
//===============================================================================
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)aData
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[buffer appendData:aData];
}

//===============================================================================
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	useAlernateDNS = NO;
    
	NSString *theIP = [[[NSString alloc] initWithData:buffer 
    	encoding:NSUTF8StringEncoding] autorelease];
    DevLog(@"I: Retrived IP: %@", theIP);

	// just store retrieved IP (all other is others resposibility) ...
    PreferencesWindowController *thePreferences = [[NSApp delegate] preferencesController];
    thePreferences.lastIPUpdate = [NSDate date];
    thePreferences.lastIP = theIP;
    [self updateMenu];
    // ... and schedule next
    [self empowerUpdateTimerWithLastUpdateDate:[NSDate date]];
}

//===============================================================================
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)anError
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (!useAlernateDNS)
    {
		ERROR(@"E: Failed main DNS -> %@", [anError description]);
        DevLog(@"D: Connecting with alternate DNS");
    	useAlernateDNS = YES;
        // on fail try with another dns server but only once
        connection = [[NSURLConnection connectionWithRequest:[NSURLRequest 
            requestWithURL:[NSURL URLWithString:@"http://dinadns02.dinaserver.com/"]] 
            delegate:self] retain];
    }
	else
    {
		ERROR(@"E: Failed to retrieve IP -> %@", [anError description]);
    	useAlernateDNS = NO;
        [self cleanup];
        [self empowerUpdateTimerWithLastUpdateDate:[NSDate date]];
    }
}

#pragma mark -
//===============================================================================
- (void)cleanup
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [buffer setData:nil];
    [iconTimer invalidate];
    [iconTimer release], iconTimer = nil;
    menuIcon.image = [icons objectAtIndex:0];
    [connection autorelease], connection = nil;
}

//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[iconTimer invalidate];
    [iconTimer release];
	[updateTimer invalidate];
    [updateTimer release];
    
    [connection cancel];
    [connection release];
    
	[icons release];
    [buffer release];
	[menuIcon release];
    [super dealloc];
}

@end
