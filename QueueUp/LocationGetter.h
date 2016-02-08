//
//  LocationGetter.h
//  QueueUp
//
//  Created by Jay Reynolds on 2/7/16.
//  Copyright © 2016 com.reynoldsJay. All rights reserved.
//


@protocol LocationGetter <NSObject>

-(void)locationCallback:(int)tag;

@end
