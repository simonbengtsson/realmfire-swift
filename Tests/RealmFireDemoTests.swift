import XCTest
import RealmSwift
@testable import RealmFireDemo

class RealmFireDemoTests: XCTestCase {
    var testRealm: Realm!
    let realm = try! Realm()
    
    override func setUp() {
        super.setUp()
        var conf = Realm.Configuration()
        conf.inMemoryIdentifier = self.name
        testRealm = try! Realm(configuration: conf)
    }
    
    override func tearDown() {
        super.tearDown()
        try! testRealm.write {
            testRealm.deleteAll()
        }
        
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    func testExample() {
    }
    
    func testPerformanceExample() {
        // Compare performance (memory, cpu) of keeping meta as
        // - big dictionary
        // - small dictionaries
        // - native objects
        self.measure {
            var val = 0
            for i in 0...10 {
                val = 1 + i
            }
            assert(val > 10)
        }
    }
}
