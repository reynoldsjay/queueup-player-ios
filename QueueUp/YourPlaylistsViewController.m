//
//  ViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay.QueueUp All rights reserved.
//

#import "YourPlaylistsViewController.h"
#import "ServerAPI.h"

@implementation YourPlaylistsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // get api object
    api = [ServerAPI getInstance];
    
    
    if (!api.loggedIn) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log in to see your playlists."
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    [self getPlaylistData:self];
    
}


-(void)getPlaylistData:(id)sender {
    NSString *playlistString;
    if (api.loggedIn){
        
        // get all playlists
        //NSLog(@"%@", api.idAndToken);
        NSString *userID = ((NSDictionary *) api.idAndToken)[@"user_id"];
        
        // get all playlists
        NSString *url = [NSString stringWithFormat:@"/api/v2/users/%@/playlists", userID];
        playlistString = [api getDataFromURL:url];
        
    } else {
        playlistString = @"";
    }
    
    
    
    
    NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
    playlists = dictionaryData[@"playlists"];
    
    // get the admins names
    creators = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *aPlaylist in playlists) {
        NSString *creatorName = aPlaylist[@"admin_name"];
        if (!creatorName) {
            [creators addObject:@"?"];
        } else {
            [creators addObject:creatorName];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
    if([sender isMemberOfClass:[UIRefreshControl class]]) {
        [sender endRefreshing];
    }

}

@end
