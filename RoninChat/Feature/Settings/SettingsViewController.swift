import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var environmentLabel: UILabel!
    @IBOutlet var versionLabel: UILabel!
    
    @IBAction func unwindFromWebViewController(sender: UIStoryboardSegue) {}
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        avatarView.set(user: Ronin.shared.authUser)
        nameLabel.text = Ronin.shared.authUser?.fullName
        emailLabel.text = Ronin.shared.authUser?.email
        environmentLabel.text = Ronin.shared.serverInfo?.hostName
        versionLabel.text = Ronin.shared.serverInfo?.serverVersion
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WebKitViewController.segueIdentifier, let viewController = segue.destination as? WebKitViewController {
            viewController.url = URL(string: "https://en.gravatar.com")
        }
    }
    
    @IBAction func signOutButtonOnTouchUpInside(_ sender: UIButton) {
        Ronin.shared.signOut()
        Ronin.reset()
        self.performSegue(withIdentifier: LoginViewController.unwindSegueIdentifier, sender: nil)
    }
}


// MARK: OutlinedButtonDelegate

extension SettingsViewController: OutlinedButtonDelegate {
    func touchUpInside() {
        self.performSegue(withIdentifier: WebKitViewController.segueIdentifier, sender: nil)
    }
}
