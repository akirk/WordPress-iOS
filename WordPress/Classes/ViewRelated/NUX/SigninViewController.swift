import UIKit

typealias SigninCallbackBlock = () -> Void

class SigninViewController : UIViewController
{
    @IBOutlet var containerView: UIView!
    @IBOutlet var helpButton: UIButton!
    @IBOutlet var icon: UIImageView!
    @IBOutlet var toggleSigninButton: UIButton!
    @IBOutlet var createAccountButton: UIButton!

    var childViewControllerStack = [UIViewController]()
    
    private var currentChildViewController: UIViewController? {
        return childViewControllerStack.last
    }
    
    class func controller() -> SigninViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninViewController") as! SigninViewController

        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad();
        navigationController?.navigationBarHidden = true

        showSigninEmailViewController()
        
        createAccountButton.addTarget(self, action: "buttonTapped", forControlEvents: .TouchUpInside)
        toggleSigninButton.addTarget(self, action: "otherButtonTapped", forControlEvents: .TouchUpInside)
    }
    
    func buttonTapped() {
        func nextVCName() -> String {
            if childViewControllerStack.count % 2 != 0 {
                return "SignIn2FAViewController"
            } else {
                return "SignInSelfHostedViewController"
            }
        }
        let storyboard = UIStoryboard(name: "SignInSelfHosted", bundle: NSBundle.mainBundle())
        let vc = storyboard.instantiateViewControllerWithIdentifier(nextVCName())
        pushChildViewController(vc, animated: true)
    }
    
    func otherButtonTapped() {
        popChildViewController(true)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let child = segue.destinationViewController
        child.view.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Controller Factories


    func showSigninEmailViewController() {
        let controller = SigninEmailViewController.controller({ email in
            self.validateEmail(email)
        })

        pushChildViewController(controller, animated: false)
    }


    func showSigninMagicLinkViewController() {
        let controller = SigninMagicLinkViewController.controller({
                self.requestLink()
            },
            signinWithPasswordBlock: {
                self.signinWithPassword()
        })

        pushChildViewController(controller, animated: true)
    }


    func showOpenMailViewController() {
        let controller = SigninOpenMailViewController.controller({
                self.openMail()
            },
            skipBlock: {
                self.signinWithPassword()
        })

        pushChildViewController(controller, animated: true)
    }


    // MARK: - Child Controller Callbacks


    func validateEmail(email: String) {
        showSigninMagicLinkViewController()
    }


    func signinWithPassword() {
        NSLog("Show password form")
    }


    func requestLink() {
        showOpenMailViewController()
    }


    func openMail() {
        let url = NSURL(string: "message://")!
        UIApplication.sharedApplication().openURL(url)
    }


    // MARK: - Actions

    @IBAction func handleCreateAccountTapped(sender: UIButton) {

    }


    @IBAction func handleToggleSigninTapped(sender: UIButton) {

    }


    @IBAction func handleHelpTapped(sender: UIButton) {

    }
    
    private var isAnimating = false
    
    func pushChildViewController(viewController: UIViewController, animated: Bool) {
        if isAnimating { return }
        
        addViewController(viewController)
        
        if !animated {
            removeViewController(currentChildViewController)
            
            containerView.pinSubview(viewController.view, toAttributes: [.Top, .Bottom, .Width, .Leading])
            childViewControllerStack.append(viewController)
        } else {
            animateFromViewController(currentChildViewController, toViewController: viewController, direction: .Right, completion: {
                self.childViewControllerStack.append(viewController)
            })
        }
    }
    
    func popChildViewController(animated: Bool) {
        if isAnimating { return }
        
        guard let currentChild =  childViewControllerStack.popLast() else { return }
        
        if !animated {
            removeViewController(currentChild)
            
            guard let previousChild = childViewControllerStack.last else { return }

            addViewController(previousChild)
            containerView.pinSubview(previousChild.view, toAttributes: [.Top, .Bottom, .Width, .Leading])
            containerView.layoutIfNeeded()
        } else {
            guard let previousChild = childViewControllerStack.last else {
                removeViewController(currentChild)
                return
            }
            
            addViewController(previousChild)
            
            animateFromViewController(currentChild, toViewController: previousChild, direction: .Left, completion: nil)
        }
    }
    
    private enum AnimationDirection {
        case Left
        case Right
    }
    
    private func animateFromViewController(fromViewController: UIViewController?, toViewController: UIViewController, direction: AnimationDirection, completion: (() -> Void)?) {
        isAnimating = true
        
        containerView.pinSubview(toViewController.view, toAttributes: [.Top, .Bottom, .Width])
        containerView.layoutIfNeeded()
        containerView.pinSubview(toViewController.view, toAttributes: [.Leading])
        
        func translateXForDirection(direction: AnimationDirection) -> CGFloat {
            switch direction {
            case .Left:
                return -CGRectGetWidth(containerView.frame)
            case .Right:
                return CGRectGetWidth(containerView.frame)
            }
        }
        
        let translateX = translateXForDirection(direction)

        toViewController.view.transform = CGAffineTransformMakeTranslation(translateX, 0)
        
        UIView.animateWithDuration(0.3, animations: {
            self.view.layoutIfNeeded()
            toViewController.view.transform = CGAffineTransformIdentity
            
            fromViewController?.view.transform = CGAffineTransformMakeTranslation(-translateX, 0)
        }, completion: { _ in
            UIView.animateWithDuration(0.3, animations: {
                self.removeViewController(fromViewController)
                self.view.layoutIfNeeded()
                }, completion: { _ in
                    completion?()
                    self.isAnimating = false
            })
        })
    }
    
    private func addViewController(viewController: UIViewController) {
        addChildViewController(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.didMoveToParentViewController(self)
    }
    
    private func removeViewController(viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        viewController.willMoveToParentViewController(nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
    }
}
