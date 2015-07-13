//
//  ImageCache.swift
//  VirtualTourist
//
//  Functions to save/retrieve image data from disk 
//
//  Created by Greybear on 6/22/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

import UIKit


class ImageCache {
    
    private var memoryCache = NSCache()
    
    
    //***************************************************
    // Get a complete path for the documents directory
    func pathForIdentifier(identifier:String) -> String {
        let documentsDirectoryURL: NSURL =  NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first! as! NSURL
        
        let fullPathURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        return fullPathURL.path!
    }//pathForIdentifier

    //***************************************************
    // Retrieve image
    func imageWithIdentifier(identifier:String?) -> UIImage? {
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        var data: NSData?
        
        // Memory Cache
        if let image = memoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        //if not in Memory cache, then in Hard drive
        if let data = NSData(contentsOfFile: path) {
            let thisImage = UIImage(data: data)
            return UIImage(data: data)
        }
        return nil
    }//imageWithIdentifier
    
    //***************************************************
    // Store image
    func storeImage(image:UIImage?, withIdentifier identifier:String) {
        
        let path = pathForIdentifier(identifier)
        
        //Remove images from cache and hard disk?
        if image == nil {
            memoryCache.removeObjectForKey(path)
            NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
            //println("Image deleted")
            return
        }
        
        //No, cache it
        memoryCache.setObject(image!, forKey: path)
        
        // ...and save it
        let data = UIImagePNGRepresentation(image!)
        if  data.writeToFile(path, atomically: true) {
            //println("Image stored")
        }
    }//storeImage
    
}//ImageCache