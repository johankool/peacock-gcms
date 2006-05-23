//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class SpectrumGraphDataSerie;

@interface JKLibraryEntry : NSObject <NSCoding> {
	NSDocument *document;
	
	// Required in JCAMP-DX
	NSString *name;			// ##TITLE=
							// ##JCAMP-DX= (string) 5.00 $$ (Name and version number of the JCAMP-DX program) 
							// ##DATA TYPE= (string) e.g., MASS SPECTRUM 
							// ##DATA CLASS= (string) e.g., PEAK TABLE 
	NSString *origin;		// ##ORIGIN=
	NSString *owner;		// ##OWNER=
	
	// Optional in JCAMP-DX
	NSString *CASNumber;	// ##CAS REGISTRY NO=
	NSString *epaMassSpecNo;// ##$EPA MASS SPEC NO=
	NSString *formula;		// ##MOLFORM=
	NSNumber *massWeight;	// ##MW=
	NSString *nistSource;	// ##$NIST SOURCE=
	NSString *ionizationEnergy; // ##.IONIZATION ENERGY=
	NSString *xUnits;		// ##XUNITS=
	NSString *yUnits;		// ##YUNITS=
	NSNumber *xFactor;		// ##XFACTOR=
	NSNumber *yFactor;		// ##YFACTOR=
	NSNumber *retentionIndex; // ##RI=
	NSString *source;		// ##SOURCE=
	
	// Peacock additions
	NSString *comment;		// ##$COMMENT=
	NSString *molString;	// ##$MOLSTRING=
	NSString *symbol;		// ##$SYMBOL=
			
	int numberOfPoints;		// ##NPOINTS=
	float *masses;
	float *intensities;
	
	float maximumIntensity;
}

- (id)initWithJCAMPString:(NSString *)inString;
- (NSString *)jcampString;
- (SpectrumGraphDataSerie *)spectrumDataSerie;
- (NSNumber *)calculateMassWeight:(NSString *)inString;

//- (JKLibraryEntry *)normalizedLibraryEntry;
//- (JKLibraryEntry *)negativeLibraryEntry;
//- (JKLibraryEntry *)negativeNormalizedLibraryEntry;

- (NSUndoManager *)undoManager;

idAccessor_h(name, setName);
idAccessor_h(origin, setOrigin);
idAccessor_h(owner, setOwner);

idAccessor_h(CASNumber, setCASNumber);
idAccessor_h(epaMassSpecNo, setEpaMassSpecNo);
idAccessor_h(formula, setFormula);
idAccessor_h(massWeight, setMassWeight);
idAccessor_h(nistSource, setNISTSource);
idAccessor_h(ionizationEnergy, setIonizationEnergy);
idAccessor_h(xUnits, setXUnits);
idAccessor_h(yUnits, setYUnits);
idAccessor_h(xFactor, setXFactor);
idAccessor_h(yFactor, setYFactor);
idAccessor_h(retentionIndex, setRetentionIndex);
idAccessor_h(source, setSource);

idAccessor_h(comment, setComment);
idAccessor_h(molString, setMolString);
idAccessor_h(symbol, setSymbol);
- (int)numberOfPoints;
- (SpectrumGraphDataSerie *)spectrumDataSerie;
- (void)setDocument:(NSDocument *)inValue;
- (NSDocument *)document;

//intAccessor_h(numberOfPoints, setNumberOfPoints);
- (void)setMasses:(float *)inArray withCount:(int)inValue;
- (float *)masses;

- (void)setIntensities:(float *)inArray withCount:(int)inValue;
- (float *)intensities;
- (float)maximumIntensity;
- (NSString *)peakTable;
- (void)setPeakTable:(NSString *)inString;

@end
