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


import Chatto

class DateSeparatorPresenter<SupplementaryT: TimeSeparatorModel>: SupplementaryChatItemPresenterProtocol {
    public final weak var dateSeparatorModel: SupplementaryT?

    init(dateSeparatorModel: SupplementaryT) {
        self.dateSeparatorModel = dateSeparatorModel
    }
    
    static func registerSupplementaryItem(_ collectionView: UICollectionView) {
        collectionView.register(DateSeparatorSupplementaryView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DateSeparatorSupplementaryView.reuseIdentifier)
    }
    
    func heightForSupplementaryItem(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 24
    }
    
    func dequeueSupplementaryItem(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: DateSeparatorSupplementaryView.reuseIdentifier, for: indexPath)
    }
    
    func configureSupplementaryItem(_ reusableView: UICollectionReusableView, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        guard let dateSeparatorView = reusableView as? DateSeparatorSupplementaryView else {
            assert(false, "expecting status cell")
            return
        }
        dateSeparatorView.text = dateSeparatorModel?.date ?? ""
    }
}

class DateSeparatorPresenterBuilder: SupplementaryChatItemPresenterBuilderProtocol {
    
    func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem is DateSeparatorModel
    }
    
    func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> SupplementaryChatItemPresenterProtocol {
        assert(self.canHandleChatItem(chatItem))
        return DateSeparatorPresenter(dateSeparatorModel: chatItem as! TimeSeparatorModel)
    }
    
    var presenterType: SupplementaryChatItemPresenterProtocol.Type {
        return DateSeparatorPresenter.self
    }
}


// MARK: - Auto creation reuseIdentifier
protocol Reusable {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionReusableView: Reusable {}
