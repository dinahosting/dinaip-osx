/////////////////////////////////////////////////////////////////////////////////
//
//  RPCExecutor.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file RPCExecutor.h

/////////////////////////////////////////////////////////////////////////////////
@class RPCMethod;
@class RPCExecutor;

/////////////////////////////////////////////////////////////////////////////////
//! A protocol of RPC executor delegate object
@protocol RPCExecutorDelegate <NSObject>
//! Called when an executor finishes performing method
- (void)methodExecutionDidFinish:(RPCMethod *)aMethod;
@end

/////////////////////////////////////////////////////////////////////////////////
//! This class represents executor of different RPC command/methods
@interface RPCExecutor : NSObject 
{
	@private
        NSOperationQueue *processor; //!< system executor
}

//! Singleton
+ (id)sharedExecutor;

//! Schedules RPC method for execution
- (void)scheduleMethod:(RPCMethod *)aMethod withDelegate:(id<RPCExecutorDelegate>)aDelegate;
//! Schedules HTTP method for execution
- (void)scheduleHTTP:(RPCMethod *)aMethod withDelegate:(id<RPCExecutorDelegate>)aDelegate;
//! Cancels method execution
- (void)cancelMethod:(RPCMethod *)aMethod;
@end
