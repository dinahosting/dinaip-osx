/////////////////////////////////////////////////////////////////////////////////
//
//  RPCMethod.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file RPCMethod.h

/////////////////////////////////////////////////////////////////////////////////
extern NSString *const kMethodResultStatus;
extern NSString *const kMethodResultValue;

/////////////////////////////////////////////////////////////////////////////////
//! This class represents base RPC method
@interface RPCMethod : NSObject 
{
	@private
        NSDictionary *results; //!< Results of method execution
        BOOL isResultFault; //!< Indicates if method fault
        NSError *error; //!< Error of method execution
}

//! Name of method
@property (nonatomic, readonly, retain) NSString *name;
//! Parameters of method
@property (nonatomic, readonly, retain) NSDictionary *parameters;
//! Order of method parameters to be sent
@property (nonatomic, readonly, retain) NSArray *orderedParameters;
//! Method execution results
@property (nonatomic, retain) NSDictionary *results;
//! Method execution error
@property (nonatomic, retain) NSError *error;
//! Indicates if result fault
@property (nonatomic, assign) BOOL isResultFault;
@end
