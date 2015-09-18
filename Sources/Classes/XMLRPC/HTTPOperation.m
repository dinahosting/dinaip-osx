/////////////////////////////////////////////////////////////////////////////////
//
//  HTTPOperation.m
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import "HTTPOperation.h"
#import "RPCMethod.h"
#import "RPCExecutor.h"
#import "Common.h"

/////////////////////////////////////////////////////////////////////////////////
// This is a private class interface
@interface HTTPOperation()
	@property (nonatomic, retain) NSURLConnection *connection;
	@property (nonatomic, retain) NSMutableData *buffer;
@end

#pragma mark -
/////////////////////////////////////////////////////////////////////////////////
@implementation HTTPOperation
	@synthesize HTTPmethod, connection, buffer;
#pragma mark -

//===============================================================================
- (void)main
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    // this method is called in a work thread (different from UI even thread)
    @synchronized(self)
    {
        self.workThread = [NSThread currentThread];
    }

	if ([self isCancelled])
    {
    	return;
    }
        
	NSURL *theURL = [NSURL URLWithString:self.endpoint];
    
    // prepare mutable URL request as mostly POST is needed
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:theURL 
    	cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    if (nil == theRequest)
    {
    	ERROR(@"E: Cannot create HTTP request for [%@]", self.method);
    	return;
    }
    
    [theRequest setHTTPMethod:self.HTTPmethod];
	
    NSData *theBody = nil;
    
    // using same approach as for RPC operation collect parameters to be sent
    // as body with POST request to a server
    NSArray *theParameters = self.method.orderedParameters;
	if (0 < theParameters.count)
    {
    	NSDictionary *theValues = self.method.parameters;
        NSString *theQuery = @"";
    	for (NSString *theParam in theParameters)
        {
        	theQuery = [theQuery stringByAppendingFormat:@"%@%@=%@", (0 < theQuery.length ? @"&" : @""),
            	theParam, [theValues objectForKey:theParam]];
        }
        theBody = [theQuery dataUsingEncoding:NSUTF8StringEncoding];
	}
    [theRequest setValue:[NSString stringWithFormat:@"%lu", theBody.length] 
        forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPBody:theBody];
    
    // setup system HTTP connection to a server
    self.buffer = [NSMutableData data];
    self.connection = [[[NSURLConnection alloc] initWithRequest:theRequest delegate:self 
    	startImmediately:NO] autorelease];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] 
    	forMode:NSDefaultRunLoopMode];
	[self.connection start];
    
    // run own even loop to process events from HTTP connection
    while (![self isFinished] && ![self isCancelled])
    {
    	NSAutoreleasePool *thePool = [NSAutoreleasePool new];
    	[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate 
        	dateWithTimeIntervalSinceNow:5.0]];
        [thePool drain];
    }
    [self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] 
    	forMode:NSDefaultRunLoopMode];
    self.connection = nil;
}

//===============================================================================
- (void)cancelExecution:(id)anObject
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	// performed on thread where openration is running just to wake runloop
    [self.connection cancel];
}

#pragma mark -
//===============================================================================
- (NSURLRequest *)connection:(NSURLConnection *)aConnection willSendRequest:(NSURLRequest *)aRequest 
	redirectResponse:(NSURLResponse *)aResponse
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	DevLog(@"D: Request -> %@ %@\n%@\n%@", [aRequest HTTPMethod], [aRequest URL], 
    	[[aRequest allHTTPHeaderFields] description], [[[NSString alloc] 
        initWithData:[aRequest HTTPBody] encoding:4] autorelease]);	
    return aRequest;
}

//===============================================================================
- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSHTTPURLResponse *)aResponse
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	DevLog(@" D: Response -> %@\n%@", [NSHTTPURLResponse localizedStringForStatusCode:[aResponse  
    	statusCode]], [[aResponse allHeaderFields] description]);	
}

//===============================================================================
- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)aData
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    [self.buffer appendData:aData];
}

//===============================================================================
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    self.isFinished = YES;

    // construct result ...
	NSString *theOutput = [[NSString alloc] initWithData:self.buffer 
    	encoding:NSUTF8StringEncoding];
    DevLog(@"D: Response payload -> \n%@", theOutput);
    
    self.method.isResultFault = (nil == theOutput);
    // ... and store in called method if not error (error processed separately)
    if (!self.method.isResultFault)
    {
        self.method.results = (id)theOutput;
    }
    [theOutput release];

	// call result listener in its own thread
    if ([self.client respondsToSelector:@selector(methodExecutionDidFinish:)])
    {
    	[self.client performSelector:@selector(methodExecutionDidFinish:) 
        	onThread:self.clientThread withObject:self.method waitUntilDone:NO];
    }
}

//===============================================================================
- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)anError
{
	TRACE(@"T: [%@ %s]", self, _cmd);
    self.isFinished = YES;
    // construct and store error in called method
    NSError *theError = [NSError errorWithDomain:@"SMSAPI" code:-100 
            	userInfo:[NSDictionary dictionaryWithObject:anError 
                forKey:NSUnderlyingErrorKey]];
    ERROR(@"E: HTTPOperation generated error: %@", [theError description]);
    self.method.error = theError;
    if ([self.client respondsToSelector:@selector(methodExecutionDidFinish:)])
    {
    	[self.client performSelector:@selector(methodExecutionDidFinish:) 
        	onThread:self.clientThread withObject:self.method waitUntilDone:NO];
    }
}

//===============================================================================
- (void)dealloc
{
	TRACE(@"T: [%@ %s]", self, _cmd);
	[connection cancel];
    [connection release];
    [buffer release];
	[HTTPmethod release];
    [super dealloc];
}

@end
