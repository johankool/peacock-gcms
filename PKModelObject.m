//
//  JKModelObject.m
//  Peacock
//
//  Created by Johan Kool on 22-3-07.
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

#import "PKModelObject.h"


@implementation PKModelObject

#pragma mark Initialization & deallocation
- (id) init
{
	if ((self = [super init]) != nil) {
		[self setContainer:nil];
	}
	return self;
}
- (void) dealloc {
    [self setContainer:nil];
    [super dealloc];
}
#pragma mark -

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)decoder
{
	[super init];
    [self setContainer:[decoder decodeObjectForKey:@"container"]];
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    if ([container respondsToSelector:@selector(encodeWithCoder:)])
        [encoder encodeObject:container forKey:@"container"];
}
#pragma mark -

#pragma mark Undo
- (NSUndoManager *)undoManager
{
    if (container) {
        return [container undoManager];
    } else {
        return nil;
    }
}
#pragma mark -

#pragma mark Document
- (NSDocument *)document
{
    id object = self;
    while ([object container]) {
        object = [object container];
        if ([object isKindOfClass:[NSDocument class]]) {
            return object;
        }
    }
    return nil;
}
#pragma mark -

#pragma mark Accessors
#pragma mark (weakly referenced)
- (id)container
{
        return container;
}
- (void)setContainer:(id)aContainer
{
    container = aContainer;
}

@end
