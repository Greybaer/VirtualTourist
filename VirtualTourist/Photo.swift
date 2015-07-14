//
//  Photo.swift
//  
//
//  Created by Greybear on 6/15/15.
//
//

import UIKit
import CoreData

//@objc(Photo)

class Photo : NSManagedObject{
    
    struct Keys {
        static let Id = "id"
        static let Url = "url_m"
    }
    
    @NSManaged var id: String
    @NSManaged var url: String
    @NSManaged var loaded: Bool
    @NSManaged var location: Pin
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }//override

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
    
        //CoreData entity registration
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Dictionary
        //id from Flickr
        id = dictionary[Keys.Id] as! String
        //path to inage location on the intarwebs
        url = dictionary[Keys.Url] as! String
        //Is the image saved onto disk yet?
        loaded = false
    }//init
    
    // Delete the file from the documents directory when necessary - DUH!
    override func prepareForDeletion() {
        super.prepareForDeletion()
        self.image = nil
    }
    
    var image: UIImage? {
        get {
            return VTClient.Cache.imageCache.imageWithIdentifier(id)
        }
        set {
            VTClient.Cache.imageCache.storeImage(newValue, withIdentifier: id)
        }
    }

}//Photo

