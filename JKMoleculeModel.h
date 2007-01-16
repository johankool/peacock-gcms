//
//  JKMoleculeModel.h
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccessorMacros.h"
#import "JKAtom.h"
#import "JKBond.h"

@interface JKMoleculeModel : NSObject <NSCoding> {
    NSMutableArray *atoms;
    NSMutableArray *bonds;
	NSString *name, *comment;
}

- (id)initWithMoleculeString:(NSString *)inString;

- (NSRect)rectForBounds;
- (float)estimateLengthOfBonds;

idAccessor_h(atoms, setAtoms)
idAccessor_h(bonds, setBonds) 
idAccessor_h(name, setName)
idAccessor_h(comment, setComment)

@end
