/////////////////////////////////////////////////////////////////////////////////
//
//  DomainSetZones.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "DomainSetZones.h"
#import "DomainZone.h"
#import "Common.h"


/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface DomainSetZones()
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation DomainSetZones

//===============================================================================
- (NSString *)name
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return @"dom_setZones";
}

//===============================================================================
- (NSDictionary *)parameters 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSMutableDictionary *theMainParams = [NSMutableDictionary 
    	dictionaryWithDictionary:[super parameters]];
    NSArray *theZones = self.domainZones;
    
    // break all zones to parameters to allow common engine to prcess them in
    // one way with other parameters
    for (NSUInteger i = 0; i < theZones.count; i++)
    {
    	DomainZone *theZone = [theZones objectAtIndex:i];
	    [theMainParams setObject:theZone.host forKey:[NSString 
        	stringWithFormat:@"Host%d", i]];
	    [theMainParams setObject:theZone.type forKey:[NSString 
        	stringWithFormat:@"Type%d", i]];
	    [theMainParams setObject:theZone.address forKey:[NSString 
        	stringWithFormat:@"Address%d", i]];
    }
    [theMainParams setObject:[NSString stringWithFormat:@"%d", theZones.count] 
    	forKey:@"NumZones"];
    return theMainParams;
}

//===============================================================================
- (NSArray *)orderedParameters
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSMutableArray *theMainParams = [NSMutableArray arrayWithArray:[super 
    	orderedParameters]];
    NSArray *theZones = self.domainZones;

    // seems order of parameters does not matter, but such works definitely
    [theMainParams addObject:@"NumZones"];
    for (NSUInteger i = 0; i < theZones.count; i++)
    {
	    [theMainParams addObject:[NSString stringWithFormat:@"Host%d", i]];
	    [theMainParams addObject:[NSString stringWithFormat:@"Type%d", i]];
	    [theMainParams addObject:[NSString stringWithFormat:@"Address%d", i]];
    }
    return theMainParams;
}

@end
