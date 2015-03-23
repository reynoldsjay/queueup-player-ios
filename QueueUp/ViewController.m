//
//  ViewController.m
//  QueueUp
//
//  Created by Jay Reynolds on 3/21/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import "ViewController.h"
#import <SIOSocket/SIOSocket.h>


@interface ViewController ()

@property SIOSocket *socket;
@property BOOL socketIsConnected;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
