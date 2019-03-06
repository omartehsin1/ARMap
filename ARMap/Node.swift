//
//  Node.swift
//  
//
//  Created by David on 2019-03-04.
//

import UIKit
import ARKit
import SCNPath
import SceneKit
import CoreLocation

class Node: SCNNode {
    
    var location: CLLocation
    var title: String?
    var anchor: ARAnchor?
    
    init(title: String?, location: CLLocation){
        self.location = location
        self.title = title
        super.init()
        let facingCamConstrains = SCNBillboardConstraint()
        facingCamConstrains.freeAxes = SCNBillboardAxis.Y
        //?
        constraints = [facingCamConstrains]
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        //?
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeBox(with size: CGFloat, color: UIColor)-> SCNNode{
        let geometry = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
        geometry.firstMaterial?.diffuse.contents = color
        let cube = SCNNode(geometry: geometry)
        return cube
    }
    
    func addNode(with size: CGFloat, and color: UIColor, and text: String){
        let cubeNode = makeBox(with: size, color: color)
        let stepText = SCNText(string: text, extrusionDepth: 0.1)
        stepText.font = UIFont(name: "AvenirNext-Medium", size: 1)
        stepText.firstMaterial?.diffuse.contents = UIColor.blue
        let textNode = SCNNode(geometry: stepText)
        let annotationNode = SCNNode()
        annotationNode.addChildNode(textNode)
        annotationNode.position = cubeNode.position
        addChildNode(cubeNode)
        addChildNode(annotationNode)
    }
    
    func addCube(with size: CGFloat, and color: UIColor){
        let cubeNode = makeBox(with: size, color: color)
        addChildNode(cubeNode)
    }
    
    
}
