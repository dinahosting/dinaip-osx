/////////////////////////////////////////////////////////////////////////////////
//
//  WorkSession.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "WorkSession.h"
#import "LoginDinaDNS.h"
#import "PreferencesWindowController.h"

#import "RPCExecutor.h"
#import "UserSetZonesDomain.h"
#import "DomainSetZones.h"
#import "DomainZone.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface WorkSession()<RPCExecutorDelegate>
	@property (nonatomic, retain) NSDictionary *zones;
    @property (nonatomic, retain) NSString *sessionIP;
- (void)onIPDidChange:(NSNotification *)aNotification;
- (void)doTheChangeGetZones:(UserGetZonesDomain *)savedData;
- (void)cleanup;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation WorkSession

	@synthesize domains, monitoredDomains, identifier, password, loginType, zones;
    @synthesize sessionIP;

//===============================================================================
+ (id)sessionWithType:(NSInteger)aLoginType identifier:(NSString *)anID 
	password:(NSString *)aPassword domains:(NSArray *)aDomains
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[[self alloc] initWithType:aLoginType identifier:anID password:aPassword 
    	domains:aDomains] autorelease];
}

//===============================================================================
- (id)initWithType:(NSInteger)aLoginType identifier:(NSString *)anID 
	password:(NSString *)aPassword domains:(NSArray *)aDomains
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(anID && aPassword, @"Contract violation");
	self = [super init];
    if (nil != self)
    {
        loginType = aLoginType;
        identifier = [anID retain];
        password = [aPassword retain];

		// for now we interesting only in domain names for drop everything else
        NSMutableArray *theDomains = [[NSMutableArray alloc] initWithCapacity:aDomains.count];
        for (NSDictionary *theRecord in aDomains)
        {
            [theDomains addObject:[theRecord objectForKey:@"dominio"]];
        }
        domains = theDomains;
        if (kDomainLogin == loginType)
        {
        	monitoredDomains = [theDomains retain];
        }
        else
        {
        	monitoredDomains = [NSMutableArray new];
        }
        zones = [NSMutableDictionary new];
        pendingMethods = [NSMutableSet new];

        [self restoreSession];
    }
    return self;
}

#pragma mark -
//===============================================================================
- (void)storeSession
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // store all data of current session into defaults
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *theSessions = [NSMutableDictionary 
    	dictionaryWithDictionary:[theDefaults objectForKey:@"sessions"]];
    NSMutableDictionary *theSession = [NSMutableDictionary dictionaryWithDictionary:[theSessions 
    	objectForKey:self.identifier]];
    
	[self storeToContainer:theSession];
    
    [theSessions setObject:theSession forKey:self.identifier];
    [theDefaults setObject:theSessions forKey:@"sessions"];
    [theDefaults synchronize];
}

//===============================================================================
- (void)storeToContainer:(NSMutableDictionary *)aContainer
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    if (nil != monitoredDomains)
    {
        [aContainer setObject:monitoredDomains forKey:@"monitoredDomains"];
    }
    if (nil != self.sessionIP)
    {
        [aContainer setObject:self.sessionIP forKey:@"sessionIP"];
    }

    NSMutableDictionary *theZones = [NSMutableDictionary dictionaryWithCapacity:zones.count];
    for (NSString *theDomain in self.zones)
    {
    	NSArray *theDomainZones = [self.zones objectForKey:theDomain];
    	NSMutableArray *theEncoded = [NSMutableArray arrayWithCapacity:theDomainZones.count];
        for (DomainZone *theZone in theDomainZones)
        {
            [theEncoded addObject:[theZone dictionaryRepresentation]];
        }
        [theZones setObject:theEncoded forKey:theDomain];
    }
    [aContainer setObject:theZones forKey:@"zones"];

    DevLog(@"D: Stored session in cotainer: \n%@", [aContainer description]);
}

//===============================================================================
- (void)restoreSession
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [self cleanup];
    [self restoreFromContainer:[[[NSUserDefaults standardUserDefaults] 
    	objectForKey:@"sessions"] objectForKey:self.identifier]];
}

//===============================================================================
- (void)restoreFromContainer:(NSDictionary *)aContainer
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [[NSNotificationCenter defaultCenter] removeObserver:self
        name:kDynamicIPDidChangeNotification object:nil];
        
    DevLog(@"D: Restoring session from cotainer: \n%@", [aContainer description]);
    if (kDomainLogin != self.loginType)
    {
        [monitoredDomains setArray:[aContainer objectForKey:@"monitoredDomains"]];
    }
	self.sessionIP = [aContainer objectForKey:@"sessionIP"];
    BOOL theIPChanged = ![self.sessionIP isEqualToString:[[NSUserDefaults 
    	standardUserDefaults] objectForKey:@"lastIP"]];
    
    // determine if IP was changed from the last activity period
    if (theIPChanged)
    {
        self.sessionIP = [[NSUserDefaults standardUserDefaults] 
        	objectForKey:@"lastIP"];
    }
    
    NSDictionary *theEncoded = [aContainer objectForKey:@"zones"];
    NSMutableDictionary *theZones = [NSMutableDictionary dictionaryWithCapacity:theEncoded.count];
    self.zones = theZones;
    BOOL theModified = NO;
    for (NSString *theDomain in theEncoded)
    {
    	BOOL theUpdated = NO;
    	NSArray *theDomainZones = [theEncoded objectForKey:theDomain];
    	NSMutableArray *theNewZones = [NSMutableArray arrayWithCapacity:theDomainZones.count];
        for (NSDictionary *theZone in theDomainZones)
        {
        	DomainZone *theNewZone = [[DomainZone alloc] initWithDictionary:theZone];
            // as IP was changed and there is dynamic zones update them right here
            if (theIPChanged && theNewZone.dynamic)
            {
            	theNewZone.address = self.sessionIP;
                theModified = YES;
                theUpdated = YES;
            }
            [theNewZones addObject:theNewZone];
            [theNewZone release];
        }
        [theZones setObject:theNewZones forKey:theDomain];
        if (theUpdated)
        {
        	// as dynamic zones were updated send them to a server
        	[self updateZones:theNewZones forDomain:theDomain delegate:self];
        }
    }
    if (theModified)
    {
    	// even if in restoring process we need to store because session data
        // was updated
    	[self storeSession];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onIPDidChange:) 
        name:kDynamicIPDidChangeNotification object:nil];
}

#pragma mark -
//===============================================================================
- (void)addDomain:(NSString *)aDomain
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aDomain, @"Contract violation");
	if (nil != aDomain && ![monitoredDomains containsObject:aDomain])
    {
    	[monitoredDomains addObject:aDomain];
        [self storeSession];
    }
}

//===============================================================================
- (void)removeDomain:(NSString *)aDomain
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aDomain, @"Contract violation");
	if (nil != aDomain)
    {
    	[monitoredDomains removeObject:aDomain];
        [zones removeObjectForKey:aDomain];
        [self storeSession];
    }
}

//===============================================================================
- (NSArray *)zonesForDomain:(NSString *)aDomain
{
	return [[[zones objectForKey:(nil == aDomain? @"" : aDomain)] retain] autorelease];
}

//===============================================================================
- (void)updateZones:(NSArray *)aZones forDomain:(NSString *)aDomain 
	delegate:(id<RPCExecutorDelegate>)anObject
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aZones && aDomain && anObject, @"Contract violation");
    if (nil == aZones || nil == aDomain || nil == anObject)
    {
    	return;
    }
    
    UserSetZonesDomain *theMethod = nil;
    // depending on login type use different server API
	if (kUserDinahostingLogin == self.loginType)
    {
        theMethod = [[UserSetZonesDomain alloc] initWithDomain:aDomain];
    }
    else
    {
        theMethod = [[DomainSetZones alloc] initWithDomain:aDomain];
    }
    theMethod.identifier = self.identifier;
    theMethod.password = self.password;
    theMethod.domainZones = [NSMutableArray arrayWithArray:aZones];
    
	if (kUserDinahostingLogin == self.loginType)
    {
	    [[RPCExecutor sharedExecutor] scheduleMethod:theMethod withDelegate:anObject];
    }
    else
    {
	    [[RPCExecutor sharedExecutor] scheduleHTTP:theMethod withDelegate:anObject];
    }
    [pendingMethods addObject:theMethod];
    [theMethod release];
}

//===============================================================================
- (void)storeZones:(NSArray *)aZones forDomain:(NSString *)aDomain
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aZones && aDomain, @"Contract violation");
    if (0 != aDomain.length && nil != aZones)
    {
    	[zones setObject:aZones forKey:aDomain];
        [self storeSession];
    }
}

#pragma mark -
//===============================================================================
- (void)methodExecutionDidFinish:(RPCMethod *)aMethod
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aMethod, @"Contract violation");
	if (!aMethod.isResultFault)	{		
		if ([aMethod isMemberOfClass:[UserGetZonesDomain class] ] || [aMethod isMemberOfClass:[DomainGetZones class]]){
			[self doTheChangeGetZones:(UserGetZonesDomain*)aMethod];
		}else {
			[self storeSession];
		}
	}
    if (nil != aMethod){
        [pendingMethods removeObject:aMethod];
    }
}
- (void)doTheChangeGetZones:(UserGetZonesDomain *)savedData{
	NSString *curDomain=savedData.domain;
	BOOL theShouldUpdate = NO;
	for (DomainZone *remoteZone in savedData.domainZones) {
		for (DomainZone *localZone in [self.zones objectForKey:curDomain]) {
			if ([localZone.host isEqualToString:remoteZone.host]){
				if (localZone.dynamic){
					remoteZone.address = self.sessionIP;
					remoteZone.dynamic=1;
					theShouldUpdate = YES;				
				}
				break;				
			}
		}
	}
	[self.zones setValue:savedData.domainZones forKey:curDomain];
	// ... then find all dynamic zones and change IP there ...
	if (theShouldUpdate)
	{
		TRACE(@"Raise the UPDATE");
		// ... and update on a server as some dynamic zones were updated
		[self updateZones:[self.zones objectForKey:curDomain] forDomain:curDomain delegate:self];
	}
	
}
//===============================================================================
- (void)onIPDidChange:(NSNotification *)aNotification
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aNotification, @"Contract violation");
	NSString *theAddress = [[aNotification userInfo] objectForKey:kNewIPAddress];

	// IP changed, so store it ...
    self.sessionIP = theAddress;
	
	for (NSString *theDomain in zones)
    {	
		//Antes de actualizar as zonas, obteño as que hai actualmente por si acaso hai algunhas novas ou cambiadas.
		UserGetZonesDomain *theMethod = nil;
		// depending on login type use different server API
		if (kUserDinahostingLogin == self.loginType)
		{
			theMethod = [[UserGetZonesDomain alloc] initWithDomain:theDomain];
		}
		else
		{
			theMethod = [[DomainGetZones alloc] initWithDomain:theDomain];
		}
		theMethod.identifier = self.identifier;
		theMethod.password = self.password;
		
		if (kUserDinahostingLogin == self.loginType)
		{
			[[RPCExecutor sharedExecutor] scheduleMethod:theMethod withDelegate:self];
		}
		else
		{
			[[RPCExecutor sharedExecutor] scheduleHTTP:theMethod withDelegate:self];
		}
		[pendingMethods addObject:theMethod];
		[theMethod release];
	}
	return;
}

//===============================================================================
- (void)cleanup
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    for (id theMethod in pendingMethods)
    {
    	[[RPCExecutor sharedExecutor] cancelMethod:theMethod];
    }
    [pendingMethods removeAllObjects];
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [self cleanup];
    
    [pendingMethods release];
	[identifier release];
    [password release];
    [domains release];
    [monitoredDomains release];
    [zones release];
    [sessionIP release];
    [super dealloc];
}
@end

