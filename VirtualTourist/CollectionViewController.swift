////
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Greybear on 6/8/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

import UIKit
import MapKit

class CollectionViewController: UIViewController, UICollectionViewDataSource, MKMapViewDelegate {

    //Outlets
    @IBOutlet weak var staticMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    //Variables
    //This gets passed in by the segue
    var photoAnnotation: MKAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        staticMap.delegate = self
        //Disable the new collection button
        //TODO: Check to see if a collection exists
        newCollectionButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        //Use the passed in annotation to mark, center and zoom the map
        //to the user's selected travel location
        let center = photoAnnotation.coordinate
        //zoom the map region to the location
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
        self.staticMap.setRegion(region, animated: true)
        //Add the annotation
        self.staticMap.addAnnotation(photoAnnotation)
        
        //Grab Flickr data for the selected location
        VTClient.sharedInstance().getFlickrData(photoAnnotation.coordinate){(success, errorString) in
            if !success{
                VTClient.sharedInstance().errorDialog(self, errTitle: "Unable to Obtain Photo Data", action: "OK", errMsg: errorString!)
            }else{
                println("getFlickrData completed")
                println("Count: \(VTClient.sharedInstance().photoList.count)")
                dispatch_async(dispatch_get_main_queue()) {
                    self.photoCollection.reloadData()
                }
            }//if/else
        }//getFlickerData

    }
    
    override func viewDidAppear(animated: Bool) {
    }

    //***************************************************
    // Collection View Methods
    //***************************************************
    
    // Layout the collection view so it's pretty
    // Thanks Mark & Jason!
    override func viewDidLayoutSubviews() {
        println("Entered viewDidLayoutSubviews")
        //1/3 of the screen
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        //Pad the sides a bit
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        //Vertical spacing ends up needing to be a bit thicker than interitemspacing
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 1
        //Now adjust the images size per cell to accomodate the spacing
        let width = floor((self.photoCollection.frame.size.width/3) - 5)
        layout.itemSize = CGSize(width: width, height: width)
        //println("Image size \(width) X \(width)")
        photoCollection.collectionViewLayout = layout
    }

    
    //Number of photos
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VTClient.sharedInstance().photoList.count
    }
    
    //Populate the cells
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        //println("Entered cellForItem")
        let photo_url = VTClient.sharedInstance().photoList[indexPath.row]
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        //Start the spinner
        //cell.backgroundColor = UIColor.grayColor()
        dispatch_async(dispatch_get_main_queue()) {
            cell.photo.image = UIImage(named: "placeholder.png")
            cell.cellSpinner.startAnimating()
        }
        //Now use the url to get image data in the background
        let priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            let imageURL = NSURL(string: photo_url)
            if let imageData = NSData(contentsOfURL: imageURL!){
                dispatch_async(dispatch_get_main_queue()) {
                    cell.photo.image = UIImage(data: imageData)
                    cell.cellSpinner.stopAnimating()
                }
            }else{
                //Pop in aplaceholder pic to note an error loading the picture
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    cell.photo.image =  UIImage(named: "nophoto.png")
                    cell.cellSpinner.stopAnimating()
                }
            }//if/else
        }//background image load
        return cell
    }//cellForItem
    
    //***************************************************
    // Configure the appearance and function of each annotation as it's added
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
    }//mapView - viewForAnnotation
    

}
