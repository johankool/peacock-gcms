//
//  JKDataModelProxy.m
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

#import "PKDataModelProxy.h"


@implementation PKDataModelProxy

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
		peaks = [coder decodeObjectForKey:@"peaks"]; 
		baseline = [coder decodeObjectForKey:@"baseline"]; 
		metadata = [coder decodeObjectForKey:@"metadata"]; 
	} 
    return self;
}

- (void)dealloc {
    [peaks release];
    [baseline release];
    [metadata release];
    [super dealloc];
}
idAccessor(peaks, setPeaks)
idAccessor(baseline, setBaseline)
idAccessor(metadata, setMetadata)

@end
