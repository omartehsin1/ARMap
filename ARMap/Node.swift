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
    
    var location: CLLocation?
    var title: String?
    var anchor: ARAnchor?
    
    
    func createBox(with size: CGFloat, color: UIColor)-> SCNNode{
        let geometry = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
        geometry.firstMaterial?.diffuse.contents = color
        let cube = SCNNode(geometry: geometry)
        return cube
    }
    
    
}
