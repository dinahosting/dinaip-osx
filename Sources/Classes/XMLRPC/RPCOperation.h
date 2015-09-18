/////////////////////////////////////////////////////////////////////////////////
//
//  RPCOperation.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file RPCOperation.h

/////////////////////////////////////////////////////////////////////////////////
@class RPCMethod;

/////////////////////////////////////////////////////////////////////////////////
//! This class represents RPC method operation
@interface RPCOperation : NSOperation 
{
	@private
    	RPCMethod *method; //!< Executed method
        id client; //!< A consumer of method results
        id delegate; //!< A delegate of operatoin
        NSString *endpoint; //!< Endpoint of RPC method
        
        NSThread *workThread; //!< Thread for method execution
        NSThread *clientThread; //!< A client thread 
        
        BOOL isFinished; //!< Indicates if operation is finished
        BOOL isCancelled; //!< Indicates if operation is cancelled
}
//! Delegate of operation
@property (nonatomic, assign) id delegate;
//! URL for method to be send
@property (nonatomic, retain) NSString *endpoint;
//! A thread of a method resutls consumer
@property (nonatomic, assign) NSThread *clientThread;
//! A method to be executor
@property (nonatomic, readonly) RPCMethod *method;
//! A method consumer
@property (nonatomic, readonly) id client;
//! A work thread of operation
@property (assign) NSThread *workThread;
//! Indicates if operation is finished
@property (assign) BOOL isFinished;
//! Indicates if operation is cancelled
@property (assign) BOOL isCancelled;

//! Creates and initializes opeartion with method to be executed and client
//! for result consumption
+ (id)operationWithMethod:(RPCMethod *)aMethod client:(id)anObject;
//! Initializes opeartion with method to be executed and client
//! for result consumption
- (id)initWithMethod:(RPCMethod *)aMethod client:(id)anObject;
//! Cancel method execution if method equals to provided
- (void)cancelIfMatch:(RPCMethod *)aMethod;

@end
