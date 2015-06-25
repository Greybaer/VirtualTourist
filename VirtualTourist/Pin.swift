//
//  Pin.swift
//  VirtualTourist
//
//  Created by Greybear on 6/16/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

import CoreData

//@objc(Pin)

class Pin : NSManagedObject {
    //Key: Value pairs for dictionary
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Photos = "photos"
        static let Page = "page"
    }//Keys
    
    //Promote the variables to Core Data attributes
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    @NSManaged var page: Int
    
    //Standard Core Data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }//override init
    
    //our init method - allows insertion of data and initialization
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        //Get the entity information from the model file
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        //Call the super.init function to insert our object into the context
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Now init our properties from the dictionary
        //println("Got \(dictionary[Keys.Latitude] as! Double): \(dictionary[Keys.Longitude] as! Double)")
        //print ("NSManaged Values: lat - \(latitude):long - \(longitude)")
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude]as! Double
        page = dictionary[Keys.Page] as! Int
        //println("Saved: Lat \(latitude): Long \(longitude)")
        //println("dlat: \(dlat)")
    }//init
}//Pin
