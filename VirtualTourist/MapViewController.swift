//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Greybear on 6/16/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

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
    
    //Annotation array
    var annotations = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //we're our own map delegate
        mapView.delegate = self
        
        //If we have persisted annotation coords load em.
        //TODO: Make this a convenience function once it works
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        //If there are results create pins. If not move on
        if let results = sharedContext.executeFetchRequest(fetchRequest, error: error){
            if error != nil{
                //puke up an error for now
                //TODO: Nice alertview
                println("Error retrieving annotations!")
            }else{
                annotations = results as! [Pin]
                //println("Annotations retrieved: \(annotations.count)")
                //println(annotations)    //Mismatch error!
                //println(annotations[0].valueForKey("latitude") as! Double)  //mismatch error!
                for p in annotations{   //mismatch error!
                    var pinAnnotation = MKPointAnnotation()
                    pinAnnotation.coordinate.latitude = p.latitude as Double
                    pinAnnotation.coordinate.longitude = p.longitude as Double
                    self.mapView.addAnnotation(pinAnnotation)
                }//for loop
            }//if/else
        }//fetchRequest
        
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
                Pin.Keys.Longitude : coordinates.longitude as Double
            ]//dictionary
            
            //...and use it to create a new Pin object
            let newPin = Pin(dictionary: dictionary, context: sharedContext)
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
    }

}

