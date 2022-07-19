import Foundation

let arguments = ProcessInfo().arguments
if arguments.count < 3 {
    print("missing arguments")
    exit(1)
}

let (inputPath, outputPath) = (arguments[1], arguments[2])

var generatedCode: [String] = [
    "import Foundation",
    "import SwiftUI",
    "",
    "// This file was autogenerated — do not modify.",
    ""
]

let stringsDictionary: [String: String] = {
    do {
        let stringsData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
        let plistObject = try PropertyListSerialization.propertyList(from: stringsData, format: nil)
        guard let stringsDictionary = plistObject as? [String: String] else {
            print("Failed to parse strings file — is it valid?")
            exit(1)
        }
        return stringsDictionary
    } catch {
        print("Failed to parse strings file — is it valid?")
        exit(1)
    }
}()

let tableName = URL(fileURLWithPath: inputPath).deletingPathExtension().lastPathComponent
let pluralizedKeySuffix: String = "_Plural"

// First, let's make some SwiftUI keys.
generatedCode.append("extension LocalizedStringKey {")

for fullKey in stringsDictionary.keys.sorted() {
    guard !fullKey.isEmpty else { continue }
    let keyComponents: [String] = fullKey.components(separatedBy: " ")
    guard !keyComponents.isEmpty else { continue }
    let keyName = keyComponents.first!
    var keyNameAsSymbol = keyName
    keyNameAsSymbol.replaceSubrange(keyNameAsSymbol.startIndex..<keyNameAsSymbol.index(keyNameAsSymbol.startIndex, offsetBy: 1),
                                    with: keyNameAsSymbol.first!.lowercased())
    let isPlural = (keyNameAsSymbol.hasSuffix(pluralizedKeySuffix))
    guard !isPlural else { continue }

    let pluralizedKeyName = keyName.appending(pluralizedKeySuffix)
    let fullKeyWithPluralizedName: String = {
        var components = Array(keyComponents.dropFirst())
        components.insert(pluralizedKeyName, at: 0)
        return components.joined(separator: " ")
    }()
    let hasPluralizedVariant = (stringsDictionary[fullKeyWithPluralizedName] != nil)

    if keyComponents.count == 1 {
        let lines = SwiftUISymbolBuilder.symbolDefinition(for: keyNameAsSymbol, fullKey: fullKey,
                                                          hasPluralization: hasPluralizedVariant,
                                                          pluralizedSuffix: pluralizedKeySuffix)
        generatedCode.append(contentsOf: lines)
    } else {
        let formatSpecifiers = keyComponents.dropFirst(1).filter({ $0.starts(with: "%") })
        let lines = SwiftUISymbolBuilder.symbolDefinition(for: keyNameAsSymbol, keyName: keyName,
                                                          formatSpecifiers: formatSpecifiers,
                                                          hasPluralization: hasPluralizedVariant,
                                                          pluralizedSuffix: pluralizedKeySuffix)
        generatedCode.append(contentsOf: lines)
    }
}

generatedCode.append("}")
generatedCode.append("")

// Next, some plain strings.
generatedCode.append("struct \(tableName) {")

for fullKey in stringsDictionary.keys.sorted() {
    guard !fullKey.isEmpty else { continue }
    let keyComponents: [String] = fullKey.components(separatedBy: " ")
    guard !keyComponents.isEmpty else { continue }
    let keyName = keyComponents.first!
    var keyNameAsSymbol = keyName
    keyNameAsSymbol.replaceSubrange(keyNameAsSymbol.startIndex..<keyNameAsSymbol.index(keyNameAsSymbol.startIndex, offsetBy: 1),
                                    with: keyNameAsSymbol.first!.lowercased())
    let isPlural = (keyNameAsSymbol.hasSuffix(pluralizedKeySuffix))
    guard !isPlural else { continue }

    let pluralizedKeyName = keyName.appending(pluralizedKeySuffix)
    let fullKeyWithPluralizedName: String = {
        var components = Array(keyComponents.dropFirst())
        components.insert(pluralizedKeyName, at: 0)
        return components.joined(separator: " ")
    }()
    let hasPluralizedVariant = (stringsDictionary[fullKeyWithPluralizedName] != nil)

    if keyComponents.count == 1 {
        let lines = StringSymbolBuilder.symbolDefinition(for: keyNameAsSymbol, fullKey: fullKey,
                                                         hasPluralization: hasPluralizedVariant,
                                                         pluralizedFullKey: fullKeyWithPluralizedName)
        generatedCode.append(contentsOf: lines)
    } else {
        let formatSpecifiers = keyComponents.dropFirst(1).filter({ $0.starts(with: "%") })
        let lines = StringSymbolBuilder.symbolDefinition(for: keyNameAsSymbol, fullKey: fullKey,
                                                         formatSpecifiers: formatSpecifiers,
                                                         hasPluralization: hasPluralizedVariant,
                                                         pluralizedFullKey: fullKeyWithPluralizedName)
        generatedCode.append(contentsOf: lines)
    }
}

generatedCode.append("}")
generatedCode.append("")

// Write out file.
let output = generatedCode.joined(separator: "\n")
try output.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)

