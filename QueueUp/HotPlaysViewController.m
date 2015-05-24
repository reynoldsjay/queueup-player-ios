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


@interface HotPlaysViewController ()

@end

@implementation HotPlaysViewController {
    NSMutableDictionary *playlists;
    NSMutableArray *playlistHolder;
    AppDelegate *appDelegate;
}

- (void)viewDidLoad {
    
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
    NSData *playlistData = [[NSData alloc] initWithContentsOfURL:
                            [NSURL URLWithString:@"http://localhost:3004/api/playlists"]];
    
    
    NSMutableDictionary *dictionaryData = [NSJSONSerialization JSONObjectWithData:playlistData
                                                                          options:NSJSONReadingMutableContainers error:&error];
    
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
