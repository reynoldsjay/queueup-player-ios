//
//  ViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay.QueueUp All rights reserved.
//

#import "HotPlaysViewController.h"
#import "Playlist.h"
#import "PlayerViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "ServerAPI.h"
#import "Config.h"


@interface HotPlaysViewController ()


@property IBOutlet UICollectionView *collectionView;


@end


@implementation HotPlaysViewController {
    NSMutableDictionary *playlists;
    NSMutableArray *playlistHolder;
    AppDelegate *appDelegate;
    ServerAPI *api;
}

- (void)viewDidLoad {
    
    api = [ServerAPI getInstance];
    
    // side bar set up
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    playlistHolder = [[NSMutableArray alloc] init];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSError *error;
    
    NSString *playlistString = [api postData:api.idAndEmail toURL:(@hostDomain @"/api/playlists")];
    
    
    NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
    
    playlists = dictionaryData[@"playlists"];
    
    if( error ) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        for (NSDictionary *playlistInfo in playlists) {
            Playlist *toAdd = [[Playlist alloc] init];
            toAdd.name = playlistInfo[@"name"];
            toAdd.playID = playlistInfo[@"_id"];
            NSDictionary *firstTrack = playlistInfo[@"current"];
            NSArray *images = firstTrack[@"album"][@"images"];
            toAdd.imgURL = [images firstObject][@"url"];
            [playlistHolder addObject:toAdd];
            //NSLog(@"%@", toAdd.name);
        }
    }
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [playlists count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString:((Playlist*)[playlistHolder objectAtIndex:indexPath.row]).imgURL]];
    
    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:imageData]];
    // set label
    UILabel *cellLabel = (UILabel *)[cell viewWithTag:100];
    
    // set transparent cover
    UIImageView *shade = (UIImageView *)[cell viewWithTag:10];
    shade.image = [UIImage imageNamed:@"albumShade.png"];
    
    
    cellLabel.text = ((Playlist*)[playlistHolder objectAtIndex:indexPath.row]).name;
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    appDelegate.currentPlaylist = ((Playlist*)[playlistHolder objectAtIndex:indexPath.row]);
    [self performSegueWithIdentifier:@"player" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
