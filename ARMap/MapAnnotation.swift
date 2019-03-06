//
//  MapAnnotation.swift
//  ARMap
//
//  Created by David on 2019-03-05.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation
import MapKit

final class MapAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    
    var title: String?
    
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, name: String) {
        self.coordinate = coordinate
        self.title = name
        self.subtitle =  "(\(coordinate.latitude),\(coordinate.longitude))"
        super.init()
    }
}
