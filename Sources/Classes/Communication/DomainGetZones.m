/////////////////////////////////////////////////////////////////////////////////
//
//  DomainGetZones.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "DomainGetZones.h"
#import "Common.h"



/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface DomainGetZones()
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation DomainGetZones

//===============================================================================
- (NSString *)name
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return @"dom_getZones";
}

//===============================================================================
- (NSDictionary *)parameters 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSArray *theSubdomains = [self.identifier componentsSeparatedByString:@"."];
    NSString *theSecondLevel = nil;
    if (0 < theSubdomains.count)
    {
        theSecondLevel = [theSubdomains objectAtIndex:0];
    }
    NSString *theTopLevel = nil;
    if (1 < theSubdomains.count)
    {
        theTopLevel = [[theSubdomains subarrayWithRange:NSMakeRange(1, 
            theSubdomains.count - 1)] componentsJoinedByString:@"."];
    }
	return [NSDictionary dictionaryWithObjectsAndKeys:[self name], @"command", 
		self.identifier, @"uid", self.password, @"pw", theSecondLevel, 
        @"sld", theTopLevel, @"tld", nil];
}

//===============================================================================
- (NSArray *)orderedParameters
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [NSArray arrayWithObjects:@"command", @"uid", @"pw", @"sld", @"tld", nil];
}

@end
