import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    var imageView : RPImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initImageView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initImageView()
    }
    
    func initImageView() {
        imageView = RPImageView(frame: self.contentView.bounds)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.addSubview(imageView)
    }
    
    override func prepareForReuse() {
        imageView.rp_cancelSet()
        imageView.image = nil
    }
    
}
