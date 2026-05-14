import UIKit
import DiiaUIComponents

final class DSImageNameResolver: DSImageNameProvider {
    
    static let instance = DSImageNameResolver()
    
    public func imageForCode(imageCode: String, placeholder: UIImage?) -> UIImage? {
        return UIImage(named: "DS_" + imageCode) ?? placeholder
    }
    
    public func imageForCode(imageCode: String?) -> UIImage? {
        guard let imageCode else { return nil }
        return imageForCode(imageCode: imageCode, placeholder: R.image.ds_placeholder.image)
    }
    
    func imageNameForCode(imageCode: String) -> String {
        return "DS_" + imageCode
    }
}
