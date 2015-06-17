//
//  Photo.swift
//  
//
//  Created by Greybear on 6/15/15.
//
//

import UIKit
import CoreData

@objc(Photo)

class Photo : NSManagedObject{
    
    struct Keys {
        static let Url = "url"
    }
    
    @NSManaged var url: String
    @NSManaged var location: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
    
        //CoreData entity registration
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Dictionary
        url = dictionary[Keys.Url] as! String
    }
}//class


//TODO: create an image function ala FavoriteActors to stor the images.String
//This should speed up display of previously accessed collections
