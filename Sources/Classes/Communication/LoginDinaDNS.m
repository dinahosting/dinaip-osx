/////////////////////////////////////////////////////////////////////////////////
//
//  LoginDinaDNS.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "LoginDinaDNS.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface LoginDinaDNS()
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation LoginDinaDNS
	@synthesize identifier, password;

//===============================================================================
+ (id)userLogin
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[[self alloc] initWithLoginType:kUserDinahostingLogin] autorelease];
}

//===============================================================================
+ (id)domainLogin
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[[self alloc] initWithLoginType:kDomainLogin] autorelease];
}

//===============================================================================
- (id)initWithLoginType:(int)aType
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self = [super init];
    if (nil != self)
    {
    	isDomain = (kDomainLogin == aType);
    }
    return self;
}

#pragma mark -
//===============================================================================
- (BOOL)isResultFault
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSNumber *theStatus = [self.results objectForKey:kMethodResultStatus];
	return [super isResultFault] || (nil != theStatus && ![theStatus boolValue]);
}

//===============================================================================
- (NSString *)name
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return @"loginDinaDNS";
}

//===============================================================================
- (NSDictionary *)parameters 
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [NSDictionary dictionaryWithObjectsAndKeys:
		self.identifier, @"identifier", self.password, @"password",
        [NSNumber numberWithBool:isDomain], @"isDomain", @"mac", @"system", nil];
}

//===============================================================================
- (NSArray *)orderedParameters
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [NSArray arrayWithObjects:@"identifier", @"password", @"isDomain", 
    	@"system", nil];
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[identifier release];
    [password release];
    [super dealloc];
}

@end
