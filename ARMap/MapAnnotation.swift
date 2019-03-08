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

    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        
        super.init()
    }
}
