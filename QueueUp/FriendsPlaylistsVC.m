//
//  ViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay.QueueUp All rights reserved.
//

#import "FriendsPlaylistsVC.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "ServerAPI.h"
#import "Config.h"
#import "UIImageView+WebCache.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@interface FriendsPlaylistsVC ()


@property IBOutlet UICollectionView *collectionView;


@end


@implementation FriendsPlaylistsVC {
    NSMutableArray *playlists;
    NSMutableArray *creators;
    ServerAPI *api;
}

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
    
    // side bar set up
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
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



- (IBAction)newPlaylist:(id)sender {
    if (!api.loggedIn) {
        [self performSegueWithIdentifier:@"toLogin" sender:self];
    } else {
        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"New playlist name:"
                                                          message:nil
                                                         delegate:self
                                                cancelButtonTitle:@"Cancel"
                                                otherButtonTitles:@"Continue", nil];
        
        [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [message show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *name = [alertView textFieldAtIndex:0].text;
//        NSLog(@"%@", name);
        // name contains the entered value
        
        NSString *clientID = ((NSDictionary*)api.idAndToken)[@"user_id"];
        NSString *token = ((NSDictionary*)api.idAndToken)[@"client_token"];
        
        NSString *toSend = [[NSString alloc] initWithFormat:@"{\"user_id\" : \"%@\", \"client_token\" : \"%@\",\"playlist\" : {\"name\" : \"%@\"}}", clientID, token, name];
        
        id jsonVote = [api parseJson:toSend];
        
        NSString *postVoteURL = [NSString stringWithFormat:@"/api/v2/playlists/new"];
        
//        NSLog(@"post: %@ to %@", jsonVote, postVoteURL);
        NSString *theRet = [api postData:jsonVote toURL:postVoteURL];
//        NSLog(@"newplay post %@", theRet);
        
        // get all playlists
        //NSLog(@"%@", api.idAndToken);
        NSString *url = [NSString stringWithFormat:@"/api/v2/users/%@/playlists", clientID];
        NSString *playlistString = [api postData:api.idAndToken toURL:url];
        NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
        playlists = dictionaryData[@"playlists"];
        //NSLog(@"%@", playlists);
        creators = [[NSMutableArray alloc] init];
        for (NSMutableDictionary *aPlaylist in playlists) {
            //        NSString *userURL = [NSString stringWithFormat:@"%@/api/v1/users/%@", @hostDomain, aPlaylist[@"admin"]];
            //        id usrDict = [api postData:api.idAndToken toURL:userURL];
            //        NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:usrDict];
            
            NSString *creatorName = aPlaylist[@"admin_name"];//[NSString stringWithFormat:@"%@", dictionaryData[@"user"][@"name"]]
//            NSLog(@"a playlisy: %@", creatorName);
            if (!creatorName) {
                [creators addObject:@"?"];
            } else {
                [creators addObject:creatorName];
            }
        }
        
        [self.collectionView reloadData];
        
    }
}

// table methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [playlists count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    // set background of cells as album covers
    NSDictionary * aPlaylist = [playlists objectAtIndex:indexPath.row];
    NSDictionary *firstTrack = aPlaylist[@"current"];
    if (firstTrack != (id)[NSNull null]) {
//        NSLog(@"%d", firstTrack == NULL);
        NSArray *images = firstTrack[@"album"][@"images"];
        NSString *thisImgURL = [images firstObject][@"url"];
        
        UIImageView *bgalbum = (UIImageView *)[cell viewWithTag:5];
        [bgalbum sd_setImageWithURL:[NSURL URLWithString:thisImgURL]
                   placeholderImage:[UIImage imageNamed:@""]];
    }
    // set transparent cover
    UIImageView *shade = (UIImageView *)[cell viewWithTag:10];
    shade.image = [UIImage imageNamed:@"albumShade.png"];
    
    
    // set label with name of playlist
    UILabel *cellLabel = (UILabel *)[cell viewWithTag:100];
    cellLabel.text = [playlists objectAtIndex:indexPath.row][@"name"];
    
    
    // get each playlist's admin
    UILabel *userLabel = (UILabel *)[cell viewWithTag:110];
    userLabel.text = [creators objectAtIndex:indexPath.row];
    
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.bounds.size.width/2 - 4, collectionView.bounds.size.width/2 - 4);
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // set current playlist as selected
    NSString *currString = ((NSDictionary *) api.currentPlaylist)[@"_id"];
    NSString *clickedString = ((NSDictionary *)[playlists objectAtIndex:indexPath.row])[@"_id"];
    
    if (![currString isEqualToString:clickedString]) {
        api.currentPlaylist = [playlists objectAtIndex:indexPath.row];
        api.hosting = NO;
    }
    [self performSegueWithIdentifier:@"player" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
