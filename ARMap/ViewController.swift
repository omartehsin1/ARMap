//
//  ViewController.swift
//  ARMap
//
//  Created by David on 2019-03-03.
//  Copyright © 2019 David. All rights reserved.
//
import CoreLocation
import UIKit
import SceneKit
import ARKit
import MapKit
import SCNPath


class ViewController: UIViewController, ARSCNViewDelegate, Mapable {

    //MARK: - Properties
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var sceneView: ARSCNView!
    var myRoute = MKRoute()
    var pathSteps = [[CLLocationCoordinate2D]]()
    //from previous VC
    var mySteps = [CLLocationCoordinate2D]()
    private var steps = [MKRoute.Step]()
    private var anchors: [ARAnchor] = []
    internal var myLocation: CLLocation!
    private var locations = [CLLocation]()
    private var nodes = [Node]()
    private var updateNodes = false
    private var updateLocations = [CLLocation]()
    private var currentPathPart = [[CLLocationCoordinate2D]]()
    private var done = false
    private var mapAnnotations = [MapAnnotation]()
    private var annotationColor = UIColor.blue
    let locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 800
    private var locationUpdate = 0 {
        didSet {
            if locationUpdate >= 5 {
                updateNodes = false
                print("updateNodes: \(updateNodes)")
            }
        }
    }
    private var pathPoints = [SCNVector3]() {
        didSet{
            self.pathNode.path = self.pathPoints
        }
    }
    private var pathNode = SCNPathNode(path: [])
    private var pathNodes = [Node]()
    
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = .showFeaturePoints
        
        getCoordinates()
        setUpScene()
        setUpNavigation()
        trackingLocation(for: myLocation)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        
        sceneView.session.pause()
    }
    func setUpScene(){
        sceneView.delegate = self
        //
//        sceneView.frame = view.bounds
        sceneView.automaticallyUpdatesLighting = true
       // sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight ]
        //view.addSubview(sceneView)
        //
        let scene = SCNScene()
        sceneView.scene = scene
        runSession()
    }
    
    func setUpNavigation(){
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self 
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        //get current location
        guard let aLocation = locationManager.location else {return}
        myLocation = aLocation
        
    }
    
    func runSession(){
     let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration, options: [.resetTracking])
    }
    
    func trackingLocation(for currentLocation: CLLocation) {
        if currentLocation.horizontalAccuracy <= 65.0 {
            updateLocations.append(currentLocation)
            print("@6")
            centerMapOnLocation(location: currentLocation.coordinate)
        }
    }
    
    //MARK: - Actions
    
    @IBAction func backBtn(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goBtn(_ sender: UIButton) {
        //
        if !pathSteps.isEmpty{
          done = true
        }
        
        trackingLocation(for: myLocation)
        updateNodes = true
        if updateLocations.count > 0 {
            myLocation = CLLocation.bestLocationEstimate(locations: updateLocations)
            if (myLocation != nil && done == true){
                DispatchQueue.main.async {
                    print("@1")
                    self.centerMapInInitialCoordinates()
                    self.addAnchors(steps: self.myRoute.steps)
                    self.addAnnotations()
                   self.showPointsOfInterestInMap(currentPath: self.mySteps)
                    
                }
            }
        }
        updateNodePosition()
    }
    
    // add info to AR nodes
    private func addAnchors(steps: [MKRoute.Step]){
        guard myLocation != nil && steps.count > 0 else {return}
        for step in steps {
            placeNode(for: step)
        }
        for location in locations {
            placeNode(for: location)
        }
        print("@2")
    }
    //Path
    private func path(){
        let pathMaterial = SCNMaterial()
        pathMaterial.diffuse.contents = UIImage(named: "art.scnassets/8k_earth_daymap.jpg")
        pathNode.materials = [pathMaterial]
        pathNode.position.y = -7
//        pathNode.position.y -= 0.5
        pathNode.width = 4
        sceneView.scene.rootNode.addChildNode(pathNode)
        print("@A")
    }

    //MARK: - Minimap crap
    private func showPointsOfInterestInMap(currentPath: [CLLocationCoordinate2D]) {
        guard let myAnnotation = currentPath.first else {return}
        guard let destinationAnnotation = currentPath.last else {return}
        let annotation = MapAnnotation(coordinate: myAnnotation)
        let destiAnnotation = MapAnnotation(coordinate: destinationAnnotation)
        self.mapView.addAnnotation(annotation)
        self.mapView.addAnnotation(destiAnnotation)
    }
    
    func centerMapOnLocation(location: CLLocationCoordinate2D){
        let coordinateRegion = MKCoordinateRegion.init(center: location, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //adds anotations and overlay to minimap
    
    private func addAnnotations(){
        mapView.addOverlay(myRoute.polyline)
         mapView.addOverlay(myRoute.polyline)
        mapView(mapView, rendererFor: myRoute.polyline)
    }
    
    //gets coordinates
    func getCoordinates(){
        for pSteps in pathSteps {
            for step in pSteps {
                mySteps.append(step)
                print("Coordinates for AR: \(step)")
            }
        }
        for myStep in mySteps {
            locations.append(CLLocation(latitude: myStep.latitude, longitude: myStep.longitude))
        }
        //print("location: \(locations)")
    }
    //MARK: - Create AR Nodes
     // placeNode in between main locations
    func placeNode(for location: CLLocation){
        let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: location)
        let stepAnchor = ARAnchor(transform: locationTransform)
        let cube = Node(title: nil, location: location)
        anchors.append(stepAnchor)
        cube.addCube(with: 0.04, and: .clear)
        cube.location = location
        cube.anchor = stepAnchor
        //add node to scene
        sceneView.session.add(anchor: stepAnchor)
        sceneView.scene.rootNode.addChildNode(cube)
        nodes.append(cube)
        print("@4")
    }
   // placeNode for Main points
    func placeNode(for step: MKRoute.Step){
        let stepLocation = step.getLocation()
        let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: stepLocation)
        let stepAnchor = ARAnchor(transform: locationTransform)
        let cube = Node(title: step.instructions, location: stepLocation)
        anchors.append(stepAnchor)
        cube.addNode(with: 0.05, and: .clear, and: step.instructions)
        cube.location = stepLocation
        cube.anchor = stepAnchor
        //add node to scene
        sceneView.session.add(anchor: stepAnchor)
        sceneView.scene.rootNode.addChildNode(cube)
        nodes.append(cube)
        pathNodes.append(cube)
        print("@5")
    }
    
    private func updateNodePosition(){
        if updateNodes{
            locationUpdate += 1
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1
            if updateLocations.count > 0 {
                myLocation = CLLocation.bestLocationEstimate(locations: updateLocations)
                for node in nodes {
                    print("@7")
                    let translation = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: node.location)
                    let position = SCNVector3.positionForNode(transform: translation)
                    let distance = node.location.distance(from: myLocation)
                    DispatchQueue.main.async {
                        let scale = 100 / Float(distance)
                        node.scale = SCNVector3(x: scale, y: scale, z: scale)
                        node.position = position
                        node.anchor = ARAnchor(transform: translation)
                        print("@8")
                    }
                }
                for pathN in pathNodes {
                    print("@9")
                    let translation = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: pathN.location)
                    let position = SCNVector3.positionForNode(transform: translation)
                    let distance = pathN.location.distance(from: myLocation)
                    DispatchQueue.main.async {
                        let scale = 100 / Float(distance)
                        pathN.scale = SCNVector3(x: scale, y: scale, z: scale)
                        pathN.position = position
                        pathN.anchor = ARAnchor(transform: translation)
                        print("@10")
                    }
                    //add vectors to path
                    pathPoints.append(position)
                }
            }
            SCNTransaction.commit()
            path()
        }
        mapView.addOverlay(myRoute.polyline)
    }

    


    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
extension ViewController: MKMapViewDelegate, CLLocationManagerDelegate {
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let currentLocation = locations.first else {return}
        updateLocations.append(currentLocation) 
        
        mapView.userTrackingMode = .followWithHeading 
    }
}
