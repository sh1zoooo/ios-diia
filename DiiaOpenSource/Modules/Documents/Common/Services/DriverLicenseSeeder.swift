import Foundation
import DiiaDocumentsCommonTypes
import DiiaUIComponents

/// Кладёт в локальний стор пусту (незаповнену) картку посвідчення водія,
/// щоб вона одразу з'являлась у розділі "Документи" без звернення до сервера.
/// Дані заповнюються згодом вручну через Налаштування.
enum DriverLicenseSeeder {

    private static let seededFlagKey = "driverLicenseSeeded"

    static func seedIfNeeded(storeHelper: StoreHelperProtocol = StoreHelper.instance) {
        guard !UserDefaults.standard.bool(forKey: seededFlagKey) else { return }

        let alreadyExists: DSFullDocumentModel? = storeHelper.getValue(forKey: .driverLicense)
        guard alreadyExists == nil else {
            UserDefaults.standard.set(true, forKey: seededFlagKey)
            return
        }

        let heading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(value: "Посвідчення водія", subtitles: nil)
        )

        let fields: [DSItemsModel] = [
            .init(tableItemVerticalMlc: .init(label: "Прізвище, ім'я, по батькові", value: "")),
            .init(tableItemVerticalMlc: .init(label: "Номер посвідчення", value: "")),
            .init(tableItemVerticalMlc: .init(label: "Категорія", value: "")),
            .init(tableItemVerticalMlc: .init(label: "Дійсне до", value: ""))
        ]

        let twoColumns = DSTableBlockTwoColumnPlaneOrg(
            items: fields,
            headingWithSubtitlesMlc: nil
        )

        let frontCardModel = DSDocumentModel(
            docHeadingOrg: heading,
            tableBlockTwoColumnsPlaneOrg: twoColumns
        )

        let docData = DSDocData(docName: "Посвідчення водія")

        let documentData = DSDocumentData(
            docStatus: 200, // .ok — щоб не показувався екран помилки документа
            id: UUID().uuidString,
            docNumber: "",
            docData: docData,
            frontCard: DSDocumentFrontCard(UA: [frontCardModel], EN: [frontCardModel])
        )

        let model = DSFullDocumentModel(
            status: .ok,
            expirationDate: Date().addingTimeInterval(60 * 60 * 24 * 365 * 10), // +10 років
            currentDate: Date(),
            data: [documentData]
        )

        storeHelper.save(model, type: DSFullDocumentModel.self, forKey: .driverLicense)
        UserDefaults.standard.set(true, forKey: seededFlagKey)
    }
}
