/////////////////////////////////////////////////////////////////////////////////
//
//  Common.h
//  DinaIP
//
/////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>

//! @file Common.h

/////////////////////////////////////////////////////////////////////////////////

#define DEVTRACE 0
#define DEVERROR 0
#define DEVINFOR 0

//! Defines console logging available only in DEBUG configuration
#ifdef DEVLOG
  	
    #define DevLog(...) NSLog(__VA_ARGS__)

    #if DEVTRACE
	  	#define TRACE(...) NSLog(__VA_ARGS__)
	#else
    	#define TRACE(...)
    #endif //DEVTRACE

    #if DEVERROR
	  	#define ERROR(...) NSLog(__VA_ARGS__)
	#else
    	#define ERROR(...)
    #endif //DEVERROR

    #if DEVINFOR
	  	#define INFO(...) NSLog(__VA_ARGS__)
	#else
    	#define INFO(...)
    #endif //DEVINFOR
    
#else // DEVLOG

    #define DevLog(...) do { } while (0)
    #define TRACE(...) do { } while (0)
    #define ERROR(...) do { } while (0)
    #define INFO(...) do { } while (0)

#endif // DEVLOG
