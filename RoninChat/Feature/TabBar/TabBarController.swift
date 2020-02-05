import UIKit

class TabBarController: UITabBarController {
    public static let segueIdentifer: String = "showTabBarController"
    
    @IBAction func unwindFromConversationViewController(sender: UIStoryboardSegue) {}
    
    public enum Tab: Int {
        case messages
        case channels
        case settings
        
        var stringValue: String {
            switch self {
            case .messages:
                return "messages"
            case .channels:
                return "channels"
            case .settings:
                return "settings"
            }
        }
    }
    
    override func viewDidLoad() {
        updateTabBarFont()
    }
    
    func updateTabBarFont() {
        let unselectedAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font: UIFont(name: "Open Sans", size: 12) ?? UIFont.systemFont(ofSize: 12.0),
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        ]
        
        let selectedAttributes:  [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font: UIFont(name: "Open Sans", size: 12) ?? UIFont.systemFont(ofSize: 12.0),
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.7033198476, green: 0.9377081394, blue: 0.697550118, alpha: 1)
        ]
        
        UITabBarItem.appearance().setTitleTextAttributes(unselectedAttributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)
    }
    
    func updateBadge(_ count: Int, for tab: Tab) {
        guard let tabBarItems = self.tabBar.items,
            isTabVisible(tab),
            let tabPosition = position(of: tab) else {
                return
        }
            
        let tabBarItem = tabBarItems[tabPosition]
        
        switch count {
        case 0:
            tabBarItem.badgeValue = nil
        case 1...99:
            tabBarItem.badgeValue = String(count)
        default:
            tabBarItem.badgeValue = "99+"
        }
    }
    
    private func isTabVisible(_ tab: Tab) -> Bool {
        guard let visibleTabs = self.tabBar.items else {
            return false
        }
        
        for case let visibleTab in visibleTabs {
            if let tabTitle = visibleTab.title, tabTitle.caseInsensitiveCompare(tab.stringValue).rawValue == 0 {
                return true
            }
        }
        
        return false
    }
    
    private func position(of tab: Tab) -> Int? {
        guard let visibleTabs = self.tabBar.items else {
            return nil
        }
        
        for case let visibleTab in visibleTabs {
            if let tabTitle = visibleTab.title, tabTitle.caseInsensitiveCompare(tab.stringValue).rawValue == 0 {
                return (visibleTabs.firstIndex(of: visibleTab))!
            }
        }
        
        return nil
    }
}
