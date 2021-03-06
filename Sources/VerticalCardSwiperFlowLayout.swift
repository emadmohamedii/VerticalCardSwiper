// MIT License
//
// Copyright (c) 2017 Joni Van Roost
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

/// Custom `UICollectionViewFlowLayout` that provides the flowlayout information like paging and `CardCell` movements.
internal class VerticalCardSwiperFlowLayout: UICollectionViewFlowLayout {
    
    /// This property sets the amount of scaling for the first item.
    internal var firstItemTransform: CGFloat?
    /// This property enables paging per card. Default is true.
    internal var isPagingEnabled: Bool = true
    /// Stores the height of a CardCell.
    internal var cellHeight: CGFloat!
    /// Allows you to make the previous card visible or not visible (stack effect). Default is `true`.
    internal var isPreviousCardVisible: Bool = true
    
    internal override func prepare() {
        super.prepare()
        
        assert(collectionView!.numberOfSections == 1, "Number of sections should always be 1.")
        assert(collectionView!.isPagingEnabled == false, "Paging on the collectionview itself should never be enabled. To enable cell paging, use the isPagingEnabled property of the VerticalCardSwiperFlowLayout instead.")
    }
    
    internal override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let items = NSArray (array: super.layoutAttributesForElements(in: rect)!, copyItems: true)
        
        items.enumerateObjects(using: { (object, index, stop) -> Void in
            let attributes = object as! UICollectionViewLayoutAttributes
            
            self.updateCellAttributes(attributes)
        })
        
        return items as? [UICollectionViewLayoutAttributes]
    }
    
    internal override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        if self.collectionView?.numberOfItems(inSection: 0) == 0 { return nil }
        
        if let attr = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes {
            self.updateCellAttributes(attr)
            return attr
        }
        return nil
    }
    
    // We invalidate the layout when a "bounds change" happens, for example when we scale the top cell. This forces a layout update on the flowlayout.
    internal override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    // Cell paging
    internal override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        // If the property `isPagingEnabled` is set to false, we don't enable paging and thus return the current contentoffset.
        guard isPagingEnabled else {
            let latestOffset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
            return latestOffset
        }
        
        // Page height used for estimating and calculating paging.
        let pageHeight = cellHeight + self.minimumLineSpacing

        // Make an estimation of the current page position.
        let approximatePage = self.collectionView!.contentOffset.y/pageHeight
        
        // Determine the current page based on velocity.
        let currentPage = (velocity.y < 0.0) ? floor(approximatePage) : ceil(approximatePage)
        
        // Create custom flickVelocity.
        let flickVelocity = velocity.y * 0.4
        
        // Check how many pages the user flicked, if <= 1 then flickedPages should return 0.
        let flickedPages = (abs(round(flickVelocity)) <= 1) ? 0 : round(flickVelocity)
        
        // Calculate newVerticalOffset.
        let newVerticalOffset = ((currentPage + flickedPages) * pageHeight) - self.collectionView!.contentInset.top

        return CGPoint(x: proposedContentOffset.x, y: newVerticalOffset)
    }
    
    internal override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        // attributes for swiping card away
        return self.layoutAttributesForItem(at: itemIndexPath)
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        // attributes for adding card
        return self.layoutAttributesForItem(at: itemIndexPath)
    }
    
    /**
     Updates the attributes.
     Here manipulate the zIndex of the cards here, calculate the positions and do the animations.
     - parameter attributes: The attributes we're updating.
     */
    fileprivate func updateCellAttributes(_ attributes: UICollectionViewLayoutAttributes) {
        
        var minY = collectionView!.bounds.minY + collectionView!.contentInset.top
        let maxY = attributes.frame.origin.y
        
        if minY > attributes.frame.origin.y + attributes.bounds.height + minimumLineSpacing + collectionView!.contentInset.top {
            minY = 0
        }
        
        let finalY = max(minY, maxY)
        var origin = attributes.frame.origin
        let deltaY = (finalY - origin.y) / attributes.frame.height
        let translationScale = CGFloat((attributes.zIndex + 1) * 10)
        
        // Card stack effect
        if let itemTransform = firstItemTransform {
            let scale = 1 - deltaY * itemTransform
            
            var t = CGAffineTransform.identity
            
            t = t.scaledBy(x: scale, y: 1)
            if isPreviousCardVisible {
                t = t.translatedBy(x: 0, y: (deltaY * translationScale))
            }

            attributes.transform = t
        }
        
        origin.x = (self.collectionView?.frame.width)! / 2 - attributes.frame.width / 2 - (self.collectionView?.contentInset.left)!
        origin.y = finalY
        attributes.frame = CGRect(origin: origin, size: attributes.frame.size)
        attributes.zIndex = attributes.indexPath.row
    }
}
