//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKComparableProtocol.h"

@interface PKManagedLibraryEntry : NSManagedObject <PKComparableProtocol> {	
    int numberOfPoints;
    float *masses;
    float *intensities;
    float maxIntensity;
    BOOL needDatapointsRefresh;
}

#pragma mark Importing data
- (NSString *)jcampString;
- (void)setJCAMPString:(NSString *)inString;
- (NSNumber *)calculateMassWeight:(NSString *)inString;
#pragma mark -

#pragma mark Helper functions
- (BOOL)isCompound:(NSString *)compoundString;
- (NSArray *)synonymsArray;
#pragma mark -

#pragma mark Undo
- (NSUndoManager *)undoManager;
#pragma mark -

- (BOOL)validateCASNumber:(id *)ioValue error:(NSError **)outError;

#pragma mark Calculated Accessors
- (NSString *)library;
- (void)setLibrary:(NSString *)aLibrary;
- (NSString *)peakTable;
- (void)setPeakTable:(NSString *)inString;
- (int)numberOfPoints;
//- (void)setNumberOfPoints:(int)newnumberOfPoints;
- (float *)masses;
//- (void)setMasses:(float *)newMasses;
- (float *)intensities;
//- (void)setIntensities:(float *)newIntensities;
- (void)datapointsRefresh;
#pragma mark -

@property (retain) NSSet *datapoints;

#pragma mark Accessors (NSManagedObject style)
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
- (NSString *)model;
- (void)setModel:(NSString *)newmodel;
- (NSString *)group;
- (void)setGroup:(NSString *)newgroup;
- (NSString *)synonyms;
- (void)setSynonyms:(NSString *)newsynonyms;

@end
