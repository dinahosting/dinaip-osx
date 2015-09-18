/////////////////////////////////////////////////////////////////////////////////
//
//  AddDomainWindowController.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "AddDomainWindowController.h"
#import "Common.h"


/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface AddDomainWindowController()<NSWindowDelegate>
- (void)addDomainDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation AddDomainWindowController

	@synthesize delegate, isManual, selectedDomain, availableDomains;
    
//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super initWithWindowNibName:@"AddDomainWindow" owner:self];
    if (nil != self)
    {
    	self.window.delegate = self;
    }
    return self;
}

//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[selectedDomain release];
    [availableDomains release];
    [super dealloc];
}

#pragma mark -
//===============================================================================
- (void)showWindowModalToWindow:(NSWindow *)aWindow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self.selectedDomain = nil;
    // show window as a sheet to parent window
    [NSApp beginSheet:[self window] modalForWindow:aWindow modalDelegate:self 
    	didEndSelector:@selector(addDomainDidEnd:returnCode:contextInfo:) 
        contextInfo:NULL];
}

//===============================================================================
- (IBAction)changeMode:(id)aSender;
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSMatrix *theSelector = (id)aSender;
    // second state of radio button is manual entrance
    self.isManual = (1 == [theSelector selectedRow]);
}

//===============================================================================
- (IBAction)accept:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

//===============================================================================
- (IBAction)cancel:(id)aSender
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
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
- (void)addDomainDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];
    if (NSOKButton == aCode)
    {
    	// call delegate that is finished
    	if ([self.delegate respondsToSelector:@selector(addDomainControllerDidSelectDomain:)])
        {
        	[self.delegate addDomainControllerDidSelectDomain:self.selectedDomain];
        }
    }
}

@end
