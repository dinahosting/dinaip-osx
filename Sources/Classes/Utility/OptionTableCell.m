/////////////////////////////////////////////////////////////////////////////////
//
//  OptionTableCell.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "OptionTableCell.h"
#import "Common.h"



/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface OptionTableCell()
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation OptionTableCell
	@synthesize shouldShowAddButton, shouldShowSwitchButton;
    
//===============================================================================
- (id)initTextCell:(NSString *)aString
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aString, @"Contract violation");
	self = [super initTextCell:@""];
    if (nil != self)
    {
    	// create wrapped helper cells ...
        
        // for checkbox
    	switchButton = [[NSButtonCell alloc] initTextCell:aString];
        [switchButton setButtonType:NSSwitchButton];
        
        // for remove button
        removeButton = [[NSButtonCell alloc] initTextCell:@"-"];
        [removeButton setButtonType:NSMomentaryPushInButton];
        [removeButton setBezelStyle:NSTexturedSquareBezelStyle];
        
        // for add button
        addButton = [[NSButtonCell alloc] initTextCell:@"+"];
        [addButton setButtonType:NSMomentaryPushInButton];
        [addButton setBezelStyle:NSTexturedSquareBezelStyle];
    }
    return self;
}

//===============================================================================
- (id)copyWithZone:(NSZone *)aZone
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // every cell MUST be copyable
    
	OptionTableCell *theCell = [super copyWithZone:aZone];
    theCell->switchButton = [switchButton retain];
    theCell->removeButton = [removeButton retain];
    theCell->addButton = [addButton retain];
    theCell.shouldShowAddButton = self.shouldShowAddButton;
    return theCell;
}

#pragma mark -
//===============================================================================
- (NSInteger)state
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // just forward state to switch button
	return [switchButton state];
}

//===============================================================================
- (void)setState:(NSInteger)aValue
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // just forward state to switch button
	[switchButton setState:aValue];
}

//===============================================================================
- (void)setControlView:(NSView *)aView
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[super setControlView:aView];
    [switchButton setControlView:aView];
    [removeButton setControlView:aView];
    [removeButton setControlView:aView];
}

//===============================================================================
- (BOOL)isEnabled
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // just forward enable to switch button
	return [switchButton isEnabled];
}

//===============================================================================
- (void)setEnabled:(BOOL)aFlag
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // just forward enable to switch button
    [switchButton setEnabled:aFlag];
}

//===============================================================================
- (NSSize)cellSizeForBounds:(NSRect)aRect
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// size includes sizes of all internal cells
	NSSize theSize = [switchButton cellSizeForBounds:aRect];
	return NSMakeSize(theSize.width + [removeButton cellSizeForBounds:aRect].width +
    	[addButton cellSizeForBounds:aRect].width, theSize.height);
}

//===============================================================================
- (void)drawWithFrame:(NSRect)aFrame inView:(NSView *)aView
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	CGFloat theButtonWidth = aFrame.size.height + 6.0;
    
    NSRect theLeft, theFrame;
    NSDivideRect(aFrame, &theFrame, &theLeft, theButtonWidth, CGRectMaxXEdge);
    
	// add button might be shown not always
    if (self.shouldShowAddButton)
    {
    	theFrame = NSInsetRect(theFrame, 1., 0);
    	[addButton drawWithFrame:theFrame inView:aView];
    }

    NSDivideRect(theLeft, &theFrame, &theLeft, theButtonWidth, CGRectMaxXEdge);
    theFrame = NSInsetRect(theFrame, 1., 0);
    [removeButton drawWithFrame:theFrame inView:aView];
    
    // switch button might be shown not always
    if (self.shouldShowSwitchButton)
    {
        theFrame = NSInsetRect(theLeft, 1., 0);
        [switchButton drawWithFrame:theFrame inView:aView];
    }
}

//===============================================================================
- (NSUInteger)hitTestForEvent:(NSEvent *)anEvent inRect:(NSRect)aFrame ofView:(NSView *)aView
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSPoint thePoint = [aView convertPoint:[anEvent locationInWindow] fromView:nil];
    
	CGFloat theButtonWidth = aFrame.size.height + 6.0;
    
    NSRect theLeft, theAddFrame, theRemoveFrame;
    NSDivideRect(aFrame, &theAddFrame, &theLeft, theButtonWidth, CGRectMaxXEdge);
    NSDivideRect(theLeft, &theRemoveFrame, &theLeft, theButtonWidth, CGRectMaxXEdge);

    // just forward hit test to internal cell depending on location
    NSUInteger theResult = 0;
    if (NSPointInRect(thePoint, theAddFrame) && self.shouldShowAddButton)
    {
    	theResult = [addButton hitTestForEvent:anEvent inRect:theAddFrame ofView:aView];
    }
    else
    if (NSPointInRect(thePoint, theRemoveFrame))
    {
    	theResult = [removeButton hitTestForEvent:anEvent inRect:theRemoveFrame ofView:aView];
    }
    else
    if (NSPointInRect(thePoint, theLeft) && self.shouldShowSwitchButton)
    {
    	theResult = [switchButton hitTestForEvent:anEvent inRect:theLeft ofView:aView];
    }
    
	return theResult;
}

//===============================================================================
- (BOOL)trackMouse:(NSEvent *)anEvent inRect:(NSRect)aFrame ofView:(NSView *)aView 
	untilMouseUp:(BOOL)aFlag
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSPoint thePoint = [aView convertPoint:[anEvent locationInWindow] fromView:nil];
    
	CGFloat theButtonWidth = aFrame.size.height + 6.0;
    
    NSRect theLeft, theAddFrame, theRemoveFrame;
    NSDivideRect(aFrame, &theAddFrame, &theLeft, theButtonWidth, CGRectMaxXEdge);
    NSDivideRect(theLeft, &theRemoveFrame, &theLeft, theButtonWidth, CGRectMaxXEdge);

    // just forward tracking to internal cells depending on location
    NSUInteger theResult = 0;
    if (NSPointInRect(thePoint, theAddFrame) && self.shouldShowAddButton)
    {
    	[addButton setHighlighted:YES];
    	theResult = [addButton trackMouse:anEvent inRect:theAddFrame ofView:aView 
        	untilMouseUp:aFlag];
    	[addButton setHighlighted:NO];
    }
    else
    if (NSPointInRect(thePoint, theRemoveFrame))
    {
    	[removeButton setHighlighted:YES];
    	theResult = [removeButton trackMouse:anEvent inRect:theRemoveFrame ofView:aView 
        	untilMouseUp:aFlag];
    	[removeButton setHighlighted:NO];
    }
    else
    if (NSPointInRect(thePoint, theLeft) && self.shouldShowSwitchButton)
    {
    	[switchButton setHighlighted:YES];
    	theResult = [switchButton trackMouse:anEvent inRect:theLeft ofView:aView 
        	untilMouseUp:aFlag];
    	[switchButton setHighlighted:NO];
    }
    
	return theResult;
}

#pragma mark -
//===============================================================================
- (void)setAddAction:(SEL)anAction target:(id)aTarget
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// assign action for add button
	[addButton setAction:anAction];
    [addButton setTarget:aTarget];
}

//===============================================================================
- (void)setRemoveAction:(SEL)anAction target:(id)aTarget
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// assign action for remove button
	[removeButton setAction:anAction];
    [removeButton setTarget:aTarget];
}

//===============================================================================
- (void)setSwitchAction:(SEL)anAction target:(id)aTarget
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// assign action for switch button
	[switchButton setAction:anAction];
    [switchButton setTarget:aTarget];
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[switchButton release];
    [removeButton release];
    [addButton release];
    [super dealloc];
}

@end
