//
//  MapViiewController.swift
//  ARMap
//
//  Created by David Gonzalez, Van Luu, Omar Tehsin on 2019-03-05.
//  Copyright © 2019 David Gonzalez, Van Luu, Omar Tehsin. All rights reserved.
//

import UIKit
//import MapKit
import CoreLocation
import ARKit
import GoogleMaps

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:GMSMarker)
    func createDirectionToDestintation(destCoordinates: CLLocationCoordinate2D)
}

class MapViiewController: UIViewController {
    @IBOutlet var searchBarMap: UISearchBar!
    @IBOutlet weak var mapView: UIView!
    
    
    let iconImage = UIImageView(image: UIImage(named: "map")!)
    
    let splashView = UIView()

 
    
    var regionRadius: CLLocationDistance = 400
    
    let locationManager = CLLocationManager()
    var currentCoordinate = CLLocation()
    
    private var steps = [MKRoute.Step]()
    private var polylines = [GMSPolyline]()
    private var route = MKRoute()
    private var currentPathPart = [[CLLocationCoordinate2D]]()
    private var pathIndicators = [[CLLocationCoordinate2D]]()
    
    var directionsArray: [MKDirections] = []
    var resultSearchController : UISearchController? = nil
    
    var selectedPin:GMSMarker? = nil
    var selectedOverlay : GMSOverlayLayer? = nil
    
    var locationSearchTableVC : LocationSearchTable?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GMSServices.provideAPIKey("AIzaSyBQTVNjCMLjDy3nAE34ekSh9KOgux6ZjCM")
        
        guard let locationLat = locationManager.location?.coordinate.latitude else {
            return
        }
        guard let locationLon = locationManager.location?.coordinate.longitude else {
            return
        }
        let camera = GMSCameraPosition.camera(withLatitude: locationLat, longitude: locationLon, zoom: 10)
        let googleMapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        //view = googleMapView
        self.mapView = googleMapView
        let currentLocation = CLLocationCoordinate2DMake(locationLat, locationLon)
        let marker = GMSMarker(position: currentLocation)
        marker.title = "Here!"
        marker.map = googleMapView
        
        
        
        
        splashView.backgroundColor = UIColor.lightGray
        
        view.addSubview(splashView)
        
        splashView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        
        iconImage.contentMode = .scaleAspectFit
        
        splashView.addSubview(iconImage)
        
        iconImage.frame = CGRect(x: splashView.frame.midX - 35, y: splashView.frame.midY - 35, width: 70, height: 70)
        
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //get current location
        guard let myLocation = locationManager.location else {return}
        currentCoordinate = myLocation
        print("Current: \(currentCoordinate.coordinate)")
        
        //Center the map.
        centerMapOnLocation(location: currentCoordinate.coordinate, distance: regionRadius)
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        locationSearchTableVC = locationSearchTable
        
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        searchBar.delegate = self
        navigationItem.titleView = resultSearchController?.searchBar
        //searchBarMap = searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        
        locationSearchTable.handleMapSearchDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            self.scaleDownAnimation()
            
        }
        
    }
    
    func scaleDownAnimation() {
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.iconImage.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            
        }) { (success) in
            
            self.scaleUpAnimation()
            
        }
        
    }
    
    func scaleUpAnimation() {
        
        UIView.animate(withDuration: 0.35, delay: 0.1, options: .curveEaseIn, animations: {
            
            self.iconImage.transform = CGAffineTransform(scaleX: 5, y: 5)
            
            
        }) { (success) in
            
            self.removeSplashScreen()
            
        }
        
    }
    
    func removeSplashScreen() {
        
        
        splashView.removeFromSuperview()
        
    }
    
    func centerMapOnLocation(location: CLLocationCoordinate2D, distance: CLLocationDistance){
        let coordinateRegion = MKCoordinateRegion.init(center: location, latitudinalMeters: distance, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
       
    }
    
    func clearData(){
        // Clears the variables
        steps = []
        mapView.removeOverlay(route.polyline)
        route = MKRoute()
        currentPathPart = [[]]
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
        pathIndicators.append(middleSteps)
        for step in middleSteps {
            print("Main steps: \(step.latitude), \(step.longitude)")
        }
    }

    private func getPathPart(for index: Int, and pathStep: MKRoute.Step) {
        
        let previousIndex = index - 1
        let previousStep = steps[previousIndex]
        let previousLocation = CLLocation(latitude: previousStep.polyline.coordinate.latitude, longitude: previousStep.polyline.coordinate.longitude)
        
        let nextLocation = CLLocation(latitude: pathStep.polyline.coordinate.latitude, longitude: pathStep.polyline.coordinate.longitude)
        
        let middleSteps = CLLocationCoordinate2D.getPathLocations(currentLocation: previousLocation, nextLocation: nextLocation)
        currentPathPart.append(middleSteps)
//        for step in middleSteps {
            //print("Middle steps: \(step.latitude), \(step.longitude)")
//        }
    }

    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
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
//    //get results from searchbar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.endEditing(true)
//        let localSearchRequest = MKLocalSearch.Request()
//        localSearchRequest.naturalLanguageQuery = searchBar.text
//        let region = MKCoordinateRegion(center: currentCoordinate.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
//        localSearchRequest.region = region
//        let localSearch = MKLocalSearch(request: localSearchRequest)
//        localSearch.start { (response, error) in
//            if error != nil {
//                print("Error1: \(String(describing: error))")
//            } else {
//                guard let response = response else {return}
//                guard let firstMapItem = response.mapItems.first else {return}
//                print("First Imet: \(firstMapItem)")
//                self.getDirection(to: firstMapItem)
//            }
//        }
        
        
    }
}

extension MapViiewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //Display line on 2D map
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 3
            
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        //button.setBackgroundImage(UIImage(named: "car"), forState: .Normal)
        
        //button.addTarget(self, action: #selector(MapViiewController.getDirection(to:)), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    
    
}

extension MapViiewController: HandleMapSearch {
    func createDirectionToDestintation(destCoordinates: CLLocationCoordinate2D) {
        clearData()
        guard let myLocation = locationManager.location else {return}
        currentCoordinate = myLocation
        
        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate.coordinate)
        let destPlacemark = MKPlacemark(coordinate: destCoordinates)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destItem = MKMapItem(placemark: destPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceItem
        directionRequest.destination = destItem
        directionRequest.transportType = .walking
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            if error != nil {
                print("Error2: \(String(describing: error))")
            } else {
                guard let response = response else {return}
                guard let primaryRoute = response.routes.first else {return}
                self.route = primaryRoute
                let distance = primaryRoute.distance
                print("Main Route Polyline : \(String(describing: primaryRoute.polyline.coordinate))")
                //Add each MKRoute.step to array of MKRouteSteps.
                for step in primaryRoute.steps {
                    print(step.polyline.coordinate)
                    self.steps.append(step)
                }
                //Draw each line on 2d map
                self.mapView.addOverlay(primaryRoute.polyline, level: .aboveRoads)
                self.polylines = [primaryRoute.polyline]
                //let rect = primaryRoute.polyline.boundingMapRect
                //self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                self.centerMapOnLocation(location: self.currentCoordinate.coordinate, distance: (distance *  2))
                //self.steps = primaryRoute.steps
                self.getLocation()
            }
        }
    }
    
    func dropPinZoomIn(placemark:GMSMarker){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name

        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
}
