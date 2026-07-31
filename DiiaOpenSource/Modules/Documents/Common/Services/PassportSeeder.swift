import Foundation
import DiiaDocumentsCommonTypes
import DiiaUIComponents

/// FORK: builds and stores the Passport card using the same DS components as the
/// real Diia backend. The card appears in the Documents tab only if
/// `DocumentVisibilityStorage.isVisible(.passport) == true`.
enum PassportSeeder {

    static func sync(storeHelper: StoreHelperProtocol = StoreHelper.instance) {
        let f = PassportStorage.shared.snapshot()

        let heading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(value: "Паспорт громадянина України", subtitles: nil)
        )

        let hasPhoto = PassportStorage.shared.photoBase64 != nil

        let twoColumns = DSTableBlockTwoColumnPlaneOrg(
            photo: hasPhoto ? DSDocumentContentData.photo.rawValue : nil,
            photoUrl: nil,
            items: [
                .init(tableItemVerticalMlc: .init(label: "Прізвище, ім'я, по батькові", value: PassportStorage.shared.fullName)),
                .init(tableItemVerticalMlc: .init(label: "Дата народження", value: f.birthDate)),
                .init(tableItemVerticalMlc: .init(label: "Серія та номер", value: f.number)),
                .init(tableItemVerticalMlc: .init(label: "Номер запису", value: f.recordNumber)),
                .init(tableItemVerticalMlc: .init(label: "Ким виданий", value: f.issuedBy)),
                .init(tableItemVerticalMlc: .init(label: "Дата видачі", value: f.issuedDate))
            ],
            headingWithSubtitlesMlc: nil
        )

        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let ticker = DSTickerAtom(
            usage: .document,
            type: .positive,
            value: "Документ оновлено о \(timeFormatter.string(from: now)) | \(dateFormatter.string(from: now))"
        )

        let bottomHeading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                value: PassportStorage.shared.fullName,
                subtitles: nil
            )
        )

        let frontCardModel = DSDocumentModel(
            docHeadingOrg: heading,
            tableBlockTwoColumnsPlaneOrg: twoColumns,
            tickerAtm: ticker,
            docButtonHeadingOrg: bottomHeading
        )

        let docData = DSDocData(docName: "Паспорт громадянина України")

        let content: [DSDocumentContent]? = PassportStorage.shared.photoBase64.map {
            [DSDocumentContent(image: $0, code: .photo)]
        }

        let documentData = DSDocumentData(
            docStatus: 200,
            id: "fork.passport",
            docNumber: f.number,
            content: content,
            docData: docData,
            frontCard: DSDocumentFrontCard(UA: [frontCardModel], EN: [frontCardModel])
        )

        let model = DSFullDocumentModel(
            status: .ok,
            expirationDate: Date().addingTimeInterval(60 * 60 * 24 * 365 * 10),
            currentDate: Date(),
            data: [documentData]
        )

        storeHelper.save(model, type: DSFullDocumentModel.self, forKey: .passport)
    }
}
