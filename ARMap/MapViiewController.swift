//
//  MapViiewController.swift
//  ARMap
//
//  Created by David on 2019-03-03.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViiewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let regionRadius: CLLocationDistance = 800
    let initialLocation = CLLocation(latitude: 43.717055, longitude: -79.330083)
    
    let locationManager = CLLocationManager()
    var currentCoordinate = CLLocation(latitude: 43.717055, longitude: -79.330083)
    
    var steps = [MKRoute.Step]()
    var polylines = [MKPolyline]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        guard let myLocation = locationManager.location else {return}
        currentCoordinate = myLocation
        print("Current: \(currentCoordinate.coordinate)")
        
        //Center the map.
        centerMapOnLocation(location: currentCoordinate.coordinate)
        
    }
    
    func centerMapOnLocation(location: CLLocationCoordinate2D){
        let coordinateRegion = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func getDirection(to destination: MKMapItem){
        let sourcePlaceMark = MKPlacemark(coordinate: currentCoordinate.coordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destination
        directionRequest.transportType = .walking
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            if error != nil {
                print("Error2: \(String(describing: error))")
            } else {
                guard let response = response else {return}
                guard let primaryRoute = response.routes.first else {return}
                print("Main Route Polyline : \(String(describing: primaryRoute.polyline.coordinate))")
                
                for step in primaryRoute.steps {
                   print(step.polyline.coordinate)
                }
                
                //print("Route Steps: \(String(describing: primaryRoute.steps.first?.polyline))")
                
                self.mapView.addOverlay(primaryRoute.polyline)
                
                self.steps = primaryRoute.steps
                self.polylines = [primaryRoute.polyline]
                
            }
        }
    }

   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }


}

extension MapViiewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    manager.stopUpdatingLocation()
        guard let currentLocation = locations.first else {return}
        currentCoordinate = currentLocation
        
        mapView.userTrackingMode = .followWithHeading
        
        
    }
}

extension MapViiewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        let localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = searchBar.text
        let region = MKCoordinateRegion(center: currentCoordinate.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        localSearchRequest.region = region
        let localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (response, error) in
            if error != nil {
                print("Error1: \(String(describing: error))")
            } else {
                guard let response = response else {return}
                guard let firstMapItem = response.mapItems.first else {return}
                print("First Imet: \(firstMapItem)")
                self.getDirection(to: firstMapItem)
            }
        }
    }
}

extension MapViiewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 8
            return renderer
        }
        return MKOverlayRenderer()
    }
}
