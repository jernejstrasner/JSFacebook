//
//  JSGraphRequest.h
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/28/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	JSFacebookOGLike
} JSFacebookOGAction;

@interface JSFacebookRequest : NSObject

@property (nonatomic, strong) NSString *graphPath;
@property (nonatomic, strong) NSString *httpMethod;
@property (strong, nonatomic, readonly) NSDictionary *parameters;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) BOOL omitResponseOnSuccess;
@property (nonatomic) BOOL authenticate;

- (id)initWithGraphPath:(NSString *)graphPath;
- (id)initWithOpenGraphNamespace:(NSString *)space andAction:(NSString *)action;
- (id)initForOpenGraphAction:(JSFacebookOGAction)action;

+ (id)requestWithGraphPath:(NSString *)graphPath;
+ (id)requestWithOpenGraphNamespace:(NSString *)space andAction:(NSString *)action;
+ (id)requestForOpenGraphAction:(JSFacebookOGAction)action;

- (void)addParameter:(NSString *)key withValue:(id)value;
- (void)removeParameter:(NSString *)key;

@end
