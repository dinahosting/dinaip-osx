/////////////////////////////////////////////////////////////////////////////////
//
//  PreferencesWindowController.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "PreferencesWindowController.h"
#import "LoginItemHelper.h"
#import "Common.h"

NSString *const kDynamicIPDidChangeNotification = @"DynamicIPDidChangeNotification";
NSString *const kNewIPAddress = @"NewIPAddress";

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface PreferencesWindowController()
- (void)onLoginItemStatusDidChange:(NSNotification *)aNotification;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation PreferencesWindowController

	@dynamic shouldUseMinutes, shouldUseHours, shouldUseDays;
	@dynamic minutes, hours, days, minimalIPUpdateInterval;
	@dynamic shouldAddToLoginItems, shouldLaunchMinimized, shouldAutodetectIP;

//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super initWithWindowNibName:@"PreferencesWindow" owner:self];
    if (nil != self)
    {
    	NSURL *theURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        // if on 10.6+ it can be used universal URL, so relocation of application
        // won't affect LoginItem
        if ([theURL respondsToSelector:@selector(fileReferenceURL)])
        {
        	theURL = [theURL fileReferenceURL];
        }
        DevLog(@"D: Creating login item helper for: %@", theURL);
    	loginItem = [[LoginItemHelper alloc] initWithURL:theURL identifier:(uint32_t)
        	[[NSUserDefaults standardUserDefaults] integerForKey:@"loginItemID"]];
        if (nil == loginItem)
        {
	        DevLog(@" E: Failed creating login item helper for: %@", theURL);
        	[self release];
            self = nil;
        }
        else
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:
                @selector(onLoginItemStatusDidChange:) name:kLoginItemStatusDidChange 
                object:loginItem];
        }
    }
    return self;
}

//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[loginItem release];
    [super dealloc];
}

#pragma mark -
//===============================================================================
- (BOOL)shouldUseMinutes
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] boolForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (BOOL)shouldUseHours
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] boolForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (BOOL)shouldUseDays
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] boolForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (NSInteger)minimalIPUpdateInterval
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] integerForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (NSInteger)minutes
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] integerForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (NSInteger)hours
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] integerForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (NSInteger)days
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] integerForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (BOOL)shouldAddToLoginItems
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return loginItem.isInstalled;
}

//===============================================================================
- (void)setShouldAddToLoginItems:(BOOL)aValue
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (aValue)
    {
    	[loginItem install:self];
        if (0 != loginItem.identifier)
        {
            [[NSUserDefaults standardUserDefaults] setInteger:loginItem.identifier 
                forKey:@"loginItemID"];
        }
    }
    else
    {
    	[loginItem uninstall:self];
        if (0 == loginItem.identifier)
        {
        	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"loginItemID"];
        }
    }
}

//===============================================================================
- (BOOL)shouldLaunchMinimized
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] boolForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (BOOL)shouldAutodetectIP
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[NSUserDefaults standardUserDefaults] boolForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (NSDate *)lastIPUpdate
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSString *theDate = [[NSUserDefaults standardUserDefaults] 
    	stringForKey:NSStringFromSelector(_cmd)];
    return (nil == theDate ? nil : [NSDate dateWithString:theDate]);
}

//===============================================================================
- (void)setLastIPUpdate:(NSDate *)aDate
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (nil != aDate)
    {
    	[[NSUserDefaults standardUserDefaults] setObject:[aDate description] 
        	forKey:@"lastIPUpdate"];
    }
}

//===============================================================================
- (NSString *)lastIP
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    return [[NSUserDefaults standardUserDefaults] objectForKey:NSStringFromSelector(_cmd)];
}

//===============================================================================
- (void)setLastIP:(NSString *)anIP
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (nil == anIP)
    {
    	return;
    }
    if (![self.lastIP isEqualToString:anIP])
    {    	
		// if IP changed notify as well all other application components
        [[NSUserDefaults standardUserDefaults] setObject:anIP forKey:@"lastIP"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDynamicIPDidChangeNotification 
            object:nil userInfo:[NSDictionary dictionaryWithObject:anIP forKey:kNewIPAddress]];
    }
}

//===============================================================================
- (void)storeToContainer:(NSMutableDictionary *)aContainer
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSMutableDictionary *theSettings = [NSMutableDictionary dictionary];
    [theSettings setObject:[NSNumber numberWithBool:self.shouldUseMinutes] 
    	forKey:@"shouldUseMinutes"];
    if (self.shouldUseMinutes)
    {
    	[theSettings setObject:[NSNumber numberWithInteger:self.minutes] 
        	forKey:@"minutes"];
    }
    [theSettings setObject:[NSNumber numberWithBool:self.shouldUseHours] 
    	forKey:@"shouldUseHours"];
    if (self.shouldUseHours)
    {
    	[theSettings setObject:[NSNumber numberWithInteger:self.hours] 
        	forKey:@"hours"];
    }
    [theSettings setObject:[NSNumber numberWithBool:self.shouldUseDays] 
    	forKey:@"shouldUseDays"];
    if (self.shouldUseDays)
    {
    	[theSettings setObject:[NSNumber numberWithInteger:self.days] 
        	forKey:@"days"];
    }
    [theSettings setObject:[NSNumber numberWithBool:self.shouldAddToLoginItems] 
    	forKey:@"shouldAddToLoginItems"];
    [theSettings setObject:[NSNumber numberWithBool:self.shouldLaunchMinimized] 
    	forKey:@"shouldLaunchMinimized"];
    [theSettings setObject:[NSNumber numberWithBool:self.shouldAutodetectIP] 
    	forKey:@"shouldAutodetectIP"];
    
    DevLog(@"Stored app settings:\n%@", [theSettings description]);
    [aContainer setObject:theSettings forKey:@"AppSettings"];
}

//===============================================================================
- (void)restoreFromContainer:(NSDictionary *)aContainer
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSMutableDictionary *theSettings = [aContainer objectForKey:@"AppSettings"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSMutableDictionary *thePersistent = [NSMutableDictionary dictionaryWithDictionary:
    	[[NSUserDefaults standardUserDefaults] persistentDomainForName:[[NSBundle mainBundle] 
        bundleIdentifier]]];
    [thePersistent addEntriesFromDictionary:theSettings];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:thePersistent 
    	forName:[[NSBundle mainBundle] bundleIdentifier]];
    DevLog(@"Restored app settings:\n%@", [theSettings description]);
}

#pragma mark -
//===============================================================================
- (void)onLoginItemStatusDidChange:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[self willChangeValueForKey:@"loginItemID"];
    if (loginItem.isInstalled)
    {
    	[[NSUserDefaults standardUserDefaults] setInteger:loginItem.identifier 
                forKey:@"loginItemID"];
    }
    else
    {
    	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"loginItemID"];
    }
	[self didChangeValueForKey:@"loginItemID"];
}

#pragma mark -
//===============================================================================
- (void)windowWillClose:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[self.window makeFirstResponder:nil];
}

@end
