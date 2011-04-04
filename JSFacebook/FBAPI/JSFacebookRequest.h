//
//  JSGraphRequest.h
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/28/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JSFacebookRequest : NSObject {
	NSString *graphPath_;
	NSString *httpMethod_;
	NSMutableDictionary *params_;
	NSString *name_;
	BOOL omitResponseOnSuccess_;
}

@property (nonatomic, retain) NSString *graphPath;
@property (nonatomic, retain) NSString *httpMethod;
@property (nonatomic, readonly) NSDictionary *parameters;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) BOOL omitResponseOnSuccess;

- (id)initWithGraphPath:(NSString *)graphPath;

+ (id)requestWithGraphPath:(NSString *)graphPath;

- (void)addParameter:(NSString *)key withValue:(id)value;
- (void)removeParameter:(NSString *)key;

@end
