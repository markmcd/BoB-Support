//
//  BobSupport1ViewController.h
//  BobSupport1
//
//  Created by Mark M on 14/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// STOLEN
@interface UIProgressIndicator : UIActivityIndicatorView {
}

+ (struct CGSize)size;
- (int)progressIndicatorStyle;
- (void)setProgressIndicatorStyle:(int)fp8;
- (void)setStyle:(int)fp8;
- (void)setAnimating:(BOOL)fp8;
- (void)startAnimation;
- (void)stopAnimation;
@end

@interface UIProgressHUD : UIView {
    UIProgressIndicator *_progressIndicator;
    UILabel *_progressMessage;
    UIImageView *_doneView;
    UIWindow *_parentWindow;
    struct {
        unsigned int isShowing:1;
        unsigned int isShowingText:1;
        unsigned int fixedFrame:1;
        unsigned int reserved:30;
    } _progressHUDFlags;
}
- (id)_progressIndicator;
- (id)initWithFrame:(struct CGRect)fp8;
- (void)setText:(id)fp8;
- (void)setShowsText:(BOOL)fp8;
- (void)setFontSize:(int)fp8;
- (void)drawRect:(struct CGRect)fp8;
- (void)layoutSubviews;
- (void)showInView:(id)fp8;
- (void)hide;
- (void)done;
- (void)dealloc;
@end


@interface BobSupport1ViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
	IBOutlet UIImageView *imageView;
	IBOutlet UIBarButtonItem *saveButton;
	UIProgressHUD *progressHUD;
}

@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIBarButtonItem *saveButton;

- (IBAction)loadPic:(id)sender;
- (IBAction)savePic:(id)sender;
- (UIImage *)scaleAndRotateImage:(UIImage *)image;
- (void)showProgressIndicator:(NSString *)text;
- (void)hideProgressIndicator;

@end

