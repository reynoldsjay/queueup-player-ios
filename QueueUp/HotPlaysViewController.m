//
//  ViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay.QueueUp All rights reserved.
//

#import "HotPlaysViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "ServerAPI.h"
#import "Config.h"
#import "UIImageView+WebCache.h"
#import "SpotifyPlayer.h"


@interface HotPlaysViewController ()


@property IBOutlet UICollectionView *collectionView;


@end


@implementation HotPlaysViewController {
    NSMutableArray *playlists;
    NSMutableArray *creators;
    ServerAPI *api;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // get api object
    api = [ServerAPI getInstance];
    
    // side bar set up
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
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
    
}


// create a new playlist alert
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

// tells server about new playlist
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *name = [alertView textFieldAtIndex:0].text;
        // name contains the entered value
        
        NSString *clientID = ((NSDictionary*)api.idAndToken)[@"user_id"];
        NSString *token = ((NSDictionary*)api.idAndToken)[@"client_token"];
        
        NSString *toSend = [[NSString alloc] initWithFormat:@"{\"user_id\" : \"%@\", \"client_token\" : \"%@\",\"playlist\" : {\"name\" : \"%@\"}}", clientID, token, name];
        
        id jsonVote = [api parseJson:toSend];
        
        NSString *postVoteURL = [NSString stringWithFormat:@"/api/v2/playlists/new"];
        
        NSLog(@"Sending playlists/new");
        [api postData:jsonVote toURL:postVoteURL];
        
        // update local playlist list
        NSString *playlistString = [api getDataFromURL:(@"/api/v2/playlists")];
        NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
        playlists = dictionaryData[@"playlists"];
        creators = [[NSMutableArray alloc] init];
        for (NSMutableDictionary *aPlaylist in playlists) {
            NSString *creatorName = aPlaylist[@"admin_name"];
            if (!creatorName) {
                [creators addObject:@"?"];
            } else {
                [creators addObject:creatorName];
            }
        }
        
        [self.collectionView reloadData];
        
    }
}



// table delegate methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [playlists count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    
//    NSArray *pics = @[@"bg1024.png", @"bg1024purple.png", @"bg1024blue.png", @"bg1024gold.png"];
    
    
    // set background of cells as album covers
    NSDictionary * aPlaylist = [playlists objectAtIndex:indexPath.row];
    NSDictionary *firstTrack = aPlaylist[@"current"];
    if (firstTrack != (id)[NSNull null]) {
        NSArray *images = firstTrack[@"album"][@"images"];
        NSString *thisImgURL = [images firstObject][@"url"];
    
        UIImageView *bgalbum = (UIImageView *)[cell viewWithTag:5];
//        bgalbum.image = [UIImage imageNamed:pics[indexPath.row%4]];
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
    [[SpotifyPlayer getInstance] pause];
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
