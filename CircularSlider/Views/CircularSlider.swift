//
//  CircularSlider.swift
//  CircularSlider
//
//  Created by Thomas on 2018-05-26.
//  Copyright © 2018 Thomas Lock. All rights reserved.
//

import UIKit

protocol CircularSliderDelegate:AnyObject {
    func tapped(angle: CGFloat)
    func panned(angle: CGFloat, pan: UIPanGestureRecognizer)
}

@IBDesignable
class CircularSlider: UIView {
    
    weak var delegate:CircularSliderDelegate?
    private var handleSelected:Bool = false
    private var valueLabel:UILabel?
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    private var handleRect:CGRect = .zero
    private var sliderDiameter: CGFloat = 0.0
    
    private struct Constants {
        static let panXYOffset: CGFloat = 50.0
        static let panScaleOffset: CGFloat = 100.0
        static let rightAngle: CGFloat = 90.0
        static let straightAngle: CGFloat = 180.0
        static let abtuseAngle: CGFloat = 270.0
        static let valueFormat: String = "%.0f"
        static let affineScaleXY: CGFloat = 0.75
        static let halfDivider: Double = 2.0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("init")
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(tap:)))
        self.addGestureRecognizer(tapGestureRecognizer)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewPanned(pan:)))
        self.addGestureRecognizer(panGestureRecognizer)
        
        self.isUserInteractionEnabled = true
    }
    
    //MARK: - Inspectables
    @IBInspectable
    var sliderValue:Double = 0.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var handleColor:UIColor = UIColor.black {
        didSet {
            self.setNeedsDisplay()
        }
    }

    @IBInspectable
    var sliderColor:UIColor = UIColor.black {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var sliderWidth:CGFloat = 1.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var handleSize:CGFloat = 50.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }

    //MARK: - Rendering Methods
    override func draw(_ rect: CGRect) {
        
        sliderDiameter = (rect.width - 105.0)

        let paddedRect = CGRect(x: rect.origin.x + Constants.panXYOffset, y: rect.origin.y + Constants.panXYOffset, width: rect.width - Constants.panScaleOffset, height: rect.height - Constants.panScaleOffset)
        let sliderPath = UIBezierPath(ovalIn: paddedRect)
        sliderPath.lineWidth = self.sliderWidth;
        self.sliderColor.setStroke()
        sliderPath.stroke()
        
        drawHandle(atAngle:self.sliderValue)
        
        let transform = CGAffineTransform(rotationAngle: (-Constants.rightAngle * CGFloat(Double.pi)) / Constants.straightAngle)
        self.transform = transform;
    }
    
    func drawHandle(atAngle angle:Double) {

        let xOffset = Double(sliderDiameter) / Constants.halfDivider * cos(-angle * Double.pi/Double(Constants.straightAngle))
        let yOffset = Double(sliderDiameter) / Constants.halfDivider * sin(-angle * Double.pi/Double(Constants.straightAngle))
        let hDivider = CGFloat(Constants.halfDivider)
        let handleSize = self.handleSize / hDivider
        self.handleRect = CGRect(x: self.bounds.width / hDivider - handleSize + CGFloat(xOffset),
                                 y: self.bounds.height / hDivider - handleSize - CGFloat(yOffset),
                                width: self.handleSize,
                                height: self.handleSize)
        
        let handlePath = UIBezierPath(ovalIn:
            self.handleRect)
        
        self.handleColor.setFill()
        handlePath.fill()

        let valueString:String = String(format: Constants.valueFormat, angle)

        if (valueLabel == nil) {
            valueLabel = UILabel(frame: self.handleRect)
            valueLabel?.textAlignment = .center
            self.addSubview(valueLabel!)
        }
        else {
            valueLabel!.frame = handleRect
        }
        
        let transform = CGAffineTransform(scaleX: Constants.affineScaleXY, y: Constants.affineScaleXY)
        valueLabel!.adjustsFontSizeToFitWidth = true
        valueLabel!.textColor = .white
        valueLabel!.text = valueString
        
        let labelTransform = CGAffineTransform(rotationAngle: Constants.rightAngle * CGFloat(Float.pi) / Constants.straightAngle)
        valueLabel?.transform = transform.concatenating(labelTransform);
    }
    
    //MARK: - Gesture Methods
    @objc public func viewPanned(pan: UIPanGestureRecognizer) {
        
        let location = pan.location(in: self)
        
        switch pan.state {
        case .began:
            self.handleSelected = true
            
            if location.x > self.valueLabel!.frame.origin.x - 10 && location.x < self.valueLabel!.frame.size.width + self.valueLabel!.frame.origin.x + 10 && location.y > self.valueLabel!.frame.origin.y - 10 && location.y < self.valueLabel!.frame.size.height + self.valueLabel!.frame.origin.y + 10 {
                self.handleSelected = true
            } else {
                self.handleSelected = false
            }
        case .changed:
            if self.handleSelected {
                
                let x = location.x - self.frame.size.width / CGFloat(Constants.halfDivider)
                let y = location.y - self.frame.size.height / CGFloat(Constants.halfDivider)
                
                var angle = atan(y/x) * (Constants.straightAngle / CGFloat(Float.pi))
                if x >= 0 && y < 0 {
                    angle = (Constants.rightAngle + angle) + Constants.abtuseAngle
                } else if x <= 0 && y > 0 {
                    if angle > 0 { angle = -angle }
                    angle = (Constants.rightAngle + angle) + Constants.rightAngle
                } else if x < 0 && y <= 0 {
                    angle = Constants.straightAngle + angle
                }
                
                self.sliderValue = Double(angle)
            }
        case .ended:
            self.handleSelected = false
        default:
            break
        }
        
        if let delegate = self.delegate {
            delegate.panned(angle: CGFloat(self.sliderValue), pan: pan)
        }
    }
    
    @objc public func viewTapped(tap: UITapGestureRecognizer) {
        let location = tap.location(in: self)
        
        if location.x > self.valueLabel!.frame.origin.x && location.x < self.valueLabel!.frame.size.width + self.valueLabel!.frame.origin.x && location.y > self.valueLabel!.frame.origin.y && location.y < self.valueLabel!.frame.size.height + self.valueLabel!.frame.origin.y {
            
            if let delegate = self.delegate {
                delegate.tapped(angle: CGFloat(self.sliderValue))
            }
            
        } else {
            print("didn't touch handle")
        }
    }
}
