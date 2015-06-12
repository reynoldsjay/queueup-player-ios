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
    NSString *playlistString = [api postData:api.idAndToken toURL:(@hostDomain @"/api/playlists")];
    NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:playlistString];
    playlists = dictionaryData[@"playlists"];
    creators = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *aPlaylist in playlists) {
        NSString *userURL = [NSString stringWithFormat:@"%@/api/users/%@", @hostDomain, aPlaylist[@"admin"]];
        id usrDict = [api postData:api.idAndToken toURL:userURL];
        NSMutableDictionary *dictionaryData = (NSMutableDictionary*) [api parseJson:usrDict];
        NSString *creatorName = [NSString stringWithFormat:@"%@", dictionaryData[@"user"][@"name"]];
        [creators addObject:creatorName];
    }
    NSLog(@"%@", creators);
    
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
    NSArray *images = firstTrack[@"album"][@"images"];
    NSString *thisImgURL = [images firstObject][@"url"];
    
    UIImageView *bgalbum = (UIImageView *)[cell viewWithTag:5];
    [bgalbum sd_setImageWithURL:[NSURL URLWithString:thisImgURL]
             placeholderImage:[UIImage imageNamed:@""]];
    
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


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // set current playlist as selected
    api.currentPlaylist = [playlists objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"player" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
