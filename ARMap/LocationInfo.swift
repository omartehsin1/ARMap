//
//  LocationInfo.swift
//  ARMap
//
//  Created by David Gonzalez, Van Luu, Omar Tehsin on 2019-03-05.
//  Copyright © 2019 David Gonzalez, Van Luu, Omar Tehsin. All rights reserved.
//

import Foundation
import MapKit

struct LocationInfo{
    var pathParts: [[CLLocationCoordinate2D]]
    var steps: [MKRoute.Step]
    var destinationLocation: CLLocation!
}
