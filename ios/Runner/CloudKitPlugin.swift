import CloudKit
import Flutter

public class CloudKitPlugin: NSObject, FlutterPlugin {
    let container = CKContainer(identifier: "iCloud.com.loop.liuyao")
    let db: CKDatabase
    
    override init() {
        self.db = container.privateCloudDatabase
        super.init()
        
        // 打印容器信息用于调试
        print("CloudKit 容器ID: \(container.containerIdentifier ?? "unknown")")
        
        // 获取用户信息和账户状态
        container.fetchUserRecordID { recordID, error in
            if let recordID = recordID {
                print("CloudKit 用户记录ID: \(recordID.recordName)")
            } else if let error = error {
                print("获取CloudKit用户ID失败: \(error.localizedDescription)")
            }
        }
        
        // 检查账户状态
        container.accountStatus { accountStatus, error in
            switch accountStatus {
            case .available:
                print("CloudKit 账户状态: 可用")
            case .noAccount:
                print("CloudKit 账户状态: 未登录iCloud")
            case .restricted:
                print("CloudKit 账户状态: 受限制")
            case .couldNotDetermine:
                print("CloudKit 账户状态: 无法确定")
            case .temporarilyUnavailable:
                print("CloudKit 账户状态: 暂时不可用")
            @unknown default:
                print("CloudKit 账户状态: 未知状态")
            }
            
            if let error = error {
                print("检查CloudKit账户状态失败: \(error.localizedDescription)")
            }
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cloudkit_channel", binaryMessenger: registrar.messenger())
        let instance = CloudKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "saveProgress":
            guard let args = call.arguments as? [String: Any],
                  let word = args["word"] as? String,
                  let score = args["score"] as? Int else {
                result(FlutterError(code: "BAD_ARGS", message: "Missing arguments", details: nil))
                return
            }
            
            let record = CKRecord(recordType: "Progress")
            record["word"] = word as NSString
            record["score"] = score as NSNumber
            record["timestamp"] = Date() as NSDate
            
            print("正在保存Progress记录到CloudKit: \(word) - \(score)")
            db.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ CloudKit Progress保存失败: \(error.localizedDescription)")
                        if let ckError = error as? CKError {
                            print("CKError代码: \(ckError.code.rawValue)")
                        }
                        result(FlutterError(code: "CK_SAVE_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        print("✅ CloudKit Progress记录保存成功: \(savedRecord?.recordID.recordName ?? "unknown")")
                        result(true)
                    }
                }
            }
            
        case "fetchProgress":
            // 使用简单查询避免索引问题
            let query = CKQuery(recordType: "Progress", predicate: NSPredicate(value: true))
            // 暂时移除排序以避免索引问题
            // query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            print("正在查询Progress记录...")
            db.perform(query, inZoneWith: nil) { records, error in
                DispatchQueue.main.async {
                    if let error = error {
                        // 如果是记录类型不存在的错误，返回空数组而不是错误
                        if error.localizedDescription.contains("Did not find record type") {
                            result([])
                        } else {
                            result(FlutterError(code: "CK_FETCH_ERR", message: error.localizedDescription, details: nil))
                        }
                    } else {
                        let data = records?.map { record in
                            return [
                                "word": record["word"] as? String ?? "",
                                "score": record["score"] as? Int ?? 0,
                                "timestamp": (record["timestamp"] as? Date)?.timeIntervalSince1970 ?? 0
                            ]
                        } ?? []
                        result(data)
                    }
                }
            }
            
        case "saveModuleProgress":
            guard let args = call.arguments as? [String: Any],
                  let moduleId = args["moduleId"] as? String,
                  let progress = args["progress"] as? Double,
                  let completedQuestions = args["completedQuestions"] as? Int,
                  let totalQuestions = args["totalQuestions"] as? Int else {
                result(FlutterError(code: "BAD_ARGS", message: "Missing arguments", details: nil))
                return
            }
            
            let record = CKRecord(recordType: "ModuleProgress")
            record["moduleId"] = moduleId as NSString
            record["progress"] = progress as NSNumber
            record["completedQuestions"] = completedQuestions as NSNumber
            record["totalQuestions"] = totalQuestions as NSNumber
            record["timestamp"] = Date() as NSDate
            
            print("正在保存ModuleProgress记录到CloudKit: \(moduleId)")
            db.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ CloudKit ModuleProgress保存失败: \(error.localizedDescription)")
                        if let ckError = error as? CKError {
                            print("CKError代码: \(ckError.code.rawValue)")
                        }
                        result(FlutterError(code: "CK_SAVE_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        print("✅ CloudKit ModuleProgress记录保存成功: \(savedRecord?.recordID.recordName ?? "unknown")")
                        result(true)
                    }
                }
            }
            
        case "fetchModuleProgress":
            let query = CKQuery(recordType: "ModuleProgress", predicate: NSPredicate(value: true))
            // 暂时移除排序以避免索引问题
            // query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            print("正在查询ModuleProgress记录...")
            db.perform(query, inZoneWith: nil) { records, error in
                DispatchQueue.main.async {
                    if let error = error {
                        // 如果是记录类型不存在的错误，返回空数组而不是错误
                        if error.localizedDescription.contains("Did not find record type") {
                            result([])
                        } else {
                            result(FlutterError(code: "CK_FETCH_ERR", message: error.localizedDescription, details: nil))
                        }
                    } else {
                        let data = records?.map { record in
                            return [
                                "moduleId": record["moduleId"] as? String ?? "",
                                "progress": record["progress"] as? Double ?? 0.0,
                                "completedQuestions": record["completedQuestions"] as? Int ?? 0,
                                "totalQuestions": record["totalQuestions"] as? Int ?? 0,
                                "timestamp": (record["timestamp"] as? Date)?.timeIntervalSince1970 ?? 0
                            ]
                        } ?? []
                        result(data)
                    }
                }
            }
            
        case "saveWrongQuestion":
            guard let args = call.arguments as? [String: Any],
                  let questionText = args["questionText"] as? String,
                  let correctAnswer = args["correctAnswer"] as? String,
                  let userAnswer = args["userAnswer"] as? String,
                  let moduleId = args["moduleId"] as? String else {
                result(FlutterError(code: "BAD_ARGS", message: "Missing arguments", details: nil))
                return
            }
            
            let record = CKRecord(recordType: "WrongQuestion")
            record["questionText"] = questionText as NSString
            record["correctAnswer"] = correctAnswer as NSString
            record["userAnswer"] = userAnswer as NSString
            record["moduleId"] = moduleId as NSString
            record["timestamp"] = Date() as NSDate
            record["reviewCount"] = 0 as NSNumber
            
            print("正在保存WrongQuestion记录到CloudKit: \(questionText)")
            db.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ CloudKit WrongQuestion保存失败: \(error.localizedDescription)")
                        if let ckError = error as? CKError {
                            print("CKError代码: \(ckError.code.rawValue)")
                        }
                        result(FlutterError(code: "CK_SAVE_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        print("✅ CloudKit WrongQuestion记录保存成功: \(savedRecord?.recordID.recordName ?? "unknown")")
                        result(true)
                    }
                }
            }
            
        case "fetchWrongQuestions":
            let query = CKQuery(recordType: "WrongQuestion", predicate: NSPredicate(value: true))
            // 暂时移除排序以避免索引问题
            // query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            print("正在查询WrongQuestion记录...")
            db.perform(query, inZoneWith: nil) { records, error in
                DispatchQueue.main.async {
                    if let error = error {
                        // 如果是记录类型不存在的错误，返回空数组而不是错误
                        if error.localizedDescription.contains("Did not find record type") {
                            result([])
                        } else {
                            result(FlutterError(code: "CK_FETCH_ERR", message: error.localizedDescription, details: nil))
                        }
                    } else {
                        let data = records?.map { record in
                            return [
                                "questionText": record["questionText"] as? String ?? "",
                                "correctAnswer": record["correctAnswer"] as? String ?? "",
                                "userAnswer": record["userAnswer"] as? String ?? "",
                                "moduleId": record["moduleId"] as? String ?? "",
                                "reviewCount": record["reviewCount"] as? Int ?? 0,
                                "timestamp": (record["timestamp"] as? Date)?.timeIntervalSince1970 ?? 0
                            ]
                        } ?? []
                        result(data)
                    }
                }
            }
            
        case "testPublicCloudKit":
            print("测试公共CloudKit连接...")
            
            // 使用公共数据库创建测试记录
            let publicDB = container.publicCloudDatabase
            let testRecord = CKRecord(recordType: "PublicTestRecord")
            testRecord["message"] = "Hello Public CloudKit" as NSString
            testRecord["timestamp"] = Date() as NSDate
            
            publicDB.save(testRecord) { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 公共CloudKit测试记录保存失败: \(error.localizedDescription)")
                        result(FlutterError(code: "CK_PUBLIC_TEST_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        print("✅ 公共CloudKit测试记录保存成功!")
                        print("记录ID: \(savedRecord?.recordID.recordName ?? "unknown")")
                        result(true)
                    }
                }
            }
            
        case "testCloudKitConnection":
            print("测试CloudKit连接...")
            
            // 创建一个简单的测试记录
            let testRecord = CKRecord(recordType: "TestRecord")
            testRecord["message"] = "Hello CloudKit" as NSString
            testRecord["timestamp"] = Date() as NSDate
            
            print("正在保存测试记录到CloudKit...")
            db.save(testRecord) { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ CloudKit测试记录保存失败: \(error.localizedDescription)")
                        if let ckError = error as? CKError {
                            print("CKError代码: \(ckError.code.rawValue)")
                            print("CKError详情: \(ckError.userInfo)")
                        }
                        result(FlutterError(code: "CK_TEST_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        print("✅ CloudKit测试记录保存成功!")
                        print("记录ID: \(savedRecord?.recordID.recordName ?? "unknown")")
                        print("记录类型: \(savedRecord?.recordType ?? "unknown")")
                        print("容器: \(savedRecord?.recordID.zoneID.zoneName ?? "unknown")")
                        
                        // 立即查询验证记录是否存在
                        let query = CKQuery(recordType: "TestRecord", predicate: NSPredicate(value: true))
                        self.db.perform(query, inZoneWith: nil) { records, queryError in
                            DispatchQueue.main.async {
                                if let queryError = queryError {
                                    print("❌ 查询TestRecord失败: \(queryError.localizedDescription)")
                                } else {
                                    print("✅ 查询到 \(records?.count ?? 0) 条TestRecord记录")
                                    if let records = records {
                                        for record in records {
                                            print("  - 记录ID: \(record.recordID.recordName)")
                                            print("  - 消息: \(record["message"] ?? "无")")
                                            print("  - 区域: \(record.recordID.zoneID.zoneName)")
                                            print("  - 所有者: \(record.recordID.zoneID.ownerName)")
                                            print("  - 创建时间: \(record.creationDate ?? Date())")
                                        }
                                    }
                                }
                            }
                        }
                        
                        result(true)
                    }
                }
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
