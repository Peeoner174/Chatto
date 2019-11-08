//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

// Supplementary is variety of chat item

public protocol SupplementaryItemProtocol: AnyObject, UniqueIdentificable {
    /// Supplementary element
    var supplementary: ChatItemProtocol { get }
    /// Related messages elements
    var messages: [ChatItemProtocol] { get set}
}

public protocol SupplementaryItemPresenterProtocol: class {
    static func registerSupplementaryItem(_ collectionView: UICollectionView)
    
    var canCalculateHeightInBackground: Bool { get } // Default is false
    func heightForSupplementaryItem(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat
    func dequeueSupplementaryItem(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionReusableView
    func configureSupplementaryItem(_ cell: UICollectionReusableView, decorationAttributes: ChatItemDecorationAttributesProtocol?)
    func supplementaryItemWillBeShown(_ cell: UICollectionReusableView) // optional
    func supplementaryItemWasHidden(_ cell: UICollectionReusableView) // optional
}

public protocol SectionItemPresenterBuilderProtocol {
    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool
    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> SectionItemPresenterProtocol
    var presenterType: SectionItemPresenterProtocol.Type { get }
}
