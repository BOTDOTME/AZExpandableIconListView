//
//  AZExpandableIconListView.swift
//  Pods
//
//  Created by Chris Wu on 01/28/2016.
//  Copyright (c) 2016 Chris Wu. All rights reserved.
//

import Foundation

open class AZExpandableIconListView: UIView {
    
    fileprivate var icons: [(UILabel, UIImageView)] = []
    fileprivate var scrollView: UIScrollView
    fileprivate var isSetupFinished: Bool = false
    fileprivate var isExpanded: Bool = false
    fileprivate var rightMiddleItemSpacingConstraint: NSLayoutConstraint!
    fileprivate var leftMiddleItemSpacingConstraint: NSLayoutConstraint!
    fileprivate var rightItemSpacingConstraints: [NSLayoutConstraint] = []
    fileprivate var leftItemSpacingConstraints: [NSLayoutConstraint] = []
    
    open var imageSpacing: CGFloat = 4.0
    open var onExpanded: (()->())?
    open var onCollapsed:(()->())?
    
    /// Image width is set to be always 80% of container view's frame width
    fileprivate var imageWidth: CGFloat { return scrollView.frame.height * 0.6 }
    fileprivate var halfImageWidth: CGFloat { return imageWidth * 0.5 }
    fileprivate var stretchedImageWidth: CGFloat { return (CGFloat(icons.count) * imageWidth) + (CGFloat(icons.count) * imageSpacing) }
    
    /**
     Initializer
     
     - parameter frame:  The frame
     - parameter images: An array of images that are going to be displayed
     
     - returns: an AZExpandableIconListView
     */
    /////////////////////////////////////////////////////////////////////////////
    public init(frame: CGRect, views: [(UILabel, UIImageView)], imageSpacing: CGFloat) {

        scrollView = UIScrollView(frame: frame)
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = true
        
        super.init(frame: frame)
        
        self.imageSpacing = imageSpacing
        self.clipsToBounds = false

        let onTapView = UITapGestureRecognizer(target: self, action: #selector(AZExpandableIconListView.onViewTapped))
        scrollView.addGestureRecognizer(onTapView)
        
        // Reverse the array of incoming participants so that the User is the last one added (is on top)
        for (label, image) in views.reversed() {
            let newImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth*0.5, height: imageWidth*0.5))
            newImageView.image = image.image
            newImageView.translatesAutoresizingMaskIntoConstraints = false
            self.icons.append((label, newImageView))
            scrollView.addSubview(newImageView)
        }

        // Reverse again so that constraints match in the future
        self.icons = self.icons.reversed()

        self.addSubview(scrollView)
        updateConstraints()
        updateContentSize()
    }
    
    /////////////////////////////////////////////////////////////////////////////
    func onViewTapped(){
        updateSpacingConstraints()
        isExpanded = !isExpanded
        displayNames()
        updateContentSize()
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.3,
                       options: UIViewAnimationOptions(),
                       animations: { [weak self] in self?.layoutIfNeeded() },
                       completion: { [weak self] finished in
                        if let weakself = self {
                            if weakself.isExpanded {
                                weakself.onExpanded?()
                            }
                            else { weakself.onCollapsed?() }
                        }
        })
    }
    
    /////////////////////////////////////////////////////////////////////////////
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /////////////////////////////////////////////////////////////////////////////
    open override func updateConstraints() {
        super.updateConstraints()
        if isSetupFinished == false {
            setupInitialLayout()
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////
    fileprivate func setupInitialLayout() {
        
        var layoutConstraints:[NSLayoutConstraint] = []
        let hasMiddle = icons.count % 2 == 0 ? false : true
        let middleIndex = hasMiddle ? ((icons.count - 1) / 2) : (icons.count / 2)
        let avatarYoffset = -(scrollView.frame.height / 8)
        var previousRightView = icons[middleIndex].1
        var previousLeftView = hasMiddle ? icons[middleIndex].1 : icons[middleIndex - 1].1

        // Add constraints for middle Avatar(s)
        
        if hasMiddle {
            let middleView = icons[middleIndex].1
            
            layoutConstraints.append(NSLayoutConstraint(item: middleView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: scrollView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: middleView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: middleView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: middleView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: scrollView, attribute: .centerX, multiplier: 1, constant: 1))
        }

        else {
            let middleRightView = icons[middleIndex].1
            let middleLeftView = icons[middleIndex - 1].1
            
            layoutConstraints.append(NSLayoutConstraint(item: middleRightView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: scrollView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: middleRightView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: middleRightView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))
            self.rightMiddleItemSpacingConstraint = NSLayoutConstraint(item: middleRightView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: scrollView, attribute: .centerX, multiplier: 1, constant: imageWidth * 0.25)

            layoutConstraints.append(NSLayoutConstraint(item: middleLeftView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: scrollView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: middleLeftView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: middleLeftView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))
            self.leftMiddleItemSpacingConstraint = NSLayoutConstraint(item: middleLeftView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: scrollView, attribute: .centerX, multiplier: 1, constant: -(imageWidth * 0.25))

            layoutConstraints.append(self.rightMiddleItemSpacingConstraint)
            layoutConstraints.append(self.leftMiddleItemSpacingConstraint)
        }
        
        // Add constraints iteratively for the non-middle Avatars
        
        for index in (middleIndex + 1) ..< icons.count {
            let distanceFromCenter = index - middleIndex
            let rightView = icons[index].1
            let leftView = hasMiddle ? icons[middleIndex - distanceFromCenter].1 : icons[(middleIndex - 1) - distanceFromCenter].1

            // Proportion constraints
            layoutConstraints.append(NSLayoutConstraint(item: rightView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: scrollView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: rightView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: rightView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))

            layoutConstraints.append(NSLayoutConstraint(item: leftView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: scrollView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: leftView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: leftView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 0.6, constant: 0))

            // Spacing constraints
            self.rightItemSpacingConstraints.append(NSLayoutConstraint(item: rightView, attribute: .left, relatedBy: .equal, toItem: previousRightView, attribute: .centerX, multiplier: 1, constant: 1))
            self.leftItemSpacingConstraints.append(NSLayoutConstraint(item: leftView, attribute: .right, relatedBy: .equal, toItem: previousLeftView, attribute: .centerX, multiplier: 1, constant: 1))

            previousRightView = rightView
            previousLeftView = leftView
        }

        layoutConstraints.append(contentsOf: rightItemSpacingConstraints)
        layoutConstraints.append(contentsOf: leftItemSpacingConstraints)
        scrollView.addConstraints(layoutConstraints)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[container]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["container":scrollView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[container]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["container":scrollView]))
        isSetupFinished = true
    }

    /////////////////////////////////////////////////////////////////////////////
    fileprivate func displayNames() {

        if (isExpanded) {

            var layoutConstraints: [NSLayoutConstraint] = []

            for icon in self.icons {

                let label = icon.0
                let image = icon.1

                label.font = UIFont(name: "Sofia Pro", size: 10.5)
                label.shadowOffset = CGSize(width: 0, height: 2)
                label.shadowColor = UIColor.black
                label.numberOfLines = 1

                image.addSubview(label)

                layoutConstraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: image, attribute: .centerX, multiplier: 1, constant: 0))
                layoutConstraints.append(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: image, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: imageWidth*0.75))
                layoutConstraints.append(NSLayoutConstraint(item: label, attribute: .width, relatedBy: .equal, toItem: image, attribute: .width, multiplier: 1.50, constant: 1))
                layoutConstraints.append(NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: image, attribute: .height, multiplier: 0.25, constant: 1))

                image.addConstraints(layoutConstraints)
                layoutConstraints = []
            }
        } else {
            for icon in self.icons {
                icon.0.removeFromSuperview()
            }
        }
    }

    /**
     Update the contraints of image spacing based on whether the images are expanded or not.
     Update content size of the containing UIScrollView.
     */
    /////////////////////////////////////////////////////////////////////////////
    fileprivate func updateSpacingConstraints() {
        if !isExpanded {
            for constraint in rightItemSpacingConstraints { constraint.constant = halfImageWidth + imageSpacing }
            for constraint in leftItemSpacingConstraints { constraint.constant = -(halfImageWidth + imageSpacing) }

            if let midRightConstraint = self.rightMiddleItemSpacingConstraint, let midLeftConstraint = self.leftMiddleItemSpacingConstraint {
                midRightConstraint.constant = (0.1 * imageWidth) + imageSpacing
                midLeftConstraint.constant = -((0.1 * imageWidth) + imageSpacing)
            }
        }
        else {
            for constraint in rightItemSpacingConstraints { constraint.constant = 1 }
            for constraint in leftItemSpacingConstraints { constraint.constant = 1 }

            if let middleRightConstraint = self.rightMiddleItemSpacingConstraint, let middleLeftConstraint = self.leftMiddleItemSpacingConstraint {
                middleRightConstraint.constant = imageWidth * 0.25
                middleLeftConstraint.constant = -(imageWidth * 0.25)
            }
        }
    }
    
    /**
     Update the content size of the containing UIScrollView based on whether the images are expanded or not.
     */
    /////////////////////////////////////////////////////////////////////////////
    fileprivate func updateContentSize(){
        if isExpanded {
            let width = stretchedImageWidth
            scrollView.contentSize = CGSize(width: width, height: self.frame.height)
            scrollView.contentInset = UIEdgeInsets(top: 0.0, left: width/2.5, bottom: 0.0, right: -(width/4))
        } else {
            let width = CGFloat(icons.count) * halfImageWidth
            scrollView.contentSize = CGSize(width: width, height: self.frame.height)
            scrollView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    /**
     Convert the passed in UIImage to a round UIImageView, plus add a white border around it.
     
     - parameter image: The icon
     - parameter frame: The container's frame of the image
     
     - returns: A circular UIImageView
     */
    /////////////////////////////////////////////////////////////////////////////
    fileprivate func buildCircularIconFrom(_ image:UIImage, containerFrame frame:CGRect) -> UIImageView {
        let newframe = CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth)
        
        let imageView = UIImageView(frame:newframe)
        imageView.image = image
        
        let borderLayer = CALayer()
        let borderFrame = CGRect(x: -1, y: -1, width: newframe.width + 2, height: newframe.height + 2)
        
        borderLayer.backgroundColor = UIColor.clear.cgColor
        borderLayer.frame = borderFrame
        borderLayer.cornerRadius = newframe.width * 0.5
        borderLayer.borderWidth = 2.0
        borderLayer.borderColor = UIColor.clear.cgColor
        borderLayer.masksToBounds = false
        
        imageView.layer.addSublayer(borderLayer)
        imageView.clipsToBounds = false
        imageView.layer.cornerRadius = newframe.width * 0.5
        
        return imageView
    }
    
}
