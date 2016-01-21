//
//  NearbyVC.h
//  QueueUp
//
//  Created by Jay Reynolds on 1/9/16.
//  Copyright © 2016 com.reynoldsJay. All rights reserved.
//

#import "AbstractPlaylistView.h"
#import <CoreLocation/CoreLocation.h>

@interface NearbyVC : AbstractPlaylistView <CLLocationManagerDelegate> {
    CLLocationManager *locationManager;
}


@end
