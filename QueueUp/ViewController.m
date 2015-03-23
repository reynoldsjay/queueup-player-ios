//
//  ViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "ViewController.h"
#import <SIOSocket/SIOSocket.h>
#import "Playlist.h"


@interface ViewController ()

@property SIOSocket *socket;
@property BOOL socketIsConnected;

@end

@implementation ViewController {
    NSMutableDictionary *playlists;
    NSMutableArray *playlistHolder;
}

- (void)viewDidLoad {
    playlistHolder = [[NSMutableArray alloc] init];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSError *error;
    NSData *playlistData = [[NSData alloc] initWithContentsOfURL:
                            [NSURL URLWithString:@"http://queueup.louiswilliams.org/api/playlists"]];
    
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
    
    
    
    
    [SIOSocket socketWithHost: @"http://queueup.louiswilliams.org" response: ^(SIOSocket *socket) {
        self.socket = socket;
        
        __weak typeof(self) weakSelf = self;
        
        // on connecting to socket
        self.socket.onConnect = ^()
        {
            weakSelf.socketIsConnected = YES;
        };
        
        
    }];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
