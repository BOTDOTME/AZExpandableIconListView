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
    fileprivate var contentView: UIView
    fileprivate var isSetupFinished: Bool = false
    open var isExpanded: Bool = false
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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = true
        
        contentView = UIView(frame: frame)

        super.init(frame: frame)
        
        self.imageSpacing = imageSpacing
        self.clipsToBounds = false
        
        let onTapView = UITapGestureRecognizer(target: self, action: #selector(AZExpandableIconListView.adjustView))
        onTapView.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(onTapView)

        var tag = views.count - 1

        // Add the participantViews
        // Reverse the array of incoming participants so that the User is the last one added (is on top)
        for (label, image) in views.reversed() {
            image.frame = CGRect(x: 0, y: 0, width: imageWidth*0.5, height: imageWidth*0.5)
            image.tag = tag
            self.icons.append((label, image))
            contentView.addSubview(image)
            tag -= 1
        }

        // Reverse again so that constraints match in the future
        self.icons = self.icons.reversed()

        self.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // constraints for scrollView -> self
        self.addConstraint(NSLayoutConstraint(item: scrollView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: scrollView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: scrollView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: scrollView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0))

        // constraints for contentView -> scrollView
        scrollView.addConstraint(NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: scrollView, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        scrollView.addConstraint(NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: scrollView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
        scrollView.addConstraint(NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: 1, constant: 0))
        scrollView.addConstraint(NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 1, constant: 0))
        scrollView.addConstraint(NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: scrollView, attribute: .top, multiplier: 1, constant: 0))
        scrollView.addConstraint(NSLayoutConstraint(item: contentView, attribute: .left, relatedBy: .equal, toItem: scrollView, attribute: .left, multiplier: 1, constant: 0))
        scrollView.addConstraint(NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: scrollView, attribute: .bottom, multiplier: 1, constant: 0))
        scrollView.addConstraint(NSLayoutConstraint(item: contentView, attribute: .right, relatedBy: .equal, toItem: scrollView, attribute: .right, multiplier: 1, constant: 0))

        updateConstraints()
        updateContentSize()
    }
    
    /////////////////////////////////////////////////////////////////////////////
    public func adjustView(){

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
        let avatarYoffset = -(self.frame.height / 8)
        var previousRightView = icons[middleIndex].1
        var previousLeftView = hasMiddle ? icons[middleIndex].1 : icons[middleIndex - 1].1

        // Add constraints for middle Avatar(s)

        if hasMiddle {
            let middleView = icons[middleIndex].1
            
            layoutConstraints.append(NSLayoutConstraint(item: middleView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: middleView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: middleView, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: middleView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 1))
        }

        else {
            let middleRightView = icons[middleIndex].1
            let middleLeftView = icons[middleIndex - 1].1

            layoutConstraints.append(NSLayoutConstraint(item: middleRightView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: middleRightView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: middleRightView, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))
            self.rightMiddleItemSpacingConstraint = NSLayoutConstraint(item: middleRightView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: imageWidth * 0.25)

            layoutConstraints.append(NSLayoutConstraint(item: middleLeftView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: middleLeftView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: middleLeftView, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))
            self.leftMiddleItemSpacingConstraint = NSLayoutConstraint(item: middleLeftView, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: -(imageWidth * 0.25))

            layoutConstraints.append(self.rightMiddleItemSpacingConstraint)
            layoutConstraints.append(self.leftMiddleItemSpacingConstraint)
        }

        // Add constraints iteratively for the non-middle Avatars

        for index in (middleIndex + 1) ..< icons.count {
            let distanceFromCenter = index - middleIndex
            let rightView = icons[index].1
            let leftView = hasMiddle ? icons[middleIndex - distanceFromCenter].1 : icons[(middleIndex - 1) - distanceFromCenter].1

            // Proportion constraints
            layoutConstraints.append(NSLayoutConstraint(item: rightView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: rightView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: rightView, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))

            layoutConstraints.append(NSLayoutConstraint(item: leftView, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: avatarYoffset))
            layoutConstraints.append(NSLayoutConstraint(item: leftView, attribute: .width, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))
            layoutConstraints.append(NSLayoutConstraint(item: leftView, attribute: .height, relatedBy: .equal, toItem: contentView, attribute: .height, multiplier: 0.6, constant: 0))

            // Spacing constraints
            self.rightItemSpacingConstraints.append(NSLayoutConstraint(item: rightView, attribute: .left, relatedBy: .equal, toItem: previousRightView, attribute: .centerX, multiplier: 1, constant: 1))
            self.leftItemSpacingConstraints.append(NSLayoutConstraint(item: leftView, attribute: .right, relatedBy: .equal, toItem: previousLeftView, attribute: .centerX, multiplier: 1, constant: 1))

            previousRightView = rightView
            previousLeftView = leftView
        }

        layoutConstraints.append(contentsOf: rightItemSpacingConstraints)
        layoutConstraints.append(contentsOf: leftItemSpacingConstraints)

        contentView.addConstraints(layoutConstraints)

        isSetupFinished = true
    }

    /////////////////////////////////////////////////////////////////////////////
    fileprivate func displayNames() {

        if (isExpanded) {

            var layoutConstraints: [NSLayoutConstraint] = []

            for icon in self.icons {

                let label = icon.0
                let image = icon.1

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

        // Spacing constraints for expanding
        if !isExpanded {

            let width = stretchedImageWidth < scrollView.frame.width ? scrollView.frame.width : stretchedImageWidth

            contentView.frame = CGRect(x: (contentView.frame.origin.x), y: contentView.frame.origin.y, width: width, height: scrollView.frame.height)
            scrollView.contentSize = CGSize(width: contentView.frame.width, height: scrollView.frame.height)

            for constraint in rightItemSpacingConstraints { constraint.constant = halfImageWidth + imageSpacing }
            for constraint in leftItemSpacingConstraints { constraint.constant = -(halfImageWidth + imageSpacing) }

            if let midRightConstraint = self.rightMiddleItemSpacingConstraint, let midLeftConstraint = self.leftMiddleItemSpacingConstraint {
                midRightConstraint.constant = (0.1 * imageWidth) + imageSpacing
                midLeftConstraint.constant = -((0.1 * imageWidth) + imageSpacing)
            }
        }

        // Spacing constraints for contracting
        else {
            contentView.frame = CGRect(x: scrollView.frame.origin.x, y: scrollView.frame.origin.y + 10.0, width: scrollView.frame.width, height: scrollView.frame.height)
            scrollView.contentSize = CGSize(width: contentView.frame.width, height: scrollView.frame.height)

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

        // Update for expanded content
        if isExpanded {
            let width = stretchedImageWidth
            scrollView.contentSize = CGSize(width: width, height: scrollView.frame.height)
        }

        // Update for contracted content
        else {
            let width = CGFloat(icons.count) * halfImageWidth
            scrollView.contentSize = CGSize(width: width, height: scrollView.frame.height)
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
