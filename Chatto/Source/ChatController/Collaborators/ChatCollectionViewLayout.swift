/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit

public protocol ChatCollectionViewLayoutDelegate: class {
    func chatCollectionViewLayoutModel() -> ChatCollectionViewLayoutModel
}

public struct ChatCollectionViewLayoutModel {
    let contentSize: CGSize
    let layoutAttributes: [UICollectionViewLayoutAttributes]
    var layoutAttributesBySectionAndItem: [[UICollectionViewLayoutAttributes]]
    let initialLayoutAttributesBySectionAndItem: [[UICollectionViewLayoutAttributes]]
    let calculatedForWidth: CGFloat

    public static func createModel(_ collectionViewWidth: CGFloat, itemsLayoutData: [(height: CGFloat, bottomMargin: CGFloat)]) -> ChatCollectionViewLayoutModel {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        var layoutAttributesBySectionAndItem = [[UICollectionViewLayoutAttributes]]()
        layoutAttributesBySectionAndItem.append([UICollectionViewLayoutAttributes]())
        var initialLayoutAttributesBySectionAndItem = [[UICollectionViewLayoutAttributes]]()
        
        var verticalOffset: CGFloat = 0
        for (index, layoutData) in itemsLayoutData.enumerated() {
            let indexPath = IndexPath(item: index, section: 0)
            let (height, bottomMargin) = layoutData
            let itemSize = CGSize(width: collectionViewWidth, height: height)
            let frame = CGRect(origin: CGPoint(x: 0, y: verticalOffset), size: itemSize)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            layoutAttributes.append(attributes)
            layoutAttributesBySectionAndItem[0].append(attributes)
            verticalOffset += itemSize.height
            verticalOffset += bottomMargin
        }
        
        for layoutAttributes in layoutAttributesBySectionAndItem {
            let cloneLayoutAttributes = layoutAttributes.clone()
            initialLayoutAttributesBySectionAndItem.append(cloneLayoutAttributes)
        }

        return ChatCollectionViewLayoutModel(
            contentSize: CGSize(width: collectionViewWidth, height: verticalOffset),
            layoutAttributes: layoutAttributes,
            layoutAttributesBySectionAndItem: layoutAttributesBySectionAndItem,
            initialLayoutAttributesBySectionAndItem: initialLayoutAttributesBySectionAndItem,
            calculatedForWidth: collectionViewWidth
        )
    }

    public static func createEmptyModel() -> ChatCollectionViewLayoutModel {
        return ChatCollectionViewLayoutModel(
            contentSize: .zero,
            layoutAttributes: [],
            layoutAttributesBySectionAndItem: [],
            initialLayoutAttributesBySectionAndItem: [],
            calculatedForWidth: 0
        )
    }
}

open class ChatCollectionViewLayout: UICollectionViewFlowLayout {
    var layoutModel: ChatCollectionViewLayoutModel!
    public weak var delegate: ChatCollectionViewLayoutDelegate?
    
    open var stickyIndexPaths = [IndexPath(row: 0, section: 0)]
    private var insertingIndexPaths = [IndexPath]()

    // Optimization: after reloadData we'll get invalidateLayout, but prepareLayout will be delayed until next run loop.
    // Client may need to force prepareLayout after reloadData, but we don't want to compute layout again in the next run loop.
    private var layoutNeedsUpdate = true
    open override func invalidateLayout() {
        super.invalidateLayout()
        self.layoutNeedsUpdate = true
    }
    
    public func updateStickyIndexPathsSet(_ dataSource: ChatDataSourceProtocol) {
        stickyIndexPaths = []
        for (indx, chatItem) in dataSource.chatItems.enumerated() {
            guard chatItem is Stickable else { continue }
            stickyIndexPaths.append(IndexPath(item: indx, section: 0))
        }
    }
    
    public func cellInStickedState(by indexPath: IndexPath) -> Bool {
        guard
            let initialLayoutAttributes = layoutModel.initialLayoutAttributesBySectionAndItem[guarded: indexPath.section]?[guarded: indexPath.item],
            let layoutAttributes = layoutModel.layoutAttributesBySectionAndItem[guarded: indexPath.section]?[guarded: indexPath.item]
            else { return false }
        
        return initialLayoutAttributes.frame.origin.y < layoutAttributes.frame.origin.y// - 50
    }
    
    open override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        
        insertingIndexPaths.removeAll()
        
        for update in updateItems {
            if let indexPath = update.indexPathAfterUpdate, update.updateAction == .insert {
                insertingIndexPaths.append(indexPath)
            }
        }
    }
    
    open override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        
        insertingIndexPaths.removeAll()
    }
    
    open override func prepare() {
        super.prepare()
        guard self.layoutNeedsUpdate else { return }
        guard let delegate = self.delegate else {
            self.layoutModel = ChatCollectionViewLayoutModel.createEmptyModel()
            return
        }
        var oldLayoutModel = self.layoutModel
        self.layoutModel = delegate.chatCollectionViewLayoutModel()
        self.layoutNeedsUpdate = false
        DispatchQueue.global(qos: .default).async { () -> Void in
            // Dealloc of layout with 5000 items take 25 ms on tests on iPhone 4s
            // This moves dealloc out of main thread
            if oldLayoutModel != nil {
                // Use nil check above to remove compiler warning: Variable 'oldLayoutModel' was written to, but never read
                oldLayoutModel = nil
            }
        }
    }
    
    open override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let oldBounds = collectionView!.bounds
        let sizeChanged = oldBounds.width != newBounds.width || oldBounds.height != newBounds.height
        
        let context = super.invalidationContext(forBoundsChange: newBounds)
        
        if !sizeChanged {
            context.invalidateItems(at: stickyIndexPaths)
        }
        return context
    }
    
    override open func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        
        if insertingIndexPaths.contains(itemIndexPath) {
            attributes?.alpha = 1.0
            attributes?.frame.origin.y -= attributes!.frame.height
            
        }
        return attributes
    }
    
    open override var collectionViewContentSize: CGSize {
        return self.layoutModel?.contentSize ?? .zero
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var newLayoutAttributes = [UICollectionViewLayoutAttributes]()

        let layoutAttributesForElementsInRect = self.layoutModel.layoutAttributes.filter { $0.frame.intersects(rect) }
        for layoutAttributesItem in layoutAttributesForElementsInRect {
            guard !stickyIndexPaths.contains(layoutAttributesItem.indexPath), layoutAttributesItem.representedElementKind == nil else {
                continue
            }
            newLayoutAttributes.append(layoutAttributesItem)
        }
        for indexPath in stickyIndexPaths {
            if let attr = layoutAttributesForItem(at: indexPath) {
                newLayoutAttributes.append(attr)
            }
        }
        
        return newLayoutAttributes
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let initialLayoutAttributes = layoutModel.initialLayoutAttributesBySectionAndItem[guarded: indexPath.section]?[guarded: indexPath.item] else {
            return super.layoutAttributesForItem(at: indexPath)
        }
        guard
            let collectionView = collectionView,
            let layoutAttributes = layoutModel.layoutAttributesBySectionAndItem[guarded: indexPath.section]?[guarded: indexPath.item],
            stickyIndexPaths.contains(indexPath)
            else { return initialLayoutAttributes }
        
        let headerCellStickyPositionYOffset = collectionView.contentOffset.y + layoutAttributes.frame.height + (collectionView.parentViewController?.navigationController?.navigationBar.frame.height ?? 0.0)
        
        guard headerCellStickyPositionYOffset > initialLayoutAttributes.frame.origin.y else {
            return initialLayoutAttributes
        }
        
        layoutAttributes.zIndex = 1000
        layoutAttributes.frame.origin.y = headerCellStickyPositionYOffset
        return makePopingHeaderCellIfNeeded(on: indexPath, with: layoutAttributes, initialLayoutAttributes: initialLayoutAttributes)
    }
    
    func makePopingHeaderCellIfNeeded(on indexPath: IndexPath, with layoutAttributes: UICollectionViewLayoutAttributes, initialLayoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard
            let nextStickyCellIndexPath = stickyIndexPaths[guarded: stickyIndexPaths.firstIndex(of: indexPath)! + 1],
            let nextHeaderCellLayoutAttributes = layoutModel.initialLayoutAttributesBySectionAndItem[guarded: nextStickyCellIndexPath.section]?[guarded: nextStickyCellIndexPath.item]
            else {
                return layoutAttributes
        }
        
        let cellsSpacing = nextHeaderCellLayoutAttributes.frame.origin.y - layoutAttributes.frame.origin.y
    
        guard cellsSpacing <= layoutAttributes.frame.height else { return layoutAttributes }
        if cellsSpacing < -60.0 {
            return initialLayoutAttributes
        } else {
            layoutAttributes.frame.origin.y = layoutAttributes.frame.origin.y - layoutAttributes.frame.height + cellsSpacing
            return layoutAttributes
        }
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

extension Array {
    subscript(guarded idx: Int) -> Element? {
        guard (startIndex..<endIndex).contains(idx) else {
            return nil
        }
        return self[idx]
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

extension Array where Element: NSCopying {
    func clone() -> Array {
        var copiedArray = Array<Element>()
        for element in self {
            copiedArray.append(element.copy() as! Element)
        }
        return copiedArray
    }
}

