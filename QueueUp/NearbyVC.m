//
//  NearbyVC.m
//  QueueUp
//
//  Created by Jay Reynolds on 1/9/16.
//  Copyright © 2016 com.reynoldsJay. All rights reserved.
//

#import "NearbyVC.h"
#import "ServerAPI.h"



@implementation NearbyVC {
    BOOL firstLoad;

}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // get api object
    firstLoad = YES;
    api = [ServerAPI getInstance];
    lManager = [LocationManager getInstance];
    [self getPlaylistData:self];
    
}


- (void)getPlaylistData:(id)sender {
    
    [lManager getALocation:self withTag:1];
    // fix
    if([sender isMemberOfClass:[UIRefreshControl class]]) {
        [sender endRefreshing];
    }

}

- (void) updatePLaylists:(id)sender {
    NSString *toSend = [[NSString alloc] initWithFormat:@"{\"location\" : {\"latitude\" : %.6f, \"longitude\" : %.6f}}", lattitude, longitude];
    id jsonLocation = [api parseJson:toSend];
    NSString *postURL = [NSString stringWithFormat:@"/api/v2/playlists/nearby"];
    NSString *playlistString = [api postData:jsonLocation toURL:postURL];
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
    
}

-(void)locationCallback:(int)tag{
    lattitude = lManager.lattitude;
    longitude = lManager.longitude;
    if (tag == 1) {
        [self updatePLaylists:self];
    } else if (tag == 0) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"New playlist name:"
                                                          message:nil
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"Continue", nil];
        
        [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [message show];
    
    }

}









@end