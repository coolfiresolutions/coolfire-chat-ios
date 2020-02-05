import UIKit

extension UIScrollView {
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismissKeyboard()
        super.touchesBegan(touches, with: event)
    }
    
    
    // taken from: https://stackoverflow.com/a/33568798 on 09/24/2019
    var scrolledToTop: Bool {
        let topEdge = 0 - contentInset.top
        return contentOffset.y <= topEdge
    }

    var scrolledToBottom: Bool {
        let bottomEdge = contentSize.height + contentInset.bottom - bounds.height
        return contentOffset.y >= bottomEdge
    }
}
