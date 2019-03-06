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
    internal var mapAnnotations = [MapAnnotation]()
    private var annotationColor = UIColor.blue
    
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.debugOptions = .showFeaturePoints
       
        getCoordinates()
        parceData()
        setUpScene()
        
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
        let scene = SCNScene()
        sceneView.scene = scene
        runSession()
    }
    
    func runSession(){
     let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func parceData(){
        for myStep in mySteps {
            locations.append(CLLocation(latitude: myStep.latitude, longitude: myStep.longitude))
        }
    }
    
    func trackingLocation(for currentLocation: CLLocation) {
        if currentLocation.horizontalAccuracy <= 65.0 {
            updateLocations.append(currentLocation)
            updateNodePosition()
        }
    }
    
    //MARK: - Actions
    
    @IBAction func backBtn(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goBtn(_ sender: UIButton) {
        //
        done = true
        //
        updateNodes = true
        if updateLocations.count > 0 {
            myLocation = CLLocation.bestLocationEstimate(locations: updateLocations)
            if (myLocation != nil && done == true){
                DispatchQueue.main.async {
                    self.centerMapInInitialCoordinates()
                    self.addAnchors(steps: self.myRoute.steps)
                    self.showPointsOfInterestInMap(currentLegs: self.currentPathPart)
                    self.addAnnotations()
                }
            }
        }
    }

    //MARK: - Minimap crap
    private func showPointsOfInterestInMap(currentLegs: [[CLLocationCoordinate2D]]) {
        for leg in currentLegs {
            for item in leg {
                let mapAnnotation = MapAnnotation(coordinate: item, name: String(describing:item))
                self.mapAnnotations.append(mapAnnotation)
                self.mapView.addAnnotation(mapAnnotation)
            }
        }
    }
    //adds anotations and overlay to minimap
    private func addAnnotations(){
        guard let map = mapView else {return}
        map.addOverlay(myRoute.polyline)
        mapAnnotations.forEach { (annotation) in
            DispatchQueue.main.async {
                if annotation.title != nil {
                   self.annotationColor = .green
                } else {
                    self.annotationColor = .yellow
                }
                
                map.addAnnotation(annotation)
                map.addOverlay(MKCircle(center: annotation.coordinate, radius: 0.2))
            }
        }
    }
    
    private func addAnchors(steps: [MKRoute.Step]){
        guard myLocation != nil && steps.count > 0 else {return}
        for step in steps {
            placeNode(for: step)
        }
        for location in locations {
            placeNode(for: location)
        }
    }
    
    //gets coordinates
    func getCoordinates(){
        for pSteps in pathSteps {
            for step in pSteps {
                mySteps.append(step)
                print("Coordinates for AR: \(step)")
            }
        }
    }
    //MARK: - Create AR Nodes
     // placeNode in between main locations
    func placeNode(for location: CLLocation){
        let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: location)
        let stepAnchor = ARAnchor(transform: locationTransform)
        let cube = Node(title: nil, location: location)
        anchors.append(stepAnchor)
        cube.addCube(with: 0.5, and: .green)
        cube.location = location
        cube.anchor = stepAnchor
        //add node to scene
        sceneView.session.add(anchor: stepAnchor)
        sceneView.scene.rootNode.addChildNode(cube)
        nodes.append(cube)
    }
   // placeNode for Main points
    func placeNode(for step: MKRoute.Step){
        let stepLocation = step.getLocation()
        let locationTransform = Matrix.transformMatrix(for: matrix_identity_float4x4, originLocation: myLocation, location: stepLocation)
        let stepAnchor = ARAnchor(transform: locationTransform)
        let cube = Node(title: step.instructions, location: stepLocation)
        anchors.append(stepAnchor)
        cube.addNode(with: 1, and: .yellow, and: step.instructions)
        cube.location = stepLocation
        cube.anchor = stepAnchor
        //add node to scene
        sceneView.session.add(anchor: stepAnchor)
        sceneView.scene.rootNode.addChildNode(cube)
        nodes.append(cube)
    }
    
    private func updateNodePosition(){
    
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
