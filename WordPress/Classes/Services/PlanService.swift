import Foundation

typealias PlanFeatures = [PlanID: [PlanFeature]]

struct PlanService<S: Store> {
    // FIXME: @koke 2016-03-22
    // This was going to be generic but it's causing a lot of trouble. Figure out conflicts first
//    typealias S = StoreKitStore
    let store: S
    let remote: PlansRemote

    private let featuresRemote: PlanFeaturesRemote

    init(store: S, remote: PlansRemote, featuresRemote: PlanFeaturesRemote) {
        self.store = store
        self.remote = remote
        self.featuresRemote = featuresRemote
    }

    func plansWithPricesForBlog(siteID: Int, success: SitePricedPlans -> Void, failure: ErrorType -> Void) {
        remote.getPlansForSite(siteID,
            success: {
                activePlan, availablePlans in
                PlanStorage.activatePlan(activePlan, forSite: siteID)
                self.store.getPricesForPlans(availablePlans,
                    success: { pricedPlans in
                        let result = (siteID: siteID, activePlan: activePlan, availablePlans: pricedPlans)
                        success(result)
                    }, failure: failure)
            }, failure: failure)
    }

    func verifyPurchase(siteID: Int, plan: Plan, receipt: NSData, completion: Bool -> Void) {
        // Let's pretend this suceeds for now
        PlanStorage.activatePlan(plan, forSite: siteID)
        completion(true)
    }
}

extension PlanService {
    init?(siteID: Int, store: S) {
        self.store = store
        let manager = ContextManager.sharedInstance()
        let context = manager.mainContext
        let service = BlogService(managedObjectContext: context)
        guard let blog = service.blogByBlogId(siteID) else {
            let error = "Tried to obtain a PlanService for a non-existing site (ID: \(siteID))"
            assertionFailure(error)
            DDLogSwift.logError(error)
            return nil
        }
        guard let account = blog.account else {
            let error = "Tried to obtain a PlanService for a self hosted site"
            assertionFailure(error)
            DDLogSwift.logError(error)
            return nil
        }
        self.remote = PlansRemote(api: account.restApi)
        self.featuresRemote = PlanFeaturesRemote(api: account.restApi)
    }
}

struct PlanStorage {
    static func activatePlan(plan: Plan, forSite siteID: Int) {
        let manager = ContextManager.sharedInstance()
        let context = manager.newDerivedContext()
        let service = BlogService(managedObjectContext: context)
        context.performBlockAndWait {
            guard let blog = service.blogByBlogId(siteID) else {
                let error = "Tried to activate a plan for a non-existing site (ID: \(siteID))"
                assertionFailure(error)
                DDLogSwift.logError(error)
                return
            }
            if blog.planID != plan.id {
                blog.planID = plan.id
                manager.saveContextAndWait(context)
            }
        }
    }
}

extension PlanService {
    init(blog: Blog, store: S) {
        let remote = PlansRemote(api: blog.restApi())
        let featuresRemote = PlanFeaturesRemote(api: blog.restApi())
        
        self.init(store: store, remote: remote, featuresRemote: featuresRemote)
    }
}

enum PlanServiceError: ErrorType {
    case MissingFeaturesForPlan
    case MissingFeatureForSlug
}

extension PlanService {
    func featureGroupsForPlan(plan: Plan, features: PlanFeatures) throws -> [PlanFeatureGroup] {
        guard let planFeatures = features[plan.id] else {
            throw PlanServiceError.MissingFeaturesForPlan
        }
        return try plan.featureGroups.map({ group in
            let features: [PlanFeature] = try group.slugs.map({ slug in
                guard let feature = planFeatures.filter({ $0.slug == slug }).first else {
                    throw PlanServiceError.MissingFeatureForSlug
                }
                return feature
            })
            return PlanFeatureGroup(title: group.title, features: features)
        })
    }

    func updateAllPlanFeatures(success success: PlanFeatures -> Void, failure: ErrorType -> Void) {
        featuresRemote.getPlanFeatures({
            success($0)
        }, failure: failure)
    }
}
