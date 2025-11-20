import Foundation
import FMLogger
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public extension TEContainer {
    func registerTextEngineServices() {
        // Configuration Service
        register(TEConfigurationManagerProtocol.self) {
            TEConfigurationManager()
        }
        
        // Logging Service
        register(TETextLoggerProtocol.self) {
            TETextLogger()
        }
        
        // Performance Monitoring Service
        register(TEPerformanceMonitorProtocol.self) {
            TEPerformanceMonitor()
        }
        
        // Cache Service
        register(TECacheManagerProtocol.self) {
            TECacheManager()
        }
        
        // Statistics Service
        register(TEStatisticsServiceProtocol.self) {
            TEStatisticsService()
        }
        
        // Layout Service
        register(TELayoutServiceProtocol.self) {
            TELayoutService()
        }
        
        // Rendering Service
        register(TERenderingServiceProtocol.self) {
            TERenderingService()
        }
        
        // Parsing Service
        register(TEParsingServiceProtocol.self) {
            TEParsingService()
        }
        
        // Platform Service
        register(TEPlatformServiceProtocol.self) {
            TEPlatformService()
        }
        
        // Text Engine (Singleton)
        registerSingleton(TETextEngineProtocol.self) {
            TETextEngine()
        }
    }
}

public protocol TETextEngineProtocol {
    var configuration: TEConfiguration { get set }
    var isRunning: Bool { get }
    
    func start() throws
    func stop()
    func reset()
    func performHealthCheck() -> Result<Bool, TETextEngineError>
    
    // Text processing methods
    func processText(_ text: String, options: TEProcessingOptions?) -> Result<NSAttributedString, TETextEngineError>
    func layoutText(_ attributedString: NSAttributedString, containerSize: CGSize) -> Result<TETextLayout, TETextEngineError>
    func renderText(_ layout: TETextLayout, in context: CGContext) -> Result<Void, TETextEngineError>
}

public struct TEProcessingOptions {
    public var enableAsync: Bool
    public var maxConcurrency: Int
    public var cacheResult: Bool
    public var timeout: TimeInterval
    
    public init(enableAsync: Bool = true, 
                maxConcurrency: Int = 4,
                cacheResult: Bool = true,
                timeout: TimeInterval = 30.0) {
        self.enableAsync = enableAsync
        self.maxConcurrency = maxConcurrency
        self.cacheResult = cacheResult
        self.timeout = timeout
    }
}

public struct TETextLayout {
    public let attributedString: NSAttributedString
    public let containerSize: CGSize
    public let textContainer: TETextContainer
    public let layoutManager: TELayoutManager
    public let textStorage: Any?
    
    public init(attributedString: NSAttributedString,
                containerSize: CGSize,
                textContainer: TETextContainer,
                layoutManager: TELayoutManager,
                textStorage: Any? = nil) {
        self.attributedString = attributedString
        self.containerSize = containerSize
        self.textContainer = textContainer
        self.layoutManager = layoutManager
        self.textStorage = textStorage
    }
}