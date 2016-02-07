//
//  LocationManager.h
//  QueueUp
//
//  Created by Jay Reynolds on 2/7/16.
//  Copyright © 2016 com.reynoldsJay. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface LocationManager : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *locationManager;
    
}

@property double lattitude;
@property double longitude;

+ (LocationManager*) getInstance;
- (void)getALocation:(id)sender;

@end
