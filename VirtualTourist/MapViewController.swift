//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Greybear on 6/16/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//
//***************************************************
// By far the most difficult app exercise for me!
// A big THANK YOU to Chrisna, AyushUdacity, and all the others
// who offered suggestions and encouragement on the discussion board.
//
// Also, a big shout out and thank you to Shruti Pawar for the example of her
// CoreData code. In rummaging through discussions about my CoreData problems someone
// referenced her code, and I checked it out to examine it. Looking at her example helped me
// contextualize CoreData and got me past a really nasty block. 

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longpress: UILongPressGestureRecognizer!
    
    
    //variables
    //Shorthand for the CoreData context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    //Map Dictionary values for saving region
    struct Map {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
        static let mapFileName = "mapRegionArchive"
    }
    
    //Path to the save location of the map region data
    var mapRegionFilePath: String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent(Map.mapFileName).path!
    }
    
    //Annotation array
    var annotations = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //we're our own map delegate
        mapView.delegate = self
        //Restore the region if saved
        restoreMapRegion(false)

        //If we have persisted annotation coords load em.
        loadPins()
        //println("Loaded Pins")
    }//viewDidLoad
    
    override func viewWillAppear(animated: Bool) {
        //Hide the nav bar
        self.navigationController?.navigationBarHidden = true
        
    }//viewWillAppear
    
    override func viewWillDisappear(animated: Bool) {
        //Re-show the nav bar before disappearing. Failing to do so makes the back button invisible!
        self.navigationController?.navigationBarHidden = false

    }
    
    //***************************************************
    // Save the mapRegion with NSKeyedArchiver
    func saveMapRegion() {
        let mapRegionDictionary = [
            Map.Latitude : mapView.region.center.latitude,
            Map.Longitude : mapView.region.center.longitude,
            Map.LatitudeDelta : mapView.region.span.latitudeDelta,
            Map.LongitudeDelta : mapView.region.span.longitudeDelta
        ]
        NSKeyedArchiver.archiveRootObject(mapRegionDictionary, toFile: mapRegionFilePath)
    }
    
    //***************************************************
    // Restore the map to the previously saved region
    func restoreMapRegion(animated: Bool) {
        if let mapRegionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(mapRegionFilePath) as? [String:AnyObject] {
            
            let longitude = mapRegionDictionary[Map.Longitude] as! CLLocationDegrees
            let latitude = mapRegionDictionary[Map.Latitude] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = mapRegionDictionary[Map.LongitudeDelta] as! CLLocationDegrees
            let latitudeDelta = mapRegionDictionary[Map.LatitudeDelta] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: animated)
        }
    }


    //***************************************************
    // Action Methods
    //***************************************************

    //***************************************************
    // Long Press - User wants to drop a pin at the location
    @IBAction func tapHold(sender: AnyObject) {
        //Create an annotation
        var annotation = MKPointAnnotation()
        //and a coordinate object
        var coordinates: CLLocationCoordinate2D!
        //new page please
        var pageNumber = 0
        
        //Respond once the hold has ended
        if longpress.state == UIGestureRecognizerState.Ended{
            //println("Tap/Hold end recognized")
            //Get the tap location
            var touchPoint = longpress.locationOfTouch(0, inView: mapView)
            //Get the coordinates of the touch
            coordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            //This method avoids swapping the coords!
            annotation.coordinate = coordinates
            self.mapView.addAnnotation(annotation)
            
            //Now save the annotation coordinate to the Pin array
            //Maybe we'll need to check to see if an exact duplicate pin already exists? Later!
            
            //Create a new Pin dictionary
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude : coordinates.latitude as Double,
                Pin.Keys.Longitude : coordinates.longitude as Double,
                Pin.Keys.Page : pageNumber    //new pin means by definition we've never loaded any photos
            ]//dictionary
            
           
            //...and use it to create a new Pin object
            let newPin = Pin(dictionary: dictionary, context: self.sharedContext)
            //Add it to the array here as well
            self.annotations.append(newPin)
            //Save to the context
            CoreDataStackManager.sharedInstance().saveContext()
        }//longpress
    }//tapHold

    //***************************************************
    // Delegate Methods
    //***************************************************
    
    //***************************************************
    // User changed the map region, so save it
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    

    //***************************************************
    // Re-use method for displaying pins -
    // ripped from the PinSample code. I have plenty to do without re-inventing the wheel
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinColor = .Red
       }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }//viewForAnnotation
    
    //***************************************************
    // User tapped an annotation
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        //unselect the pin so we can re-select it later if desired
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        
        //Segue to Collection View
        //grab the reference
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("CollectionViewController") as! CollectionViewController
        //and pass the selected annotation for display on the collection view maplet
        //TODO: Remove this and use the pin we pass!
        //controller.photoAnnotation = view.annotation
        controller.annotation = VTClient.sharedInstance().getMapLocationFromAnnotation(view.annotation, pins: annotations)

        //and show it
        self.navigationController?.pushViewController(controller,animated: true)
        
    }//didSelectAnnotation

    //***************************************************
    // Helper Methods
    //***************************************************

    //***************************************************
    // loadPins - Load pin data from CoreData and display them
    func loadPins(){
        //error object if fetch fails
        let error: NSErrorPointer = nil
        //build the fetchRequest
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        //If there are results create pins. If not move on
        if let results = sharedContext.executeFetchRequest(fetchRequest, error: error) {
            if error != nil{
                //puke up an error for now
                //TODO: Nice alertview
                println("Error retrieving annotations!")
            }else{
                //Kludge alert! - I deal with the data without casting because I get data errors when trying to work with [Pin] objects
                //println("Annotations retrieved: \(results!.count)")
                //So, we iterate through the results and pull out the coordinates...
                annotations = results as! [Pin]
                if annotations.count > 0{
                    for p in annotations{
                        //create an annotation object
                        var pinAnnotation = MKPointAnnotation()
                        //and populate it with the data from results
                        pinAnnotation.coordinate = CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)
                        //and display it on the map
                        self.mapView.addAnnotation(pinAnnotation)
                    }
                }//for loop
            }//if/else
        }//fetchRequest
    }//loadPins
    

}

