//
//  PGTEntry.m
//  essaiLoc
//
//  Created by famille on 15/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "PGTEntry.h"

@implementation PGTEntry

@synthesize fileURL = _fileURL;
@synthesize metadata = _metadata;
@synthesize state = _state;
@synthesize version = _version;

- (id)initWithFileURL:(NSURL *)fileURL metadata:(PGTMetaData *)metadata state:(UIDocumentState)state version:(NSFileVersion *)version {
    
    if ((self = [super init])) {
        self.fileURL = fileURL;
        self.metadata = metadata;
        self.state = state;
        self.version = version;
    }
    return self;
    
}

- (NSString *) description {
    return [[self.fileURL lastPathComponent] stringByDeletingPathExtension];
}


@end
