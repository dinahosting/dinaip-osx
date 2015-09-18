/////////////////////////////////////////////////////////////////////////////////
//
//  ZonesWindowController.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "ZonesWindowController.h"
#import "UserGetZonesDomain.h"
#import "DomainGetZones.h"
#import "DomainSetZones.h"
#import "UserSetZonesDomain.h"
#import "RPCExecutor.h"
#import "DomainZone.h"
#import "LoginDinaDNS.h"
#import "WorkSession.h"
#import "RPCMethod.h"

#import "OptionTableCell.h"
#import "Common.h"

NSString *const kZoneEditDidFinishNotification = @"ZoneEditDidFinishNotification";

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface ZonesWindowController()<RPCExecutorDelegate, NSWindowDelegate>
	@property (nonatomic, retain) UserGetZonesDomain *lastMethod;
	@property (nonatomic, retain) RPCMethod *executedMethod;
	@property (nonatomic, assign) BOOL modified;

- (void)zonesDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext;
- (void)retrieveZonesDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext;
- (void)updateZonesDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext;
- (void)updateZones;
- (void)failedSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(void *)aContext;
- (NSArray *)availableZoneTypes;
- (BOOL)verifyZones;
- (void)focusHostField;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation ZonesWindowController

	@synthesize delegate, domain, session, lastMethod, executedMethod;
    @synthesize modified=isModified, shouldDetectDynamicIP;
    
//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super initWithWindowNibName:@"ZonesWindow" owner:self];
    if (nil != self)
    {
    	[self window].delegate = self;
        // cached custom "option" cells
        reusedCells = [NSMutableDictionary new];
    }
    return self;
}

//===============================================================================
- (void)awakeFromNib
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSTableColumn *theColumn = [zonesTable tableColumnWithIdentifier:@"type"];
    [[theColumn dataCell] removeAllItems];
    [[theColumn dataCell] addItemsWithTitles:[self availableZoneTypes]];

	self.shouldDetectDynamicIP = [[NSUserDefaults standardUserDefaults] 
    	boolForKey:@"shouldAutodetectIP"];
}

//===============================================================================
- (NSArray *)availableZoneTypes
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	static NSArray *sZoneTypes = nil;
    @synchronized([self class])
    {
    	if (nil == sZoneTypes)
        {
        	sZoneTypes = [[NSArray alloc] initWithObjects:@"A", @"AAAA", @"CNAME",
            	@"FRAME", /*@"MX", @"MXD1", @"MXD2", @"MXS", @"SPF", @"SRV",*/ @"TXT", 
                @"URL", @"URL_301", nil];
        }
    }
    return sZoneTypes;
}

//===============================================================================
- (void)setShouldDetectDynamicIP:(BOOL)aFlag
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	shouldDetectDynamicIP = aFlag;
    [zonesTable reloadData];
}

#pragma mark -
//===============================================================================
- (void)showWindowModalToWindow:(NSWindow *)aWindow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	owner = aWindow;
    [status setStringValue:NSLocalizedString(@"RetrieveZonesKey", @"")];


	if (nil == aWindow)
    {
    	[self.window setTitle:[[self.window title] stringByAppendingFormat:@": %@", 
        	self.domain]];
    	[self showWindow:nil];
    }
    // show GetZones progress right when go to the screen
    [NSApp beginSheet:progressPane modalForWindow:(nil != owner ? owner : [self window]) 
    	modalDelegate:self didEndSelector:@selector(retrieveZonesDidEnd:returnCode:contextInfo:) 
        contextInfo:NULL];

    [spinner startAnimation:self];
    
    // use differnet server API depending on login type
    UserGetZonesDomain *theMethod = nil;
	NSInteger theLoginType = [[NSUserDefaults standardUserDefaults] integerForKey:@"loginType"];
	if (kUserDinahostingLogin == theLoginType)
    {
        theMethod = [[UserGetZonesDomain alloc] initWithDomain:self.domain];
    }
    else
    {
        theMethod = [[DomainGetZones alloc] initWithDomain:self.domain];
    }
    theMethod.identifier = self.session.identifier;
    theMethod.password = self.session.password;
    self.lastMethod = theMethod;
    [theMethod release];

	
	if (kUserDinahostingLogin == theLoginType)
    {    
        [[RPCExecutor sharedExecutor] scheduleMethod:self.lastMethod withDelegate:self];
    }
    else
    {
        [[RPCExecutor sharedExecutor] scheduleHTTP:self.lastMethod withDelegate:self];
    }
}

//===============================================================================
- (IBAction)saveChanges:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (nil != owner)
    {
        [NSApp endSheet:[self window] returnCode:NSOKButton];
    }
    else
    {
    	// make sure all modified zones are valid before proceed update
    	if ([self verifyZones])
        {
            [self updateZones];
        }
        else
        {
            NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedZoneVerifyTitleKey", @""), 
                NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
                @selector(failedSheetDidEnd:returnCode:contextInfo:), 
                NULL, NULL, NSLocalizedString(@"FailedZoneVerifyMessageKey", @""));
        }
    }
}

//===============================================================================
- (IBAction)cancel:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (nil != owner)
    {
        [NSApp endSheet:[self window] returnCode:NSCancelButton];
    }
    else
    {
    	[self close];
    }
}

//===============================================================================
- (IBAction)cancelProgress:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[spinner stopAnimation:self];
	[NSApp endSheet:progressPane returnCode:NSCancelButton];
}

//===============================================================================
- (void)updateZones
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [status setStringValue:NSLocalizedString(@"UpdateZonesKey", @"")];
    
    // show update progress...
    [NSApp beginSheet:progressPane modalForWindow:(nil != owner ? owner : [self window])
         modalDelegate:self didEndSelector:@selector(updateZonesDidEnd:returnCode:contextInfo:) 
        contextInfo:NULL];
    [spinner startAnimation:self];
    
    // ... and delegate current session the responsibility to update zones
    [self.window makeFirstResponder:nil];
    NSMutableArray *theZones = [NSMutableArray 
    	arrayWithArray:self.lastMethod.domainZones];
    for (DomainZone *theZone in theZones)
    {
    	if (theZone.isEmpty)
        {
        	[self.lastMethod.domainZones removeObject:theZone];
        }
    }
    [self.session updateZones:[NSArray arrayWithArray:self.lastMethod.domainZones] 
    	forDomain:self.domain delegate:self];
    
    if (0 == self.lastMethod.domainZones.count)
    {
        [self.lastMethod.domainZones addObject:[[DomainZone new] autorelease]];
    }
    [zonesTable noteNumberOfRowsChanged];
    [zonesTable reloadData];
}

//===============================================================================
- (void)addZone:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [self.lastMethod.domainZones addObject:[[DomainZone new] autorelease]];
    [zonesTable noteNumberOfRowsChanged];

    // put focus in first field of newly created row
    [self performSelector:@selector(focusHostField) withObject:nil afterDelay:0];
    self.modified = YES;
}

//===============================================================================
- (void)focusHostField
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSInteger theIndex = self.lastMethod.editableZones.count - 1;
	[zonesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:theIndex] 
    	byExtendingSelection:NO];
    [zonesTable editColumn:0 row:theIndex withEvent:nil select:YES];
}

//===============================================================================
- (void)removeZone:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSInteger theIndex = [zonesTable clickedRow];
    [self.lastMethod.domainZones removeObject:[self.lastMethod.editableZones 
    	objectAtIndex:theIndex]];
    [reusedCells removeObjectForKey:[NSNumber numberWithInteger:theIndex]];
    [zonesTable noteNumberOfRowsChanged];
    if (0 == self.lastMethod.domainZones.count)
    {
    	[self addZone:nil];
    }
    self.modified = YES;
}

//===============================================================================
- (void)toggleZoneDynamicIP:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // action for manual selection of dynamic zones
    NSInteger theIndex = [zonesTable clickedRow];
    NSInteger theState = [[reusedCells objectForKey:[NSNumber 
    	numberWithInteger:theIndex]] state];
    [[self.lastMethod.editableZones objectAtIndex:theIndex] 
    	setDynamic:(NSOnState == theState)];
    self.modified = YES;
}

//===============================================================================
- (BOOL)verifyZones
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    BOOL theResult = YES;
    for (DomainZone *theZone in self.lastMethod.domainZones)
    {
    	if (!theZone.isValid)
        {
        	theResult = NO;
            break;
        }
    }
    return theResult;
}

#pragma mark -
//===============================================================================
- (void)windowWillClose:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [[NSNotificationCenter defaultCenter] postNotificationName:kZoneEditDidFinishNotification 
    	object:self];
	if ([self.delegate respondsToSelector:@selector(zoneEditControllerDidFinish:)])
    {
    	[self.delegate zoneEditControllerDidFinish:self];
    }
}

//===============================================================================
- (void)methodExecutionDidFinish:(RPCMethod *)aMethod
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[spinner stopAnimation:self];
    self.executedMethod = aMethod;
	[NSApp endSheet:progressPane returnCode:(!aMethod.isResultFault ? NSOKButton : 
    	NSCancelButton)];
}

#pragma mark -
//===============================================================================
- (void)retrieveZonesDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];
    // zones retrive did finish ...
    if (NSOKButton == aCode)
    {
    	if (nil != owner)
        {
            [NSApp beginSheet:[self window] modalForWindow:owner modalDelegate:self 
                didEndSelector:@selector(zonesDidEnd:returnCode:contextInfo:) 
                contextInfo:NULL];
        }
        // ... reconstruct table if method successful
        [reusedCells removeAllObjects];
        NSArray *theNewZones = self.lastMethod.editableZones;
        NSArray *theOldZones = [self.session zonesForDomain:domain];
        for (DomainZone *theZone in theNewZones)
        {
        	NSInteger theIndex = [theOldZones indexOfObject:theZone];
            if (NSNotFound != theIndex)
            {
        		theZone.dynamic = [[theOldZones objectAtIndex:theIndex] dynamic];
            }
        }
        [zonesTable reloadData];
    }
    else if (self.lastMethod.isResultFault)
    {
    	// ... or show alert if failed
        if (-100 == self.lastMethod.error.code)
        {
            NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedNetworkTitleKey", @""), 
                NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
                @selector(failedSheetDidEnd:returnCode:contextInfo:), 
                NULL, NULL, NSLocalizedString(@"FailedNetworkMessageKey", @""));
        }
        else
        {
            NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedGetZonesTitleKey", @""), 
                NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
                @selector(failedSheetDidEnd:returnCode:contextInfo:), 
                NULL, NULL, NSLocalizedString(@"FailedZonesMessageKey", @""));
        }
    }
}

//===============================================================================
- (void)zonesDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];
    if (NSOKButton == aCode)
    {
    	[self updateZones];
    }
}

//===============================================================================
- (void)updateZonesDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];
    self.modified = (NSOKButton != aCode);
	if (NSOKButton == aCode)
    {
    	[self.session storeZones:self.lastMethod.domainZones forDomain:self.domain];
    }
    else if (-400 == self.executedMethod.error.code)
    {
    	NSString *theText = [self.executedMethod.error.userInfo objectForKey:@"txt"];
        NSRange theRange = [theText rangeOfString:@"_" options:NSBackwardsSearch];
        NSString *theMessage = [theText substringToIndex:NSMaxRange(theRange)];
        
        NSString *theTitle = NSLocalizedString(@"FailedUpdateZonesTitleKey", @"");
        void *theContext = NULL;
        if ([theMessage isEqualToString:NSLocalizedString(theMessage, @"")])
        {
        	theMessage = NSLocalizedString(theText, @"");
        }
        else
        {
        	NSString *theRow = [theText substringFromIndex:NSMaxRange(theRange)];
        	theTitle = [NSString stringWithFormat:NSLocalizedString(@"FailedUpdateZonesInRowTitleKey", 
            	@""), [theRow integerValue] + 1];
        	if (0 < theRow.length)
            {
            	theContext = (void *)[theRow retain];
            }
        	theMessage = NSLocalizedString(theMessage, @"");
        }
        NSBeginCriticalAlertSheet(theTitle, NSLocalizedString(@"OKKey", @""), 
        	nil, nil, self.window, self, 
            @selector(failedSheetDidEnd:returnCode:contextInfo:), 
            NULL, theContext, theMessage);
    }
    else
    {
        NSBeginCriticalAlertSheet(NSLocalizedString(@"FailedUpdateZonesTitleKey", @""), 
            NSLocalizedString(@"OKKey", @""), nil, nil, self.window, self, 
            @selector(failedSheetDidEnd:returnCode:contextInfo:), 
            NULL, NULL, NSLocalizedString(@"FailedZonesMessageKey", @""));
    }
}

//===============================================================================
- (void)failedSheetDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode 
	contextInfo:(void *)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];
    if (NULL != aContext)
    {
    	NSInteger theIndex = [(NSString *)aContext integerValue];
        [zonesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:theIndex] 
        	byExtendingSelection:NO];
        [zonesTable scrollRowToVisible:theIndex];
        [(NSString *)aContext release];
    }
}

#pragma mark -
//===============================================================================
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTable
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return self.lastMethod.editableZones.count;
}

//===============================================================================
- (id)tableView:(NSTableView *)aTable objectValueForTableColumn:(NSTableColumn *)aColumn 
	row:(NSInteger)aRow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	DomainZone *theZone = [self.lastMethod.editableZones objectAtIndex:aRow];
	id theValue = [theZone valueForKey:[aColumn identifier]];
    if ([[aColumn identifier] isEqualToString:@"type"])
    {
    	// types are shown in table as indexes so remap from value
    	NSInteger theIndex = [[self availableZoneTypes] indexOfObject:theValue];
        if (NSNotFound != theIndex)
        {
            theValue = [NSNumber numberWithInteger:theIndex];
        }
    }
    return theValue;
}

//===============================================================================
- (void)tableView:(NSTableView *)aTable setObjectValue:(id)anObject 
	forTableColumn:(NSTableColumn *)aColumn row:(NSInteger)aRow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self.modified = YES;
//    [self.window setDocumentEdited:self.modified];
	DomainZone *theZone = [self.lastMethod.editableZones objectAtIndex:aRow];
    if ([[aColumn identifier] isEqualToString:@"type"])
    {
    	anObject = [[self availableZoneTypes] objectAtIndex:[anObject integerValue]];
    }
	[theZone setValue:anObject forKey:[aColumn identifier]];
}

//===============================================================================
- (BOOL)tableView:(NSTableView *)aTable shouldEditTableColumn:(NSTableColumn *)aColumn 
	row:(NSInteger)aRow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// option is custom cell with controls so prohibit edit for it
	return ![[aColumn identifier] isEqualToString:@"option"];
}

//===============================================================================
- (NSCell *)tableView:(NSTableView *)aTable dataCellForTableColumn:(NSTableColumn *)aColumn 
	row:(NSInteger)aRow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if ([[aColumn identifier] isEqualToString:@"option"])
    {
		// as option is custom for every zone hold dedicated cell for each
    	OptionTableCell *theCell = [reusedCells objectForKey:[NSNumber numberWithInteger:aRow]];
    	if (nil == theCell)
        {
        	theCell = [[OptionTableCell alloc] initTextCell:NSLocalizedString(@"DynamicIPKey", @"")];
            [reusedCells setObject:theCell forKey:[NSNumber numberWithInteger:aRow]];
            [theCell setAddAction:@selector(addZone:) target:self];
            [theCell setRemoveAction:@selector(removeZone:) target:self];
            [theCell setSwitchAction:@selector(toggleZoneDynamicIP:) target:self];
            [theCell release];
        }
		DomainZone *theZone = [self.lastMethod.editableZones objectAtIndex:aRow];
        BOOL theIPFlag = theZone.hasIPAddress;
        theCell.shouldShowSwitchButton = theIPFlag;
        if (theIPFlag)
        {
        	theCell.state = theZone.dynamic;
        }
        if (theIPFlag && self.shouldDetectDynamicIP && !theZone.dynamic)
        {
        	// in case of automatic IP check determine the value for cell to
            // be shown and update corresponding zone 
        	BOOL theState = [[[NSUserDefaults standardUserDefaults] 
            	objectForKey:@"lastIP"] isEqualToString:theZone.address];
            if (theState != theCell.state)
            {
            	// mark modified on any changes
                self.modified = YES;
            }
            theZone.dynamic = theState;
            theCell.state = theState;
        }
        else if (!theIPFlag && theZone.dynamic)
        {
        	theZone.dynamic = NO;
            self.modified = YES;
        }
        
        [theCell setEnabled:!self.shouldDetectDynamicIP];
        theCell.shouldShowAddButton = (aRow == self.lastMethod.editableZones.count - 1);
        return theCell;
    }
    else
    {
    	return [aColumn dataCell];
    }
}

//===============================================================================
- (void)tableView:(NSTableView *)aTable willDisplayCell:(id)aCell 
	forTableColumn:(NSTableColumn *)aColumn row:(NSInteger)aRow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	if ([[aColumn identifier] isEqualToString:@"option"])
    {
    	// workaround for texture button cell drawing issue
    	aColumn.width = aColumn.width + 1.0;
        aColumn.width = aColumn.width - 1.0;
    }
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    zonesTable.dataSource = nil;
    zonesTable.delegate = nil;
    [executedMethod release];
	[reusedCells release];
    [domain release];
    [session release];
    [lastMethod release];
    [super dealloc];
}

@end
