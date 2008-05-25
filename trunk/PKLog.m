/*
 * PKLog.m
 *
 * Created by Andy Lee on Wed Jul 10 2002.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 *
 * $Revision: 1.4 $
 */

#import "PKLog.h"

const NSString *PKLogVerbosityUserDefault = @"JKVerbosity";

static int g_verbosityLevel = JK_VERBOSITY_DEBUG;

int JKGetVerbosityLevel() { return g_verbosityLevel; }

void JKSetVerbosityLevel(int level) { g_verbosityLevel = level; }
