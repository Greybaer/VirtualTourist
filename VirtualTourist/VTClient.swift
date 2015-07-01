//
//  VTClient.swift
//  VirtualTourist
//
// Virtual Tourist Network/Convenience/Helper functions
//  Created by Greybear on 6/9/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData
import CoreLocation

class VTClient: NSObject {

    //Variables

    //The URL Session
    var session: NSURLSession
    
    //temporary photo array for testing collection view
    var photoList = [String]()
    
    //Shorthand for the CoreData context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    //***************************************************
    //Create a shared session for the NSURLSession calls
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }//init

    //***************************************************
    // Shared Object Methods
    
    //Shared Instance
    class func sharedInstance() -> VTClient {
    
        struct Singleton {
            static var sharedInstance = VTClient()
        }
    
        return Singleton.sharedInstance
    }//sharedInstance
    
    //Shared Image Cache
    struct Cache {
        static let imageCache = ImageCache()
    }
    
    //***************************************************
    // Network Functions
    //***************************************************
 
    //***************************************************
    // GetFlickrData - Pull photos based on pin selection
    func getFlickrData(pin: Pin, completionhandler: (success: Bool, error: String?) -> Void){
        //The arguments we need to create a Flickr request
        let methodArguments = [
            "method": Constants.METHOD_NAME,
            "api_key": Constants.API_KEY,
            "extras": Constants.EXTRAS,
            "format": Constants.DATA_FORMAT,
            "nojsoncallback": Constants.NO_JSON_CALLBACK,
            "per_page": Constants.PER_PAGE,
            "accuracy": Constants.ACCURACY,
            "lat": pin.latitude as Double,
            "lon": pin.longitude as Double,
            "page": pin.page as Int
        ]
        
        
        //Build a request string and a session
        let session = NSURLSession.sharedSession()
        let urlString = Constants.BASE_URL + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        //println(request)
        
        //println("Pin values entering FlickrData: \(pin.latitude)|\(pin.longitude)|\(pin.page)|\(pin.lastPage)")
        //println("Downloading from page \(pin.page) in GetFlickrData()")
        
        //See what we get back
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let taskError = downloadError {
                //Fail - the calling code will display the errDialog()
                completionhandler(success: false, error: "Unable to complete data transfer")
            }
            else {
                //Success - save the data in struct for collection display
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                //println("Parsed result: \(parsedResult)")
                //Create a dictionary from the results with Key:Value pairs
                if let dictionary = parsedResult.valueForKey("photos") as? [String:AnyObject]{
                    //Save the total number of pages so we can use that when loading new collections
                    var pages = dictionary["pages"] as! Int
                    //Drop the value into the pin object
                    //println("Pin values in FlickrData: \(pin.latitude)|\(pin.longitude)|\(pin.page)|\(pin.lastPage)")
                    pin.lastPage = pages
                    //and save the context
                    dispatch_async(dispatch_get_main_queue()) {
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                    //println("Total pages: \(pages)")
                    var photoCount = 0
                    //Check to see that we actually got photos to show
                    if let total =  dictionary["total"] as? String{
                        photoCount = (total as NSString).integerValue
                    }
                    //If we have photos to show, load em up
                    if photoCount > 0{
                        if let photoArray = dictionary["photo"] as? [[String:AnyObject]]{
                            //println(photoArray)
                            //loop through each entry, grab the url and append it to photo list array (for now)
                            for photog in photoArray{
                                //Make sure there is a valid string there
                                if let url = photog["url_m"] as? String{
                                    //This will get removed once the photo objects are working
                                    //self.photoList.append(url)
                                    //create a dictionary
                                    let dictionary: [String : AnyObject] = [
                                        Photo.Keys.Url : photog["url_m"] as! String,
                                        Photo.Keys.Id : photog["id"] as! String
                                    ]
                                    //and init a new Photo object with the data
                                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                                    //Set the location info for the photo, which should populate the phots array in Pin?
                                    photo.location = pin
                                    dispatch_async(dispatch_get_main_queue()) {
                                        CoreDataStackManager.sharedInstance().saveContext()
                                    }
                                }else{
                                    //skip it
                                    continue
                                }
                                //println("Photo URLs processed: \(self.photoList.count)")
                            }
                            //return success
                            //println("Leaving getFlickrData")
                           completionhandler(success: true, error: nil)
                        }//photoArray
                        else{
                            completionhandler(success: false, error: "Error Loading Photos")
                        }//photo retrieval failure
                    }else{//photoCount
                    //No photos to load. Nice alert for the folks, Rollo...
                        completionhandler(success: false, error: "No Flickr Images Found for Location")
                    }//no photo dialog
                }//dictionary
            }//top if/else
        }//session Data
        task.resume()
    }//getFlickrData
    
    //***************************************************
    // Get an image from the URL
    func taskForImage(filePath:String, completionHandler :(imageDate:NSData?, error:NSError?) -> Void)-> NSURLSessionTask {
        
        //Create the request
        let url = NSURL(string: filePath)!
        let request = NSURLRequest(URL: url)
        
        // Make the request
        let task = session.dataTaskWithRequest(request) {
            data, response, downloadError in
            
            if let error = downloadError {
                 completionHandler(imageDate: data, error: error)
            } else {
                completionHandler(imageDate: data, error: nil)
            }
        }
        task.resume()
        return task
        
    }

    
    //***************************************************
    // Helper Functions
    //***************************************************

    //***************************************************
    // Given a dictionary of parameters,
    // convert to a string for a url
    // GB - Lifted from the original class app example
    func escapedParameters(parameters: [String : AnyObject]) -> String {
    
        var urlVars = [String]()
    
        for (key, value) in parameters {
        
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
        
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
    
    return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }//escapedParameters
    
    //***************************************************
    // Create an AlertView to display an error message
    func errorDialog(viewController:UIViewController, errTitle: String, action: String, errMsg:String) -> Void{
        let alertController = UIAlertController(title: errTitle, message: errMsg, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: action, style: UIAlertActionStyle.Default, handler: nil)
        alertController.addAction(alertAction)
        viewController.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //***************************************************
    // Get a pin object based on a set of coordinates
    func getMapLocationFromAnnotation(annotation:MKAnnotation, pins: [Pin]!) -> Pin? {
        
        // Fetch exact map location from annotation view
        let filteredPins =   pins.filter {
            $0.latitude == annotation.coordinate.latitude &&
                $0.longitude == annotation.coordinate.longitude
        }
        if filteredPins.count > 0 {
            return filteredPins.last!
        }
        return nil
    }


    
}//VTClient
