//
//  JSFacebook-NSDictionary.h
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/31/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSDictionary (JSFacebook)

// Network data encoding methods
- (NSString *)generateGETParameters;
- (NSData *)generatePOSTBodyWithBoundary:(NSString *)boundary;

@end
