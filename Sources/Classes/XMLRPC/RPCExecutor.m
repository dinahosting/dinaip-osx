/////////////////////////////////////////////////////////////////////////////////
//
//  RPCExecutor.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "RPCExecutor.h"
#import "RPCOperation.h"
#import "RPCMethod.h"
#import "HTTPOperation.h"
#import "Common.h"

static NSString *const kDHRPCURL = @"https://dinahosting.com/special/dhRpc/interface.php";
static NSString *const kAPISMLURL = @"http://apisms.gestiondecuenta.com/php/comun/ejecutarComando.php";

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface RPCExecutor()
- (void)reset;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation RPCExecutor
	static RPCExecutor *sRPCExecutor = nil;

//===============================================================================
+ (id)sharedExecutor
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	@synchronized(self)
    {
    	if (nil == sRPCExecutor)
        {
        	sRPCExecutor = [[self class] new];
        }
    }
    return sRPCExecutor;
}

//===============================================================================
- (id)init
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	@synchronized([self class])
    {
    	if (nil != sRPCExecutor)
        {
        	[self release];
            self = [sRPCExecutor retain];
        }
        else 
        {
        	self = [super init];
            processor = [NSOperationQueue new];
        }

    }
    return self;
}

//===============================================================================
- (void)scheduleMethod:(RPCMethod *)aMethod withDelegate:(id<RPCExecutorDelegate>)aDelegate
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSAssert(aMethod && aDelegate, @"contract");

	// Create an operation for provided method and put it into queue for processing
	RPCOperation *theOperation = [RPCOperation operationWithMethod:aMethod client:aDelegate];
    theOperation.delegate = self;
    theOperation.endpoint = kDHRPCURL;
    theOperation.clientThread = [NSThread currentThread];
    if (nil != theOperation)
    {
    	DevLog(@"D: Scheduled command: %@", aMethod.name);
    	[processor addOperation:theOperation];
    }
}

//===============================================================================
- (void)scheduleHTTP:(RPCMethod *)aMethod withDelegate:(id<RPCExecutorDelegate>)aDelegate
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSAssert(aMethod && aDelegate, @"contract");

	// Create an operation for provided method and put it into queue for processing
	HTTPOperation *theOperation = [HTTPOperation operationWithMethod:aMethod client:aDelegate];
    theOperation.delegate = self;
    theOperation.HTTPmethod = @"POST";
    theOperation.endpoint = kAPISMLURL;
    theOperation.clientThread = [NSThread currentThread];
    if (nil != theOperation)
    {
    	DevLog(@"D: Scheduled command: %@", aMethod.name);
    	[processor addOperation:theOperation];
    }
}

//===============================================================================
- (void)cancelMethod:(RPCMethod *)aMethod
{
	NSAssert(aMethod, @"contract");
	TRACE(@"T: [%@ %s]", self, _cmd);
	if (nil != aMethod)
    {
		// let operation decide if it needs to cancel
        [[processor operations] makeObjectsPerformSelector:@selector(cancelIfMatch:) 
            withObject:aMethod];
    }
}

//===============================================================================
- (void)reset
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // stop all queued operations and clear everything
	[[processor operations] makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
	[processor cancelAllOperations];
}

//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [processor release];
    [super dealloc];
}

@end
