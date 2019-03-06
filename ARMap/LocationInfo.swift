//
//  LocationInfo.swift
//  ARMap
//
//  Created by David on 2019-03-06.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation
import MapKit

struct LocationInfo{
    var pathParts: [[CLLocationCoordinate2D]]
    var steps: [MKRoute.Step]
    var destinationLocation: CLLocation!
}
