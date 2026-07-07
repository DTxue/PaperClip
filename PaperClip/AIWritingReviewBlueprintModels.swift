import Foundation

extension AIWritingReviewResult {
    struct WritingBlueprint: Codable, Sendable {
        struct CoreSceneToBuild: Codable, Sendable {
            let scene: String
            let whyThisSceneMatters: String
            let detailsToAdd: [String]

            private enum CodingKeys: String, CodingKey {
                case scene, whyThisSceneMatters, detailsToAdd
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                scene = container.decodeString(.scene)
                whyThisSceneMatters = container.decodeString(.whyThisSceneMatters)
                detailsToAdd = container.decodeStringArray(.detailsToAdd)
            }

            init(scene: String = "", whyThisSceneMatters: String = "", detailsToAdd: [String] = []) {
                self.scene = scene
                self.whyThisSceneMatters = whyThisSceneMatters
                self.detailsToAdd = detailsToAdd
            }

            var detailsToAddText: String {
                AIWritingReviewDisplayText.chineseList(detailsToAdd)
            }
        }

        struct MaterialArrangement: Codable, Sendable {
            let shouldBeBrief: String
            let shouldBeDetailed: String
            let shouldBeRemovedOrMerged: String

            private enum CodingKeys: String, CodingKey {
                case shouldBeBrief, shouldBeDetailed, shouldBeRemovedOrMerged
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                shouldBeBrief = container.decodeString(.shouldBeBrief)
                shouldBeDetailed = container.decodeString(.shouldBeDetailed)
                shouldBeRemovedOrMerged = container.decodeString(.shouldBeRemovedOrMerged)
            }

            init(shouldBeBrief: String = "", shouldBeDetailed: String = "", shouldBeRemovedOrMerged: String = "") {
                self.shouldBeBrief = shouldBeBrief
                self.shouldBeDetailed = shouldBeDetailed
                self.shouldBeRemovedOrMerged = shouldBeRemovedOrMerged
            }
        }

        let realWritingTask: String
        let notJustAbout: String
        let deeperMeaning: String
        let emotionalArc: [String]
        let coreSceneToBuild: CoreSceneToBuild
        let materialArrangement: MaterialArrangement

        private enum CodingKeys: String, CodingKey {
            case realWritingTask, notJustAbout, deeperMeaning, emotionalArc, coreSceneToBuild, materialArrangement
        }

        init() {
            realWritingTask = ""
            notJustAbout = ""
            deeperMeaning = ""
            emotionalArc = []
            coreSceneToBuild = CoreSceneToBuild()
            materialArrangement = MaterialArrangement()
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            realWritingTask = container.decodeString(.realWritingTask)
            notJustAbout = container.decodeString(.notJustAbout)
            deeperMeaning = container.decodeString(.deeperMeaning)
            emotionalArc = container.decodeStringArray(.emotionalArc)
            coreSceneToBuild = (try? container.decode(CoreSceneToBuild.self, forKey: .coreSceneToBuild)) ?? CoreSceneToBuild()
            materialArrangement = (try? container.decode(MaterialArrangement.self, forKey: .materialArrangement)) ?? MaterialArrangement()
        }
    }
}
