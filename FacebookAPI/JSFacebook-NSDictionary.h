//
//  JSFacebook-NSDictionary.h
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/31/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JSONKit.h"


@interface NSDictionary (JSFacebook_NSDictionary)

// Network data encoding methods
- (NSString *)generateGETParameters;
- (NSData *)generatePOSTBody;

@end
