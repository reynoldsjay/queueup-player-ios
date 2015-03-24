//
//  PlayerViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/23/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "PlayerViewController.h"
#import <SIOSocket/SIOSocket.h>
#import "AppDelegate.h"

@interface PlayerViewController ()

@property SIOSocket *socket;
@property BOOL socketIsConnected;

@end

@implementation PlayerViewController {

    AppDelegate *appDelegate;
    Playlist *currentPlaylist;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    currentPlaylist = appDelegate.currentPlaylist;
    
    [SIOSocket socketWithHost: @"http://queueup.louiswilliams.org" response: ^(SIOSocket *socket) {
        self.socket = socket;
        
        __weak typeof(self) weakSelf = self;
        
        // on connecting to socket
        self.socket.onConnect = ^()
        {
            weakSelf.socketIsConnected = YES;
            NSLog(@"Connected.");
        };
        
        [self.socket on: @"auth_request" callback: ^(SIOParameterArray *args)
        {
            NSLog(@"Request auth");
            [self.socket emit: @"auth_send" args: [[NSArray alloc] initWithObjects:[[NSString alloc] initWithFormat:@"{\"id\" : \"%@\"}", currentPlaylist.playID], nil]];
            
        }];
        
        [self.socket on: @"auth_success" callback: ^(SIOParameterArray *args) {
            NSLog(@"Authenticated!");
        }];
        
        [self.socket on: @"auth_fail" callback: ^(SIOParameterArray *args) {
             NSLog(@"Authentication failed.");
        }];
        
        [self.socket on: @"state_change" callback: ^(SIOParameterArray *args) {
            
            NSMutableDictionary *dictionaryStateData = [args firstObject];
            
            @try {
                NSDictionary *track = dictionaryStateData[@"track"];
                NSString *trackURI = track[@"uri"];
                [appDelegate playSong:trackURI];
            }
            @catch (NSException *exception) {
            }
            @finally {
            }
            
            @try {
                bool playBool = [dictionaryStateData[@"play"] boolValue];
                
                if (playBool) {
                    [appDelegate play];
                } else if (!playBool) {
                    [appDelegate pause];
                }
                
            }
            @catch (NSException *exception) {
            }
            @finally {
            }
            
            
            
        }];
        
        
        
    }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
