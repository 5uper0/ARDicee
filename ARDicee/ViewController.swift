//
//  ViewController.swift
//  ARDicee
//
//  Created by Oleh on 10/19/17.
//  Copyright © 2017 Oleh V. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
  
  @IBOutlet var sceneView: ARSCNView!
  
  var diceArray = [SCNNode]()
  
  //MARK: - ViewController states
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.autoenablesDefaultLighting = true
    sceneView.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    
    // Run the view's session
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  //MARK: - Actions
  
  @IBAction func rollAgain(_ sender: UIBarButtonItem) {
    rollAll(dicesArray: diceArray)
  }
  
  @IBAction func removeAll(_ sender: UIBarButtonItem) {
    if !diceArray.isEmpty {
      for dice in diceArray {
        dice.removeFromParentNode()
      }
    }
  }
  
  //MARK: - Private Methods

  func cubeInit() {
    let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
    
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.red
    
    cube.materials = [material]
    
    let node = SCNNode()
    node.position = SCNVector3(x: 0, y: 0.1, z: -0.5)
    node.geometry = cube
    
    sceneView.scene.rootNode.addChildNode(node)
  }
  
  func sphereInit() {
    let sphere = SCNSphere(radius: 0.2)
    
    let material = SCNMaterial()
    material.diffuse.contents = UIImage(named: "art.scnassets/moon.jpg")
    
    sphere.materials = [material]
    
    let node = SCNNode()
    node.position = SCNVector3(x: 0, y: 0.1, z: -0.5)
    node.geometry = sphere
    
    sceneView.scene.rootNode.addChildNode(node)
  }
  
  func diceeInit() {
    let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
    
    if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
      diceNode.position = SCNVector3(0, 0, -0.1)
      sceneView.scene.rootNode.addChildNode(diceNode)
    }
  }
  
  func addDiceAt(hitResult location: ARHitTestResult) {
    let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
    
    if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
      
      diceNode.position =
        SCNVector3(
          location.worldTransform.columns.3.x,
          location.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
          location.worldTransform.columns.3.z
      )
      diceArray.append(diceNode)
      sceneView.scene.rootNode.addChildNode(diceNode)
      roll(dice: diceNode)
    }
  }
  
  func roll(dice: SCNNode) {
    let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
    let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
    
    dice.runAction(
      SCNAction.rotateBy(x: CGFloat(randomX * 5),
                         y: 0,
                         z: CGFloat(randomZ * 5),
                         duration: 0.5)
    )
  }

  func rollAll(dicesArray: [SCNNode]) {
    if !diceArray.isEmpty {
      for dice in diceArray {
        roll(dice: dice)
      }
    }
  }
  
  func createPlaneWith(planeAnchor: ARPlaneAnchor) -> SCNNode {
      let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x),
                           height: CGFloat(planeAnchor.extent.z))
      
      let planeNode = SCNNode()
      planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
      planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
      
      let gridMaterial = SCNMaterial()
      gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
      
      plane.materials = [gridMaterial]
      planeNode.geometry = plane

    return planeNode
  }

  //MARK: - Delegate Methods
  
  override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
    rollAll(dicesArray: diceArray)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let touch = touches.first {
      let touchLocation = touch.location(in: sceneView)
      let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
      
      if let hitResult = results.first {
        addDiceAt(hitResult: hitResult)
      }
    }
  }
  
  //MARK: ARSCNViewDelegate
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    let planeNode = createPlaneWith(planeAnchor: planeAnchor)
    node.addChildNode(planeNode)
  }
  
}
