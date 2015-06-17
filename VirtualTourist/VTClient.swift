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
import CoreLocation

class VTClient: NSObject {
    //***************************************************
    //Variables
    //***************************************************

    //The URL Session
    var session: NSURLSession
    //temporary photo array for testing collection view
    var photoList = [String]()

    //***************************************************
    //Create a shared session for the NSURLSession calls
    //***************************************************
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }//init

    //***************************************************
    // Shared Instance
    //***************************************************
    class func sharedInstance() -> VTClient {
    
        struct Singleton {
            static var sharedInstance = VTClient()
        }
    
        return Singleton.sharedInstance
    }//sharedInstance
    //***************************************************
    // Network Functions
    //***************************************************
    func getFlickrData(coords: CLLocationCoordinate2D, completionhandler: (success: Bool, error: String?) -> Void){
        //The arguments we need to create a Flickr request
        let methodArguments = [
            "method": Constants.METHOD_NAME,
            "api_key": Constants.API_KEY,
            "extras": Constants.EXTRAS,
            "format": Constants.DATA_FORMAT,
            "nojsoncallback": Constants.NO_JSON_CALLBACK,
            "per_page": Constants.PER_PAGE,
            "accuracy": Constants.ACCURACY,
            "lat": coords.latitude,
            "lon": coords.longitude,
            "page": 1   //TODO: Change this to accept passed argument for which page to grab
        ]
        
        //Build a request string and a session
        let session = NSURLSession.sharedSession()
        let urlString = Constants.BASE_URL + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        //println(request)
        
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
                    //Check to see that we actually got photos to show
                    var photoCount = 0
                    if let total =  dictionary["total"] as? String{
                        photoCount = (total as NSString).integerValue
                    }
                    //If we have photos to show, load em up
                    if photoCount > 0{
                        if let photoArray = dictionary["photo"] as? [[String:AnyObject]]{
                            //println(photoArray)
                            //loop through each entry, grab the url and append it to photo list array (for now)
                            for photo in photoArray{
                                //Make sure there is a valid string there
                                if let url = photo["url_m"] as? String{
                                    self.photoList.append(url)
                                }else{
                                    //skip it
                                    continue
                                }
                                println("Photo URLs processed: \(self.photoList.count)")
                            }
                            //return success
                            println("Leaving getFlickrData")
                            //fake a bad URL to test placeholder placement
                            //self.photoList[6] = ""
                            completionhandler(success: true, error: nil)
                        }//photoArray
                        else{
                            completionhandler(success: false, error: "Photo Count is Zero")
                        }//photo retrieval failure
                    }//photoCount
                }//dictionary
            }//top if/else
        }//session Data
        task.resume()
    }//getFlickrData
    
    //***************************************************
    // Helper Functions
    //***************************************************

    //***************************************************
    // Given a dictionary of parameters,
    // convert to a string for a url
    // GB - Lifted from the original class app example
    //***************************************************
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
    //***************************************************
    func errorDialog(viewController:UIViewController, errTitle: String, action: String, errMsg:String) -> Void{
        let alertController = UIAlertController(title: errTitle, message: errMsg, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: action, style: UIAlertActionStyle.Default, handler: nil)
        alertController.addAction(alertAction)
        viewController.presentViewController(alertController, animated: true, completion: nil)
    }

    
}//VTClient
