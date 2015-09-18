/////////////////////////////////////////////////////////////////////////////////
//
//  LoginItemHelper.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "LoginItemHelper.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
NSString *const kLoginItemStatusDidChange = @"LoginItemStatusDidChange";
static void LoginItemsListChanged(LSSharedFileListRef inList, void *inObject);

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface LoginItemHelper()
- (void)verify;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation LoginItemHelper

	@dynamic isInstalled;
	@synthesize identifier;

#pragma mark -
//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    return [self initWithURL:nil identifier:0];
}

//===============================================================================
- (id)initWithURL:(NSURL *)anItemURL identifier:(uint32_t)anID
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (nil == anItemURL)
    {
    	[self release];
        return nil;
    }
	self = [super init];
    if (nil != self)
    {
    	itemURL = [anItemURL retain];
        identifier = anID;
        
        // the list of current user LoginItems
    	sharedList = LSSharedFileListCreate(kCFAllocatorDefault, 
        	kLSSharedFileListSessionLoginItems, NULL);
        if (NULL == sharedList)
        {
			DevLog(@"\tE: Could not access LoginItems list");
        	[self release];
            self = nil;
        }
        else
        {
        	// registering for monitoring changes in list
            LSSharedFileListAddObserver(sharedList, CFRunLoopGetCurrent(), 
                kCFRunLoopCommonModes, LoginItemsListChanged, (void *)self);
            if (0 != identifier)
            {
                [self verify];
            }
        }
    }
    return self;
}

//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[itemURL release];
    if (NULL != sharedList)
    {
		LSSharedFileListRemoveObserver(sharedList, CFRunLoopGetCurrent(), 
        	kCFRunLoopCommonModes, LoginItemsListChanged, (void *)self);
    	CFRelease(sharedList);
    }
    [super dealloc];
}

#pragma mark -
//===============================================================================
- (BOOL)isInstalled
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // identifier is unique, so if non 0 the installed
    return (0 != identifier);
}

//===============================================================================
- (void)install:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (0 != identifier)
    {
		DevLog(@"\tD: No action. Already installed as <%@> ID=%d", itemURL, identifier);
    	return;
    }
    // adding application item to the user LoginItems
    LSSharedFileListItemRef theItem = LSSharedFileListInsertItemURL(sharedList, 
    	kLSSharedFileListItemLast, NULL, NULL, (CFURLRef)itemURL, NULL, NULL);
    if (NULL != theItem)
    {
    	identifier = LSSharedFileListItemGetID(theItem);
		DevLog(@"\tD: Installed as <%@> ID=%d", itemURL, identifier);
    	CFRelease(theItem);
    }
}

//===============================================================================
- (void)uninstall:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSArray *theItems = (NSArray *)LSSharedFileListCopySnapshot(sharedList, NULL);
	// iterate all items in the user's LoginItems ...
    for (id theItem in theItems)
    {
    	if (identifier == LSSharedFileListItemGetID((LSSharedFileListItemRef)theItem))
        {
        	// ... and remove only if identifier is for the app (id is unuque)
        	LSSharedFileListItemRemove(sharedList, (LSSharedFileListItemRef)theItem);
            break;
        }
    }
    [theItems release];
    identifier = 0;
}

#pragma mark -
#pragma mark Private

//===============================================================================
// This method verfies if our application LoginItem ID is still in the list of 
// user's LoginItems, as user might remove it manually using SystemPreferences
- (void)verify
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	BOOL theResult = NO;
	NSArray *theItems = (NSArray *)LSSharedFileListCopySnapshot(sharedList, NULL);
    for (id theItem in theItems)
    {
    	if (identifier == LSSharedFileListItemGetID((LSSharedFileListItemRef)theItem))
        {
        	theResult = YES;
            break;
        }
    }
    [theItems release];
    if (!theResult && 0 != identifier)
    {
    	identifier = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginItemStatusDidChange 
        	object:self];
    }
}

@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
static void LoginItemsListChanged(LSSharedFileListRef inList, void *inObject)
{
	DevLog(@"D: Activated callback - LoginItemsListChanged for [0x%x]", inList);
	[(LoginItemHelper *)inObject verify];
}
