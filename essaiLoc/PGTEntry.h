//
//  PGTEntry.h
//  essaiLoc
//
//  Created by famille on 15/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PGTMetaData;

@interface PGTEntry : NSObject

@property (strong) NSURL * fileURL;
@property (strong) PGTMetaData * metadata;
@property (assign) UIDocumentState state;
@property (strong) NSFileVersion * version;

- (id)initWithFileURL:(NSURL *)fileURL metadata:(PGTMetaData *)metadata state:(UIDocumentState)state version:(NSFileVersion *)version;
- (NSString *) description;

@end
