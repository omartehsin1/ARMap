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


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var pathSteps = [[CLLocationCoordinate2D]]()
    var steps = [CLLocationCoordinate2D]()
    private var nodes = [Node]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.debugOptions = .showFeaturePoints
        let scene = SCNScene()
        sceneView.scene = scene
        
        getCoordinates()
        

    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func getCoordinates(){
        for pSteps in pathSteps {
            for step in pSteps {
                steps.append(step)
                print("Coordinates for AR: \(step)")
            }
        }
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
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
