import UIKit

class SigninPasswordViewController: UIViewController, SigninChildViewController {
    var signinSuccessCallback: SigninSuccessBlock?
    var signinFailureCallback: SigninFailureBlock?

    @IBOutlet weak var signInButton: WPNUXMainButton!
    @IBOutlet weak var passwordField: UITextField!
    
    var email: String!
    var loginFields: LoginFields? {
        get {
            return LoginFields(username: email, password: passwordField.text, siteUrl: nil, multifactorCode: nil, userIsDotCom: true, shouldDisplayMultiFactor: false)
        }
        set {}
    }
    
    lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade()
        facade.delegate = self
        return facade
    }()
    
    lazy var blogSyncFacade = BlogSyncFacade()
    lazy var accountServiceFacade = AccountServiceFacade()
    
    var backButtonEnabled: Bool {
        return true
    }

    class func controller(email: String, success: SigninSuccessBlock, failure: SigninFailureBlock) -> SigninPasswordViewController {
        let storyboard = UIStoryboard(name: "Signin", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("SigninPasswordViewController") as! SigninPasswordViewController
        
        controller.email = email
        controller.signinSuccessCallback = success
        controller.signinFailureCallback = failure
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passwordField.placeholder = NSLocalizedString("Password", comment: "")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Not sure why this should be needed, but it doesn't have an affect
        // if we don't dispatch it.
        dispatch_async(dispatch_get_main_queue()) {
            self.passwordField.becomeFirstResponder()
        }
    }
    
    @IBAction func signInButtonTapped() {
        signInButton.showActivityIndicator(true)
        
        let loginFields = LoginFields(username: email, password: passwordField.text, siteUrl: nil, multifactorCode: nil, userIsDotCom: true, shouldDisplayMultiFactor: false)
        loginFacade.signInWithLoginFields(loginFields)
    }
}

extension SigninPasswordViewController: LoginFacadeDelegate {
    func finishedLoginWithUsername(username: String!, password: String!, xmlrpc: String!, options: [NSObject : AnyObject]!) {
    }
    
    func finishedLoginWithUsername(username: String!, authToken: String!, requiredMultifactorCode: Bool) {
        let failureHandler: ((NSError!) -> Void)! = { [weak self] error in
            // dismiss login message
            // display remote error
            
            self?.signinFailureCallback?(error: SigninFailureError.NeedsMultifactorCode)
        }
        
        let account = accountServiceFacade.createOrUpdateWordPressComAccountWithUsername(username, authToken: authToken)
        blogSyncFacade.syncBlogsForAccount(account, success: {
            // once blogs for the accounts are synced, we want to update account details for it
            self.accountServiceFacade.updateUserDetailsForAccount(account, success: {
                // dismiss login message
                // finished login
                // TODO: track
                self.signinSuccessCallback?()
                }, failure: failureHandler)
            }, failure: failureHandler)
    }
    
    func displayLoginMessage(message: String!) {
        
    }
    
    func displayRemoteError(error: NSError!) {
        
    }
    
    func needsMultifactorCode() {
        self.signinFailureCallback?(error: SigninFailureError.NeedsMultifactorCode)
    }
}
