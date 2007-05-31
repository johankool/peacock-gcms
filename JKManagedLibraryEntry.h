//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKComparableProtocol.h"

@interface JKManagedLibraryEntry : NSManagedObject <JKComparableProtocol> {	
	int numberOfPoints;
    BOOL peakTableRead;
	float *masses;
	float *intensities;
}

#pragma mark Importing data
- (NSString *)jcampString;
- (void)setJCAMPString:(NSString *)inString;
- (void)readPeakTable;
- (NSNumber *)calculateMassWeight:(NSString *)inString;
- (NSString *)library;
#pragma mark -

#pragma mark Undo
- (NSUndoManager *)undoManager;
#pragma mark -

#pragma mark Accessors (NSManagedObject style)
- (NSString *)peakTable;
- (void)setPeakTable:(NSString *)inString;
- (NSString *)name;
- (void)setName:(NSString *)newName;
- (NSString *)origin;
- (void)setOrigin:(NSString *)neworigin;
- (NSString *)owner;
- (void)setOwner:(NSString *)newowner;
- (NSString *)CASNumber;
- (void)setCASNumber:(NSString *)newCASNumber;
- (NSString *)epaMassSpecNo;
- (void)setEpaMassSpecNo:(NSString *)newepaMassSpecNo;
- (NSString *)formula;
- (void)setFormula:(NSString *)newformula;
- (NSNumber *)massWeight;
- (void)setMassWeight:(NSNumber *)newmassWeight;
- (NSString *)nistSource;
- (void)setNistSource:(NSString *)newnistSource;
- (NSString *)ionizationEnergy;
- (void)setIonizationEnergy:(NSString *)newionizationEnergy;
- (NSString *)xUnits;
- (void)setXUnits:(NSString *)newxUnits;
- (NSString *)yUnits;
- (void)setYUnits:(NSString *)newyUnits;
- (NSNumber *)xFactor;
- (void)setXFactor:(NSNumber *)newxFactor;
- (NSNumber *)yFactor;
- (void)setYFactor:(NSNumber *)newyFactor;
- (NSNumber *)retentionIndex;
- (void)setRetentionIndex:(NSNumber *)newretentionIndex;
- (NSString *)source;
- (void)setSource:(NSString *)newsource;
- (NSString *)comment;
- (void)setComment:(NSString *)newcomment;
- (NSString *)molString;
- (void)setMolString:(NSString *)newmolString;
- (NSString *)symbol;
- (void)setSymbol:(NSString *)newsymbol;
- (NSString *)modelChr;
- (void)setModelChr:(NSString *)newmodelChr;
- (NSString *)group;
- (void)setGroup:(NSString *)newgroup;
- (NSString *)synonyms;
- (void)setSynonyms:(NSString *)newsynonyms;
- (int)numberOfPoints;
- (void)setNumberOfPoints:(int)newnumberOfPoints;

@end
