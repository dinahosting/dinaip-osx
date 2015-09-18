/////////////////////////////////////////////////////////////////////////////////
//
//  DinaIPAppDelegate.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "DinaIPAppDelegate.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "StatusItemController.h"
#import "LoginWindowController.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface DinaIPAppDelegate()
- (PreferencesWindowController *)preferencesController;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation DinaIPAppDelegate
	@synthesize preferencesController, mainController;
    
//===============================================================================
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary 
    	dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" 
        ofType:@"plist"]]];
    
    loginController = [LoginWindowController new];
    loginController.delegate = self;
	statusController = [StatusItemController new];
	mainController = [MainWindowController new];

    // process "launch minimized" settings
    if ([self preferencesController].shouldLaunchMinimized && loginController.hasAutoConnect)
    {
    	[NSApp hide:nil];
    }
}

//===============================================================================
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if ([self preferencesController].shouldLaunchMinimized && loginController.hasAutoConnect)
    {
    	[mainController setupWithoutWindow];
    }
    else
    {
    	[self applicationWillUnhide:nil];
    }
    [statusController showStatusItem:self];
    [statusController startMonitoring:self];
}

//===============================================================================
- (void)applicationWillUnhide:(NSNotification *)aNotification;
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (loginController.hasAutoConnect || nil != mainController.session)
    {
        [mainController showWindow:self];
    }
    else
    {
        [loginController.window center];
        [loginController showWindow:self];
    }
}

//===============================================================================
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[self release];
}

//===============================================================================
- (void)loginControllerDidConnect:(LoginWindowController *)aController
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aController, @"Contract violation");
    [aController close];
    [mainController showWithLoginController:aController];
}

#pragma mark -
//===============================================================================
- (PreferencesWindowController *)preferencesController
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (nil == preferencesController)
    {
    	preferencesController = [PreferencesWindowController new];
    }
    return preferencesController;
}

//===============================================================================
- (IBAction)showPreferences:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [[self preferencesController] showWindow:self];
}

//===============================================================================
- (IBAction)resumeService:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [statusController startMonitoring:aSender];
}

//===============================================================================
- (IBAction)stopService:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [statusController stopMonitoring:aSender];
}

//===============================================================================
- (void)showMainWindow:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [NSApp activateIgnoringOtherApps:YES];
    [mainController showWindow:aSender];
}

//===============================================================================
- (void)toggleCheckingIP:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // this action is toggled from a Status item menu
    if (statusController.monitoring)
    {
        [self stopService:aSender];
    }
    else
    {
        [self resumeService:aSender];
    }
}

#pragma mark -
//===============================================================================
- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	BOOL theResult = YES;
    if (anItem.action == @selector(resumeService:))
    {
    	theResult = !statusController.monitoring;
    }
    else if (anItem.action == @selector(stopService:))
    {
    	theResult = statusController.monitoring;
    }
    else if (anItem.action == @selector(toggleCheckingIP:))
    {
    	if (statusController.monitoring)
        {
        	[anItem setTitle:NSLocalizedString(@"StopCheckingIPKey", @"")];
        }
        else
        {
        	[anItem setTitle:NSLocalizedString(@"StartCheckingIPKey", @"")];
        }
    }
    return theResult;
}

#pragma mark -
//===============================================================================
- (void)dealloc 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[statusController release];
	[preferencesController release];
	[mainController release];
    [loginController release];
    [super dealloc];
}

@end
