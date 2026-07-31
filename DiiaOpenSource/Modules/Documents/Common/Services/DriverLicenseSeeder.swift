import Foundation
import DiiaDocumentsCommonTypes
import DiiaUIComponents

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
    }
}
