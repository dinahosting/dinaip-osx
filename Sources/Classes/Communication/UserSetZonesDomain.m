/////////////////////////////////////////////////////////////////////////////////
//
//  UserSetZonesDomain.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "UserSetZonesDomain.h"
#import "DomainZone.h"
#import "Common.h"


/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface UserSetZonesDomain()
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation UserSetZonesDomain

	@dynamic domainZones;
//===============================================================================
- (NSString *)name
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return @"setZonesDomain";
}

//===============================================================================
- (NSDictionary *)parameters 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSArray *theZones = self.domainZones;
	NSString *theEncodedZones = [NSString stringWithFormat:@"NumZones=%d", theZones.count];
    for (NSUInteger i = 0; i < theZones.count; i++)
    {
    	DomainZone *theZone = [theZones objectAtIndex:i];
    	theEncodedZones = [theEncodedZones stringByAppendingFormat:@"&Host%d=%@&Type%d=%@&Address%d=%@",
        	i, theZone.host, i, theZone.type, i, theZone.address];
    }
	return [NSDictionary dictionaryWithObjectsAndKeys:
		self.identifier, @"identifier", self.password, @"password",
        self.domain, @"domain", theEncodedZones, @"zones", nil];
}

//===============================================================================
- (NSArray *)orderedParameters
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [NSArray arrayWithObjects:@"identifier", @"password", @"domain", @"zones", nil];
}


@end
