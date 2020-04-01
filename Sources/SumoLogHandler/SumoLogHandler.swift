import Logging
import Foundation
import Gzip
import ThreadSafeCollections
import UIKit

private struct LogJson: Codable {
  let message: String
  let timestamp: String
  let logLevel: String
  let file: String
  let function: String
  let machine: String
  let systemName: String
  let systemVersion: String
}

public class SumoLogHandler: LogHandler {
    
  public var metadata = Logger.Metadata()
  public var logLevel: Logger.Level = .debug
  public let label: String
  public let sumoUrl: URL
  public let sourceName: String
  public let sourceHost: String
  public var sourceCategory: String
  public let dateFormatter: DateFormatter
  public var thresholdPoints: Int = 10
  
  private var urlSession = URLSession(configuration: URLSessionConfiguration.default)
  private var currentLogs = ThreadSafeList<String>()
  private var currentPoints = 0
  private let machine: String
  private let systemName: String
  private let systemVersion: String

  public init(
    label: String, // swift-log requires this
    sumoUrl: URL,
    sourceName: String,
    sourceHost: String = "ios",
    sourceCategory: String = "prod/mobile",
    dateFormatString: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
  ) {
    self.label = label
    self.sumoUrl = sumoUrl
    self.sourceName = sourceName
    self.sourceHost = sourceHost
    self.sourceCategory = sourceCategory
    let formatter = DateFormatter()
    formatter.dateFormat = dateFormatString
    self.dateFormatter = formatter
    
    var systemInfo = utsname()
    uname(&systemInfo)
    self.machine = withUnsafeBytes(of: &systemInfo.machine) { rawPtr -> String in
      let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
      return String(cString: ptr)
    }
    self.systemName = UIDevice.current.systemName
    self.systemVersion = UIDevice.current.systemVersion
  }

  public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
    guard level >= logLevel else {
      print("not processing message with level = \(level)")
      return
    }
    DispatchQueue.global(qos: .background).async {
      self.process(level: level, message: message, metadata: metadata, file: file, function: function, line: line)
    }
  }
  
  private func process(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {

    var fileName = file
    if let fileWithoutExtension = file.components(separatedBy: "/").last?.components(separatedBy: ".").first {
      fileName = fileWithoutExtension
    }
    
    let json = LogJson(
      message: "\(message)",
      timestamp: dateFormatter.string(from: Date()),
      logLevel: level.rawValue,
      file: "\(fileName):\(line)",
      function: function,
      machine: self.machine,
      systemName: self.systemName,
      systemVersion: self.systemVersion
    )
    
    guard let encoded = try? JSONEncoder().encode(json) else {
      print("Failed to Encode \(json)")
      return
    }
    guard let jsonString = String(data: encoded, encoding: .utf8) else {
      print("Failed to Encode \(json)")
      return
    }

    currentLogs.append(jsonString)
    currentPoints += level.sendingPoints
    if currentPoints > thresholdPoints {
      currentPoints = 0
      let allItems = currentLogs.getAll()
      currentLogs.removeAll()
      send(logs: allItems)
    }
  }
  
  public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get {
      return metadata[key]
    }
    set(newValue) {
      metadata[key] = newValue
    }
  }

  // MARK: Networking
  
  private func send(logs: [String]) {

    var request = URLRequest(url: sumoUrl)
    request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
    request.setValue(sourceName, forHTTPHeaderField: "X-Sumo-Name")
    request.setValue(sourceHost, forHTTPHeaderField: "X-Sumo-Host")
    request.setValue(sourceCategory, forHTTPHeaderField: "X-Sumo-Category")
    request.httpMethod = "POST"

    let singleLog = logs.joined(separator: "\n")
    let data = singleLog.data(using: .utf8)
    do {
      let gz = try data?.gzipped(level: .bestCompression)
      request.httpBody = gz
    } catch {
      print("failed to gzip logs")
      return
    }
    
    urlSession.dataTask(with: request, completionHandler: { data, response, error in
      if let error = error {
        print("Failed to send logs to the server. \(error)")
      } else {
        print("Successfully sent logs to the server")
      }
    }).resume()
  }
}

private extension Logger.Level {
  var sendingPoints: Int {
    switch self {
    case .trace: return 0
    case .debug: return 1
    case .info: return 5
    case .notice: return 6
    case .warning: return 8
    case .error: return 10
    case .critical: return 10
    }
  }
}
