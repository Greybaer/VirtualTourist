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

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    //Outlets
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var staticMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var trashIcon: UIImageView!
    
    //Actions
    
    //Variables
    //This gets passed in by the segue
    var annotation: Pin!

    //Shorthand for the CoreData context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    //Keep track of selected cells for removal
    var selectedIndexes = [NSIndexPath]()

    //Keep track of how many cells have been loaded to determine
    //when to enable New Collection Button
    var cellCount = 0
    
    //Grab and save the value of the default tintcolor for the New Collection Button
    var defaultButtonColor: UIColor!
    
    //Indexes for batch operations using NSFetchController
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Grab and save the default tintcolot for the button
        defaultButtonColor = newCollectionButton.tintColor
        //We're our own map delegate
        staticMap.delegate = self
        //and our own collectionview delegate
        photoCollection.delegate = self
        //Disable the new collection button
        newCollectionButton.enabled = false
        // Start the fetched results controller

        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            //println("Error performing initial fetch: \(error)")
            VTClient.sharedInstance().errorDialog(self, errTitle: "Image Fetch Error", action: "OK", errMsg: "Error performing initial image fetch")

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
            //Increment the page number now to reflect we've loaded the first page
            //annotation.page++
            //Save the context to capture the page number
            CoreDataStackManager.sharedInstance().saveContext()
        }//if
        //println("Pin page is \(annotation.page) in ViewWillAppear()")
    }//viewWillAppear
    
 
    //***************************************************
    // Collection View Methods
    //***************************************************
    
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

    //***************************************************
    //Number of sections - superfluous?
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    //***************************************************
    //Number of photos
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return VTClient.sharedInstance().photoList.count
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        //println("number Of Cells: \(sectionInfo.numberOfObjects)")
        //Grab the number and save it for use in configureCell
        cellCount = sectionInfo.numberOfObjects
        return sectionInfo.numberOfObjects
    }
    
    //***************************************************
    //Populate the cells
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        //println("Entered cellForItem")
        //define a cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        //Functionality moved to configureCell
        configureCell(cell, atIndexPath: indexPath)
        configureToolbar()
        return cell
    }//cellForItemAtIndexPath
    
    //***************************************************
    // User selected a cell, so toggle for delete if required
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //println("Entering didSelectItemAtIndexPath")
        //define a cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        
        //Check for cell toggle condition
        if let index = find(selectedIndexes, indexPath){
            selectedIndexes.removeAtIndex(index)
        }else{
            selectedIndexes.append(indexPath)
        }
             
        //Force the cell to reload!
        var paths = [indexPath]
        photoCollection.reloadItemsAtIndexPaths(paths)
        
        //then configure the toolbar
        configureToolbar()
    }//didSelectItem
    
    //***************************************************
    // Configure the display view for the cell using fetchresultscontroller information
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
                    //println("Error loading Flickr image")
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.photo.image =  UIImage(named: "nophoto.png")
                        cell.cellSpinner.stopAnimating()
                    }//dispatch
                }
                if let imageData = data{
                    //We got an image, so grab it
                    let image = UIImage(data: imageData)
                    //Now update the cache to save it
                    photo.image = image
                    //And update the cell on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        //set the flag so we know it's on disk
                        photo.loaded = true
                        //set the image
                        cell.photo.image = image
                        //stop the spinner
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
            //Load the final resulting image
            cell.photo.image = cellImage
        if let index = find(selectedIndexes, indexPath){
            cell.photo.alpha = 0.5
        }else{
            cell.photo.alpha = 1.0
        }
     }//configureCell
    
    //***************************************************
    // Configure the appearance and function of each annotation as it's added
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinColor = .Green
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }//mapView - viewForAnnotation
 
  
    //***************************************************
    // Button Action method - Load new or delete photos
    @IBAction func newCollection(sender: UIBarButtonItem) {
        if !selectedIndexes.isEmpty{
            deleteSelected()
        }else{
            loadNewCollection()
        }
    }//newCollection
    
    //***************************************************
    // Delete selected photos
    func deleteSelected(){
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        selectedIndexes = [NSIndexPath]()
        configureToolbar()
    }//deleteSelected
    
    //***************************************************
    // Load a new Collection when the button is pressed
    func loadNewCollection(){
        //If we're here, the user has loaded at least one collection. Increment to get next page
        annotation.page++
        //Disable the button until the new photos are all loaded
        self.newCollectionButton.enabled = false
        //First, delete the old collection
        for photo in fetchedResultsController.fetchedObjects as! [Photo]{
            sharedContext.deleteObject(photo)
        }
        //Save the context - not sure this is needed, but shouldn't hurt
        //CoreDataStackManager.sharedInstance().saveContext()
        //println("Pin values exiting newCollection: \(annotation.latitude)|\(annotation.longitude)|\(annotation.page)|\(annotation.lastPage)")

        //Now got get a new collection
        //println("Pin page is \(annotation.page) in newCollection()")
        VTClient.sharedInstance().getFlickrData(annotation){(success, errorString) in
            if !success{
                VTClient.sharedInstance().errorDialog(self, errTitle: "Unable to Obtain Photo Data", action: "OK", errMsg: errorString!)
            }
        }//getFlickerData
        //And save
        dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }//loadnewCollection
    
    //***************************************************
    // Configure the toolbar for the function needed
    func configureToolbar(){
        if selectedIndexes.count > 0{
            newCollectionButton.tintColor = UIColor.redColor()
            newCollectionButton.title = "Delete Selected Photos"
            newCollectionButton.enabled = true
        }else{
            newCollectionButton.tintColor = defaultButtonColor
            newCollectionButton.title = "New Collection"
            //Check to see if the cells are loaded before enabling the button
            let photos = fetchedResultsController.fetchedObjects as! [Photo]
            let notLoaded = photos.filter{
                $0.loaded == false
            }
            if notLoaded.count > 0{
                newCollectionButton.enabled = false
            }else{
                newCollectionButton.enabled = true
            
            }
        }
    }//configureToolbar
    
    //***************************************************
    // Set the static map to the location passed in from the Map View
    func setStaticMap() {
        //Center the map on the location we care about
        let center = CLLocationCoordinate2DMake(self.annotation.latitude as Double, self.annotation.longitude as Double)
        //zoom the map region to the location
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
            //println("Item added")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Update:
            //println("Item updated")
            updatedIndexPaths.append(indexPath!)
            break
        case .Delete:
            //println("Item deleted")
            deletedIndexPaths.append(indexPath!)
            break
        default:
            break
        }
    }//controller (changed object)
    
    //***************************************************
    // Batch Process the changes
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        //println("in controllerDidChangeContent changes count: \(deletedIndexPaths.count) \(insertedIndexPaths.count)")
        
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
