//
//  BobSupport1AppDelegate.h
//  BobSupport1
//
//  Created by Mark M on 14/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BobSupport1ViewController;

@interface BobSupport1AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    BobSupport1ViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet BobSupport1ViewController *viewController;

@end

