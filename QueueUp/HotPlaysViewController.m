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

@end

@implementation HotPlaysViewController {
    NSMutableDictionary *playlists;
    NSMutableArray *playlistHolder;
    AppDelegate *appDelegate;
    ServerAPI *api;
}

- (void)viewDidLoad {
    
    api = [ServerAPI getInstance];
    
    // side bar
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
            [playlistHolder addObject:toAdd];
            //NSLog(@"%@", toAdd.name);
        }
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [playlists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = ((Playlist*)[playlistHolder objectAtIndex:indexPath.row]).name;
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    appDelegate.currentPlaylist = ((Playlist*)[playlistHolder objectAtIndex:indexPath.row]);
    [self performSegueWithIdentifier:@"player" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
