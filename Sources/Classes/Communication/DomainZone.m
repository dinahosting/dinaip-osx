/////////////////////////////////////////////////////////////////////////////////
//
//  DomainZone.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "DomainZone.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface DomainZone()
+ (NSString *)zoneTypeWithXML:(NSString *)aXMLType;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation DomainZone
	@synthesize host, type, address, dynamic;
    @dynamic hidden, isValid;

//===============================================================================
+ (NSString *)zoneTypeWithXML:(NSString *)aXMLType
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSAssert(aXMLType, @"Contract violation");
	if (0 == aXMLType.length)
    {
    	return nil;
    }

    // perform remapping from income DNS type to outcome one
	static NSDictionary *sZoneMap = nil;
    @synchronized(self)
    {
    	if (nil == sZoneMap)
        {
        	sZoneMap = [[NSDictionary alloc] initWithObjectsAndKeys:
            	@"CNAME", @"CNAM", @"FRAME", @"FRAM", @"URL", @"REDI", @"URL_301", 
                @"R301", nil];
        }
    }
    NSString *theKey = [aXMLType uppercaseString];
    NSString *theResult = [sZoneMap objectForKey:theKey];
    if (nil == theResult)
    {
    	theResult = theKey;
    }
    return theResult;
}

//===============================================================================
+ (id)zoneWithXMLElement:(NSXMLElement *)anElement
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[[self alloc] initWithXMLElement:anElement] autorelease];
}

//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    self = [self initWithXMLElement:nil];
    if (nil != self)
    {
    	self.type = @"A";
    }
    return self;
}

//===============================================================================
- (id)initWithXMLElement:(NSXMLElement *)anElement
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super init];
    if (nil != self)
    {
    	element = [anElement retain];
        [self reset];
    }
    return self;
}

//===============================================================================
- (id)initWithDictionary:(NSDictionary *)aDictionary
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super init];
    
    // this method is used to constact domain restored from file or defaults
    if (nil != self)
    {
        host = [[aDictionary objectForKey:@"host"] retain];
        address = [[aDictionary objectForKey:@"address"] retain];
        type = [[aDictionary objectForKey:@"type"] retain];
        dynamic = [[aDictionary objectForKey:@"dynamic"] boolValue];
    }
    return self;
}

//===============================================================================
- (void)reset
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (nil != element)
    {
    	// drop current and restore from those received from a server
        self.host = [[[element elementsForName:@"host"] lastObject] stringValue];
        self.address = [[[element elementsForName:@"address"] lastObject] stringValue];
        self.type = [DomainZone zoneTypeWithXML:[[[element elementsForName:@"type"] 
            lastObject] stringValue]];
    }
}

//===============================================================================
- (id)valueForUndefinedKey:(NSString *)aKey
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // this only needed for UI table to process custom cell with options in a
    // usual table values way
	if ([aKey isEqualToString:@"option"])
    {
    	return nil;
    }
    return [super valueForUndefinedKey:aKey];
}

//===============================================================================
- (BOOL)hidden
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	static NSArray *sNonEditableZones = nil;
    
    // indicates non-editable domains, but they should left to be sent back to
    // a server, so just hide them from UI
    @synchronized([self class])
    {
    	if (nil == sNonEditableZones)
        {
        	sNonEditableZones = [[NSArray alloc] initWithObjects:@"MX", @"MXS", 
            	@"MXD1", @"MXD2", @"SPF", @"SRV", nil];
        }
    }
    return (nil != self.type && [sNonEditableZones containsObject:self.type]);
}

//===============================================================================
- (BOOL)isValid
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (self.isEmpty)
    {
    	return YES;
    }
    // define valid zone only if all fields are filled
    return (0 < self.host.length && 0 < self.type.length && 0 < self.address.length);
}

//===============================================================================
- (BOOL)isEmpty
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    return (nil == element && 0 == self.host.length && [self.type isEqualToString:@"A"] && 
    	0 == self.address.length);
}

//===============================================================================
- (BOOL)hasIPAddress
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // try to determine that zone has IP just by simple euristic
	return [self.address rangeOfCharacterFromSet:[[NSCharacterSet 
    	characterSetWithCharactersInString:@"0123456789."] invertedSet]].length == 0 
        && 4 == [self.address componentsSeparatedByString:@"."].count;
}

//===============================================================================
- (NSDictionary *)dictionaryRepresentation
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // needed to be stored in file and defaults
    return [NSDictionary dictionaryWithObjectsAndKeys:self.host, @"host", self.type, 
    	@"type", self.address, @"address", [NSNumber numberWithBool:self.dynamic], 
        @"dynamic", nil];
}

#pragma mark -
//===============================================================================
- (NSComparisonResult)compare:(DomainZone *)aDomain;
{
	return [self.host compare:aDomain.host];
}

//===============================================================================
- (NSUInteger)hash
{
	return [self.host hash];
}

//===============================================================================
- (BOOL)isEqual:(id)anObject
{
	BOOL theResult = YES;
    if ([anObject isKindOfClass:[self class]])
    {
    	theResult = ([self.host isEqualToString:[anObject host]] && [self.type
        	isEqualToString:[anObject type]]);
    }
    return theResult;
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[element release];
    [host release];
    [type release];
    [address release];
    [super dealloc];
}

@end
