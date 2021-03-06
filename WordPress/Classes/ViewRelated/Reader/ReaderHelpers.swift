import Foundation
import WordPressComAnalytics

@objc public class ReaderHelpers : NSObject {


    // MARK: - Topic Helpers

    /**
    Check if the specified topic is a default topic

    @param topic A ReaderAbstractTopic
    @return True if the topic is a default topic
    */
    public class func isTopicDefault(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderDefaultTopic)
    }

    /**
    Check if the specified topic is a list

    @param topic A ReaderAbstractTopic
    @return True if the topic is a list topic
    */
    public class func isTopicList(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderListTopic)
    }

    /**
    Check if the specified topic is a site topic

    @param topic A ReaderAbstractTopic
    @return True if the topic is a site topic
    */
    public class func isTopicSite(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderSiteTopic)
    }

    /**
    Check if the specified topic is a tag

    @param topic A ReaderAbstractTopic
    @return True if the topic is a tag topic
    */
    public class func isTopicTag(topic:ReaderAbstractTopic) -> Bool {
        return topic.isKindOfClass(ReaderTagTopic)
    }

    /**
    Check if the specified topic is for Freshly Pressed

    @param topic A ReaderAbstractTopic
    @return True if the topic is for Freshly Pressed
    */
    public class func topicIsFreshlyPressed(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/freshly-pressed")
    }

    /**
     Check if the specified topic is for Discover

     @param topic A ReaderAbstractTopic
     @return True if the topic is for Discover
     */
    public class func topicIsDiscover(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.containsString("/read/sites/53424024/posts")
    }

    /**
    Check if the specified topic is for Following

    @param topic A ReaderAbstractTopic
    @return True if the topic is for Following
    */
    public class func topicIsFollowing(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/read/following")
    }

    /**
    Check if the specified topic is for Posts I Like

    @param topic A ReaderAbstractTopic
    @return True if the topic is for Posts I Like
    */
    public class func topicIsLiked(topic: ReaderAbstractTopic) -> Bool {
        let path = topic.path as NSString!
        return path.hasSuffix("/read/liked")
    }


    // MARK: Analytics Helpers

    public class func trackLoadedTopic(topic: ReaderAbstractTopic, withProperties properties:[NSObject : AnyObject]) {
        var stat:WPAnalyticsStat?

        if topicIsFreshlyPressed(topic) {
            stat = .ReaderFreshlyPressedLoaded

        } else if isTopicDefault(topic) && topicIsDiscover(topic) {
            // Tracks Discover only if it was one of the default menu items.
            stat = .ReaderDiscoverViewed

        } else if isTopicList(topic) {
            stat = .ReaderListLoaded

        } else if isTopicTag(topic) {
            stat = .ReaderTagLoaded

        }
        if (stat != nil) {
            WPAnalytics.track(stat!, withProperties: properties)
        }
    }


    public class func statsPropertiesForPost(post:ReaderPost, andValue value:AnyObject?, forKey key:String?) -> [NSObject: AnyObject] {
        var properties = [NSObject: AnyObject]();
        properties[WPAppAnalyticsKeyBlogID] = post.siteID
        properties[WPAppAnalyticsKeyPostID] = post.postID
        properties[WPAppAnalyticsKeyIsJetpack] = post.isJetpack
        if let feedID = post.feedID, feedItemID = post.feedItemID {
            properties[WPAppAnalyticsKeyFeedID] = feedID
            properties[WPAppAnalyticsKeyFeedItemID] = feedItemID
        }

        if let value = value, key = key {
            properties[key] = value
        }

        return properties
    }


    // MARK: Logged in helper

    public class func isLoggedIn() -> Bool {
        // Is Logged In
        let service = AccountService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        let account = service.defaultWordPressComAccount()
        return account != nil
    }

}
