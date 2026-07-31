import Foundation
import DiiaDocumentsCommonTypes
import DiiaUIComponents

/// FORK: builds and stores the "Актовий запис про народження" card.
enum BirthCertificateSeeder {

    static func sync(storeHelper: StoreHelperProtocol = StoreHelper.instance) {
        let f = BirthCertificateStorage.shared.snapshot()

        let heading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(value: "Актовий запис про народження", subtitles: nil)
        )

        // No photo for this document — birth certificate uses text-only layout.
        let twoColumns = DSTableBlockTwoColumnPlaneOrg(
            photo: nil,
            photoUrl: nil,
            items: [
                .init(tableItemVerticalMlc: .init(label: "Прізвище, ім'я, по батькові", value: BirthCertificateStorage.shared.fullName)),
                .init(tableItemVerticalMlc: .init(label: "Дата народження", value: f.birthDate)),
                .init(tableItemVerticalMlc: .init(label: "Місце народження", value: f.birthPlace)),
                .init(tableItemVerticalMlc: .init(label: "Номер актового запису", value: f.recordNumber)),
                .init(tableItemVerticalMlc: .init(label: "Орган реєстрації", value: f.issuedBy)),
                .init(tableItemVerticalMlc: .init(label: "Дата реєстрації", value: f.issuedDate))
            ],
            headingWithSubtitlesMlc: nil
        )

        // IMPORTANT: no date in here. The Diia UI appends its own
        // "• Документ оновлено о HH:mm | dd.MM.yyyy" using `currentDate`,
        // so duplicating it caused the "2026Документ" glue bug.
        let ticker = DSTickerAtom(
            usage: .document,
            type: .positive,
            value: "Документ дійсний"
        )

        let bottomHeading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                value: BirthCertificateStorage.shared.fullName,
                subtitles: nil
            )
        )

        let frontCardModel = DSDocumentModel(
            docHeadingOrg: heading,
            tableBlockTwoColumnsPlaneOrg: twoColumns,
            tickerAtm: ticker,
            docButtonHeadingOrg: bottomHeading
        )

        let docData = DSDocData(docName: "Актовий запис про народження")

        let documentData = DSDocumentData(
            docStatus: 200,
            id: "fork.birthCertificate",
            docNumber: f.recordNumber,
            content: nil,
            docData: docData,
            frontCard: DSDocumentFrontCard(UA: [frontCardModel], EN: [frontCardModel])
        )

        let model = DSFullDocumentModel(
            status: .ok,
            expirationDate: Date().addingTimeInterval(60 * 60 * 24 * 365 * 10),
            currentDate: Date(),
            data: [documentData]
        )

        storeHelper.save(model, type: DSFullDocumentModel.self, forKey: .birthCertificate)
    }
}
