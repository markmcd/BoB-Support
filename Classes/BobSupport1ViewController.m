//
//  BobSupport1ViewController.m
//  BobSupport1
//
//  Created by Mark M on 14/10/10.
//  Copyright 2010 Mark McDonald. All rights reserved.
//

#import "BobSupport1ViewController.h"

#import <opencv/cv.h>

@implementation BobSupport1ViewController

@synthesize imageView;
@synthesize saveButton;

#pragma mark my code

- (IBAction)loadPic:(id)sender {
	// TODO use UIImagePickerController test to see if we can load from gallery, take photo, etc
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Where is your BoB™?" 
			delegate:self 
			cancelButtonTitle:@"Cancel" 
			destructiveButtonTitle:nil 
			otherButtonTitles:@"Take photo", @"Load from gallery", nil];
	
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	[actionSheet showInView: self.view];
	[actionSheet release];
}

- (IBAction)savePic:(id)sender {
	[self showProgressIndicator:@"Saving"];
	UIImageWriteToSavedPhotosAlbum(imageView.image, self, @selector(finishUIImageWriteToSavedPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
}


- (void)finishUIImageWriteToSavedPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	[self hideProgressIndicator];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	// sanity check 
	if (buttonIndex > 1) return;
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	// take photo
	if (buttonIndex == 0)
		picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	// load from gallery
	else if (buttonIndex == 1)
		picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.delegate = self;
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	imageView.image = [info valueForKey:UIImagePickerControllerOriginalImage];
	[self showProgressIndicator:@"Detecting"];
	[self performSelectorInBackground:@selector(opencvFaceDetect:) withObject:nil];
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}

#pragma mark stolen code

// STOLEN from http://github.com/niw/iphone_opencv_test
// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
	CGImageRef imageRef = image.CGImage;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
	
	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, ret, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);
	
	return ret;
}

// modified a bit...
- (void) opencvFaceDetect:(UIImage *) overlayImage {
	if(imageView.image) {
		cvSetErrMode(CV_ErrModeParent);
		
		IplImage *image = [self CreateIplImageFromUIImage:imageView.image];
		
		// Scaling down
		IplImage *small_image = cvCreateImage(cvSize(image->width/2,image->height/2), IPL_DEPTH_8U, 3);
		cvPyrDown(image, small_image, CV_GAUSSIAN_5x5);
		int scale = 2;
		
		// Load XML
		NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade" ofType:@"xml"];
		CvHaarClassifierCascade* cascade = (CvHaarClassifierCascade*)cvLoad([path cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, NULL);
		CvMemStorage* storage = cvCreateMemStorage(0);
		
		// Detect faces and draw rectangle on them
		CvSeq* faces = cvHaarDetectObjects(small_image, cascade, storage, 1.2f, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(20, 40));
		cvReleaseImage(&small_image);
		
		// Create canvas to show the results
		CGImageRef imageRef = imageView.image.CGImage;
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef contextRef = CGBitmapContextCreate(NULL, imageView.image.size.width, imageView.image.size.height,
														8, imageView.image.size.width * 4,
														colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
		CGContextDrawImage(contextRef, CGRectMake(0, 0, imageView.image.size.width, imageView.image.size.height), imageRef);
		
		
		// crop the image
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		if (faces->total > 0) {
			/* croppy crop
			CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, 0);
			CGRect face_rect = CGContextConvertRectToDeviceSpace(contextRef, CGRectMake(cvrect.x * scale, cvrect.y * scale, cvrect.width * scale, cvrect.height * scale));
			NSLog(@"cvrect: %d x %d", cvrect.width * scale, cvrect.height * scale);
			NSLog(@" x = %d, y = %d", cvrect.x * scale, cvrect.y * scale);
			CGImageRef original = CGBitmapContextCreateImage(contextRef);
			NSLog(@"original: %d x %d", CGImageGetWidth(original), CGImageGetHeight(original));
			CGImageRef cropped = CGImageCreateWithImageInRect(original, face_rect);
			NSLog(@"cropped: %d x %d", CGImageGetWidth(cropped), CGImageGetHeight(cropped));
			UIImage *uiimg = [UIImage imageWithCGImage:cropped];
			NSLog(@"uiimg: %d x %d", uiimg.size.width, uiimg.size.height);
			imageView.image = uiimg;
			 */
			
			CGContextSetLineWidth(contextRef, 10);
			CGContextSetRGBStrokeColor(contextRef, 0.0, 0.0, 1.0, 0.5);
			
			// Draw results on the image
			NSLog(@"Found %d faces", faces->total);
			for (int i = 0; i < faces->total; i++) {
				NSLog(@"Found a face, %d", i);
				CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, i);
				CGRect face_rect = CGContextConvertRectToDeviceSpace(contextRef, CGRectMake(cvrect.x * scale, cvrect.y * scale, cvrect.width * scale, cvrect.height * scale));
				
				CGContextStrokeRect(contextRef, face_rect);
			}
			imageView.image = [UIImage imageWithCGImage:CGBitmapContextCreateImage(contextRef)];
		}
		
		else {
			NSLog(@"detected no faces");
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"BoB™ detection" message:@"Unable to find BoB™ indicator panel, try taking another photo." delegate:self
										cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
			[alert show];
			
		}
		[pool release];
		
		CGContextRelease(contextRef);
		CGColorSpaceRelease(colorSpace);
		
		cvReleaseMemStorage(&storage);
		cvReleaseHaarClassifierCascade(&cascade);

		[self hideProgressIndicator];
	}
}


- (UIImage *)scaleAndRotateImage:(UIImage *)image {
	static int kMaxResolution = 640;
	
	CGImageRef imgRef = image.CGImage;
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > kMaxResolution || height > kMaxResolution) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = kMaxResolution;
			bounds.size.height = bounds.size.width / ratio;
		} else {
			bounds.size.height = kMaxResolution;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) {
		case UIImageOrientationUp:
			transform = CGAffineTransformIdentity;
			break;
		case UIImageOrientationUpMirrored:
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
		case UIImageOrientationDown:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
		case UIImageOrientationLeftMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationLeft:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationRightMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		case UIImageOrientationRight:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	} else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageCopy;
}

- (void)showProgressIndicator:(NSString *)text {
	//[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	self.view.userInteractionEnabled = FALSE;
	if(!progressHUD) {
		CGFloat w = 160.0f, h = 120.0f;
		progressHUD = [[UIProgressHUD alloc] initWithFrame:CGRectMake((self.view.frame.size.width-w)/2, (self.view.frame.size.height-h)/2, w, h)];
		[progressHUD setText:text];
		[progressHUD showInView:self.view];
	}
}

- (void)hideProgressIndicator {
	//[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.view.userInteractionEnabled = TRUE;
	if(progressHUD) {
		[progressHUD hide];
		[progressHUD release];
		progressHUD = nil;
		
//		AudioServicesPlaySystemSound(alertSoundID);
	}
}


#pragma mark auto-generated code

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
	[imageView dealloc];
}

@end
