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
import ARKit


class MapViiewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let regionRadius: CLLocationDistance = 800
    let initialLocation = CLLocation(latitude: 43.717055, longitude: -79.330083)
    
    let locationManager = CLLocationManager()
    var currentCoordinate = CLLocation(latitude: 43.717055, longitude: -79.330083)
    
    private var steps = [MKRoute.Step]()
    private var polylines = [MKPolyline]()
    private var route = MKRoute()
    private var currentPathPart = [[CLLocationCoordinate2D]]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //get current location
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
                self.route = primaryRoute
                print("Main Route Polyline : \(String(describing: primaryRoute.polyline.coordinate))")
                //Add each MKRoute.step to array of MKRouteSteps.
                for step in primaryRoute.steps {
                   print(step.polyline.coordinate)
                    self.steps.append(step)
                }
                //Draw each line on 2d map
                self.mapView.addOverlay(primaryRoute.polyline)
                self.polylines = [primaryRoute.polyline]
                //self.steps = primaryRoute.steps
                self.getLocation()
            }
        }
    }
    
     private func getLocation() {
        for (index, step) in steps.enumerated() {
            setPathFromStep(step, and: index)
        }
    }

   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let viewController = segue.destination as! ViewController
        viewController.pathSteps = currentPathPart
        viewController.myRoute = route
        // Pass the selected object to the new view controller.
    }
    
    //MARK: - Get Parts of Path
    
    
    private func setPathFromStep(_ pathStep: MKRoute.Step, and index: Int){
        if index > 0 {
            getPathPart(for: index, and: pathStep)
        } else {
            getFirstPath(for: pathStep)
        }
    }
    
    private func getFirstPath(for pathStep: MKRoute.Step){
        let nextLocation = CLLocation(latitude: pathStep.polyline.coordinate.latitude, longitude: pathStep.polyline.coordinate.longitude)
        let middleSteps = CLLocationCoordinate2D.getPathLocations(currentLocation: currentCoordinate, nextLocation: nextLocation)
        currentPathPart.append(middleSteps)
        for step in middleSteps {
            print("Middle steps: \(step.latitude), \(step.longitude)")
        }
    }

    private func getPathPart(for index: Int, and pathStep: MKRoute.Step) {
        
        let previousIndex = index - 1
        let previousStep = steps[previousIndex]
        let previousLocation = CLLocation(latitude: previousStep.polyline.coordinate.latitude, longitude: previousStep.polyline.coordinate.longitude)
        
        let nextLocation = CLLocation(latitude: pathStep.polyline.coordinate.latitude, longitude: pathStep.polyline.coordinate.longitude)
        
        let middleSteps = CLLocationCoordinate2D.getPathLocations(currentLocation: previousLocation, nextLocation: nextLocation)
        currentPathPart.append(middleSteps)
        for step in middleSteps {
            //print("Middle steps: \(step.latitude), \(step.longitude)")
        }
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
    //get results from searchbar
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
        //Display line on 2D map
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    
}
