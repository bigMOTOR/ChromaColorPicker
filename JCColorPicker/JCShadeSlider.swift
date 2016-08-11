//
//  JCShadeSlider.swift
//
//  Created by Jonathan Cardasis on 7/7/16.
//  Copyright © 2016 Jonathan Cardasis. All rights reserved.
//

import UIKit

class JCSliderTrackLayer: CALayer{
    let gradient = CAGradientLayer()
    
    override init() {
        super.init()
        gradient.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()]
        self.addSublayer(gradient)
    }
    override init(layer: AnyObject) {
        super.init(layer: layer)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol JCShadeSliderDelegate {
    func shadeSliderChoseColor(slider: JCShadeSlider, color: UIColor)
}

class JCShadeSlider: UIControl {
    var currentValue: CGFloat = 0.0 //range of {-1,1}
    
    let trackLayer = JCSliderTrackLayer()
    let handleView = JCColorHandle()
    var handleWidth: CGFloat{ return self.bounds.height }
    var handleCenterX: CGFloat = 0.0
    var delegate: JCShadeSliderDelegate?
    
    var primaryColor = UIColor.grayColor(){
        didSet{
            self.changeColorHue(to: currentColor)
            self.updateGradientTrack(for: primaryColor)
        }
    }
    /* The computed color of the primary color with shading based on the currentValue */
    var currentColor: UIColor{
        get{
            if currentValue < 0 {//darken
                return primaryColor.darkerColor(-currentValue)
            }
            else{ //lighten
                return primaryColor.lighterColor(currentValue)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit(){
        self.backgroundColor = nil
        handleCenterX = self.bounds.width/2
        
        trackLayer.backgroundColor = UIColor.blueColor().CGColor
        trackLayer.masksToBounds = true
        trackLayer.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()] //disable implicit animations
        self.layer.addSublayer(trackLayer)
        
        handleView.color = UIColor.blueColor()
        handleView.circleLayer.borderWidth = 3
        handleView.userInteractionEnabled = false //disable interaction for touch events
        self.layer.addSublayer(handleView.layer)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(resetHandleToCenter))
        doubleTapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTapGesture)
        
        self.layoutLayerFrames()
        self.changeColorHue(to: currentColor)
        self.updateGradientTrack(for: primaryColor)
    }
    
    override func didMoveToSuperview() {
        self.updateGradientTrack(for: primaryColor)
    }
    
    func layoutLayerFrames(){
        trackLayer.frame = self.bounds.insetBy(dx: handleWidth/2, dy: self.bounds.height/4) //Make half the height of the bounds
        trackLayer.cornerRadius = trackLayer.bounds.height/2
        
        self.updateGradientTrack(for: primaryColor)
        handleCenterX = (currentValue+1)/2 * (bounds.width - handleView.bounds.width) +  handleView.bounds.width/2 //Update where the handles center should be
        self.layoutHandleFrame()
    }
    
    //Lays out handle according to the currentValue on slider
    func layoutHandleFrame(){
        handleView.frame = CGRect(x: handleCenterX - handleWidth/2, y: self.bounds.height/2 - handleWidth/2, width: handleWidth, height: handleWidth)
    }
    
    func changeColorHue(to newColor: UIColor){
        handleView.color = newColor
        if currentValue != 0 { //Don't call delegate if the color hasnt changed
            self.delegate?.shadeSliderChoseColor(self, color: newColor)
        }
    }
    
    func updateGradientTrack(for color: UIColor){
        trackLayer.gradient.frame = trackLayer.bounds
        trackLayer.gradient.startPoint = CGPoint(x: 0, y: 0.5)
        trackLayer.gradient.endPoint = CGPoint(x: 1, y: 0.5)
        
        //Gradient is for astetics - the slider is actually between black and white
        trackLayer.gradient.colors = [color.darkerColor(0.65).CGColor, color.CGColor, color.lighterColor(0.65).CGColor]
    }
    
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        if handleView.frame.contains(location) {
            return true
        }
        return false
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        //Update for center point
        handleCenterX = location.x
        handleCenterX = fittedValueInBounds(handleCenterX) //adjust value to fit in bounds if needed
        
        
        //Update current value
        currentValue = ((handleCenterX - handleWidth/2)/trackLayer.bounds.width - 0.5) * 2  //find current value between {-1,1} of the slider
        
        //Update handle color
        self.changeColorHue(to: currentColor)
        
        //Update layers frames
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.layoutHandleFrame()
        CATransaction.commit()
        
        self.sendActionsForControlEvents(.ValueChanged)
        return true
    }
    
    func resetHandleToCenter(recognizer: UITapGestureRecognizer){
        let location = recognizer.locationInView(self)
        guard handleView.frame.contains(location) else {
            return
        }
        
        //tap is on handle
        handleCenterX = self.bounds.width/2
        self.layoutHandleFrame()
        handleView.color = primaryColor
        currentValue = 0.0
        
        self.sendActionsForControlEvents(.ValueChanged)
        self.delegate?.shadeSliderChoseColor(self, color: currentColor)
    }
    
    /* Helper Methods */
    //Returns a CGFloat for the highest/lowest possble value such that it is inside the views bounds
    private func fittedValueInBounds(value: CGFloat) -> CGFloat {
        return min(max(value, trackLayer.frame.minX), trackLayer.frame.maxX)
    }
    
}



