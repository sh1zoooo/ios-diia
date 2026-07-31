import Foundation
import DiiaDocumentsCommonTypes
import DiiaUIComponents
import DiiaCommonServices

/// Будує та кладе в StoreHelper картку посвідчення водія, використовуючи ті самі
/// design-system компоненти, що й реальний бекенд Дії (перевірено по коду
/// `DSDocumentWithPhotoView.configure`):
///   docHeadingOrg                 -> заголовок "Посвідчення водія"
///   tableBlockTwoColumnsPlaneOrg  -> фото зліва + ПІБ/дата народження/категорія/номер справа
///   tickerAtm                     -> плашка "Документ дійсний ... єДокумент..." (легальний статус)
///   docButtonHeadingOrg           -> нижня плашка з ПІБ і кнопкою "..."
///
/// ВАЖЛИВО: `tableBlockPlaneOrg` навмисно НЕ використовується разом із
/// `tableBlockTwoColumnsPlaneOrg` — в `DSDocumentWithPhotoView` обидва анкоряться
/// до одного й того ж `verticalStack.bottomAnchor`, тобто одночасний показ обох
/// призводить саме до накладання блоків одне на одне, яке було на скріншоті.
///
/// Значення полів беруться з `DriverLicenseStorage` (заповнюються в Налаштуваннях),
/// тож функцію треба викликати не лише один раз при першому запуску, а щоразу при
/// старті додатку (і одразу після збереження форми).
enum DriverLicenseSeeder {

    static func sync(storeHelper: StoreHelperProtocol = StoreHelper.instance) {
        let fields = DriverLicenseStorage.shared.snapshot()

        let heading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(value: "Посвідчення водія", subtitles: nil)
        )

        let hasPhoto = DriverLicenseStorage.shared.photoBase64 != nil

        let twoColumns = DSTableBlockTwoColumnPlaneOrg(
            photo: hasPhoto ? DSDocumentContentData.photo.rawValue : nil,
            photoUrl: nil,
            items: [
                .init(tableItemVerticalMlc: .init(label: "Прізвище, ім'я, по батькові", value: fields.fullName)),
                .init(tableItemVerticalMlc: .init(label: "Дата народження", value: fields.birthDate)),
                .init(tableItemVerticalMlc: .init(label: "Категорії", value: fields.category)),
                .init(tableItemVerticalMlc: .init(label: "Номер документа", value: fields.number))
            ],
            headingWithSubtitlesMlc: nil
        )

        // Ticker text. DSTickerView.adjustLabelSize() duplicates the text while
        // it's shorter than the ticker frame, and once more for the marquee.
        // If our value is "A • B", duplicating it produces "A • BA • B" — the
        // two halves get glued without a separator.
        // Fix: end the value with " • " so every duplicate glues cleanly:
        //   "... • unit • unit • unit • ..."
        let now = Date()
        let timeStr = format(now, "HH:mm")
        let dateStr = format(now, "dd.MM.yyyy")
        let unit = "Документ оновлено о \(timeStr) | \(dateStr)"
        let ticker = DSTickerAtom(
            usage: .document,
            type: .positive,
            value: "\(unit) • "
        )

        let bottomHeading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                value: fields.fullName,
                subtitles: nil
            )
        )

        let frontCardModel = DSDocumentModel(
            docHeadingOrg: heading,
            tableBlockTwoColumnsPlaneOrg: twoColumns,
            tickerAtm: ticker,
            docButtonHeadingOrg: bottomHeading
        )

        let docData = DSDocData(docName: "Посвідчення водія")

        let content: [DSDocumentContent]? = DriverLicenseStorage.shared.photoBase64.map {
            [DSDocumentContent(image: $0, code: .photo)]
        }

        let documentData = DSDocumentData(
            docStatus: 200, // DriverLicenseStatus.ok
            id: "fork.driverLicense",
            docNumber: fields.number,
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

        storeHelper.save(model, type: DSFullDocumentModel.self, forKey: .driverLicense)

        // FORK: force the Documents tab to re-render immediately, without an
        // app restart. See PassportSeeder.sync() for the full explanation.
        (ServicesProvider.shared.documentsLoader as? DocumentsLoader)?.forkNotifyListeners()
    }

    private static func format(_ date: Date, _ format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: date)
    }
}
