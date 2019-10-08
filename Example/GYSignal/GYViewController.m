//
//  GYViewController.m
//  GYSignal
//
//  Created by ygyalone on 10/18/2018.
//  Copyright (c) 2018 ygyalone. All rights reserved.
//

#import "GYViewController.h"
@import GYSignal;

@interface GYViewController ()

@end

@implementation GYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    GYSignal *signal1 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"1"];
        [subscriber sendComplete];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    GYSignal *signal2 = [GYSignal signalWithAction:^GYSignalDisposer *(id<GYSubscriber> subscriber) {
        [subscriber sendValue:@"2"];
        [subscriber sendValue:nil];
        return [GYSignalDisposer disposerWithAction:^{
            NSLog(@"signal disposed");
        }];
    }];
    
    [[signal1 zip:@[signal2]] subscribeValue:^(GYTuple *value) {
        BOOL valid = [value[0] isEqual:@"1"] && [value[1] isEqual:@"2"];
        
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
