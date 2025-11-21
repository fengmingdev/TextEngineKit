// 
//  TEErrorHandling.swift 
//  TextEngineKit 
// 
//  Created by fengming on 2025/11/17. 
// 
//  错误处理：定义错误类型与日志记录策略，支持统一的错误上报。 
// 
import Foundation

/// 统一错误类型定义
public enum TETextEngineError: Error, LocalizedError {
    
    // MARK: - 布局相关错误
    
    /// 无效文本范围
    case invalidTextRange(range: NSRange, totalLength: Int)
    
    /// 布局失败
    case layoutFailure(reason: String, textLength: Int)
    
    /// 容器尺寸无效
    case invalidContainerSize(size: CGSize)
    
    // MARK: - 渲染相关错误
    
    /// 渲染失败
    case renderingFailure(reason: String, contextInfo: String)
    
    /// 图形上下文错误
    case graphicsContextError(reason: String)
    
    // MARK: - 解析相关错误
    
    /// 解析失败
    case parserFailure(type: String, reason: String, input: String)
    
    /// 正则表达式错误
    case regexError(pattern: String, reason: String)
    
    // MARK: - 缓存相关错误
    
    /// 缓存错误
    case cacheError(operation: String, key: String)
    
    /// 缓存溢出
    case cacheOverflow(size: Int, limit: Int)
    
    // MARK: - 内存相关错误
    
    /// 内存警告
    case memoryWarning(currentUsage: Int, threshold: Int)
    
    /// 内存分配失败
    case memoryAllocationFailure(requestedSize: Int)
    
    // MARK: - 文件系统错误
    
    /// 文件读取失败
    case fileReadError(path: String, reason: String)
    
    /// 文件写入失败
    case fileWriteError(path: String, reason: String)
    
    // MARK: - 网络相关错误
    
    /// 网络请求失败
    case networkError(url: String, statusCode: Int?, reason: String)
    
    /// 超时错误
    case timeoutError(operation: String, timeout: TimeInterval)
    
    // MARK: - 配置相关错误
    
    /// 配置错误
    case configurationError(key: String, value: Any?, reason: String)
    
    /// 无效参数
    case invalidParameter(name: String, value: Any?, reason: String)
    
    // MARK: - 平台相关错误
    
    /// 平台不支持
    case platformNotSupported(feature: String, platform: String)
    
    /// 版本不兼容
    case versionIncompatible(feature: String, required: String, current: String)
    
    // MARK: - 引擎相关错误
    
    /// 引擎已在运行
    case engineAlreadyRunning
    
    /// 引擎启动失败
    case engineStartupFailure(reason: String)
    
    /// 健康检查失败
    case healthCheckFailure(reason: String)
    
    /// 无效配置
    case invalidConfiguration(reason: String)
    
    /// 文件未找到
    case fileNotFound(path: String)
    
    /// 线程安全违规
    case threadSafetyViolation(operation: String)
    
    /// 资源耗尽
    case resourceExhausted(resource: String, limit: Int)
    
    /// 引擎未初始化
    case engineNotInitialized
    
    // MARK: - 本地化错误描述
    
    public var errorDescription: String? {
        switch self {
        case .invalidTextRange(let range, let totalLength):
            return "文本范围 \(range) 超出总长度 \(totalLength)"
            
        case .layoutFailure(let reason, let textLength):
            return "布局失败：\(reason)，文本长度：\(textLength)"
            
        case .invalidContainerSize(let size):
            return "无效容器尺寸：\(size)"
            
        case .renderingFailure(let reason, let contextInfo):
            return "渲染失败：\(reason)，上下文信息：\(contextInfo)"
            
        case .graphicsContextError(let reason):
            return "图形上下文错误：\(reason)"
            
        case .parserFailure(let type, let reason, let input):
            return "\(type)解析失败：\(reason)，输入长度：\(input.count)"
            
        case .regexError(let pattern, let reason):
            return "正则表达式错误：模式'\(pattern)'，原因：\(reason)"
            
        case .cacheError(let operation, let key):
            return "缓存操作'\(operation)'失败，键：\(key)"
            
        case .cacheOverflow(let size, let limit):
            return "缓存溢出：当前大小\(size)，限制\(limit)"
            
        case .memoryWarning(let currentUsage, let threshold):
            return "内存警告：当前使用\(currentUsage)，阈值\(threshold)"
            
        case .memoryAllocationFailure(let requestedSize):
            return "内存分配失败：请求大小\(requestedSize)"
            
        case .fileReadError(let path, let reason):
            return "文件读取失败：\(path)，原因：\(reason)"
            
        case .fileWriteError(let path, let reason):
            return "文件写入失败：\(path)，原因：\(reason)"
            
        case .networkError(let url, let statusCode, let reason):
            let status = statusCode != nil ? "状态码：\(statusCode!)" : "无状态码"
            return "网络请求失败：\(url)，\(status)，原因：\(reason)"
            
        case .timeoutError(let operation, let timeout):
            return "操作'\(operation)'超时：\(timeout)秒"
            
        case .configurationError(let key, let value, let reason):
            return "配置错误：键'\(key)'，值\(value ?? "nil")，原因：\(reason)"
            
        case .invalidParameter(let name, let value, let reason):
            return "无效参数：\(name) = \(value ?? "nil")，原因：\(reason)"
            
        case .platformNotSupported(let feature, let platform):
            return "平台不支持：功能'\(feature)'，平台'\(platform)'"
            
        case .versionIncompatible(let feature, let required, let current):
            return "版本不兼容：功能'\(feature)'，需要版本\(required)，当前版本\(current)"
            
        case .engineAlreadyRunning:
            return "引擎已在运行中"
            
        case .engineStartupFailure(let reason):
            return "引擎启动失败：\(reason)"
            
        case .healthCheckFailure(let reason):
            return "健康检查失败：\(reason)"
            
        case .invalidConfiguration(let reason):
            return "无效配置：\(reason)"
            
        case .fileNotFound(let path):
            return "文件未找到：\(path)"
            
        case .threadSafetyViolation(let operation):
            return "线程安全违规：操作'\(operation)'"
            
        case .resourceExhausted(let resource, let limit):
            return "资源耗尽：资源'\(resource)'，限制\(limit)"
            
        case .engineNotInitialized:
            return "引擎未初始化"
        }
    }
}

/// 错误结果包装器
public enum TETextEngineResult<Success> {
    case success(Success)
    case failure(TETextEngineError)
    
    /// 获取成功值
    public var value: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// 获取错误
    public var error: TETextEngineError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    /// 是否成功
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// 是否失败
    public var isFailure: Bool {
        return !isSuccess
    }
}

/// Result扩展
public extension TETextEngineResult {
    
    /// 映射转换
    func map<NewSuccess>(_ transform: (Success) -> NewSuccess) -> TETextEngineResult<NewSuccess> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// 扁平映射转换
    func flatMap<NewSuccess>(_ transform: (Success) -> TETextEngineResult<NewSuccess>) -> TETextEngineResult<NewSuccess> {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// 错误映射转换
    func mapError(_ transform: (TETextEngineError) -> TETextEngineError) -> TETextEngineResult<Success> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(transform(error))
        }
    }
    
    /// 获取值或默认值
    func getOrElse(_ defaultValue: Success) -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return defaultValue
        }
    }
    
    /// 获取值或抛出错误
    func getOrThrow() throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

/// 错误处理辅助函数
public func TETextEngineTry<T>(_ block: () throws -> T) -> TETextEngineResult<T> {
    do {
        return .success(try block())
    } catch let error as TETextEngineError {
        return .failure(error)
    } catch {
        return .failure(.invalidParameter(name: "unknown", value: nil, reason: error.localizedDescription))
    }
}

/// 错误恢复机制
public extension TETextEngineError {
    
    /// 获取错误恢复建议
    var recoverySuggestion: String? {
        switch self {
        case .invalidTextRange:
            return "请检查文本范围参数，确保在有效范围内"
            
        case .layoutFailure:
            return "请检查文本内容和容器尺寸设置"
            
        case .invalidContainerSize:
            return "请确保容器尺寸大于零"
            
        case .renderingFailure:
            return "请检查图形上下文状态和渲染参数"
            
        case .parserFailure:
            return "请检查输入文本格式和解析器配置"
            
        case .regexError:
            return "请检查正则表达式语法"
            
        case .cacheError:
            return "请检查缓存键和缓存状态"
            
        case .cacheOverflow:
            return "请清理缓存或减少缓存大小"
            
        case .memoryWarning, .memoryAllocationFailure:
            return "请释放内存或减少内存使用"
            
        case .fileReadError, .fileWriteError:
            return "请检查文件路径和权限"
            
        case .networkError:
            return "请检查网络连接和服务器状态"
            
        case .timeoutError:
            return "请增加超时时间或优化操作性能"
            
        case .configurationError:
            return "请检查配置参数的有效性"
            
        case .invalidParameter:
            return "请检查参数值是否符合要求"
            
        case .platformNotSupported, .versionIncompatible:
            return "请检查平台版本和兼容性要求"
            
        case .graphicsContextError(let reason):
            return "请检查图形上下文状态: \(reason)"
            
        case .engineAlreadyRunning:
            return "引擎已在运行中，请勿重复启动"
            
        case .engineStartupFailure(let reason):
            return "引擎启动失败: \(reason)"
            
        case .healthCheckFailure(let reason):
            return "健康检查失败: \(reason)"
            
        case .invalidConfiguration(let reason):
            return "配置无效: \(reason)"
            
        case .fileNotFound(let path):
            return "文件未找到: \(path)"
            
        case .threadSafetyViolation(let operation):
            return "线程安全违规: \(operation)"
            
        case .resourceExhausted(let resource, let limit):
            return "资源耗尽: \(resource) 超过限制 \(limit)"
            
        case .engineNotInitialized:
            return "请先初始化引擎"
        }
    }
    
    /// 判断是否为可恢复错误
    var isRecoverable: Bool {
        switch self {
        case .invalidTextRange,
             .invalidContainerSize,
             .invalidParameter,
             .configurationError:
            return true
            
        case .layoutFailure,
             .renderingFailure,
             .parserFailure,
             .regexError,
             .cacheError,
             .cacheOverflow,
             .memoryWarning,
             .memoryAllocationFailure,
             .fileReadError,
             .fileWriteError,
             .networkError,
             .timeoutError,
             .platformNotSupported,
             .versionIncompatible:
            return false
            
        case .graphicsContextError,
             .engineAlreadyRunning,
             .engineStartupFailure,
             .healthCheckFailure,
             .invalidConfiguration,
             .fileNotFound,
             .threadSafetyViolation,
             .resourceExhausted,
             .engineNotInitialized:
            return false
        }
    }
    
    /// 获取错误严重程度
    var severity: TEErrorSeverity {
        switch self {
        case .memoryWarning:
            return .warning
            
        case .invalidTextRange,
             .invalidContainerSize,
             .invalidParameter,
             .configurationError:
            return .error
            
        case .layoutFailure,
             .renderingFailure,
             .parserFailure,
             .regexError,
             .cacheError,
             .cacheOverflow,
             .memoryAllocationFailure,
             .fileReadError,
             .fileWriteError,
             .networkError,
             .timeoutError,
             .platformNotSupported,
             .versionIncompatible:
            return .critical
            
        case .graphicsContextError,
             .engineAlreadyRunning,
             .engineStartupFailure,
             .healthCheckFailure,
             .invalidConfiguration,
             .fileNotFound,
             .threadSafetyViolation,
             .resourceExhausted,
             .engineNotInitialized:
            return .critical
        }
    }
}

/// 错误严重程度
public enum TEErrorSeverity: String, CaseIterable {
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

/// 错误日志记录扩展
public extension TETextEngineError {
    
    /// 记录错误日志
    func log(category: String = "error") {
        let severity = self.severity
        let message = self.localizedDescription
        let metadata: [String: Any] = [
            "error_type": String(describing: type(of: self)),
            "severity": severity.rawValue,
            "recoverable": self.isRecoverable
        ]
        
        Task {
            let logger: TETextLoggerProtocol = await TEContainer.shared.resolve(TETextLoggerProtocol.self)
            let logLevel: TELogLevel
            switch severity {
            case .warning:
                logLevel = .warning
            case .error:
                logLevel = .error
            case .critical:
                logLevel = .critical
            }
            await logger.log(message, level: logLevel, category: category, metadata: metadata)
        }
    }
}

/// 错误处理上下文
public struct TEErrorContext {
    public let operation: String
    public let parameters: [String: Any]
    public let timestamp: Date
    public let file: String
    public let function: String
    public let line: Int
    
    public init(
        operation: String,
        parameters: [String: Any] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        self.operation = operation
        self.parameters = parameters
        self.timestamp = Date()
        self.file = file
        self.function = function
        self.line = line
    }
}

/// 带上下文的错误处理
public func TETextEngineTryWithContext<T>(
    context: TEErrorContext,
    _ block: () throws -> T
) -> TETextEngineResult<T> {
    do {
        return .success(try block())
    } catch let error as TETextEngineError {
        error.log(category: context.operation)
        return .failure(error)
    } catch {
        let engineError = TETextEngineError.invalidParameter(
            name: "unknown",
            value: nil,
            reason: error.localizedDescription
        )
        engineError.log(category: context.operation)
        return .failure(engineError)
    }
}
