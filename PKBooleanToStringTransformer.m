//
//  BooleanToStringTransformer.m
//  Peacock
//
//  Created by Johan Kool on 4-5-07.
//  Copyright 2007-2008 Johan Kool.
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

#import "PKBooleanToStringTransformer.h"

@implementation PKBooleanToStringTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)aValue {
    if (!aValue) {
        return @"-";
    } else if ([aValue intValue] == 0) {
    	return NSLocalizedString(@"No", @"");
    } else if ([aValue intValue] == 1) {
     	return NSLocalizedString(@"Yes", @"");
    } else {
        return @"-";
    }
}

@end
