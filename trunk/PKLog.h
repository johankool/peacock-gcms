/*
 * PKLog.h
 *
 * Created by Andy Lee on Wed Jul 10 2002.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 *
 * $Revision: 1.12 $
 */

#import <Foundation/Foundation.h>

/*!
* @header      PKLog
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
* @const       PKLogVerbosityUserDefault
 * @discussion  For use by NSUserDefaults.  Value is @"JKVerbosity".
 */
extern const NSString *PKLogVerbosityUserDefault;

/*!
* @function    JKGetVerbosityLevel
 * @discussion  Returns the verbosity level used by the various
 *              PKLogXXX() functions.
 */
extern int JKGetVerbosityLevel();

/*!
* @function    JKSetVerbosityLevel
 * @discussion  Sets the verbosity level used by the various
 PKLogXXX()
 *              functions.
 */
extern void JKSetVerbosityLevel(int level);

/*!
* @function    PKLogError
 * @discussion  Logs output if verbosity level >= JK_VERBOSITY_ERROR.
 */
#define PKLogError(format, ...)\
if (JKGetVerbosityLevel() >= JK_VERBOSITY_ERROR)\
{\
	do {\
        NSLog(@"[ERROR] %s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:format, ## __VA_ARGS__]);\
	} while (0);\
}

/*!
* @function    PKLogWarning
 * @discussion  Logs output if verbosity level >=
 JK_VERBOSITY_WARNING.
 */
#define PKLogWarning(format, ...)\
if (JKGetVerbosityLevel() >= JK_VERBOSITY_WARNING)\
{\
	do {\
        NSLog(@"[WARNING] %s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:format, ## __VA_ARGS__]);\
	} while (0);\
}

/*!
* @function    PKLogInfo
 * @discussion  Logs output if verbosity level >= JK_VERBOSITY_INFO.
 */
#define PKLogInfo(format, ...)\
if (JKGetVerbosityLevel() >= JK_VERBOSITY_INFO)\
{\
	do {\
        NSLog(@"[INFO] %s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:format, ## __VA_ARGS__]);\
	} while (0);\
}

/*!
* @function    PKLogDebug
 * @discussion  Logs output if verbosity level >= JK_VERBOSITY_DEBUG.
 */
#define PKLogDebug(format, ...)\
if (JKGetVerbosityLevel() >= JK_VERBOSITY_DEBUG)\
{\
	do {\
        NSLog(@"[DEBUG] %s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:format, ## __VA_ARGS__]);\
	} while (0);\
}

/*!
* @function    PKLogMissingOverride
 * @discussion  Stick this in implementations of abstract methods.
 */
#define PKLogMissingOverride()\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_ERROR)\
		PKLogError(\
					 @"%@ must override %@",\
					 [self class],\
					 NSStringFromSelector(_cmd));\
}

/*!
* @function    PKLogEnteringMethod
 * @discussion  Stick this at the beginning of a method to log the fact
 *              that it is being entered.
 */
#define PKLogEnteringMethod()\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_DEBUG)\
		PKLogDebug(\
					 @"%@ -- entering %@",\
					 [self class],\
					 NSStringFromSelector(_cmd));\
}

/*!
* @function    PKLogExitingMethodPrematurely
 * @discussion  Call this to log the fact that you are about to return
 *              from a method prematurely due to an error condition.
 */
#define PKLogExitingMethodPrematurely(msgString)\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_ERROR)\
		PKLogError(\
					 @"%@ -- exiting %@ early -- %@",\
					 [self class],\
					 NSStringFromSelector(_cmd),\
					 (msgString));\
}

/*!
* @function    PKLogExitingMethod
 * @discussion  Stick this at the end of a method to log the fact
 that it
 *              is being exited.
 */
#define PKLogExitingMethod()\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_DEBUG)\
		PKLogDebug(\
					 @"%@ -- exiting %@",\
					 [self class],\
					 NSStringFromSelector(_cmd));\
}

/*!
* @function    PKLogNondesignatedInitializer
 * @discussion  Call this in the implementation of an initializer that
 *              should never be called because it is not the designated
 *              initializer.
 */
#define PKLogNondesignatedInitializer()\
{\
	if (JKGetVerbosityLevel() >= JK_VERBOSITY_ERROR)\
		PKLogError(\
					 @"%@ -- '%@' is not the designated initializer",\
					 [self class],\
					 NSStringFromSelector(_cmd));\
}

