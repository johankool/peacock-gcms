/*
 * JKLog.h
 *
 * Created by Andy Lee on Wed Jul 10 2002.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 *
 * $Revision: 1.12 $
 */

#import <Foundation/Foundation.h>

/*!
* @header      JKLog
 * @discussion  Wrappers around NSLog that allow setting of log
 verbosity
 *              levels.
 */

/*!
* @enum        Log verbosity levels
 * @abstract    Values that can be passed to JKSetVerbosityLevel().
 * @discussion  Anything lower than JK_VERBOSITY_NONE works the same
 *              as JK_VERBOSITY_NONE, and anything higher than
 *              JK_VERBOSITY_ALL works the same as
 JK_VERBOSITY_ALL.
 *
 * @constant    JK_VERBOSITY_NONE
 *                  Use JK_VERBOSITY_NONE to suppress all log output.
 * @constant    JK_VERBOSITY_ERROR
 *                  Use JK_VERBOSITY_ERROR to log anomalies without
 *                  workarounds.
 * @constant    JK_VERBOSITY_WARNING
 *                  Use JK_VERBOSITY_WARNING to log anomalies with
 *                  workarounds.
 * @constant    JK_VERBOSITY_INFO
 *                  Use JK_VERBOSITY_INFO to log normal information
 *                  about the state of the program.  This is the
 default
 *                  verbosity level.
 * @constant    JK_VERBOSITY_DEBUG
 *                  Use JK_VERBOSITY_DEBUG to log information that is
 *                  only needed for debugging and should not be logged
 *                  by a deployed version of the app.
 * @constant    JK_VERBOSITY_ALL
 *                  Use JK_VERBOSITY_ALL to turn on all logging.
 */
enum{
    JK_VERBOSITY_NONE = 0,
    JK_VERBOSITY_ERROR = 10,
    JK_VERBOSITY_WARNING = 20,
    JK_VERBOSITY_INFO = 30,
    JK_VERBOSITY_DEBUG = 40,
    JK_VERBOSITY_ALL = 99
};

/*!
* @const       JKLogVerbosityUserDefault
 * @discussion  For use by NSUserDefaults.  Value is @"JKVerbosity".
 */
extern const NSString *JKLogVerbosityUserDefault;

/*!
* @function    JKGetVerbosityLevel
 * @discussion  Returns the verbosity level used by the various
 *              JKLogXXX() functions.
 */
extern int JKGetVerbosityLevel();

/*!
* @function    JKSetVerbosityLevel
 * @discussion  Sets the verbosity level used by the various
 JKLogXXX()
 *              functions.
 */
extern void JKSetVerbosityLevel(int level);

/*!
* @function    JKLogError
 * @discussion  Logs output if verbosity level >= JK_VERBOSITY_ERROR.
 */
#define JKLogError(format, ...)\
if (JKGetVerbosityLevel() >= JK_VERBOSITY_ERROR)\
{\
	NSLog(@"[ERROR] %s", __PRETTY_FUNCTION__);\
	NSLog(\
		  [@"[ERROR] " stringByAppendingString:(format)],\
## __VA_ARGS__);\
}

/*!
* @function    JKLogWarning
 * @discussion  Logs output if verbosity level >=
 JK_VERBOSITY_WARNING.
 */
#define JKLogWarning(format, ...)\
if (JKGetVerbosityLevel() >= JK_VERBOSITY_WARNING)\
{\
	do {\
	NSLog(@"[WARNING] %s", __PRETTY_FUNCTION__);\
	NSLog(\
		  [@"[WARNING] " stringByAppendingString:(format)],\
## __VA_ARGS__);\
	} while (0);\
}

/*!
* @function    JKLogInfo
 * @discussion  Logs output if verbosity level >= JK_VERBOSITY_INFO.
 */
#define JKLogInfo(format, ...)\
if (JKGetVerbosityLevel() >= JK_VERBOSITY_INFO)\
{\
	do {\
	NSLog(@"[INFO] %s", __PRETTY_FUNCTION__);\
	NSLog(\
		  [@"[INFO] " stringByAppendingString:(format)],\
## __VA_ARGS__);\
	} while (0);\
}

/*!
* @function    JKLogDebug
 * @discussion  Logs output if verbosity level >= JK_VERBOSITY_DEBUG.
 */
#define JKLogDebug(format, ...)\
if (JKGetVerbosityLevel() >= JK_VERBOSITY_DEBUG)\
{\
	do {\
	NSLog(@"[DEBUG] %s", __PRETTY_FUNCTION__);\
	NSLog(\
		  [@"[DEBUG] " stringByAppendingString:(format)],\
## __VA_ARGS__);\
} while (0);\
}

/*!
* @function    JKLogMissingOverride
 * @discussion  Stick this in implementations of abstract methods.
 */
#define JKLogMissingOverride()\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_ERROR)\
		JKLogError(\
					 @"%@ must override %@",\
					 [self class],\
					 NSStringFromSelector(_cmd));\
}

/*!
* @function    JKLogEnteringMethod
 * @discussion  Stick this at the beginning of a method to log the fact
 *              that it is being entered.
 */
#define JKLogEnteringMethod()\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_DEBUG)\
		JKLogDebug(\
					 @"%@ -- entering %@",\
					 [self class],\
					 NSStringFromSelector(_cmd));\
}

/*!
* @function    JKLogExitingMethodPrematurely
 * @discussion  Call this to log the fact that you are about to return
 *              from a method prematurely due to an error condition.
 */
#define JKLogExitingMethodPrematurely(msgString)\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_ERROR)\
		JKLogError(\
					 @"%@ -- exiting %@ early -- %@",\
					 [self class],\
					 NSStringFromSelector(_cmd),\
					 (msgString));\
}

/*!
* @function    JKLogExitingMethod
 * @discussion  Stick this at the end of a method to log the fact
 that it
 *              is being exited.
 */
#define JKLogExitingMethod()\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_DEBUG)\
		JKLogDebug(\
					 @"%@ -- exiting %@",\
					 [self class],\
					 NSStringFromSelector(_cmd));\
}

/*!
* @function    JKLogNondesignatedInitializer
 * @discussion  Call this in the implementation of an initializer that
 *              should never be called because it is not the designated
 *              initializer.
 */
#define JKLogNondesignatedInitializer()\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_ERROR)\
		JKLogError(\
					 @"%@ -- '%@' is not the designated initializer",\
					 [self class],\
					 NSStringFromSelector(_cmd));\
}

