/////////////////////////////////////////////////////////////////////////////////
//
//  UserGetZonesDomain.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "UserGetZonesDomain.h"
#import "DomainZone.h"
#import "Common.h"


/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface UserGetZonesDomain()
@property (nonatomic, retain) NSMutableArray *domainZones;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation UserGetZonesDomain
	@synthesize identifier, password, domain, domainZones;
    @dynamic editableZones;
    
//===============================================================================
- (id)initWithDomain:(NSString *)aDomain
{
	NSAssert(aDomain, @"Contract violation");
	if (nil == aDomain)
    {
    	[self release];
    	return nil;
    }
	self = [super init];
    if (nil != self)
    {
    	domain = [aDomain retain];
    }
    return self;
}

#pragma mark -
//===============================================================================
- (NSString *)name
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return @"getZonesDomain";
}

//===============================================================================
- (NSDictionary *)parameters 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [NSDictionary dictionaryWithObjectsAndKeys:
		self.identifier, @"identifier", self.password, @"password",
        self.domain, @"domain", nil];
}

//===============================================================================
- (NSArray *)orderedParameters
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [NSArray arrayWithObjects:@"identifier", @"password", @"domain", nil];
}

//===============================================================================
- (void)setResults:(NSDictionary *)aResults
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aResults, @"Conract violation");
	[super setResults:aResults];
    
    NSError *theError = nil;
    NSXMLDocument *theDocument = nil;
    NSString *theResponse = [self.results objectForKey:kMethodResultValue];
	// expected result is string
    if (nil != theResponse)
    {
    	// so parse XML from it if present
        theDocument = [[NSXMLDocument alloc] initWithXMLString:theResponse 
            options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) error:&theError];
        if (nil == theDocument)
        {
        	// in case of melformed XML try to parse anything
            theDocument = [[NSXMLDocument alloc] initWithXMLString:(id)aResults 
                options:NSXMLDocumentTidyXML error:&theError];
        }
    }
    if (nil != theDocument)
    {
        NSArray *theErrorCount = [[theDocument rootElement] elementsForName:@"ErrCount"];
        if (0 < [[[theErrorCount lastObject] stringValue] intValue])
        {
        	NSString *theError = [[[[[[theDocument rootElement] elementsForName:@"errors"] 
            	lastObject] elementsForName:@"Err1"] lastObject] stringValue];
            self.error = [NSError errorWithDomain:@"API" code:-400 userInfo:[NSDictionary 
            	dictionaryWithObject:theError forKey:@"txt"]];
            self.isResultFault = YES;
        }
    	// if XML parsed then construct model here in work thread to unload
        // UI thread from unneeded activity
        NSArray *theXMLZones = [[theDocument rootElement] elementsForName:@"zone"];
    	DevLog(@" D: Parsed zones to XML document: %d zones", theXMLZones.count);
        NSMutableArray *theDomainZones = [NSMutableArray arrayWithCapacity:theXMLZones.count];
        for (NSXMLElement *theXMLZone in theXMLZones)
        {
        	DomainZone *theZone = [DomainZone zoneWithXMLElement:theXMLZone];
            if (nil != theZone)
            {
            	[theDomainZones addObject:theZone];
            }
        }
        if (0 < theDomainZones.count)
        {
        	[theDomainZones sortUsingSelector:@selector(compare:)];
            self.domainZones = theDomainZones;
        }
        [theDocument release];
    }
    else
    {
    	DevLog(@"E: Could not parse get zones result: %@", [theError description]);
    }
}

//===============================================================================
- (NSArray *)editableZones
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// query only those zones which are allowed to be shown in UI
	NSPredicate *theQuery = [NSPredicate predicateWithFormat:@"hidden == NO"];
    return [self.domainZones filteredArrayUsingPredicate:theQuery];
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[domain release];
    [domainZones release];
    [identifier release];
    [password release];
	[super dealloc];
}

@end
