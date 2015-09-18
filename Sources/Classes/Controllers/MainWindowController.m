/////////////////////////////////////////////////////////////////////////////////
//
//  MainWindowController.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "MainWindowController.h"
#import "LoginWindowController.h"
#import "AddDomainWindowController.h"
#import "ZonesWindowController.h"
#import "VerifyWindowController.h"
#import "DinaIPAppDelegate.h"

#import "LoginDinaDNS.h"
#import "WorkSession.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface MainWindowController()<NSTableViewDelegate, LoginWindowControllerDelegate,
	ZonesWindowControllerDelegate, NSTableViewDataSource>
	@property (nonatomic, retain) NSMutableArray *domains;

- (void)performEditDomain:(id)aSender;
- (void)deleteDomainSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(void *)aContext;
- (void)failedSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(void *)aContext;
- (void)onZoneEditControllerDidFinish:(NSNotification *)aNotification;
- (void)notifyOnVersion:(NSDictionary *)aVersionInfo;
- (void)saveDidEnd:(NSSavePanel *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext;
- (void)openDidEnd:(NSOpenPanel *)aPanel returnCode:(NSInteger)aCode contextInfo:(id)aContext;
- (void)verifyForExportDidEndWithCode:(NSNumber *)aCode;
- (void)verifyForImportDidEndWithCode:(NSNumber *)aCode;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation MainWindowController
	@synthesize domainTable, domains, session;

//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super initWithWindowNibName:@"MainWindow" owner:self];
    if (nil != self)
    {
    	// create all related controllers empty
    	loginController = [LoginWindowController new];
        loginController.delegate = self;
        
        verifyController = [VerifyWindowController new];
        verifyController.delegate = self;

    	addController = [AddDomainWindowController new];
        addController.delegate = self;

		editingDomains = [NSMutableDictionary new];
        domains = [NSMutableArray new];
        justLaunched = YES;
    }
    return self;
}

//===============================================================================
- (void)awakeFromNib
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    
    // finish set UI here
	self.domainTable.delegate = self;
    self.domainTable.dataSource = self;
    [self.domainTable setDoubleAction:@selector(performEditDomain:)];

}

#pragma mark -
//===============================================================================
- (IBAction)login:(id)aSender 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // Activate Log in controller to perform log in
	[loginController showWindowModalToWindow:[self window]];
}

//===============================================================================
- (IBAction)addDomain:(id)aSender 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // Activate Add domain controller with not added yet domains
    
    NSMutableArray *theDomains = [NSMutableArray arrayWithArray:self.session.domains];
    [theDomains removeObjectsInArray:self.session.monitoredDomains];
    addController.availableDomains = theDomains;
    
	[addController showWindowModalToWindow:[self window]];
}

//===============================================================================
- (IBAction)deleteDomain:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // delete selected domain with warning for a user
    NSBeginCriticalAlertSheet(NSLocalizedString(@"DeleteDomainTitleKey", @""), 
    	NSLocalizedString(@"AcceptKey", @""), NSLocalizedString(@"CancelKey", @""), 
        nil, self.window, self, @selector(deleteDomainSheetDidEnd:returnCode:contextInfo:), 
        NULL, NULL, NSLocalizedString(@"DeleteDomainMessageKey", @""));
}

//===============================================================================
- (void)performEditDomain:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // Activate edit domain on double-click in table
    if (-1 != [self.domainTable clickedRow])
    {
    	[self editDomain:aSender];
    }
}

//===============================================================================
- (IBAction)editDomain:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // Activate Edit Zones controller for selected domain
    NSString *theDomain = [self.session.monitoredDomains objectAtIndex:[self.domainTable 
    	selectedRow]];
    ZonesWindowController *theController = [editingDomains objectForKey:theDomain];
    if (nil == theController)
    {
        theController = [ZonesWindowController new];
        
        // main controller needs to listen when the edit controller finished
        // to avoid two edit controllers for one domain
        [[NSNotificationCenter defaultCenter] addObserver:self 
        	selector:@selector(onZoneEditControllerDidFinish:) name:kZoneEditDidFinishNotification 
            object:theController];

        theController.domain = theDomain;
        theController.session = self.session;
        [editingDomains setObject:theController forKey:theDomain];
        [theController release];

	    [theController showWindowModalToWindow:nil];
    }
    else 
    {
        [theController showWindow:self];
    }
}

//===============================================================================
- (IBAction)exportConfiguration:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // Activate account verififcation before export
    verifyController.session = self.session;
    verifyController.callback = @selector(verifyForExportDidEndWithCode:);
    [verifyController showWindowModalToWindow:[self window]];
}

//===============================================================================
- (void)verifyForExportDidEndWithCode:(NSNumber *)aCode
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // verification for export did finish ...
    if ([aCode boolValue])
    {
    	// ... successfully - show standard save dialog
        NSSavePanel *thePanel = [NSSavePanel savePanel];
        [thePanel setAllowedFileTypes:[NSArray arrayWithObject:@"plist"]];
        [thePanel beginSheetForDirectory:NSHomeDirectory() file:@"DinaIP" 
            modalForWindow:self.window modalDelegate:self 
            didEndSelector:@selector(saveDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
    else
    {
    	// ... failed - show alert
        NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedLoginTitleKey", @""), 
            NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
            @selector(failedSheetDidEnd:returnCode:contextInfo:), 
            NULL, NULL, NSLocalizedString(@"FailedLoginMessageKey", @""));
    }
}

//===============================================================================
- (IBAction)importConfiguration:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// Activate account verification for import 
    verifyController.session = self.session;
    verifyController.callback = @selector(verifyForImportDidEndWithCode:);
    [verifyController showWindowModalToWindow:[self window]];
}

//===============================================================================
- (void)verifyForImportDidEndWithCode:(NSNumber *)aCode
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // verification for import did finish ...
    if ([aCode boolValue])
    {
    	// ... successfully - show standard open dialog
        NSOpenPanel *thePanel = [NSOpenPanel openPanel];
        [thePanel setCanChooseDirectories:NO];
        [thePanel setAllowsMultipleSelection:NO];
        [thePanel setAllowedFileTypes:[NSArray arrayWithObject:@"plist"]];
        [thePanel beginSheetForDirectory:NSHomeDirectory() file:@"DinaIP" modalForWindow:self.window 
            modalDelegate:self didEndSelector:@selector(openDidEnd:returnCode:contextInfo:) 
            contextInfo:NULL];
    }
    else
    {
    	// ... failed - show alert
        NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedLoginTitleKey", @""), 
            NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
            @selector(failedSheetDidEnd:returnCode:contextInfo:), 
            NULL, NULL, NSLocalizedString(@"FailedLoginMessageKey", @""));
    }
}


#pragma mark -
//===============================================================================
- (void)saveDidEnd:(NSSavePanel *)aPanel returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aPanel close];
    if (NSOKButton == aCode)
    {
		// save configured - so just save all current settings to a file
    	[[NSUserDefaults standardUserDefaults] synchronize];
        
        NSMutableDictionary *theContainer = [NSMutableDictionary dictionary];
        [[[NSApp delegate] preferencesController] storeToContainer:theContainer];
        [self.session storeToContainer:theContainer];
        [theContainer setObject:[self.session.identifier dataUsingEncoding:NSUTF8StringEncoding] 
        	forKey:@"lt"];
        [theContainer setObject:[self.session.password dataUsingEncoding:NSUTF8StringEncoding] 
        	forKey:@"gt"];
        
        DevLog(@"Export configuration to: %@", [aPanel filename]);
    	if (![theContainer writeToFile:[aPanel filename] atomically:YES])
        {
            NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedStoreTitleKey", @""), 
                NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
                @selector(failedSheetDidEnd:returnCode:contextInfo:), 
                NULL, NULL, NSLocalizedString(@"FailedStoreMessageKey", @""));
        }
    }
}

//===============================================================================
- (void)openDidEnd:(NSOpenPanel *)aPanel returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aPanel close];
    NSArray *theFiles = [aPanel filenames];
    if (NSOKButton == aCode && 0 < theFiles.count)
    {
    	// open is configured so restore all settings from a file
        NSDictionary *theSettings = [NSDictionary dictionaryWithContentsOfFile:[theFiles 
        	lastObject]];
        DevLog(@"Import configuration from: %@", [theFiles lastObject]);
        NSData *theIDData = [theSettings objectForKey:@"lt"];
        NSData *thePWData = [theSettings objectForKey:@"gt"];
        if (nil != theSettings && nil != theIDData && nil != thePWData)
        {
        	NSString *theNewID = [[NSString alloc] initWithData:theIDData 
            	encoding:NSUTF8StringEncoding];
            NSString *theNewPW = [[NSString alloc] initWithData:thePWData 
            	encoding:NSUTF8StringEncoding];
            if ([self.session.identifier isEqualToString:theNewID] && [self.session.password 
            	isEqualToString:theNewPW])
            {
                [[[NSApp delegate] preferencesController] restoreFromContainer:theSettings];
                [self.session restoreFromContainer:theSettings];
            }
            [theNewID release];
            [theNewPW release];
            [self.domainTable reloadData];
            [self.session storeSession];
        }
        else
        {
            NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedRestoreTitleKey", @""), 
                NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
                @selector(failedSheetDidEnd:returnCode:contextInfo:), 
                NULL, NULL, NSLocalizedString(@"FailedRestoreMessageKey", @""));
        }
    }
}

//===============================================================================
- (void)deleteDomainSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(void *)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];
    if (NSOKButton == aCode)
    {
    	// delete domain approved - so remove a domain from a list of monitored
        [self.session removeDomain:[self.session.monitoredDomains 
        	objectAtIndex:[self.domainTable selectedRow]]];
        [self.domainTable reloadData];
    }
}

//===============================================================================
- (void)failedSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(void *)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // on any fail or cancel just close sheet
	[aSheet close];
}

//===============================================================================
- (void)updateSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(NSDictionary *)aVersionInfo
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];

	NSString *theUpdate = [[aVersionInfo objectForKey:@"nivel_auth"] uppercaseString];
    if (NSCancelButton == aCode && ([theUpdate isEqualToString:@"OPTIONAL"] || 
    	[theUpdate isEqualToString:@"MUST"]))
    {
    	// in this case don't show notification for upate anymore
    	[[NSUserDefaults standardUserDefaults] setObject:[aVersionInfo objectForKey:@"version"] 
        	forKey:@"skipVersion"];
    	return;
    }
	// user confirms udpate - so extract URL and open in browser, if required - 
    // terminate application
    NSString *theLink = [aVersionInfo objectForKey:@"url"];
    if (nil != theLink)
    {
    	NSURL *theURL = [NSURL URLWithString:theLink];
        if (nil != theURL)
        {
        	[[NSWorkspace sharedWorkspace] openURL:theURL];
            NSString *theUpdate = [[aVersionInfo objectForKey:@"nivel_auth"] 
            	uppercaseString];
            if ([theUpdate isEqualToString:@"REQUIRED"])
            {
            	[NSApp terminate:nil];
            }
        }
    }
    [aVersionInfo release];
}

#pragma mark -
//===============================================================================
- (void)addDomainControllerDidSelectDomain:(NSString *)aDomain
{
	TRACE(@"T: [%@ %s]", self, _cmd);
//    NSAssert(aDomain, @"Contract violation");
    if (nil == aDomain)
    {
    	return;
    }
    // user selects domain to be added
    if ([self.session.domains containsObject:aDomain])
    {
        [self.session addDomain:aDomain];
	    [self.domainTable reloadData];
    }
    else 
    {
        NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedAddTitleKey", @""), 
            NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
            @selector(failedSheetDidEnd:returnCode:contextInfo:), 
            NULL, NULL, NSLocalizedString(@"FailedAddMessageKey", @""));
    }
}

//===============================================================================
- (void)showWithLoginController:(LoginWindowController *)aController
{
	[self showWindow:nil];
	// login did finish so create work session
    self.session = [WorkSession sessionWithType:aController.loginType
    	identifier:aController.identifier password:aController.password 
        domains:[aController domains]];
    
    [self.domainTable reloadData];
    
    // initiate check for update if was requested
    if (aController.shouldCheckForUpdates)
    {
    	NSDictionary *theVersionInfo = [aController version];
        NSString *theServerVersion = [theVersionInfo objectForKey:@"version"]; 
        if (NSOrderedDescending == [theServerVersion compare:[[NSBundle mainBundle] 
        	objectForInfoDictionaryKey:@"CFBundleShortVersionString"]])
        {
        	[self notifyOnVersion:theVersionInfo];
        }
    }
}

//===============================================================================
- (void)loginControllerDidConnect:(LoginWindowController *)aController
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aController, @"Contract violation");
    
	// login did finish so create work session
    self.session = [WorkSession sessionWithType:aController.loginType
    	identifier:aController.identifier password:aController.password 
        domains:[aController domains]];
    
    [self.domainTable reloadData];
    
    // initiate check for update if was requested
    if (aController.shouldCheckForUpdates)
    {
    	NSDictionary *theVersionInfo = [aController version];
        NSString *theServerVersion = [theVersionInfo objectForKey:@"version"]; 
        if (NSOrderedDescending == [theServerVersion compare:[[NSBundle mainBundle] 
        	objectForInfoDictionaryKey:@"CFBundleShortVersionString"]])
        {
        	[self notifyOnVersion:theVersionInfo];
        }
    }
}

//===============================================================================
- (void)onZoneEditControllerDidFinish:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aNotification, @"Contract violation");
    // called from notification
    [[NSNotificationCenter defaultCenter] removeObserver:self 
    	name:kZoneEditDidFinishNotification object:[aNotification object]];
	[self zoneEditControllerDidFinish:[aNotification object]];
}

//===============================================================================
- (void)zoneEditControllerDidFinish:(ZonesWindowController *)aController
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aController, @"Contract violation");
    // called as delegate method - but removed from monitored
    [editingDomains removeObjectForKey:aController.domain];
}

//===============================================================================
- (void)notifyOnVersion:(NSDictionary *)aVersionInfo
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aVersionInfo, @"Contract violation");
    NSString *theUpdate = [[aVersionInfo objectForKey:@"nivel_auth"] uppercaseString];
    NSString *theTitle = NSLocalizedString(@"NewVersionTitleKey", @"");
    
    NSString *theSkipVersion = [[NSUserDefaults standardUserDefaults] 
    	objectForKey:@"skipVersion"];
    NSString *theNewVersion = [aVersionInfo objectForKey:@"version"];
    
    // show different alerts depending on detected update type
    if ([theUpdate isEqualToString:@"REQUIRED"])
    {
        NSBeginInformationalAlertSheet(theTitle, NSLocalizedString(@"AcceptKey", @""), 
        	nil, nil, self.window, self, 
            @selector(updateSheetDidEnd:returnCode:contextInfo:), 
            NULL, (void *)[aVersionInfo retain], 
            [NSString stringWithFormat:NSLocalizedString(@"RequiredUpdateMessageKey", 
            @""), theNewVersion]);
    }
    else
    if ([theUpdate isEqualToString:@"OPTIONAL"] && ![theSkipVersion isEqualToString:theNewVersion])
    {
        NSBeginInformationalAlertSheet(theTitle, NSLocalizedString(@"AcceptKey", @""), 
        	NSLocalizedString(@"CancelKey", @""), nil, self.window, self, 
            @selector(updateSheetDidEnd:returnCode:contextInfo:), 
            NULL, (void *)[aVersionInfo retain], 
            [NSString stringWithFormat:NSLocalizedString(@"OptionalUpdateMessageKey", 
            @""), theNewVersion]);
    }
    else
    if ([theUpdate isEqualToString:@"MUST"] && ![theSkipVersion isEqualToString:theNewVersion])
    {
        NSBeginInformationalAlertSheet(theTitle, NSLocalizedString(@"AcceptKey", @""), 
        	NSLocalizedString(@"CancelKey", @""), nil, self.window, self, 
            @selector(updateSheetDidEnd:returnCode:contextInfo:), 
            NULL, (void *)[aVersionInfo retain], 
            [NSString stringWithFormat:NSLocalizedString(@"MustUpdateMessageKey", 
            @""), theNewVersion]);
    }
}

//===============================================================================
- (void)windowWillClose:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aNotification, @"Contract violation");
    
    // main window closed - so terminate application
	[NSApp terminate:self];
}

#pragma mark -
//===============================================================================
- (void)setupWithoutWindow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    	if (loginController.hasAutoConnect && nil == self.session)
        {
            [loginController connect];
    	}
}

//===============================================================================
- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aNotification, @"Contract violation");
    
    // right after window appear check if autologin is needed
    if (justLaunched)
    {
    	if (loginController.hasAutoConnect && nil == self.session)
        {
            [loginController performSelector:@selector(connectModalToWindow:) 
                withObject:[self window] afterDelay:0.3];
    	}
    }
    justLaunched = NO;
}

//===============================================================================
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(anItem, @"Contract violation");
	BOOL theResult = YES;
    if ([anItem action] == @selector(addDomain:))
    {
    	theResult = (kDomainLogin != self.session.loginType) && 
        	0 < self.session.domains.count;
    }
    else if ([anItem action] == @selector(deleteDomain:))
    {
    	theResult = (kDomainLogin != self.session.loginType) && 
        	(-1 != [self.domainTable selectedRow]);
    }
    else if ([anItem action] == @selector(editDomain:))
    {
    	theResult = (-1 != [self.domainTable selectedRow]);
    }
    else if ([anItem action] == @selector(exportConfiguration:) || [anItem action] 
    	== @selector(importConfiguration:))
    {
    	theResult = nil != self.session;
    }
    return theResult;
}

#pragma mark -
//===============================================================================
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTable
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return self.session.monitoredDomains.count;
}

//===============================================================================
- (id)tableView:(NSTableView *)aTable objectValueForTableColumn:(NSTableColumn *)aColumn 
	row:(NSInteger)aRow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [self.session.monitoredDomains objectAtIndex:aRow];
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [verifyController release];
    [editingDomains release];
    [domains release];
	[loginController release];
    [addController release];
    [session release];
    [super dealloc];
}

@end
