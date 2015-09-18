/////////////////////////////////////////////////////////////////////////////////
//
//  HTTPOperation.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>
#import "RPCOperation.h"

//! @file HTTPOperation.h

/////////////////////////////////////////////////////////////////////////////////
//! This class represents HTTP operation perform using NSURLConnection
@interface HTTPOperation : RPCOperation 
{
	@private
        NSString *HTTPmethod; //!< HTTP method (POST, GET, etc.)
        NSURLConnection *connection; //!< Method executor
        NSMutableData *buffer; //!< Buffer to collect response data
}

//! HTTP method
@property (nonatomic, retain) NSString *HTTPmethod;
@end
