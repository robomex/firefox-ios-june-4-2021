/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

open class ClosedTabsStore {
    let prefs: Prefs

    lazy open var tabs: [ClosedTab] = {
        guard let tabsArray: Data = self.prefs.objectForKey("recentlyClosedTabs") as Any? as? Data
        else {
            return []
        }
        
        do {
            guard let unarchivedArray = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(tabsArray) as? [ClosedTab] else { return [] }
            return unarchivedArray
        } catch {
            print("Error unarchiving ClosedTab array: \(error.localizedDescription)")
            return []
        }
    }()

    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    open func addTab(_ url: URL, title: String?, faviconURL: String?) {
        let recentlyClosedTab = ClosedTab(url: url, title: title ?? "", faviconURL: faviconURL ?? "")
        tabs.insert(recentlyClosedTab, at: 0)
        if tabs.count > 5 {
            tabs.removeLast()
        }

        do {
            let archivedTabsArray = try NSKeyedArchiver.archivedData(withRootObject: tabs, requiringSecureCoding: true)
            prefs.setObject(archivedTabsArray, forKey: "recentlyClosedTabs")
        } catch {
            print("Error archiving recentlyClosedTabs: \(error.localizedDescription)")
        }
    }

    open func clearTabs() {
        prefs.removeObjectForKey("recentlyClosedTabs")
        tabs = []
    }
}

open class ClosedTab: NSObject, NSCoding, NSSecureCoding {
    public static var supportsSecureCoding: Bool = true
    
    public let url: URL
    public let title: String?
    public let faviconURL: String?

    var jsonDictionary: [String: Any] {
        let title = (self.title ?? "")
        let faviconURL = (self.faviconURL ?? "")
        let json: [String: Any] = ["title": title, "url": url, "faviconURL": faviconURL]
        return json
    }

    init(url: URL, title: String?, faviconURL: String?) {
        assert(Thread.isMainThread)
        self.title = title
        self.url = url
        self.faviconURL = faviconURL
        super.init()
    }

    required convenience public init?(coder: NSCoder) {
        guard let url = coder.decodeObject(forKey: "url") as? URL,
              let faviconURL = coder.decodeObject(forKey: "faviconURL") as? String,
              let title = coder.decodeObject(forKey: "title") as? String else { return nil }

        self.init(
            url: url,
            title: title,
            faviconURL: faviconURL
        )
    }

    open func encode(with coder: NSCoder) {
        coder.encode(url, forKey: "url")
        coder.encode(faviconURL, forKey: "faviconURL")
        coder.encode(title, forKey: "title")
    }
}
