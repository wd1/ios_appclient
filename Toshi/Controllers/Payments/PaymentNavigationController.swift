import UIKit

final class PaymentNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.barStyle = .default
        navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationBar.shadowImage = UIImage()
        
        let titleTextAttributes: [NSAttributedStringKey: Any] = [
            .font: Theme.regular(size: 17),
            .foregroundColor: Theme.darkTextColor
        ]
        
        navigationBar.titleTextAttributes = titleTextAttributes
    }
}
