/////////////////////////////////////////////////////////////////////////////////
//  RPCOperation.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "RPCOperation.h"
#import "RPCExecutor.h"
#import "RPCMethod.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
void RPCMethodInvocationCallBack(WSMethodInvocationRef inInvocation, void *inInfo, 
	CFDictionaryRef inResults);

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface RPCOperation()
- (void)cancelExecution:(id)anObject;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation RPCOperation
	@synthesize delegate, endpoint, clientThread, workThread;
    @synthesize isCancelled, isFinished, method, client;

//===============================================================================
+ (id)operationWithMethod:(RPCMethod *)aMethod client:(id)anObject
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return [[[[self class] alloc] initWithMethod:aMethod client:anObject] autorelease];
}

//===============================================================================
- (id)initWithMethod:(RPCMethod *)aMethod client:(id)anObject
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	NSAssert(aMethod && anObject, @"");
    if (nil == aMethod || nil == anObject)
    {
    	ERROR(@"E: Contract violation [%@]", [self class]);
    	[self release];
        return nil;
    }
	self = [super init];
    if (nil != self)
    {
    	method = [aMethod retain];
        client = anObject;
    }
    return self;
}

//===============================================================================
- (BOOL)isConcurrent
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	return NO;
}

#pragma mark -
//===============================================================================
- (void)main
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // this method is executed in work thread (different from UI even loop thread)
    @synchronized(self)
    {
        self.workThread = [NSThread currentThread];
    }

	if (self.isCancelled)
    {
    	return;
    }
        
	NSURL *theURL = [NSURL URLWithString:self.endpoint];

	// create RPC invocation request
    WSMethodInvocationRef theRequest = WSMethodInvocationCreate((CFURLRef)theURL, 
    	(CFStringRef)method.name, kWSXMLRPCProtocol);
    if (NULL == theRequest)
    {
    	ERROR(@"E: Cannot create RPC request for method [%@]", self.method);
    	return;
    }
    
    WSMethodInvocationSetParameters(theRequest, (CFDictionaryRef)method.parameters, 
    	(CFArrayRef)method.orderedParameters);
    
    // setup RPC invocation properties
    WSMethodInvocationSetProperty(theRequest, kWSHTTPFollowsRedirects, kCFBooleanTrue);
#ifdef DEBUG
	WSMethodInvocationSetProperty(theRequest, kWSDebugIncomingBody, kCFBooleanTrue);
    WSMethodInvocationSetProperty(theRequest, kWSDebugIncomingHeaders, kCFBooleanTrue);
    WSMethodInvocationSetProperty(theRequest, kWSDebugOutgoingBody, kCFBooleanTrue);
    WSMethodInvocationSetProperty(theRequest, kWSDebugOutgoingHeaders, kCFBooleanTrue);
#endif

	// prepare RPC invocation for asynchronous call
	WSClientContext theInfo = {0, self, NULL, NULL, NULL};
	WSMethodInvocationSetCallBack(theRequest, RPCMethodInvocationCallBack, &theInfo);
    WSMethodInvocationScheduleWithRunLoop(theRequest, CFRunLoopGetCurrent(), 
    	kCFRunLoopDefaultMode);
    
    // run own even loop for communication even processing
    while (!self.isFinished && !self.isCancelled)
    {
    	NSAutoreleasePool *thePool = [NSAutoreleasePool new];
    	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 5.0, true);
        [thePool drain];
    }
    WSMethodInvocationUnscheduleFromRunLoop(theRequest, CFRunLoopGetCurrent(), 
    	kCFRunLoopDefaultMode);
    CFRelease(theRequest);
}

//===============================================================================
- (void)cancel
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	self.isCancelled = YES;
    @synchronized(self)
    {
		// just wake up working thread so it can handle changed isCancelled state
        if (nil != self.workThread)
        {
            [self performSelector:@selector(cancelExecution:) onThread:self.workThread 
                withObject:nil waitUntilDone:NO];
        }
    }
}

//===============================================================================
- (void)cancelExecution:(id)anObject
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// performed on thread where openration is running just to wake runloop
    
}

//===============================================================================
- (void)processResults:(NSDictionary *)aResults forRequest:(WSMethodInvocationRef)aRequest
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    NSAssert(aResults && aRequest, @"contract violation");
    
	DevLog(@"D: Received response:\n%@", [aResults description]);
    method.isResultFault = WSMethodResultIsFault((CFDictionaryRef)aResults);
	// extract result from method
    if (!method.isResultFault)
    {
        method.results = [aResults objectForKey:(id)kWSMethodInvocationResult];
    }
    else
    {
    	// ... or generate and error
    	NSError *theError = nil;
        if ([[aResults objectForKey:(id)kWSFaultString] 
        	isEqualToString:(id)kWSNetworkStreamFaultString])
        {
        	theError = [NSError errorWithDomain:@"Network" code:-100 
            	userInfo:aResults];
        }
        else 
        {
        	theError = [NSError errorWithDomain:@"RPCAPI" code:-200 
            	userInfo:aResults];
        }
    	ERROR(@"E: Error for method: %@\n", method.name, [theError description]);
    	method.error = theError;    
    }
    self.isFinished = YES;
    // ... and notify client that finished
    if ([client respondsToSelector:@selector(methodExecutionDidFinish:)])
    {
    	[client performSelector:@selector(methodExecutionDidFinish:) 
        	onThread:self.clientThread withObject:method waitUntilDone:NO];
    }
}

//===============================================================================
- (void)cancelIfMatch:(RPCMethod *)aMethod
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// call cancel to itself if method is own
	if (method == aMethod)
    {
    	[self cancel];
    }
}

#pragma mark -
//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[endpoint release];
    [method release];
    [super dealloc];
}
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
void RPCMethodInvocationCallBack(WSMethodInvocationRef inRequest, void *inInfo, 
	CFDictionaryRef inResults)
{
	TRACE(@"T: RPCMethodInvocationCallBack");
	RPCOperation *theOperation = (RPCOperation *)inInfo;
    [theOperation processResults:(id)inResults forRequest:inRequest];
}
