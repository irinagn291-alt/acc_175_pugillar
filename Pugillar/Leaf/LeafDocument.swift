import Foundation

/// Role: Leaf. On-disk envelope for one leaf. Domain types never decode this directly.
struct LeafDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var id: UUID
    var dayKey: LeafDayKey
    var alphaInk: String
    var betaInk: String
    var prompt: PromptDocument?
    var isSealed: Bool
    var pairEntry: PairEntryDocument?
}

struct PromptDocument: Codable, Equatable, Sendable {
    var id: UUID
    var question: String
    var alphaAnswer: String
    var betaAnswer: String
}

struct PairEntryDocument: Codable, Equatable, Sendable {
    var sealedAtUnixMilliseconds: Int64
    var alphaInk: String
    var betaInk: String
    var promptQuestion: String?
    var promptAlphaAnswer: String?
    var promptBetaAnswer: String?
}

struct BondDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var handAlphaName: String
    var handBetaName: String
    var bondedAtUnixMilliseconds: Int64
}

struct SettingsDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var onboardingComplete: Bool
}

/// Role: Leaf. schemaVersion switch and Leaf ↔ document mapping. No FileManager.
enum LeafCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable, Sendable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func document(from leaf: Leaf) -> LeafDocument {
        LeafDocument(
            schemaVersion: currentSchema,
            id: leaf.id,
            dayKey: leaf.dayKey,
            alphaInk: leaf.alphaPlate.ink,
            betaInk: leaf.betaPlate.ink,
            prompt: leaf.prompt.map {
                PromptDocument(
                    id: $0.id,
                    question: $0.question,
                    alphaAnswer: $0.alphaAnswer,
                    betaAnswer: $0.betaAnswer
                )
            },
            isSealed: leaf.isSealed,
            pairEntry: leaf.pairEntry.map {
                PairEntryDocument(
                    sealedAtUnixMilliseconds: $0.sealedAtUnixMilliseconds,
                    alphaInk: $0.alphaInk,
                    betaInk: $0.betaInk,
                    promptQuestion: $0.promptQuestion,
                    promptAlphaAnswer: $0.promptAlphaAnswer,
                    promptBetaAnswer: $0.promptBetaAnswer
                )
            }
        )
    }

    static func leaf(from document: LeafDocument) -> Leaf {
        Leaf(
            id: document.id,
            dayKey: document.dayKey,
            alphaPlate: Plate(hand: .alpha, ink: document.alphaInk),
            betaPlate: Plate(hand: .beta, ink: document.betaInk),
            prompt: document.prompt.map {
                Prompt(
                    id: $0.id,
                    question: $0.question,
                    alphaAnswer: $0.alphaAnswer,
                    betaAnswer: $0.betaAnswer
                )
            },
            isSealed: document.isSealed,
            pairEntry: document.pairEntry.map {
                PairEntry(
                    sealedAtUnixMilliseconds: $0.sealedAtUnixMilliseconds,
                    alphaInk: $0.alphaInk,
                    betaInk: $0.betaInk,
                    promptQuestion: $0.promptQuestion,
                    promptAlphaAnswer: $0.promptAlphaAnswer,
                    promptBetaAnswer: $0.promptBetaAnswer
                )
            }
        )
    }

    static func encode(_ leaf: Leaf) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document(from: leaf))
    }

    static func decode(_ data: Data) throws -> Leaf {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return leaf(from: try decoder.decode(LeafDocument.self, from: data))
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

enum BondCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable, Sendable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ bond: BondRecord) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(
            BondDocument(
                schemaVersion: currentSchema,
                handAlphaName: bond.handAlphaName,
                handBetaName: bond.handBetaName,
                bondedAtUnixMilliseconds: bond.bondedAtUnixMilliseconds
            )
        )
    }

    static func decode(_ data: Data) throws -> BondRecord {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            let document = try decoder.decode(BondDocument.self, from: data)
            return BondRecord(
                handAlphaName: document.handAlphaName,
                handBetaName: document.handBetaName,
                bondedAtUnixMilliseconds: document.bondedAtUnixMilliseconds
            )
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

enum SettingsCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable, Sendable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(onboardingComplete: Bool) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(
            SettingsDocument(schemaVersion: currentSchema, onboardingComplete: onboardingComplete)
        )
    }

    static func decode(_ data: Data) throws -> Bool {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            return try decoder.decode(SettingsDocument.self, from: data).onboardingComplete
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
