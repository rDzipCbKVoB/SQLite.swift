#if SQLITE_SWIFT_SQLCIPHER
import XCTest
import SQLite
import SQLCipher

class CipherTests: XCTestCase {

    let db = try! Connection()
    let db2 = try! Connection()

    override func setUp() {
        // db
        try! db.key("hello")

        try! db.run("CREATE TABLE foo (bar TEXT)")
        try! db.run("INSERT INTO foo (bar) VALUES ('world')")

        // db2
        let keyData = NSMutableData(length: 64)!
        let _ = SecRandomCopyBytes(kSecRandomDefault, 64,
                                   keyData.mutableBytes.assumingMemoryBound(to: UInt8.self))
        try! db2.key(Blob(bytes: keyData.bytes, length: keyData.length))

        try! db2.run("CREATE TABLE foo (bar TEXT)")
        try! db2.run("INSERT INTO foo (bar) VALUES ('world')")

        super.setUp()
    }

    func test_key() {
        XCTAssertEqual(1, try! db.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_rekey() {
        try! db.rekey("goodbye")
        XCTAssertEqual(1, try! db.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_data_key() {
        XCTAssertEqual(1, try! db2.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_data_rekey() {
        let keyData = NSMutableData(length: 64)!
        let _  = SecRandomCopyBytes(kSecRandomDefault, 64,
                           keyData.mutableBytes.assumingMemoryBound(to: UInt8.self))

        try! db2.rekey(Blob(bytes: keyData.bytes, length: keyData.length))
        XCTAssertEqual(1, try! db2.scalar("SELECT count(*) FROM foo") as? Int64)
    }

    func test_keyFailure() {
        let path = "\(NSTemporaryDirectory())/db.sqlite3"
        _ = try? FileManager.default.removeItem(atPath: path)

        let connA = try! Connection(path)
        defer { try! FileManager.default.removeItem(atPath: path) }

        try! connA.key("hello")

        let connB = try! Connection(path)

        var rc: Int32?
        do {
            try connB.key("world")
        } catch Result.error(_, let code, _) {
            rc = code
        } catch {
            XCTFail()
        }
        XCTAssertEqual(SQLITE_NOTADB, rc)
    }
}
#endif
