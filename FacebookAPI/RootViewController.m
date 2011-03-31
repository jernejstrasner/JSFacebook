//
//  RootViewController.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/26/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "RootViewController.h"

@implementation RootViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookDidLogin:) name:kFacebookDidLoginNotification object:nil];
}

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

- (void)facebookDidLogin:(NSNotification *)notification {
//	// Test the Facebook API
//	JSFacebook *facebook = [JSFacebook sharedInstance];
//	[facebook requestWithGraphPath:@"/me/home" onSuccess:^(id responseObject) {
//		DLog(@"Response 1 received!");
//	} onError:^(NSError *error) {
//		DLog(@"Error 1: %@", [error localizedDescription]);
//	}];
//	[facebook requestWithGraphPath:@"/me/inbox" onSuccess:^(id responseObject) {
//		DLog(@"Response 2 received!");
//	} onError:^(NSError *error) {
//		DLog(@"Error 2: %@", [error localizedDescription]);
//	}];
//	[facebook requestWithGraphPath:@"/me/feed" onSuccess:^(id responseObject) {
//		DLog(@"Response 3 received!");
//	} onError:^(NSError *error) {
//		DLog(@"Error 3: %@", [error localizedDescription]);
//	}];
//	// Post
//	JSGraphRequest *graphRequest = [JSGraphRequest requestWithGraphPath:@"/me/feed"];
//	[graphRequest setHttpMethod:@"POST"];
//	[graphRequest addParameter:@"message" withValue:@"Just testing :)"];
//	[facebook fetchRequest:graphRequest onSuccess:^(id responseObject) {
//		DLog(@"Posted to the wall!");
//	} onError:^(NSError *error) {
//		DLog(@"Error posting: %@", [error localizedDescription]);
//	}];
//	JSGraphRequest *request1 = [JSGraphRequest requestWithGraphPath:@"me/friends?limit=5"];
//	[request1 setName:@"get-friends"];
//	JSGraphRequest *request2 = [JSGraphRequest requestWithGraphPath:@"?ids={result=get-friends:$.data..id}"];
//	[facebook fetchRequests:[NSArray arrayWithObjects:request1, request2, nil] onSuccess:^(NSArray *responseObjects) {
//		DLog(@"Responses:\n%@", responseObjects);
//	} onError:^(NSError *error) {
//		DLog(@"Error: %@", [error localizedDescription]);
//	}];
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

	// Configure the cell.
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
	*/
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc
{
    [super dealloc];
}

@end
