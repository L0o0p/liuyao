import CloudKit
import Flutter

public class CloudKitPlugin: NSObject, FlutterPlugin {
    let container = CKContainer(identifier: "iCloud.com.loop.liuyao")
    let db: CKDatabase
    
    override init() {
        self.db = container.privateCloudDatabase  // 改回私有数据库
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
            print("🔍 Progress记录详情:")
            print("  - 记录类型: \(record.recordType)")
            print("  - 数据库: \(db)")
            print("  - 容器: \(container.containerIdentifier ?? "unknown")")
            
            db.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ CloudKit Progress保存失败: \(error.localizedDescription)")
                        if let ckError = error as? CKError {
                            print("CKError代码: \(ckError.code.rawValue)")
                            print("CKError详细信息: \(ckError.userInfo)")
                        }
                        result(FlutterError(code: "CK_SAVE_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        print("✅ CloudKit Progress记录保存成功!")
                        if let savedRecord = savedRecord {
                            print("  - 记录ID: \(savedRecord.recordID.recordName)")
                            print("  - 区域: \(savedRecord.recordID.zoneID.zoneName)")
                            print("  - 所有者: \(savedRecord.recordID.zoneID.ownerName)")
                            print("  - 创建时间: \(savedRecord.creationDate ?? Date())")
                        }
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
            
            // 使用固定的recordName（基于moduleId），这样可以通过recordID直接获取，无需查询
            let recordID = CKRecord.ID(recordName: "module_\(moduleId)")
            let record = CKRecord(recordType: "ModuleProgress", recordID: recordID)
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
            // 不使用查询，而是直接通过已知的moduleId列表获取记录
            // 这样可以避免索引问题
            // 这里的moduleId对应的是学习模块（页面级别），不是题目类型
            let moduleIds = ["tiangandizhi_wuxing", "tiangandizhi_yinyang", 
                           "tiangandizhi_direction", "tiangandizhi_time", 
                           "tiangandizhi_shengke", "tiangandizhi_comprehensive",
                           "hechong", "wuxing", "shierchangsheng", "64gua",
                           "comprehensive", "tiangandizhi", "directiontime"]
            
            print("正在获取ModuleProgress记录（通过recordID）...")
            let recordIDs = moduleIds.map { CKRecord.ID(recordName: "module_\($0)") }
            
            let fetchOperation = CKFetchRecordsOperation(recordIDs: recordIDs)
            
            // 使用旧API以兼容iOS 14及以下版本
            fetchOperation.perRecordCompletionBlock = { record, recordID, error in
                if let error = error {
                    // 记录不存在是正常的（用户还没有该模块的进度）
                    if (error as NSError).code != CKError.unknownItem.rawValue {
                        print("⚠️ 获取记录失败 \(recordID?.recordName ?? "unknown"): \(error.localizedDescription)")
                    } else {
                        print("📝 记录不存在: \(recordID?.recordName ?? "unknown") (这是正常的)")
                    }
                } else if let record = record {
                    print("✅ 获取到模块进度: \(record["moduleId"] ?? "无") - recordID: \(record.recordID.recordName)")
                }
            }
            
            fetchOperation.fetchRecordsCompletionBlock = { recordsByID, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 批量获取ModuleProgress失败: \(error.localizedDescription)")
                        // 即使失败也返回空数组，避免阻塞应用
                        result([])
                    } else if let recordsByID = recordsByID {
                        var data: [[String: Any]] = []
                        for (_, record) in recordsByID {
                            data.append([
                                "moduleId": record["moduleId"] as? String ?? "",
                                "progress": record["progress"] as? Double ?? 0.0,
                                "completedQuestions": record["completedQuestions"] as? Int ?? 0,
                                "totalQuestions": record["totalQuestions"] as? Int ?? 0,
                                "timestamp": (record["timestamp"] as? Date)?.timeIntervalSince1970 ?? 0
                            ])
                        }
                        print("✅ 成功获取 \(data.count) 条ModuleProgress记录")
                        result(data)
                    } else {
                        result([])
                    }
                }
            }
            
            db.add(fetchOperation)
            
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
            print("🔍 WrongQuestion记录详情:")
            print("  - 记录类型: \(record.recordType)")
            print("  - 数据库类型: \(type(of: db))")
            print("  - 是否私有数据库: \(db === container.privateCloudDatabase)")
            
            db.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ CloudKit WrongQuestion保存失败: \(error.localizedDescription)")
                        if let ckError = error as? CKError {
                            print("CKError代码: \(ckError.code.rawValue)")
                            print("CKError详细信息: \(ckError.userInfo)")
                        }
                        result(FlutterError(code: "CK_SAVE_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        print("✅ CloudKit WrongQuestion记录保存成功!")
                        if let savedRecord = savedRecord {
                            print("  - 记录ID: \(savedRecord.recordID.recordName)")
                            print("  - 区域: \(savedRecord.recordID.zoneID.zoneName)")
                            print("  - 所有者: \(savedRecord.recordID.zoneID.ownerName)")
                            print("  - 数据库: \(savedRecord.recordID.zoneID.ownerName == CKCurrentUserDefaultName ? "私有" : "公共")")
                        }
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
            
        case "debugCloudKitStatus":
            print("🔍 CloudKit 详细状态调试...")
            
            // 1. 检查容器和数据库信息
            print("📋 基本信息:")
            print("  - 容器ID: \(container.containerIdentifier ?? "unknown")")
            print("  - 数据库类型: \(db === container.privateCloudDatabase ? "私有" : "公共")")
            
            // 2. 检查账户状态
            container.accountStatus { accountStatus, error in
                DispatchQueue.main.async {
                    print("👤 账户状态:")
                    switch accountStatus {
                    case .available:
                        print("  - 状态: ✅ 可用")
                    case .noAccount:
                        print("  - 状态: ❌ 未登录iCloud")
                    case .restricted:
                        print("  - 状态: ⚠️ 受限制")
                    case .couldNotDetermine:
                        print("  - 状态: ❓ 无法确定")
                    case .temporarilyUnavailable:
                        print("  - 状态: ⏳ 暂时不可用")
                    @unknown default:
                        print("  - 状态: ❓ 未知")
                    }
                    
                    if let error = error {
                        print("  - 错误: \(error.localizedDescription)")
                    }
                }
            }
            
            // 3. 尝试查询每种记录类型的数量
            let recordTypes = ["Progress", "WrongQuestion", "ModuleProgress"]
            for recordType in recordTypes {
                let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                self.db.perform(query, inZoneWith: nil) { records, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("📊 \(recordType): ❌ 查询失败 - \(error.localizedDescription)")
                        } else {
                            print("📊 \(recordType): ✅ 找到 \(records?.count ?? 0) 条记录")
                            if let records = records, records.count > 0 {
                                print("  - 最新记录ID: \(records.first?.recordID.recordName ?? "unknown")")
                                print("  - 创建时间: \(records.first?.creationDate ?? Date())")
                            }
                        }
                    }
                }
            }
            
            result("CloudKit状态调试完成，请查看控制台输出")
            
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
