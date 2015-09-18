/////////////////////////////////////////////////////////////////////////////////
//
//  LoginWindowController.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "LoginWindowController.h"
#import "LoginDinaDNS.h"
#import "RPCExecutor.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface LoginWindowController()<RPCExecutorDelegate, NSWindowDelegate>
	@property (nonatomic, retain) NSArray *storedIdentifiers;
	@property (nonatomic, retain) NSMutableDictionary *storedInfo;
    @property (nonatomic, retain) LoginDinaDNS *lastMethod;
    
- (void)loginDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext;
- (void)progressDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext;
- (void)failedSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(void *)aContext;
- (void)reset;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation LoginWindowController
	@synthesize delegate, lastMethod, progressPane, spinner;
    
    @synthesize shouldStoreUsername, shouldStorePassword, shouldAutoconnect, shouldCheckForUpdates;
    @synthesize identifier, password, loginType, storedIdentifiers, storedInfo;
    @dynamic hasAutoConnect;

//===============================================================================
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)aKey
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSSet *theResult = [super keyPathsForValuesAffectingValueForKey:aKey];
    if ([aKey isEqualToString:@"isFormFilled"])
    {
        theResult = [NSSet setWithObjects:@"identifier", @"password", nil];
    }
    else if ([aKey isEqualToString:@"password"])
    {
        theResult = [NSSet setWithObjects:@"identifier", nil];
    }
    return theResult;
}
    
//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super initWithWindowNibName:@"LoginWindow" owner:self];
    if (nil != self)
    {
    	[self window].delegate = self; // required to load NIB
    	[self reset];
        if (self.hasAutoConnect)
        {
        	self.identifier = [self.storedIdentifiers objectAtIndex:0];
        }
    }
    return self;
}

#pragma mark -
//===============================================================================
- (NSArray *)domains
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    return [self.lastMethod.results objectForKey:@"domains"];
}

//===============================================================================
- (NSDictionary *)version
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    return [self.lastMethod.results objectForKey:@"version"];
}

//===============================================================================
- (BOOL)hasAutoConnect
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    BOOL theResult = NO;
    if (0 < self.storedIdentifiers.count)
    {
    	NSString *theID = [self.storedIdentifiers objectAtIndex:0];
        NSDictionary *theInfo = [self.storedInfo objectForKey:theID];
        theResult = [[theInfo objectForKey:@"autoconnect"] boolValue];
    }
    return theResult;
}

//===============================================================================
- (void)setShouldStoreUsername:(BOOL)aFlag
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	shouldStoreUsername = aFlag;
    if (!shouldStoreUsername)
    {
    	self.shouldAutoconnect = NO;
        self.shouldStorePassword = NO;
    }
}

//===============================================================================
- (void)setShouldStorePassword:(BOOL)aFlag
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	shouldStorePassword = aFlag;
    if (!shouldStorePassword)
    {
    	self.shouldAutoconnect = NO;
    }
}

//===============================================================================
- (void)setIdentifier:(NSString *)anID
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (identifier != anID)
    {
    	[identifier autorelease];
        identifier = [anID retain];
        
        NSDictionary *theInfo = [self.storedInfo objectForKey:self.identifier];
	    self.password = [theInfo objectForKey:@"password"];
        self.shouldStoreUsername = [[theInfo objectForKey:@"storeIdentifier"] boolValue];
        self.shouldStorePassword = [[theInfo objectForKey:@"storePassword"] boolValue];;
        self.shouldAutoconnect = [[theInfo objectForKey:@"autoconnect"] boolValue];;
        self.shouldCheckForUpdates = [[theInfo objectForKey:@"checkUpdate"] boolValue];;
    }
}

//===============================================================================
- (BOOL)isFormFilled
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return (0 < self.identifier.length && 0 < self.password.length);
}

#pragma mark -
//===============================================================================
- (void)showWindowModalToWindow:(NSWindow *)aWindow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (nil == aWindow)
    {
    	[self showWindow:nil];
    }
    else
    {
        owner = aWindow;
        [NSApp beginSheet:[self window] modalForWindow:owner modalDelegate:self 
            didEndSelector:@selector(loginDidEnd:returnCode:contextInfo:) 
            contextInfo:NULL];
    }
}

//===============================================================================
- (void)connectModalToWindow:(NSWindow *)aWindow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [NSApp beginSheet:self.progressPane modalForWindow:(nil != aWindow ? aWindow : 
    	self.window) modalDelegate:self 
    	didEndSelector:@selector(progressDidEnd:returnCode:contextInfo:) 
        contextInfo:NULL];
    [self.spinner startAnimation:self];
	[self connect];
}

//===============================================================================
- (void)connect
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // Create login RPC method ...
	LoginDinaDNS *theMethod = (kUserDinahostingLogin == self.loginType ?
    	[LoginDinaDNS userLogin] : [LoginDinaDNS domainLogin]);
    theMethod.identifier = self.identifier;
    theMethod.password = self.password;
    self.lastMethod = theMethod;
    
    // ... and schedule it for execution asynchronously
    [[RPCExecutor sharedExecutor] scheduleMethod:self.lastMethod withDelegate:self];
}

//===============================================================================
- (IBAction)accept:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if ([self.window isSheet])
    {
        [NSApp endSheet:[self window] returnCode:NSOKButton];
    }
    else
    {
    	// on click OK start connecting to server ...
        [self connectModalToWindow:nil];
    }
}

//===============================================================================
- (IBAction)cancel:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if ([self.window isSheet])
    {
		[NSApp endSheet:[self window] returnCode:NSCancelButton];
    }
    else
    {
    	[NSApp terminate:nil];
    }
}

//===============================================================================
- (IBAction)cancelConnect:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[NSApp endSheet:self.progressPane returnCode:NSCancelButton];
}

//===============================================================================
- (IBAction)changeIdentifier:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
}

#pragma mark -
//===============================================================================
- (void)loginDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];
    if (NSOKButton == aCode)
    {
    	// on click OK start connecting to server ...
        [self connectModalToWindow:owner];
    }
    else
    {
    	// ... otherwise just reset settings
	    [self reset];
    }
}

//===============================================================================
- (void)progressDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [self.spinner stopAnimation:self];
	[aSheet close];

	// login progress did finish
    if (NSCancelButton == aCode)
    {
    	// ... cancel was pressed, so interrupt
	    [[RPCExecutor sharedExecutor] cancelMethod:self.lastMethod];
        return;
    }
    
    if (self.lastMethod.isResultFault)
    {
    	//... operation failed, so just report
        if (-100 == self.lastMethod.error.code)
        {
            NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedNetworkTitleKey", @""), 
                NSLocalizedString(@"OKKey", @""), nil, nil, (nil != owner ? owner : self.window), self, 
                @selector(failedSheetDidEnd:returnCode:contextInfo:), 
                NULL, NULL, NSLocalizedString(@"FailedNetworkMessageKey", @""));
        }
        else
        {
            NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedLoginTitleKey", @""), 
                NSLocalizedString(@"OKKey", @""), nil, nil, (nil != owner ? owner : self.window), self, 
                @selector(failedSheetDidEnd:returnCode:contextInfo:), 
                NULL, NULL, NSLocalizedString(@"FailedLoginMessageKey", @""));
        }
        return;
    }
    
    // log in finished successfully, so store all parameters
    NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
    [theDefaults setInteger:self.loginType forKey:@"loginType"];
    
    NSMutableDictionary *theInfo = nil;
    if (self.shouldStoreUsername)
    {
        NSMutableArray *theIdentifiers = [NSMutableArray arrayWithArray:self.storedIdentifiers];
        [theIdentifiers removeObject:self.identifier];
        [theIdentifiers insertObject:self.identifier atIndex:0];
        self.storedIdentifiers = theIdentifiers;
        [theDefaults setObject:[NSArchiver archivedDataWithRootObject:theIdentifiers] 
            forKey:@"ids"];
            
    	theInfo = [NSMutableDictionary dictionary];
        if (self.shouldStorePassword)
        {
            [theInfo setObject:self.password forKey:@"password"];
        }
        [theInfo setObject:[NSNumber numberWithBool:self.shouldStoreUsername] 
        			forKey:@"storeIdentifier"];
        [theInfo setObject:[NSNumber numberWithBool:self.shouldStorePassword] 
        			forKey:@"storePassword"];
        [theInfo setObject:[NSNumber numberWithBool:self.shouldAutoconnect] 
        			forKey:@"autoconnect"];
        [theInfo setObject:[NSNumber numberWithBool:self.shouldCheckForUpdates] 
        			forKey:@"checkUpdate"];
    }
    if (nil != theInfo)
    {
    	[self.storedInfo setObject:theInfo forKey:self.identifier];
    }
    [theDefaults setObject:[NSArchiver archivedDataWithRootObject:self.storedInfo] 
        forKey:@"dps"];
        
    [theDefaults synchronize];
    [self.delegate loginControllerDidConnect:self];
}

//===============================================================================
- (void)failedSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(void *)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // on any fail or cancel just close sheet
	[aSheet close];
    if (nil != owner)
    {
        [NSApp beginSheet:[self window] modalForWindow:owner modalDelegate:self 
            didEndSelector:@selector(loginDidEnd:returnCode:contextInfo:) 
            contextInfo:NULL];
    }
}

#pragma mark -
//===============================================================================
- (void)reset
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    
    // reset all initial parameters from defaults
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];

    self.loginType = [theDefaults integerForKey:@"loginType"];
    
    NSData *theData = [theDefaults objectForKey:@"ids"];
    if (nil != theData)
    {
        self.storedIdentifiers = [NSUnarchiver unarchiveObjectWithData:theData];
    }
    theData = [theDefaults objectForKey:@"dps"];
    if (nil != theData)
    {
        self.storedInfo = [NSMutableDictionary dictionaryWithDictionary:[NSUnarchiver 
            unarchiveObjectWithData:theData]];
    }
    else 
    {
        self.storedInfo = [NSMutableDictionary dictionary];
    }

//    if (0 < self.storedIdentifiers.count)
//    {
//        self.identifier = [self.storedIdentifiers objectAtIndex:0];
//	    self.password = [self.storedInfo objectForKey:self.identifier];
//    }
//
//	self.shouldStoreUsername = [theDefaults boolForKey:@"shouldStoreUsername"];
//    self.shouldStorePassword = [theDefaults boolForKey:@"shouldStorePassword"];
//    self.shouldAutoconnect = [theDefaults boolForKey:@"shouldAutoconnect"];
//    self.shouldCheckForUpdates = [theDefaults boolForKey:@"shouldCheckForUpdates"];
}

//===============================================================================
- (void)methodExecutionDidFinish:(RPCMethod *)aMethod
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aMethod, @"Contract violation");
    // RPC method did finish so close progress window
    if ([self.progressPane isSheet])
    {
        [NSApp endSheet:self.progressPane returnCode:NSOKButton];
    }
    else
    {
    	[self progressDidEnd:nil returnCode:NSOKButton contextInfo:NULL];
    }
}

#pragma mark -
//===============================================================================
- (void)windowWillClose:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[self.window makeFirstResponder:nil];
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[lastMethod release];
	//[progressPane release]; // top object in NIB so must be released
	[identifier release];
    [password release];
    [storedIdentifiers release];
    [storedInfo release];
    [super dealloc];
}

@end
