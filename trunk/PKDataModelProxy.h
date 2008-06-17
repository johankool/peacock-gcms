//
//  JKDataModelProxy.h
//  Peacock
//
//  Created by Johan Kool on 22-6-06.
//  Copyright 2006-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>

// This classs is used to read in data that was stored with an earlier version of Peacock

@interface PKDataModelProxy : NSObject {
	id peaks;
	id baseline;
	id metadata;
}

idAccessor_h(peaks, setPeaks)
idAccessor_h(baseline, setBaseline)
idAccessor_h(metadata, setMetadata)

@end