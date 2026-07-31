import Foundation
import DiiaDocumentsCommonTypes
import DiiaUIComponents

/// FORK: builds and stores the Passport card using the same DS components as the
/// real Diia backend. The card appears in the Documents tab only if
/// `DocumentVisibilityStorage.isVisible(.passport) == true`.
///
/// Layout decisions (matched to the original Diia on 2026-07-31):
///   - heading "Паспорт громадянина\nУкраїни" — newline so it wraps to 2 lines
///   - only 2 fields on the card: "Дата народження" + "Номер"
///   - bottomHeading uses ALL-CAPS multi-line full name:
///     "САМУСЕНКО\nАЛІСА\nОЛЕКСАНДРІВНА"
///   - ticker text is just "Документ дійсний" — the Diia UI appends
///     "• Документ оновлено о HH:mm | dd.MM.yyyy" automatically from `currentDate`,
///     so we must NOT duplicate the date here (that caused the "2026Документ" glue bug).
///   - signature image (if set) is attached via the second `DSDocumentContent` item
///     with code `.signature` (or falls back to `.photo` if the enum doesn't have it).
enum PassportSeeder {

    static func sync(storeHelper: StoreHelperProtocol = StoreHelper.instance) {
        let f = PassportStorage.shared.snapshot()

        // Force 2-line heading: "Паспорт громадянина" + newline + "України".
        let heading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                value: "Паспорт громадянина\nУкраїни",
                subtitles: nil
            )
        )

        let hasPhoto = PassportStorage.shared.photoBase64 != nil

        // Only the 2 fields shown on the real Diia passport card.
        let twoColumns = DSTableBlockTwoColumnPlaneOrg(
            photo: hasPhoto ? DSDocumentContentData.photo.rawValue : nil,
            photoUrl: nil,
            items: [
                .init(tableItemVerticalMlc: .init(label: "Дата народження", value: f.birthDate)),
                .init(tableItemVerticalMlc: .init(label: "Номер", value: f.number))
            ],
            headingWithSubtitlesMlc: nil
        )

        // IMPORTANT: no date in here. The Diia UI appends its own
        // "• Документ оновлено о HH:mm | dd.MM.yyyy" using `currentDate`.
        let ticker = DSTickerAtom(
            usage: .document,
            type: .positive,
            value: "Документ дійсний"
        )

        // All-caps, multi-line full name.
        let bottomHeading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                value: PassportStorage.shared.fullNameUppercased,
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

        // Photo + optional signature as document content items.
        var content: [DSDocumentContent] = []
        if let photoB64 = PassportStorage.shared.photoBase64 {
            content.append(DSDocumentContent(image: photoB64, code: .photo))
        }
        if let signatureB64 = PassportStorage.shared.signaturePNGBase64 {
            // DSDocumentContentData may not have a `.signature` case in this
            // version of the package; fall back to `.photo` so it still renders.
            content.append(DSDocumentContent(image: signatureB64, code: .photo))
        }
        let contentArr: [DSDocumentContent]? = content.isEmpty ? nil : content

        let documentData = DSDocumentData(
            docStatus: 200,
            id: "fork.passport",
            docNumber: f.number,
            content: contentArr,
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
