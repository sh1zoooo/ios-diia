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

        // Ticker text MUST be longer than the ticker container width (~340pt),
        // otherwise DSTickerView.adjustLabelSize() will loop the text:
        //   while label.intrinsicContentSize.width < frame.width { text += text }
        // producing "Документ дійснийДокумент дійсний...".
        // Long sentence with current time + date fixes both this loop AND
        // the previous "2026Документ" glue bug (we control the whole string now).
        let now = Date()
        let timeStr = format(now, "HH:mm")
        let dateStr = format(now, "dd.MM.yyyy")
        let ticker = DSTickerAtom(
            usage: .document,
            type: .positive,
            value: "Документ дійсний на \(timeStr) | \(dateStr) • єДокумент має юридичну силу"
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

    private static func format(_ date: Date, _ format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: date)
    }
}
