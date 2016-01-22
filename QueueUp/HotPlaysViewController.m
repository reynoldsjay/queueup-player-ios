//
//  ViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay.QueueUp All rights reserved.
//

#import "HotPlaysViewController.h"
#import "ServerAPI.h"

@implementation HotPlaysViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getPlaylistData:self];
}

- (void)getPlaylistData:(id)sender {
    // get all playlists
    NSString *playlistString = [api getDataFromURL:(@"/api/v2/playlists")];
    
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