//
//  VTConstants.swift
//  VirtualTourist
//
//  Constant Values for Virtual Tourist
//  Created by Greybear on 6/9/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

extension VTClient{
    

    struct Constants{
        // constant info for Flickr API
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "215bab9264d94fa2f53a935fbd3183d6"
        static let EXTRAS = "url_m"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let PER_PAGE = 21    //3 rows across, 7 down. Always filling!
        static let ACCURACY = 6     //Results should be pertinent to the city wide location or better
    }//Constants

}//extension