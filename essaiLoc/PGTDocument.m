//
//  PGTDocument.m
//  essaiLoc
//
//  Created by famille on 14/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "DDLog.h"
#import "PGTDocument.h"
#import "PGTData.h"
#import "PGTMetaData.h"
//#import "PGTDataPoint.h"
//#import "PGTDataPointMetadata.h"
#import "UIImageExtras.h"

#define METADATA_FILENAME   @"parcours.metadata"
#define DATA_FILENAME       @"parcours.crumbs"
#define ANNOTATIONS_FILENAME       @"parcours.annotations"

@interface PGTDocument ()
@property (nonatomic, strong) PGTData * data;
@property (nonatomic, strong) NSFileWrapper * fileWrapper;
@property (nonatomic, strong) NSMutableArray* annotationsData;
@end

@implementation PGTDocument

@synthesize data = _data;
@synthesize fileWrapper = _fileWrapper, annotationsData = _annotationsData;

- (void)encodeObject:(id<NSCoding>)object toWrappers:(NSMutableDictionary *)wrappers preferredFilename:(NSString *)preferredFilename {
    @autoreleasepool {
        NSMutableData * data = [NSMutableData data];
        NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:object forKey:@"data"];
        [archiver finishEncoding];
        NSFileWrapper * wrapper = [[NSFileWrapper alloc] initRegularFileWithContents:data];
        [wrappers setObject:wrapper forKey:preferredFilename];
    }
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    
    if (self.metadata == nil || self.data == nil) {
        return nil;
    }
    
    DDLog(@"");
    NSMutableDictionary * wrappers = [NSMutableDictionary dictionary];
    [self encodeObject:self.metadata toWrappers:wrappers preferredFilename:METADATA_FILENAME];
    [self encodeObject:self.data toWrappers:wrappers preferredFilename:DATA_FILENAME];
    [self encodeObject:self.annotationsData toWrappers:wrappers preferredFilename:ANNOTATIONS_FILENAME];
    
    NSFileWrapper * fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers];
    
    return fileWrapper;
    
}


- (id)decodeObjectFromWrapperWithPreferredFilename:(NSString *)preferredFilename {
    
    NSFileWrapper * fileWrapper = [self.fileWrapper.fileWrappers objectForKey:preferredFilename];
    if (!fileWrapper) {
        NSLog(@"Unexpected error: Couldn't find %@ in file wrapper!", preferredFilename);
        return nil;
    }
    
    NSData * data = [fileWrapper regularFileContents];
    NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    return [unarchiver decodeObjectForKey:@"data"];
    
}

- (PGTMetaData *)metadata {
    if (_metadata == nil) {
        if (self.fileWrapper != nil) {
            //NSLog(@"Loading metadata for %@...", self.fileURL);
            self.metadata = [self decodeObjectFromWrapperWithPreferredFilename:METADATA_FILENAME];
        } else {
            self.metadata = [[PGTMetaData alloc] init];
        }
    }
    return _metadata;
}

- (PGTData *)data {
    if (_data == nil) {
        if (self.fileWrapper != nil) {
            //NSLog(@"Loading photo for %@...", self.fileURL);
            self.data = [self decodeObjectFromWrapperWithPreferredFilename:DATA_FILENAME];
        } else {
            self.data = [[PGTData alloc] init];
        }
    }
    return _data;
}

- (NSMutableArray*)annotationsData {
    if (_annotationsData == nil) {
        if (self.fileWrapper != nil) {
            self.annotationsData = [self decodeObjectFromWrapperWithPreferredFilename:ANNOTATIONS_FILENAME];
        } else {
            self.annotationsData = [NSMutableArray array];
        }
    }
    return _annotationsData;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    
    self.fileWrapper = (NSFileWrapper *) contents;
    
    // The rest will be lazy loaded...
    self.data = nil;
    self.metadata = nil;
    self.annotationsData = nil;
    
    return YES;
    
}
- (NSString *) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}

#pragma mark Accessors

- (UIImage *)photo {
    return self.data.photo;
}

- (void)setPhoto:(UIImage *)photo {
    
    if ([self.data.photo isEqual:photo]) return;
    
    UIImage * oldPhoto = self.data.photo;
    self.data.photo = photo;
    self.metadata.thumbnail = [self.data.photo imageByScalingAndCroppingForSize:CGSizeMake(145, 145)];
    
    [self.undoManager setActionName:@"Image Change"];
    [self.undoManager registerUndoWithTarget:self selector:@selector(setPhoto:) object:oldPhoto];
}

- (PGTCrumbPath*)crumbPath
{
    return self.data.path;
}

-(void)startCrumbPathWithLocation:(CLLocation *)location
{
    self.data.path = [[PGTCrumbPath alloc] initWithCenterLocation:location];
    [self updateChangeCount:UIDocumentChangeDone];
}

-(void)addLocation:(CLLocation *)location
{
    [self.data.path addLocation:location];
    [self updateChangeCount:UIDocumentChangeDone];
}

-(void)addPhotoAnnotation:(PGTPhotoAnnotation *)annotation
{
    DDLog(@"");
    [self.annotationsData addObject:annotation];
    [self updateChangeCount:UIDocumentChangeDone];

}

-(NSMutableArray*)annotations
{
    return self.annotationsData;
}
@end
