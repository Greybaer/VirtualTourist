////
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Greybear on 6/8/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class CollectionViewController: UIViewController, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    //Outlets
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var staticMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    
    //Variables
    //This gets passed in by the segue
    //var photoAnnotation: MKAnnotation!
    var annotation: Pin!

    //Shorthand for the CoreData context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    //Keep track of selected cells for removal
    var selectedIndexes = [NSIndexPath]()

    //Indexes for batch operations using NSFetchController
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //We're our own map delegate
        staticMap.delegate = self
        //Disable the new collection button
        newCollectionButton.enabled = false
        // Start the fetched results controller

        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            println("Error performing initial fetch: \(error)")
        }
        fetchedResultsController.delegate = self

        
    }
    
    override func viewWillAppear(animated: Bool) {
        //Use the passed in annotation to mark, center and zoom the map
        //to the user's selected travel location
        setStaticMap()
        
        //Determine whether we have to load photos
        if annotation.photos.isEmpty{ //Yes, do it
            VTClient.sharedInstance().getFlickrData(annotation){(success, errorString) in
                if !success{
                    VTClient.sharedInstance().errorDialog(self, errTitle: "Unable to Obtain Photo Data", action: "OK", errMsg: errorString!)
                }
            }//getFlickerData
            //Increment the page number now. If we need to load a new collection we're pre-set
            annotation.page++
            //Save the context to capture the page number
            CoreDataStackManager.sharedInstance().saveContext()
        }//if
    }//viewWillAppear
    
    override func viewDidAppear(animated: Bool) {
    }

    //***************************************************
    // Collection View Methods
    //***************************************************
    
    // Layout the collection view so it's pretty
    // Thanks Mark & Jason!
    override func viewDidLayoutSubviews() {
        //println("Entered viewDidLayoutSubviews")
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

    //Number of sections - superfluous?
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    //Number of photos
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return VTClient.sharedInstance().photoList.count
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        println("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    //Populate the cells
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        println("Entered cellForItem")

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        //Functionality moved to configureCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }//cellForItemAtIndexPath
    
    func configureCell(cell:CollectionViewCell, atIndexPath indexPath:NSIndexPath) {
        //Grab the photo object
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        //Default to a placeholder iumage
        var cellImage = UIImage(named: "placeholder.png")
        //Image saved? Drop it in and go
        if photo.image != nil{
                //replace the default with the cached image
                cellImage = photo.image
        }else{
            //Start the spinner
            cell.cellSpinner.startAnimating()
            //Start downloading in the background
            let task = VTClient.sharedInstance().taskForImage(photo.url) {data, error in
                if let loadError = error{
                    println("Error loading Flickr image")
                    cell.cellSpinner.stopAnimating()
                }
                if let imageData = data{
                    //We got an image, so grab it
                    let image = UIImage(data: imageData)
                    //Now update the cache to save it
                    photo.image = image
                    //And update the cell on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.photo.image = image
                        cell.cellSpinner.stopAnimating()
                        //Save the context
                        CoreDataStackManager.sharedInstance().saveContext()
                    }//dispatch
                }else{
                    //Pop in a placeholder pic to note an error loading the picture
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.photo.image =  UIImage(named: "nophoto.png")
                        cell.cellSpinner.stopAnimating()
                    }//dispatch
                }//if/else
            }//task
            //If the user has scrolled the cell out of sight, skip the update
            cell.cancelTaskOnReuse = task
        }//if/else
        //Drop in the image
        dispatch_async(dispatch_get_main_queue()) {
            cell.photo.image = cellImage
        }//dispatch
    }//configureCell
    
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
    
    //***************************************************
    // Set the static map to the location passed in from the Map View
    func setStaticMap() {
        //Center the map on the location we care about
        let center = CLLocationCoordinate2DMake(self.annotation.latitude as Double, self.annotation.longitude as Double)        //zoom the map region to the location
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
        self.staticMap.setRegion(region, animated: true)
        //Add the annotation
        var pin = MKPointAnnotation()
        pin.coordinate = center
        self.staticMap.addAnnotation(pin)
    }//setStaticMap

    //***************************************************
    // CoreData Methods
    //***************************************************

    //***************************************************
    // fetchedRequestController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.annotation)
        let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchResultController
        }()//fetchedResultController
    
    //***************************************************
    // Content is going to change
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }//controllerWillChangeContent
    
    //***************************************************
    // Controller changed something - save the changes for batch processing
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            println("Item added")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Update:
            println("Item updated")
            updatedIndexPaths.append(indexPath!)
            break
        case .Delete:
            println("Item deleted")
            deletedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }//controller (changed object)
    
    //***************************************************
    // Batch Process the changes
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        println("in controllerDidChangeContent changes count: \(deletedIndexPaths.count) \(insertedIndexPaths.count)")
        
        photoCollection.performBatchUpdates({ () -> Void in
            for indexPath in self.insertedIndexPaths {
                self.photoCollection.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoCollection.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.photoCollection.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }//controllerDidChangeContent



}//class
