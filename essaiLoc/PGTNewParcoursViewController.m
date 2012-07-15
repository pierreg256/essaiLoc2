//
//  PGTNewParcoursViewController.m
//  essaiLoc
//
//  Created by famille on 11/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//

#import "PGTNewParcoursViewController.h"
#import "PGTDocument.h"
#import "PGTData.h"
#import "UIImageExtras.h"
#import "DDLog.h"

@interface PGTNewParcoursViewController ()
    - (void)configureView;
@end

@implementation PGTNewParcoursViewController {
    UIImagePickerController * _picker;
}

@synthesize mapView = _mapView, crumbs = _crumbs, crumbView = _crumbView;

@synthesize doc = _doc;
@synthesize imageView = _imageView;
@synthesize delegate = _delegate;

#pragma mark - Managing the detail item

- (void)setDoc:(id)newDoc
{
    if (_doc != newDoc) {
        _doc = newDoc;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    self.title = [self.doc description];
    if (self.doc.photo) {
        self.imageView.image = self.doc.photo;
    } else {
        self.imageView.image = [UIImage imageNamed:@"defaultImage.png"];
    }
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //self.mapView.showsUserLocation = NO;
    //self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.delegate = self;
    
    // Note: we are using Core Location directly to get the user location updates.
    // We could normally use MKMapView's user location update delegation but this does not work in
    // the background.  Plus we want "kCLLocationAccuracyBestForNavigation" which gives us a better accuracy.
    //
    self.locationManager = [[CLLocationManager alloc] init] ;
    self.locationManager.delegate = self; // Tells the location manager to send updates to this object
    
    // By default use the best accuracy setting (kCLLocationAccuracyBest)
	//
	// You mau instead want to use kCLLocationAccuracyBestForNavigation, which is the highest possible
	// accuracy and combine it with additional sensor data.  Note that level of accuracy is intended
	// for use in navigation applications that require precise position information at all times and
	// are intended to be used only while the device is plugged in.
    //
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //[self.locationManager startUpdatingLocation];
    
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
    self.navigationItem.leftBarButtonItem = backButtonItem;
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    [self configureView];


}

- (void)viewDidUnload
{
    DDLog(@"");
    [self setImageView:nil];
    self.locationManager=nil;
    
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Callbacks

- (void)imageTapped:(UITapGestureRecognizer *)recognizer {
    if (!_picker) {
        _picker = [[UIImagePickerController alloc] init];
        _picker.delegate = self;
        _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _picker.allowsEditing = NO;
    }
    
    [self presentViewController:_picker animated:YES completion:nil];
}

- (void)doneTapped:(id)sender {
    
    NSLog(@"Closing %@...", self.doc.fileURL);
    
    [self.doc saveToURL:self.doc.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        [self.doc closeWithCompletionHandler:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!success) {
                    NSLog(@"Failed to close %@", self.doc.fileURL);
                    // Continue anyway...
                }
                
                [self.delegate detailViewControllerDidClose:self];
            });
        }];
    }];
    
}

#pragma mark - UIImagePickeerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CGSize mainSize = self.view.bounds.size; //self.imageView.bounds.size;
    UIImage *sImage = [image imageByBestFitForSize:mainSize]; //[image scaleToFitSize:mainSize];
    
    self.doc.photo = sImage;
    self.imageView.image = sImage;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark -
#pragma mark CLLocationManager delegate methods
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"locationManagerDidUpdateToLocation");
    if (newLocation)
    {
		// make sure the old and new coordinates are different
        if ((oldLocation.coordinate.latitude != newLocation.coordinate.latitude) &&
            (oldLocation.coordinate.longitude != newLocation.coordinate.longitude))
        {
            if (!self.crumbs)
            {
                DDLog(@"creating first crumb");
                // This is the first time we're getting a location update, so create
                // the CrumbPath and add it to the map.
                //
                self.crumbs = [[PGTPath alloc] initWithCenterCoordinate:newLocation.coordinate];
                [self.mapView addOverlay:self.crumbs];
                
                // On the first location update only, zoom map to user location
                MKCoordinateRegion region =
                MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
                [self.mapView setRegion:region animated:YES];
            }
            else
            {
                DDLog(@"adding more crumbs");
                // This is a subsequent location update.
                // If the crumbs MKOverlay model object determines that the current location has moved
                // far enough from the previous location, use the returned updateRect to redraw just
                // the changed area.
                //
                // note: iPhone 3G will locate you using the triangulation of the cell towers.
                // so you may experience spikes in location data (in small time intervals)
                // due to 3G tower triangulation.
                //
                MKMapRect updateRect = [self.crumbs addCoordinate:newLocation.coordinate];
                
                if (!MKMapRectIsNull(updateRect))
                {
                    // There is a non null update rect.
                    // Compute the currently visible map zoom scale
                    MKZoomScale currentZoomScale = (CGFloat)(self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width);
                    // Find out the line width at this zoom scale and outset the updateRect by that amount
                    CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                    updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
                    // Ask the overlay view to update just the changed area.
                    [self.crumbView setNeedsDisplayInMapRect:updateRect];
                }
            }
        }
    }
}



#pragma mark -
#pragma mark MKMapView delegate methods
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if (!self.crumbView)
    {
        self.crumbView = [[PGTPathView alloc] initWithOverlay:overlay];
    }
    return self.crumbView;
}

/*
- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode != MKUserTrackingModeFollow) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    }
}
*/
@end
