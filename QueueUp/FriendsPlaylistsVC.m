//
//  ViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay.QueueUp All rights reserved.
//

#import "FriendsPlaylistsVC.h"
#import "ServerAPI.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@implementation FriendsPlaylistsVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // get api object
    api = [ServerAPI getInstance];
    
    if (!api.loggedIn) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log in to see your friends' playlists."
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
//    NSString *playlistString;
//    if (api.loggedIn){
//        
//        // get all playlists
//        //NSLog(@"%@", api.idAndToken);
//        NSString *userID = ((NSDictionary *) api.idAndToken)[@"user_id"];
//        
//        // get all playlists
//        NSString *url = [NSString stringWithFormat:@"/api/v2/users/%@/playlists", userID];
//        playlistString = [api getDataFromURL:url];
//        
//    } else {
//        playlistString = @"";
//    }
    
//        NSString *userID = ((NSDictionary *) api.idAndToken)[@"user_id"];
//
//    
//    NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
//    playlists = dictionaryData[@"playlists"];
//    
//    // get the admins names
//    creators = [[NSMutableArray alloc] init];
//    for (NSMutableDictionary *aPlaylist in playlists) {
//        NSString *creatorName = aPlaylist[@"admin_name"];
//        if (!creatorName) {
//            [creators addObject:@"?"];
//        } else {
//            [creators addObject:creatorName];
//        }
//    }
//    
    
        // TESTING FRIENDS
        if ([FBSDKAccessToken currentAccessToken]) {
            [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:@{}]
             startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                 if (!error) {
//                     NSLog(@"%@", result);
                     NSArray* friends = ((NSDictionary *) result)[@"data"];
                     NSMutableArray* fbIds = [[NSMutableArray alloc] init];
                     for (NSDictionary* aFriend in friends) {
                         [fbIds addObject:aFriend[@"id"]];
                     }
    
    
    
                     NSString *clientID = ((NSDictionary*)api.idAndToken)[@"user_id"];
                     NSString *token = ((NSDictionary*)api.idAndToken)[@"client_token"];
    
                     // SWITCH TO THIS
                     NSDictionary* sendObject = [NSDictionary dictionaryWithObjects:@[clientID, token, fbIds] forKeys:@[@"user_id", @"client_token", @"fb_ids"]];
    
                     NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sendObject options:0 error:nil];
                     NSString *JSONString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    
                     id toSend = [api parseJson:JSONString];
//                     NSLog(@"%@", toSend);
    
                     NSString *url = [NSString stringWithFormat:@"/api/v2/users/friends/playlists"];
                     NSString *playlistString = [api postData:toSend toURL:url];
                     NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
                     playlists = dictionaryData[@"playlists"];
//                     NSLog(@"friends list %@", playlists);
                     creators = [[NSMutableArray alloc] init];
                     for (NSMutableDictionary *aPlaylist in playlists) {
                         //        NSString *userURL = [NSString stringWithFormat:@"%@/api/v1/users/%@", @hostDomain, aPlaylist[@"admin"]];
                         //        id usrDict = [api postData:api.idAndToken toURL:userURL];
                         //        NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:usrDict];
    
                         NSString *creatorName = aPlaylist[@"admin_name"];//[NSString stringWithFormat:@"%@", dictionaryData[@"user"][@"name"]]
                         //NSLog(@"a playlisy: %@", creatorName);
                         if (!creatorName) {
                             [creators addObject:@"?"];
                         } else {
                             [creators addObject:creatorName];
                         }
                     }
                     [self.collectionView reloadData];
                 }
             }];
        }
}

@end