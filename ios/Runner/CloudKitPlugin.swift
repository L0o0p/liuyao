import CloudKit
import Flutter

public class CloudKitPlugin: NSObject, FlutterPlugin {
    let db = CKContainer.default().privateCloudDatabase
    
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
            
            let record = CKRecord(recordType: "UserProgress")
            record["word"] = word as NSString
            record["score"] = score as NSNumber
            record["timestamp"] = Date() as NSDate
            
            db.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        result(FlutterError(code: "CK_SAVE_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        result(true)
                    }
                }
            }
            
        case "fetchProgress":
            let query = CKQuery(recordType: "UserProgress", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            db.perform(query, inZoneWith: nil) { records, error in
                DispatchQueue.main.async {
                    if let error = error {
                        // 如果是记录类型不存在的错误，返回空数组而不是错误
                        if error.localizedDescription.contains("not marked indexable") || 
                           error.localizedDescription.contains("Did not find record type") {
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
            
            let record = CKRecord(recordType: "UserModuleProgress")
            record["moduleId"] = moduleId as NSString
            record["progress"] = progress as NSNumber
            record["completedQuestions"] = completedQuestions as NSNumber
            record["totalQuestions"] = totalQuestions as NSNumber
            record["timestamp"] = Date() as NSDate
            
            db.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        result(FlutterError(code: "CK_SAVE_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        result(true)
                    }
                }
            }
            
        case "fetchModuleProgress":
            let query = CKQuery(recordType: "UserModuleProgress", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            db.perform(query, inZoneWith: nil) { records, error in
                DispatchQueue.main.async {
                    if let error = error {
                        // 如果是记录类型不存在的错误，返回空数组而不是错误
                        if error.localizedDescription.contains("not marked indexable") || 
                           error.localizedDescription.contains("Did not find record type") {
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
            
            let record = CKRecord(recordType: "UserWrongQuestion")
            record["questionText"] = questionText as NSString
            record["correctAnswer"] = correctAnswer as NSString
            record["userAnswer"] = userAnswer as NSString
            record["moduleId"] = moduleId as NSString
            record["timestamp"] = Date() as NSDate
            record["reviewCount"] = 0 as NSNumber
            
            db.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        result(FlutterError(code: "CK_SAVE_ERR", message: error.localizedDescription, details: nil))
                    } else {
                        result(true)
                    }
                }
            }
            
        case "fetchWrongQuestions":
            let query = CKQuery(recordType: "UserWrongQuestion", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            db.perform(query, inZoneWith: nil) { records, error in
                DispatchQueue.main.async {
                    if let error = error {
                        // 如果是记录类型不存在的错误，返回空数组而不是错误
                        if error.localizedDescription.contains("not marked indexable") || 
                           error.localizedDescription.contains("Did not find record type") {
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
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
