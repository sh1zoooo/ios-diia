import Foundation
import DiiaDocumentsCommonTypes
import DiiaUIComponents

/// FORK: builds and stores the Passport card using the same DS components as the
/// real Diia backend. The card appears in the Documents tab only if
/// `DocumentVisibilityStorage.isVisible(.passport) == true`.
///
/// Layout decisions (matched to the original Diia on 2026-07-31):
///
/// 1. Heading "Паспорт громадянина\nУкраїни" — `\n` forces the heading label
///    (which has `numberOfLines = 3`) to wrap onto 2 lines, exactly like the
///    original Diia card.
///
/// 2. Only 2 fields on the card: "Дата\nнародження:" + "Номер:". The `\n` inside
///    the label works because DSTableItemVerticalMlc passes the label string
///    straight to a UILabel that supports multi-line. The ":" is kept to match
///    the original Diia look.
///
/// 3. Bottom heading: each component of the FULL NAME on its own line,
///    UPPERCASED. Done via DSHeadingWithSubtitlesModel:
///      value:     "САМУСЕНКО"           <- surname (large, bold)
///      subtitles: ["АЛІСА", "ОЛЕКСАНДРІВНА"]  <- first + middle name (smaller)
///    This is exactly how the real Diia card stacks the name in the bottom-left.
///
/// 4. Ticker text MUST be longer than the visible ticker width (~340pt),
///    because DSTickerView has a marquee animation that loops the text while
///    it's shorter than the container:
///        while label.intrinsicContentSize.width < frame.width { text += text }
///    A short text like "Документ дійсний" was being tripled, producing
///    "Документ дійснийДокумент дійснийДокумент дійсний...".
///    We use a long, real-looking sentence with the current time and date.
///
/// 5. Signature: stored in PassportStorage.signaturePNGBase64. We do NOT push
///    it into `content[]` (which only supports `.photo` on the actual card UI)
///    — that caused the signature to be rendered as the main photo. The
///    signature is still accessible from the Passport edit form for viewing
///    and re-drawing.
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

        // 2 fields, "Дата\nнародження:" wraps to 2 lines as in original Diia.
        let twoColumns = DSTableBlockTwoColumnPlaneOrg(
            photo: hasPhoto ? DSDocumentContentData.photo.rawValue : nil,
            photoUrl: nil,
            items: [
                .init(tableItemVerticalMlc: .init(label: "Дата\nнародження:", value: f.birthDate)),
                .init(tableItemVerticalMlc: .init(label: "Номер:", value: f.number))
            ],
            headingWithSubtitlesMlc: nil
        )

        // Build a long marquee text. Without the time+date, DSTickerView will
        // triple the short text and you'd see "Документ дійснийДокумент дійсний...".
        // The user explicitly asked for the format below — same sentence twice,
        // joined by ' • '. This guarantees a long-enough string so the marquee
        // animation never loops the text.
        let now = Date()
        let timeStr = format(now, "HH:mm")
        let dateStr = format(now, "dd.MM.yyyy")
        let unit = "Документ оновлено о \(timeStr) | \(dateStr)"
        let tickerText = "\(unit) • \(unit)"

        let ticker = DSTickerAtom(
            usage: .document,
            type: .positive,
            value: tickerText
        )

        // Full name split into value + subtitles so each part goes on its own line.
        // All UPPERCASED — matches the original Diia bottom heading.
        let surnameUpp = f.surname.uppercased()
        let firstNameUpp = f.firstName.uppercased()
        let middleNameUpp = f.middleName.uppercased()

        // If surname is empty, fall back to whatever was typed (so the
        // bottomHeading isn't an empty line on first launch).
        let bottomValue = surnameUpp.isEmpty ? "ПРІЗВИСЬКО" : surnameUpp
        var bottomSubtitles: [String] = []
        if !firstNameUpp.isEmpty { bottomSubtitles.append(firstNameUpp) }
        if !middleNameUpp.isEmpty { bottomSubtitles.append(middleNameUpp) }
        if bottomSubtitles.isEmpty { bottomSubtitles = ["ІМ’Я", "ПО БАТЬКОВІ"] }

        let bottomHeading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                value: bottomValue,
                subtitles: bottomSubtitles
            )
        )

        let frontCardModel = DSDocumentModel(
            docHeadingOrg: heading,
            tableBlockTwoColumnsPlaneOrg: twoColumns,
            tickerAtm: ticker,
            docButtonHeadingOrg: bottomHeading
        )

        let docData = DSDocData(docName: "Паспорт громадянина України")

        // ONLY the photo goes into `content[]`. The signature is intentionally
        // excluded — `DSDocumentContentData.signature` exists in the enum but
        // is never rendered anywhere by DSDocumentWithPhotoView, so pushing
        // it as `.photo` caused the signature to be displayed as the main
        // document photo.
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

    private static func format(_ date: Date, _ format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: date)
    }
}
