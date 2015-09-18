/////////////////////////////////////////////////////////////////////////////////
//
//  RPCMethod.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "RPCMethod.h"
#import "Common.h"

NSString *const kMethodResultStatus = @"RPCMethodResultStatus";
NSString *const kMethodResultValue = @"RPCMethodResultValue";

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface RPCMethod()
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation RPCMethod
	@dynamic name, parameters, orderedParameters;
    @synthesize results, isResultFault, error;

//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[results release];
    [error release];
    [super dealloc];
}

//===============================================================================
- (void)setResults:(id)anObject
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// real result might be of different type, so convert it in one internal
    // representation
	if ([anObject isKindOfClass:[NSDictionary class]])
    {
    	results = [anObject retain];
    }
    else if ([anObject isKindOfClass:[NSNumber class]])
    {
    	results = [[NSDictionary alloc] initWithObjectsAndKeys:anObject,
        	kMethodResultStatus, nil];
    }
    else
    {
    	results = [[NSDictionary alloc] initWithObjectsAndKeys:anObject,
        	kMethodResultValue, nil];
    }
}

@end
