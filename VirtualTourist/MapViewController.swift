//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Greybear on 6/16/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longpress: UILongPressGestureRecognizer!
    
    
    //variables
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //we're our own map delegate
        mapView.delegate = self
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
            println("Tap/Hold end recognized")
            //Get the tap location
            var touchPoint = longpress.locationOfTouch(0, inView: mapView)
            //Get the coordinates of the touch
            coordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            annotation.coordinate = coordinates
            self.mapView.addAnnotation(annotation)
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

