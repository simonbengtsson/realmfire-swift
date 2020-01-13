import UIKit
import Firebase
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Realm.Configuration.defaultConfiguration.deleteRealmIfMigrationNeeded = true
        
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }

        FIRApp.configure()
        
        RealmFire.setErrorHandler { error in
            switch error {
            case .firebaseMalformedResult:
                print("Malformed firebase result")
            case .firebaseSyncError(let err):
                print(err.localizedDescription)
            case .realmError(let err):
                print(err.localizedDescription)
            case .objectDependenciesMissing:
                print("Missing deps!")
            case .realmUnsupportedValue(let object, let prop, let desc):
                print("Unsupported value for \(type(of: object).className()) \(prop). Desc: \(desc)")
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm'+0000'"
        RealmFire.mapDate(encode: { date in
            return dateFormatter.string(from: date)
        }, decode: { value in
            guard let dateStr = value as? String else { return nil }
            return dateFormatter.date(from: dateStr)
        })

        return true
    }
}

class CustomMapper: Mapper {
    
    override func encode(date: Date?) -> Any? {
        guard let date = date else { return nil }
        return dateFormatter().string(from: date)
    }
    
    override func decode(dateValue: Any?) -> Date? {
        guard let dateValue = dateValue as? String else { return nil }
        return dateFormatter().date(from: dateValue)
    }
    
    func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm'+0000'"
        return dateFormatter
    }
    
}

