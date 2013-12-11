//
//  SHCAttachment.h
//  Digipost
//
//  Created by Eivind Bohler on 11.12.13.
//  Copyright (c) 2013 Shortcut. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SHCDocument;

@interface SHCAttachment : NSManagedObject

// Attributes
@property (strong, nonatomic) NSString *authenticationLevel;
@property (strong, nonatomic) NSNumber *fileSize;
@property (strong, nonatomic) NSString *fileType;
@property (strong, nonatomic) NSNumber *mainDocument;
@property (strong, nonatomic) NSNumber *read;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSString *uri;

// Relationships
@property (strong, nonatomic) SHCDocument *document;

@end
