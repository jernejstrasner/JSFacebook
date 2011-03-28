//
//  FacebookAPITests.m
//  FacebookAPITests
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FacebookAPITests.h"

#import "JSFacebook.h"


@implementation FacebookAPITests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testFacebookNetworkQueue
{
	JSFacebook *facebook = [JSFacebook sharedInstance];
	STAssertNotNil(facebook, @"Facebook should not be nil!");
}

@end
