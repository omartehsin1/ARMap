//
//  MapExtension.swift
//  ARMap
//
//  Created by David on 2019-03-05.
//  Copyright © 2019 David. All rights reserved.
//

import MapKit

protocol Mapable: class  {
    var myLocation: CLLocation! { get set }
    var mapView: MKMapView! { get set }
}

extension Mapable {
    
    func centerMapInInitialCoordinates() {
        if myLocation != nil {
            DispatchQueue.main.async {
                self.mapView.setCenter(self.myLocation.coordinate, animated: true)
                let latDelta: CLLocationDegrees = 0.005
                let lonDelta: CLLocationDegrees = 0.005
                let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
                let region = MKCoordinateRegion(center: self.myLocation.coordinate, span: span)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
}
