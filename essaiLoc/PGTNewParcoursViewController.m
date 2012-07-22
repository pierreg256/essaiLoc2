//
//  PGTNewParcoursViewController.m
//  essaiLoc
//
//  Created by famille on 11/07/12.
//  Copyright (c) 2012 Pierre Gilot. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "PGTNewParcoursViewController.h"
#import "PGTDocument.h"
#import "PGTData.h"
#import "UIImageExtras.h"
#import "DDLog.h"
#import "PGTPhotoAnnotation.h"

@interface PGTNewParcoursViewController ()

@property BOOL isTracking;
@property BOOL isAccurate;
@property (readonly) NSUInteger currentIndex;


- (void)configureView;
- (UIImage*)screenshot;

@end

@implementation PGTNewParcoursViewController {

    UIImagePickerController * _picker;
}

@synthesize mapView = _mapView, crumbPathView = _crumbPathView;

@synthesize doc = _doc;
@synthesize imageView = _imageView;
@synthesize delegate = _delegate;
@synthesize btnTracking = _btnTracking;

@synthesize isAccurate, isTracking;

#pragma mark - Helpers
-(NSUInteger) currentIndex
{
    return _doc.crumbPath.crumbs.count -1;
}

#pragma mark - Managing the detail item

- (void)setDoc:(id)newDoc
{
    if (_doc != newDoc) {
        _doc = newDoc;
        
        // Update the view.
        [self configureView];
    }
}

- (void)centerMyPosition:(BOOL)animated
{
    CLLocationDegrees north = ((CLLocation*)[self.doc.crumbPath.crumbs objectAtIndex:0]).coordinate.latitude;
    CLLocationDegrees south = ((CLLocation*)[self.doc.crumbPath.crumbs objectAtIndex:0]).coordinate.latitude;
    CLLocationDegrees east = ((CLLocation*)[self.doc.crumbPath.crumbs objectAtIndex:0]).coordinate.longitude;
    CLLocationDegrees west = ((CLLocation*)[self.doc.crumbPath.crumbs objectAtIndex:0]).coordinate.longitude;
    //DDLog(@"north:%f, south:%f, east:%f, west:%f", north, south, east, west);
    for (int i=1; i<self.doc.crumbPath.crumbs.count;i++) {
        north = MIN(north, ((CLLocation*)[self.doc.crumbPath.crumbs objectAtIndex:i]).coordinate.latitude);
        south = MAX(south, ((CLLocation*)[self.doc.crumbPath.crumbs objectAtIndex:i]).coordinate.latitude);
        east = MIN(east, ((CLLocation*)[self.doc.crumbPath.crumbs objectAtIndex:i]).coordinate.longitude);
        west = MAX(west, ((CLLocation*)[self.doc.crumbPath.crumbs objectAtIndex:i]).coordinate.longitude);
        //DDLog(@"north:%f, south:%f, east:%f, west:%f", north, south, east, west);
    }
    
    MKCoordinateSpan monSpan = MKCoordinateSpanMake(ABS(south-north)*1.2, ABS(west-east)*1.2);
    MKCoordinateRegion maRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake((north+south)/2, (east+west)/2), monSpan);
    [self.mapView setRegion:maRegion animated:animated];
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
    
    if (self.doc.crumbPath)
    {
        [self centerMyPosition:YES];
        [self.locationManager stopUpdatingLocation];
        [self.mapView setShowsUserLocation:NO];
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
        [self.mapView addOverlay:self.doc.crumbPath];
        [self.mapView addAnnotations:self.doc.annotations];
    } else {
        [self.mapView setShowsUserLocation:YES];
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
        [self.locationManager startUpdatingLocation];
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
    DDLog(@"");
    [super viewDidLoad];
    self.isAccurate=NO;
	// Do any additional setup after loading the view.
    //self.mapView.showsUserLocation = NO;
    //self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.delegate = self;
    
    // Note: we are using Core Location directly to get the user location updates.
    // We could normally use MKMapView's user location update delegation but this does not work in
    // the background.  Plus we want "kCLLocationAccuracyBestForNavigation" which gives us a better accuracy.
    //
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init] ;
        self.locationManager.delegate = self; // Tells the location manager to send updates to this object
    }
    
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
    
    //UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    //[self.view addGestureRecognizer:tapRecognizer];
    
    [self configureView];


}

- (void)viewDidUnload
{
    DDLog(@"");
    [self setImageView:nil];
    
    
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(documentStateChanged:)
                                                 name:UIDocumentStateChangedNotification
                                               object:self.doc];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)documentStateChanged:(NSNotification *)notificaiton {
    
    [self configureView];
    
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
    [self.locationManager stopUpdatingLocation];
    [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
    [self.mapView setShowsUserLocation: NO];
    
    
    if (self.doc.photo == nil) {
        [self centerMyPosition:NO];

        [self.doc setPhoto:[self screenshot]];
    }
    
/*
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
*/
    [self.doc closeWithCompletionHandler:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!success) {
                NSLog(@"Failed to close %@", self.doc.fileURL);
                // Continue anyway...
            }
            
            [self.delegate detailViewControllerDidClose:self];
        });
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
    
    //[self.doc addPhoto:sImage atIndex:self.currentIndex];
    PGTPhotoAnnotation* ann = [[PGTPhotoAnnotation alloc] initWithCoordinate2D:self.locationManager.location.coordinate withPhoto:sImage];
    ann.name = @"Photo";
    [self.doc addPhotoAnnotation:ann];
    [self.mapView addAnnotation:ann];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark -

#pragma mark -
#pragma mark CLLocationManager delegate methods
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if (newLocation)
    {
        if (!self.isAccurate){
            self.isAccurate = YES;
            return;
        }
        //DDLog(@"H: %f, V: %f", newLocation.horizontalAccuracy, newLocation.verticalAccuracy);
        // test that the horizontal accuracy does not indicate an invalid measurement
        if (newLocation.horizontalAccuracy < 0) return;
        // test the age of the location measurement to determine if the measurement is cached
        // in most cases you will not want to rely on cached measurements
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        if (locationAge > 5.0) return;
        
		// make sure the old and new coordinates are different
        if ((oldLocation.coordinate.latitude != newLocation.coordinate.latitude) &&
            (oldLocation.coordinate.longitude != newLocation.coordinate.longitude))
        {
            if (!_doc.crumbPath)
            {
                //DDLog(@"creating first crumb");
                // This is the first time we're getting a location update, so create
                // the CrumbPath and add it to the map.
                //
                //self.crumbs = [[PGTPath alloc] initWithCenterCoordinate:newLocation.coordinate];
                //[self.mapView addOverlay:self.crumbs];
                
                [_doc startCrumbPathWithLocation:newLocation];
                //_doc.crumbPath = [[PGTCrumbPath alloc] initWithCenterLocation:newLocation];
                [self.mapView addOverlay:_doc.crumbPath];
                
                // On the first location update only, zoom map to user location
                MKCoordinateRegion region =
                MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
                [self.mapView setRegion:region animated:YES];
            }
            else
            {
                //DDLog(@"adding more crumbs");
                // This is a subsequent location update.
                // If the crumbs MKOverlay model object determines that the current location has moved
                // far enough from the previous location, use the returned updateRect to redraw just
                // the changed area.
                //
                // note: iPhone 3G will locate you using the triangulation of the cell towers.
                // so you may experience spikes in location data (in small time intervals)
                // due to 3G tower triangulation.
                //
                //MKMapRect updateRect = [self.crumbs addCoordinate:newLocation.coordinate];
                MKMapRect updateRect = [_doc.crumbPath addLocation:newLocation];
               
                // ATTENTION A RAJOUTER UNE FOIS FINI!
                if (!MKMapRectIsNull(updateRect))
                {
                    // There is a non null update rect.
                    // Compute the currently visible map zoom scale
                    MKZoomScale currentZoomScale = (CGFloat)(self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width);
                    // Find out the line width at this zoom scale and outset the updateRect by that amount
                    CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                    updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
                    // Ask the overlay view to update just the changed area.
                    [self.crumbPathView setNeedsDisplayInMapRect:updateRect];
                }
                //
            }
        }
    }
}



#pragma mark -
#pragma mark MKMapView delegate methods
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if (!self.crumbPathView)
    {
        self.crumbPathView = [[PGTCrumbPathView alloc] initWithOverlay:overlay];
    }
    return self.crumbPathView;
}


- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MKUserTrackingModeNone) {
        self.btnTracking.tintColor = [UIColor whiteColor];
    } else {
        self.btnTracking.tintColor = [UIColor blueColor];
    }
}

- (MKAnnotationView*) mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString* photoAnnotationIdentifier = @"PGTPhotoAnnotation";
    
    if ([annotation isKindOfClass:[PGTPhotoAnnotation class]]) {
        MKPinAnnotationView* pinView = (MKPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:photoAnnotationIdentifier];
        if(!pinView) {
            MKAnnotationView* annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:photoAnnotationIdentifier];
            annotationView.canShowCallout = YES;
            annotationView.opaque = NO;
            annotationView.image = ((PGTPhotoAnnotation*)annotation).thumbnail; //[UIImage imageNamed:@"86-camera"];
            annotationView.layer.cornerRadius = 10;
            annotationView.layer.borderColor = (__bridge CGColorRef)([UIColor blueColor]);
            annotationView.layer.borderWidth = 2;
            
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            return annotationView;
        } else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    
    return nil;
}

#pragma mark - view actions
-(IBAction)addPhoto:(id)sender
{
    DDLog(@"current index : %d", self.currentIndex);
    if (!_picker) {
        _picker = [[UIImagePickerController alloc] init];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            _picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            _picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        _picker.delegate = self;
        _picker.allowsEditing = NO;
    }
    
    [self presentViewController:_picker animated:YES completion:nil];

}

-(IBAction)autoLocateSwitch:(id)sender
{
    DDLog(@"");
    if (self.mapView.userTrackingMode == MKUserTrackingModeNone) {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    }
}

-(IBAction)startStopMap:(id)sender
{
    DDLog(@"");
}

- (UIImage*)screenshot
{
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}
@end
