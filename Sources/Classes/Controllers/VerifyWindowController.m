/////////////////////////////////////////////////////////////////////////////////
//
//  VerifyWindowController.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "VerifyWindowController.h"
#import "WorkSession.h"
#import "Common.h"


// This is a private class interface
@interface VerifyWindowController()
- (void)verifyDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext;
@end

#pragma mark -
@implementation VerifyWindowController
    @synthesize identifier, password, loginType;
    @synthesize session, callback, delegate;

//===============================================================================
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)aKey
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSSet *theResult = [super keyPathsForValuesAffectingValueForKey:aKey];
    if ([aKey isEqualToString:@"isFormFilled"])
    {
        theResult = [NSSet setWithObjects:@"identifier", @"password", nil];
    }
    return theResult;
}
    
//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super initWithWindowNibName:@"VerifyWindow" owner:self];
    if (nil != self)
    {
    	[self window]; // required to load NIB    	[self reset];
    }
    return self;
}

#pragma mark -
//===============================================================================
- (void)showWindowModalToWindow:(NSWindow *)aWindow
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [NSApp beginSheet:[self window] modalForWindow:aWindow modalDelegate:self 
    	didEndSelector:@selector(verifyDidEnd:returnCode:contextInfo:) 
        contextInfo:NULL];
}

//===============================================================================
- (BOOL)isFormFilled
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return (0 < self.identifier.length && 0 < self.password.length);
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

//===============================================================================
- (void)verifyDidEnd:(NSWindow *)aSheet returnCode:(NSInteger)aCode contextInfo:(id)aContext
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[aSheet close];
    if (NSOKButton != aCode)
    {
    	return;
    }
    
    // result of verififcation is just simple comparison of provided parameters
    // with those from current work session
    aCode = self.session.loginType == self.loginType && [self.session.identifier 
    	isEqualToString:self.identifier] && [self.session.password 
        isEqualToString:self.password];
        
	if ([self.delegate respondsToSelector:self.callback])
    {
    	[self.delegate performSelector:self.callback withObject:[NSNumber 
        	numberWithInteger:aCode]];
    }
    // clear everything so next verification
    self.session = nil;
    self.callback = NULL;
    self.password = nil;
    self.identifier = nil;
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
    [identifier release];
    [password release];
    [session release];
    [super dealloc];
}

@end
