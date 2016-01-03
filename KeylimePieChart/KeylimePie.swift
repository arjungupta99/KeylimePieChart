//
//  KeylimePie.swift
//  SwiftPieChart
//
//  Created by Arjun Gupta on 9/26/15.
//  Copyright © 2015 ArjunGupta. All rights reserved.
//


import Foundation
import UIKit

class KeylimePie:UIView {
    
    var keysAndValues:[NSString:CGFloat]?
    
    var useVariableSizeSlicing                  = true  //True will make a coxcomb style graph
    var adjustGraphRadiusToFillLabels           = false //Graph will get small if the label is to long
    var showLabels                              = true
    var makeCenterFill                          = true
    var addInnerBorder                          = false
    
    var beginAngle          :CGFloat            = 45    //In degrees
    var innerBorderWidth    :CGFloat            = 3.0
    var sideMargin          :CGFloat            = 100.0 //Bigger margin = smaller graph. Increase if there will be long labels
    var variableSizeOffset  :CGFloat            = 41    //Higher number means more popping out for slices
    
    var pieInnerBorderWidth :CGFloat            = 1.0   //Gives the appearance of split slices
    var pieInnerBorderColor                     = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    var pieFillColor        :UIColor            = UIColor.lightGrayColor()
    var pieBackgroundColor  :UIColor            = UIColor.whiteColor()
    
    var labelFontName                           = "Helvetica"
    var labelFontSize       :CGFloat            = 12.0
    
    var maxLabelCharacters                      = 30
    var labelBorderThickness:CGFloat            = 0
    var labelBorderColor                        = UIColor.grayColor()
    var labelJointLength    :CGFloat            = 19
    var labelJointColor                         = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    var labelBGColor                            = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    var labelSpacer         :CGFloat            = 1.0
    
    
    //Optional if you want to specify your own colors
    var pieColorArray       :NSArray?           =   [
                                                        UIColor(red: 0.61, green: 0.31, blue: 0.83, alpha: 1.0),
                                                        UIColor(red: 0.16, green: 0.73, blue: 0.96, alpha: 1.0),
                                                        UIColor(red: 0.92, green: 0.73, blue: 0.50, alpha: 1.0),
                                                        UIColor(red: 0.00, green: 0.67, blue: 0.31, alpha: 1.0),
                                                        UIColor(red: 0.29, green: 0.88, blue: 0.50, alpha: 1.0),
                                                        UIColor(red: 0.90, green: 0.50, blue: 0.01, alpha: 1.0),
                                                        UIColor(red: 0.12, green: 0.25, blue: 0.57, alpha: 1.0),
                                                        UIColor(red: 0.80, green: 0.15, blue: 0.47, alpha: 1.0),
                                                    ]
    
    
    
    private let kLabelVertMargin:CGFloat        = 3
    private let kLabelSideMargin:CGFloat        = 5
    private let kLabelJoint0Length:CGFloat      = 3
    private let kLabelJoint2Length:CGFloat      = 7
    private let kJointThickness:CGFloat         = 1
    private let kLabelDisplacement:CGFloat      = 5.0
    private var pieCenter:CGPoint               = CGPointZero
    private var pieRadius:CGFloat               = 0
    private var labelNodes                      = [LabelNode]()
    private var totalOfValues:CGFloat           = 0
    private var maxValue:CGFloat                = 0
    private var maxLabelWidth:CGFloat           = 0
    private var labelAttributes :NSDictionary?
    
    private var graphPoints:[(color:UIColor, radius:CGFloat, startAngle:CGFloat, endAngle:CGFloat, (a:CGPoint, b:CGPoint, c:CGPoint))] = []
    private var centerGraphPoints:[(color:UIColor, radius:CGFloat, startAngle:CGFloat, endAngle:CGFloat, (a:CGPoint, b:CGPoint, c:CGPoint))] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    
    
//MARK:- Build
    
    
    
    
    func build () {
        
        guard let _ = self.keysAndValues else {
            print("Input values are empty.");
            return
        }
        
        
        self.backgroundColor = self.pieBackgroundColor
        self.labelNodes.removeAll()
        self.pieCenter  = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        self.pieRadius  = min(self.pieCenter.x, self.pieCenter.y) - self.sideMargin
        self.labelJointLength = min(19,  max(10, 19 * self.pieRadius/self.sideMargin))
        
        self.setupTotalAndMax()
        let labelAdjustmentsNeeded = self.setupLabelFrames()

        if (self.adjustGraphRadiusToFillLabels && self.showLabels && labelAdjustmentsNeeded) {
            self.sideMargin  = max(self.sideMargin, self.maxLabelWidth + self.labelJointLength)
            self.pieRadius   = max(min(self.pieCenter.x, self.pieCenter.y) - self.sideMargin - self.labelJointLength + 10, 55)
            self.setupLabelFrames()
        }
        
        self.graphPoints = self.calculateGraphPoints(self.pieRadius)
        
        if (self.makeCenterFill) {
            let smlRadius  = self.pieRadius / 1.3
            self.centerGraphPoints = self.calculateGraphPoints(smlRadius)
        }
        
        if (labelAdjustmentsNeeded) {
            self.balanceLabels()
        }
        self.setNeedsDisplay()
    }
    
    

    
    
//MARK: - Balance
    
    
    
    
    func balanceLabels() {
        
        var collisionPresent = true
        var iterationCount      = 0
        let maxIterations       = 1000
        while (collisionPresent == true && iterationCount < maxIterations) {
            
            collisionPresent = self.repeater()
            iterationCount++
        }
    }
    
    
    func repeater () -> Bool {
        
        var collisionPresent = false
        var counter = 0
        for var node in self.labelNodes {
            
            let collidingNodes = self.fetchCollidingNodes(node)
            
            for cNode in collidingNodes {
                
                let clockwise   = self.shouldGoClockwise(node, collidingNode: cNode)
                let rad = CGFloat(1).DEGREE_TO_RADIANS
                
                let f = self.rotateNode(node, clockwise: clockwise, canvasSize: self.frame.size, radians: rad)
                node.frame = f.0
                node.currentAngle = f.1
                self.labelNodes[counter] = node
                
                collisionPresent = true
            }
            counter++
        }
        
        return collisionPresent
    }

    
    
    
    
    
//MARK:- Drawing
    
    
    
    
    
    
    override func drawRect(rect: CGRect) {
        
        
        guard let theKeysAndValues = self.keysAndValues else {
            print("Input values are empty.");
            return
        }
        
        //MARK: Graph drawing
        
        func drawGraph () {
        
            var pointCount = 0
            for pointTuple in self.graphPoints {
                
                let context     = UIGraphicsGetCurrentContext()
                let points      = [pointTuple.4.a, pointTuple.4.b, pointTuple.4.c]
                let theCenter   = pointTuple.4.b
                pointTuple.color.set()
                
                CGContextAddLines(context, points, points.count);
                CGContextAddArc(context, theCenter.x, theCenter.y, pointTuple.radius, pointTuple.startAngle, pointTuple.endAngle, 0);
                CGContextDrawPath(context, .EOFill);
                
                if (self.makeCenterFill) {
                    let centerPointTuple    = self.centerGraphPoints[pointCount]
                    let centerPoints        = [centerPointTuple.4.a, centerPointTuple.4.b, centerPointTuple.4.c]
                    UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.17).set()
                    CGContextAddLines(context, centerPoints, centerPoints.count);
                    CGContextAddArc(context, theCenter.x, theCenter.y, centerPointTuple.radius, centerPointTuple.startAngle, centerPointTuple.endAngle, 0);
                    CGContextDrawPath(context, .EOFill);
                }
                
                if (self.addInnerBorder) {
                    CGContextSetStrokeColorWithColor(context, self.pieInnerBorderColor.CGColor)
                    CGContextSetLineWidth(context, self.pieInnerBorderWidth)
                    CGContextAddLines(context, points, points.count);
                    CGContextDrawPath(context, .Stroke);
                }
                
                pointCount++
            }
        }
        drawGraph()
        
        
        //MARK: Label Drawing
        
        
        func drawLabels() {
            
            if (self.labelNodes.count == 0) {
                print("KeyLimePie : You might want to call the build() method after defining the labelNodes...")
                return
            }
            
            var itemCount = 0
            for val in theKeysAndValues {
                
                let node = self.labelNodes[itemCount]
                let joint0StartPoint    = node.joint0StartPoint
                let joint0EndPoint      = node.joint0EndPoint
                let joint1StartPoint    = node.joint1StartPoint
                var joint1EndPoint      = node.joint1EndPoint
                var joint2EndPoint      = node.joint2EndPoint
                let finalLabelRect      = node.frame
                
                let value       = val.1
                let key         = val.0
                
                let labelStr = sizedLabelForString(key, value: value)
                
                if (finalLabelRect.origin.x < rect.size.width/2) {
                    
                    //Left
                    joint2EndPoint = CGPointMake(CGRectGetMaxX(finalLabelRect) - self.labelSpacer, CGRectGetMinY(finalLabelRect) + self.kJointThickness/2 + self.labelSpacer);
                    joint1EndPoint = CGPointMake(joint2EndPoint.x + self.kLabelJoint2Length, joint2EndPoint.y);
                    
                    //Join at bottom
                    if (joint1StartPoint.y > CGRectGetMidY(finalLabelRect)) {
                        joint2EndPoint = CGPointMake(CGRectGetMaxX(finalLabelRect) - self.labelSpacer, CGRectGetMaxY(finalLabelRect) - self.kJointThickness/2 - self.labelSpacer);
                        joint1EndPoint = CGPointMake(joint2EndPoint.x + self.kLabelJoint2Length, joint2EndPoint.y);
                    }
                    
                    //Prevent excessive twisting
                    if (joint2EndPoint.x >= joint1StartPoint.x || fabs(joint0EndPoint.x - joint2EndPoint.x) < kLabelJoint2Length) {
                        joint1EndPoint = CGPointMake(joint2EndPoint.x, joint2EndPoint.y);
                    }
                }
                else {
                    
                    //Right
                    joint2EndPoint = CGPointMake(CGRectGetMinX(finalLabelRect) + self.kJointThickness/2 + self.labelSpacer, CGRectGetMinY(finalLabelRect) + self.kJointThickness/2 + self.labelSpacer);
                    joint1EndPoint = CGPointMake(joint2EndPoint.x - self.kLabelJoint2Length, joint2EndPoint.y);
                    
                    //Join at top
                    if (joint1StartPoint.y < rect.size.height/2) {
                        joint2EndPoint = CGPointMake(CGRectGetMinX(finalLabelRect) + self.kJointThickness/2 + self.labelSpacer, CGRectGetMaxY(finalLabelRect) - self.kJointThickness/2 - self.labelSpacer);
                        joint1EndPoint = CGPointMake(joint2EndPoint.x - self.kLabelJoint2Length, joint2EndPoint.y);
                    }
                    
                    //Prevent excessive twisting
                    if (joint2EndPoint.x <= joint1StartPoint.x || fabs(joint0EndPoint.x - joint2EndPoint.x) < kLabelJoint2Length) {
                        joint1EndPoint = CGPointMake(joint2EndPoint.x + self.kJointThickness/2, joint2EndPoint.y);
                    }
                }
                
                //If the distance is too small then reduce flexes
                if (self.distanceBetweenPoint1(joint0EndPoint, p2:joint2EndPoint) < self.labelJointLength) {
                    joint1EndPoint = joint2EndPoint;
                }
                
                
                // If the label is somewhere in the middle
                if ((CGRectGetMinX(finalLabelRect) < rect.size.width / 2 && CGRectGetMaxX(finalLabelRect) > rect.size.width / 2) ||
                    CGRectGetMidX(finalLabelRect) < rect.size.width / 2 && joint0EndPoint.x < CGRectGetMaxX(finalLabelRect) ||
                    CGRectGetMidX(finalLabelRect) > rect.size.width / 2 && joint0EndPoint.x > CGRectGetMinX(finalLabelRect)
                    ) {
                        
                        var pointCenter     = CGPointZero
                        var pointLeft       = CGPointZero
                        var pointRight      = CGPointZero
                        var connectionPoint = CGPointZero
                        
                        if (CGRectGetMidY(finalLabelRect) < rect.size.height/2) {
                            //On top. Join at bottom
                            pointCenter = CGPointMake(CGRectGetMidX(finalLabelRect), CGRectGetMaxY(finalLabelRect) - self.labelSpacer)
                            pointLeft   = CGPointMake(CGRectGetMinX(finalLabelRect) + self.kJointThickness/2 + self.labelSpacer + CGRectGetWidth(finalLabelRect)/3.5, CGRectGetMaxY(finalLabelRect) - self.labelSpacer)
                            pointRight  = CGPointMake(CGRectGetMaxX(finalLabelRect) - self.kJointThickness/2 - self.labelSpacer - CGRectGetWidth(finalLabelRect)/3.5, CGRectGetMaxY(finalLabelRect) - self.labelSpacer)
                        }
                        else {
                            //On bottom. Join on top
                            pointCenter = CGPointMake(CGRectGetMidX(finalLabelRect), CGRectGetMinY(finalLabelRect) + self.labelSpacer)
                            pointLeft   = CGPointMake(CGRectGetMinX(finalLabelRect) + self.kJointThickness/2 + self.labelSpacer + CGRectGetWidth(finalLabelRect)/3.5, CGRectGetMinY(finalLabelRect) + kJointThickness/2 + self.labelSpacer)
                            pointRight  = CGPointMake(CGRectGetMaxX(finalLabelRect) - self.kJointThickness/2 - self.labelSpacer - CGRectGetWidth(finalLabelRect)/3.5, CGRectGetMinY(finalLabelRect) + kJointThickness/2 + self.labelSpacer)
                        }
                        
                        let distCenter  = self.distanceBetweenPoint1(joint0EndPoint, p2:pointCenter)
                        let distLeft    = self.distanceBetweenPoint1(joint0EndPoint, p2:pointLeft)
                        let distRight   = self.distanceBetweenPoint1(joint0EndPoint, p2:pointRight)
                        
                        let minDist =  min(min(distCenter, distLeft), distRight);
                        
                        if      (minDist == distCenter) { connectionPoint = pointCenter }
                        else if (minDist == distLeft)   { connectionPoint = pointLeft   }
                        else if (minDist == distRight)  { connectionPoint = pointRight  }
                        
                        joint1EndPoint = connectionPoint
                        joint2EndPoint = joint1EndPoint
                }
                
                
                //Draw Joint Lines
                let context = UIGraphicsGetCurrentContext()
                CGContextSetStrokeColorWithColor(context, self.labelJointColor.CGColor)
                CGContextSetLineCap(context, .Round)
                CGContextSetLineWidth(context, self.kJointThickness)
                
                CGContextMoveToPoint(context, joint0StartPoint.x, joint0StartPoint.y)
                CGContextAddLineToPoint(context, joint0EndPoint.x, joint0EndPoint.y)
                CGContextAddLineToPoint(context, joint1EndPoint.x, joint1EndPoint.y)
                CGContextAddLineToPoint(context, joint2EndPoint.x, joint2EndPoint.y)
                CGContextStrokePath(context)
                
                
                //Small gap around labels so they don't appear sticking together
                var fillRect = finalLabelRect;
                fillRect.origin.x       += self.labelSpacer
                fillRect.origin.y       += self.labelSpacer
                fillRect.size.width     -= 2 * self.labelSpacer
                fillRect.size.height    -= 2 * self.labelSpacer
                
                //Label fill
                CGContextSetFillColorWithColor(context, self.labelBGColor.CGColor)
                CGContextFillRect(context, fillRect)
                
                //Label border
                if (self.labelBorderThickness > 0) {
                    CGContextSetStrokeColorWithColor(context, self.labelBorderColor.CGColor)
                    CGContextSetLineWidth(context, self.labelBorderThickness)
                    CGContextStrokeRect(context, fillRect)
                }
                
                var textRect = finalLabelRect;
                textRect.origin.x       += self.kLabelSideMargin
                textRect.origin.y       += self.kLabelVertMargin
                textRect.size.width     -= 2 * self.kLabelSideMargin
                textRect.size.height    -= 2 * self.kLabelVertMargin
                
                let labelNSStr = labelStr as NSString
                labelNSStr.drawInRect(textRect, withAttributes: self.labelAttribs() as? [String : AnyObject])
                
                itemCount++;
            }
        }
        
        if (self.showLabels) {
            drawLabels()
        }
        
    }
    

    
    
    
//MARK: -  Graph Setup
    
    
    func calculateGraphPoints (thePieRadius:CGFloat) -> [(color:UIColor, radius:CGFloat, startAngle:CGFloat, endAngle:CGFloat, (a:CGPoint, b:CGPoint, c:CGPoint))] {
        
        var tempAngleOne    = self.beginAngle.DEGREE_TO_RADIANS;
        var keyCount        = -1
        
        var theGraphPoints:[(color:UIColor, radius:CGFloat, startAngle:CGFloat, endAngle:CGFloat, (a:CGPoint, b:CGPoint, c:CGPoint))] = []
        var stuff:[(name: String, value: Int)] = []
        
        for val in self.keysAndValues! {
            
            keyCount++
            let value       = val.1
            let progress    = value / self.totalOfValues
            
            let startAngle  = Float(tempAngleOne)
            let endAngle    = Float((2 * CGFloat(M_PI) * progress) + tempAngleOne)
            
            //Use as the start angle for next slice
            tempAngleOne = CGFloat(endAngle)
            
            let deltaRadius = self.deltaRadiusCalc(progress, thePieRadius: thePieRadius)
            
            let fillStartPoint  = CGPointMake(self.pieCenter.x + deltaRadius * CGFloat(cosf(startAngle)), self.pieCenter.y + deltaRadius * CGFloat(sinf(startAngle)));
            let fillEndPoint    = CGPointMake(self.pieCenter.x + deltaRadius * CGFloat(cosf(endAngle)), self.pieCenter.y + deltaRadius * CGFloat(sinf(endAngle)));
            
            // Pie Fill Color
            var currentColor:UIColor {
                if (self.pieColorArray != nil) {
                    return self.pieColorArray![keyCount % self.pieColorArray!.count] as! UIColor
                }
                else {
                    //Default fill color
                    let colorMultiplier     =  0.7 / CGFloat(self.keysAndValues!.count)
                    let colorVal    = 0.2 + colorMultiplier * CGFloat(keyCount)
                    return UIColor(red: colorVal, green: colorVal, blue: colorVal, alpha: 1.0)
                }
            }
            
            theGraphPoints.append((color: currentColor, radius: deltaRadius, startAngle:CGFloat(startAngle), endAngle:CGFloat(endAngle), (a: fillStartPoint, b: self.pieCenter, c: fillEndPoint)))
        }
        
        return theGraphPoints
    }
    
    
    
    
    
//MARK: Label setup
    
    
    
    func setupTotalAndMax() {
        
        for val in self.keysAndValues! {
            let value           = val.1
            self.totalOfValues += value
            
            //Variable size slicing
            let progress        = value / self.totalOfValues
            self.maxValue       = max(progress, self.maxValue)
        }
    }
    
    
    func setupLabelFrames () -> Bool {
        
        var tempAngleTwo            = self.beginAngle.DEGREE_TO_RADIANS
        var itemCount               = 0
        var labelAdjustmentsNeeded    = false
        
        for val in self.keysAndValues! {
            
            let value       = val.1
            let key         = val.0
            let progress    = value / self.totalOfValues
            
            if (value == 0) { continue }
            
            let deltaRadius = self.deltaRadiusCalc(progress, thePieRadius:self.pieRadius)
            
            let centerAngle = ((2 * CGFloat(M_PI) * progress/2) + tempAngleTwo)
            let endAngle    = ((2 * CGFloat(M_PI) * progress) + tempAngleTwo)
            
            tempAngleTwo = CGFloat(endAngle)
            let labelStr = self.sizedLabelForString(key, value: value)
            
            //Label Joints
            let joint0StartPoint    = CGPointMake(self.pieCenter.x + (deltaRadius + self.kJointThickness/2) * CGFloat(cosf(Float(centerAngle))), self.pieCenter.y + (deltaRadius + self.kJointThickness/2) * CGFloat(sinf(Float(centerAngle))))
            let joint0EndPoint      = CGPointMake(self.pieCenter.x + (deltaRadius + self.kLabelJoint0Length) * CGFloat(cosf(Float(centerAngle))), self.pieCenter.y + (deltaRadius + kLabelJoint0Length) * CGFloat(sinf(Float(centerAngle))))
            let joint1StartPoint    = joint0EndPoint
            var joint1EndPoint      = CGPointMake(self.pieCenter.x + (deltaRadius + labelJointLength) * CGFloat(cosf(Float(centerAngle))), self.pieCenter.y + (deltaRadius + labelJointLength) * CGFloat(sinf(Float(centerAngle))))
            var joint2EndPointCalc:CGPoint {
                if (joint1EndPoint.x >= self.frame.size.width / 2) {
                    return CGPointMake(joint1EndPoint.x + self.kLabelJoint2Length, joint1EndPoint.y);
                }
                else {
                    return CGPointMake(joint1EndPoint.x - self.kLabelJoint2Length, joint1EndPoint.y);
                }
            }
            let joint2EndPoint      = joint2EndPointCalc
            
            var labelRect           = self.labelSizeForTitle(labelStr, canvasSize: self.frame.size, attribs: self.labelAttribs())
            labelRect.origin        = joint2EndPoint;
            let finalRect = self.positionRectForLabelRect(labelRect, canvasSize: self.frame.size, angle: centerAngle, deltaRadius: deltaRadius)
            
            //Create node
            var node                = LabelNode(frameVal: finalRect)
            node.joint0StartPoint   = joint0StartPoint
            node.joint0EndPoint     = joint0EndPoint
            node.joint1StartPoint   = joint1StartPoint
            node.joint1EndPoint     = joint1EndPoint
            node.joint2EndPoint     = joint2EndPoint
            node.currentAngle       = centerAngle
            node.deltaRadius        = self.distanceBetweenPoint1(self.pieCenter, p2: joint2EndPoint)
            node.sizedRadius        = self.distanceBetweenPoint1(self.pieCenter, p2: CGPointMake(CGRectGetMidX(finalRect), CGRectGetMidY(finalRect)))
            node.frame              = finalRect
            node.nodeIndex          = itemCount
            
            self.maxLabelWidth      = max(self.maxLabelWidth, finalRect.width)
            
            if (self.labelNodes.count <= itemCount) {
                self.labelNodes.append(node)
            }
            else {
                self.labelNodes[itemCount] = node
            }
            
            if (!labelAdjustmentsNeeded) {
                labelAdjustmentsNeeded    = self.checkIfFrameOutsideBoundary(finalRect, canvasSize: self.frame.size).0
                if (!labelAdjustmentsNeeded) {
                    let collidingNodesCount = self.fetchCollidingNodes(node).count
                    if (collidingNodesCount > 0) {
                        labelAdjustmentsNeeded = true
                    }
                }
            }
            
            itemCount++
        }
        
        return labelAdjustmentsNeeded
    }
    
    
    
    
    
    //MARK:- Utils
    
    
    
    
    
    func positionRectForLabelRect(labelRect:CGRect, canvasSize:CGSize, angle:CGFloat, deltaRadius:CGFloat) -> CGRect {
        
        var connectionX = labelRect.origin.x;
        var connectionY = labelRect.origin.y;
        
        //Arrange correctly based on side
        if (labelRect.origin.x < canvasSize.width/2) {
            connectionX = connectionX - labelRect.size.width ;
        }
        if (labelRect.origin.y < canvasSize.height/2) {
            connectionY = connectionY - labelRect.size.height;
        }
        
        let finalLabelRect  = CGRectMake(connectionX, connectionY, labelRect.size.width, labelRect.size.height);
        
        return finalLabelRect
    }
    
    
    func distanceBetweenPoint1(p1:CGPoint, p2:CGPoint) -> CGFloat {
        
        let xDist = (p2.x - p1.x);
        let yDist = (p2.y - p1.y);
        let distance = sqrt((xDist * xDist) + (yDist * yDist));
        return distance;
    }
    
    
    func labelSizeForTitle(title:String, canvasSize:CGSize, attribs:NSDictionary) -> CGRect {
        
        let titleStr     = title as NSString
        var boundingRect = titleStr.boundingRectWithSize(canvasSize, options: .UsesLineFragmentOrigin, attributes: attribs as? [String : AnyObject], context: nil)
        boundingRect.size.width     += 2*kLabelSideMargin;
        boundingRect.size.height    += 2*kLabelVertMargin;
        
        return boundingRect
    }
    
    
    func checkIfFrameOutsideBoundary(theFrame:CGRect, canvasSize:CGSize) -> (Bool, FrameSide) {
        
        if (CGRectGetMaxX(theFrame) > canvasSize.width) {
            return (true, FrameSide.right)
        }
        if (theFrame.origin.x < 0) {
            return (true, FrameSide.left)
        }
        if (CGRectGetMaxY(theFrame) > canvasSize.height) {
            return (true, FrameSide.bottom)
        }
        if (theFrame.origin.y < 0) {
            return (true, FrameSide.top)
        }
        return (false, FrameSide.none)
    }
    
    
    func rotateNode(node:LabelNode, clockwise:Bool, canvasSize:CGSize, radians:CGFloat) -> (CGRect,CGFloat) {
        
        var cAngle      = node.currentAngle
        var newFrame    = node.frame
        
        if (clockwise) {
            cAngle += radians
        }
        else {
            cAngle -= radians
        }
        
        let dist = node.sizedRadius
        
        let xPoint = canvasSize.width/2  + (dist * cos(cAngle))
        let yPoint = canvasSize.height/2 + (dist * sin(cAngle))

        newFrame.origin.x = xPoint - newFrame.width/2
        newFrame.origin.y = yPoint - newFrame.height/2
        
        
        if (CGRectGetMaxY(newFrame) < canvasSize.height/2 - node.deltaRadius) {
            let extraDist = canvasSize.height/2 - node.deltaRadius - CGRectGetMaxY(newFrame)
            newFrame.origin.y += extraDist
        }
        
        if (CGRectGetMaxX(newFrame) < canvasSize.width/2 - node.deltaRadius) {
            let extraDist = canvasSize.width/2 - node.deltaRadius - CGRectGetMaxX(newFrame)
            newFrame.origin.x += extraDist
        }
        
        if (CGRectGetMinY(newFrame) > canvasSize.height/2 + node.deltaRadius) {
            let extraDist = CGRectGetMinY(newFrame) - (canvasSize.height/2 + node.deltaRadius)
            newFrame.origin.y -= extraDist
        }
        
        if (CGRectGetMinX(newFrame) > canvasSize.width/2 + node.deltaRadius) {
            let extraDist = CGRectGetMinX(newFrame) - (canvasSize.width/2 + node.deltaRadius)
            newFrame.origin.x -= extraDist
        }
        
        //Find connection pt
        let connectionPt = self.calculateConnectionPoint(newFrame)
        let connectDist = self.distanceBetweenPoint1(connectionPt.0, p2: self.pieCenter)
        if (connectDist < node.deltaRadius) {
            if (connectionPt.1 == .RTop || connectionPt.1 == .RCenter || connectionPt.1 == .RBottom) {
                newFrame.origin.x -= (node.deltaRadius - connectDist)
            }
            else if (connectionPt.1 == .LTop || connectionPt.1 == .LCenter || connectionPt.1 == .LBottom) {
                newFrame.origin.x += (node.deltaRadius - connectDist)
            }
        }
        
        if (cAngle > CGFloat(2*M_PI)) {
            cAngle = cAngle - CGFloat(2*M_PI)
        }
        if (cAngle < 0) {
            cAngle = CGFloat(2*M_PI) - cAngle
        }
        
        return (newFrame, cAngle)
    }
    
    
    func calculateConnectionPoint (f:CGRect) -> (CGPoint, ConnectionPoint) {
        
        var connectionPt = ConnectionPoint.LTop
        
        let p1 = CGPointMake(CGRectGetMinX(f), CGRectGetMinY(f))    //LTop
        let d1 = self.distanceBetweenPoint1(self.pieCenter, p2: p1)
        
        let p2 = CGPointMake(CGRectGetMidX(f), CGRectGetMinY(f))    //MTop
        let d2 = self.distanceBetweenPoint1(self.pieCenter, p2: p2)
        
        let p3 = CGPointMake(CGRectGetMaxX(f), CGRectGetMinY(f))    //RTop
        let d3 = self.distanceBetweenPoint1(self.pieCenter, p2: p3)
        
        let p4 = CGPointMake(CGRectGetMinX(f), CGRectGetMidY(f))    //LCenter
        let d4 = self.distanceBetweenPoint1(self.pieCenter, p2: p4)
        
        let p5 = CGPointMake(CGRectGetMaxX(f), CGRectGetMidY(f))    //RCenter
        let d5 = self.distanceBetweenPoint1(self.pieCenter, p2: p5)
        
        let p6 = CGPointMake(CGRectGetMinX(f), CGRectGetMaxY(f))    //LBottom
        let d6 = self.distanceBetweenPoint1(self.pieCenter, p2: p6)
        
        let p7 = CGPointMake(CGRectGetMidX(f), CGRectGetMaxY(f))    //MBottom
        let d7 = self.distanceBetweenPoint1(self.pieCenter, p2: p7)
        
        let p8 = CGPointMake(CGRectGetMaxX(f), CGRectGetMaxY(f))    //RBottom
        let d8 = self.distanceBetweenPoint1(self.pieCenter, p2: p8)
        
        let d = min(d1, min(d2, min(d3, min(d4, min(d5, min(d6, min(d7, d8)))))))
        var p = p1
        
        switch d {
            case d1 :
                p = p1
                connectionPt = ConnectionPoint.LTop
            case d2 :
                p = p2
                connectionPt = ConnectionPoint.MTop
            case d3 :
                p = p3
                connectionPt = ConnectionPoint.RTop
            case d4 :
                p = p4
                connectionPt = ConnectionPoint.LCenter
            case d5 :
                p = p5
                connectionPt = ConnectionPoint.RCenter
            case d6 :
                p = p6
                connectionPt = ConnectionPoint.LBottom
            case d7 :
                p = p7
                connectionPt = ConnectionPoint.MBottom
            case d8 :
                p = p8
                connectionPt = ConnectionPoint.RBottom
            default:
                p = CGPointZero
        }
        
        return (p, connectionPt)
    }
    
    
    func sizedLabelForString(key:NSString, value:CGFloat) -> String {
        
        var str = key
        if (str.length > maxLabelCharacters) {
            str = key.substringToIndex(maxLabelCharacters)
            str = str.stringByAppendingString("...")
        }
        let valueStr = value.description
        if (str.length > maxLabelCharacters - valueStr.characters.count) {
            str = key.substringToIndex(maxLabelCharacters - valueStr.characters.count)
            str = str.stringByAppendingString("...")
        }
        
        //Display the value in addition to the key
        if (roundf(Float(value)) == Float(value)) {
            str = str.stringByAppendingString(" (\(Int(value)))")
        }
        else {
            str = str.stringByAppendingString(" (\(value))")
        }
        
        return str as String
    }
    
    
    func deltaRadiusCalc(progress:CGFloat, thePieRadius:CGFloat) -> CGFloat {
        
        if (!self.useVariableSizeSlicing) {
            return thePieRadius
        }
        else {
            //Variable size slicing
            let delta = 1 - (progress / self.maxValue);
            return (thePieRadius - self.variableSizeOffset) + (self.variableSizeOffset) * delta
        }
    }
    
    
    
    func fetchCollidingNodes(theNode:LabelNode) -> [LabelNode] {
        let theFrame        = theNode.frame
        var collidingNodes  = [LabelNode]()
        
        for node in self.labelNodes {
            
            if (CGRectIntersectsRect(theFrame, node.frame) && theNode.nodeIndex != node.nodeIndex) {
                collidingNodes.append(node)
            }
        }
        return collidingNodes
    }
    
    
    func shouldGoClockwise (theNode:LabelNode, collidingNode:LabelNode) -> Bool {
        
        var clockwiseDirection = true
        
        if (theNode.nodeIndex < collidingNode.nodeIndex) {
            
            clockwiseDirection = false
            if (collidingNode.nodeIndex - theNode.nodeIndex > 2) {
                clockwiseDirection = true
            }
        }
        else {
            if (theNode.nodeIndex - collidingNode.nodeIndex  > 2) {
                clockwiseDirection = false
            }
        }
        
        return clockwiseDirection
    }
    
    
    
    
    
//MARK: - Label Attributes
    
    
    
    
    func labelAttribs() -> NSDictionary {
        
        if (self.labelAttributes != nil) { return self.labelAttributes! }
        
        let paragraphStyle:NSMutableParagraphStyle  = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode    = .ByTruncatingTail
        paragraphStyle.alignment        = .Center
        
        self.labelAttributes = [
            NSFontAttributeName             : UIFont(name: self.labelFontName, size: self.labelFontSize)!,
            NSForegroundColorAttributeName  : UIColor.blackColor(),
            NSParagraphStyleAttributeName   : paragraphStyle,
            NSBackgroundColorAttributeName  : UIColor.clearColor()
        ]
        return self.labelAttributes!
    }
    
    
}





//MARK:- Extensions and enums




extension CGFloat {
    
    var DEGREE_TO_RADIANS:CGFloat {
        return (self * CGFloat(M_PI) / 180.0)
    }
    var RADIANS_TO_DEGREES:CGFloat {
        return (self * CGFloat(180 / M_PI))
    }
}


enum FrameSide:Int {
    case none
    case top
    case bottom
    case left
    case right
}


enum ConnectionPoint:Int {
    case LTop
    case LBottom
    case LCenter
    case RTop
    case RBottom
    case RCenter
    case MTop
    case MBottom
}




//MARK:- Label node protocol



protocol Node {
    
    var nodeIndex       :Int     { get set }
    var frame           :CGRect  { get set }
    
    init (frameVal:CGRect)
}

struct LabelNode:Node {
    
    var nodeIndex       :Int     = -1
    var frame           :CGRect  = CGRectZero
    
    var currentAngle    :CGFloat = 0
    var deltaRadius     :CGFloat = 0
    var sizedRadius     :CGFloat = 0
    
    var joint0StartPoint:CGPoint = CGPointZero
    var joint0EndPoint  :CGPoint = CGPointZero
    var joint1StartPoint:CGPoint = CGPointZero
    var joint1EndPoint  :CGPoint = CGPointZero
    var joint2EndPoint  :CGPoint = CGPointZero
    
    init(frameVal: CGRect) {
        frame = frameVal
    }
}