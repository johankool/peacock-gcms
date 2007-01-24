//
//  JKDataModelProxy.h
//  Peacock
//
//  Created by Johan Kool on 22-6-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// This classs is used to read in data that was stored with an earlier version of Peacock

@interface JKDataModelProxy : NSObject {
	id peaks;
	id baseline;
	id metadata;
}

idAccessor_h(peaks, setPeaks)
idAccessor_h(baseline, setBaseline)
idAccessor_h(metadata, setMetadata)

@end
