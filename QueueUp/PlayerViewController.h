//
//  PlayerViewController.h
//  QueueUp
//
//  Created by Jay Reynolds on 6/16/15.
//  Copyright (c) 2015 com.reynoldsJay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerUIProtocol.h"

@interface PlayerViewController : UIViewController <PlayerUIProtocol, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@property IBOutlet UIProgressView * trackProgress;
@property IBOutlet UILabel * progressLabel;


@end
