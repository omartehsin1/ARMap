//
//  MapAnnotation.swift
//  ARMap
//
//  Created by David Gonzalez, Van Luu, Omar Tehsin on 2019-03-05.
//  Copyright © 2019 David Gonzalez, Van Luu, Omar Tehsin. All rights reserved.
//

import Foundation
import MapKit

final class MapAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D

    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        
        super.init()
    }
}
