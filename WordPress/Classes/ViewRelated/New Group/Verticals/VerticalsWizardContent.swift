import UIKit

final class VerticalsWizardContent: UIViewController {
    private let service: SiteVerticalsService
    private var dataSource: UITableViewDataSource?

    init(service: SiteVerticalsService) {
        self.service = service
        super.init(nibName: String(describing: type(of: self)), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
