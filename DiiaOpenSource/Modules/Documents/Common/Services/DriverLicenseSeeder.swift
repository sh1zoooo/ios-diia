import Foundation
import DiiaDocumentsCommonTypes
import DiiaUIComponents

/// Будує та кладе в StoreHelper картку посвідчення водія, використовуючи ті самі
/// design-system компоненти, що й реальний бекенд Дії (перевірено по коду
/// `DSDocumentWithPhotoView.configure`):
///   docHeadingOrg              -> заголовок "Посвідчення водія"
///   tableBlockTwoColumnsPlaneOrg -> фото зліва + ПІБ/дата народження/категорія/дійсне до справа
///   tableBlockPlaneOrg         -> рядок "Видав: ..."
///   docButtonHeadingOrg        -> нижня плашка з номером документа (і "..." меню)
///
/// Значення полів беруться з `DriverLicenseStorage` (заповнюються в Налаштуваннях),
/// тож функцію треба викликати не лише один раз при першому запуску, а щоразу при
/// старті додатку (і одразу після збереження форми) — інакше картка "зникає",
/// якщо StoreHelper був очищений (наприклад, через `hasAppBeenLaunchedBefore`).
enum DriverLicenseSeeder {

    static func sync(storeHelper: StoreHelperProtocol = StoreHelper.instance) {
        let fields = DriverLicenseStorage.shared.snapshot()

        let heading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(value: "Посвідчення водія", subtitles: nil)
        )

        let twoColumns = DSTableBlockTwoColumnPlaneOrg(
            photo: nil,
            photoUrl: nil,
            items: [
                .init(tableItemVerticalMlc: .init(label: "Прізвище, ім'я, по батькові", value: fields.fullName)),
                .init(tableItemVerticalMlc: .init(label: "Дата народження", value: fields.birthDate)),
                .init(tableItemVerticalMlc: .init(label: "Категорії", value: fields.category)),
                .init(tableItemVerticalMlc: .init(label: "Дійсне до", value: fields.validUntil))
            ],
            headingWithSubtitlesMlc: nil
        )

        let issuedByBlock = DSTableBlockItemModel(
            tableMainHeadingMlc: nil,
            tableSecondaryHeadingMlc: nil,
            items: [
                .init(tableItemHorizontalMlc: .init(label: "Видав", value: fields.issuedBy))
            ]
        )

        let bottomHeading = DSDocumentHeading(
            docNumberCopyMlc: DSDocNumberCopyMlc(value: fields.number)
        )

        let frontCardModel = DSDocumentModel(
            docHeadingOrg: heading,
            tableBlockTwoColumnsPlaneOrg: twoColumns,
            tableBlockPlaneOrg: issuedByBlock,
            docButtonHeadingOrg: bottomHeading
        )

        let docData = DSDocData(docName: "Посвідчення водія")

        let documentData = DSDocumentData(
            docStatus: 200, // DriverLicenseStatus.ok
            id: "fork.driverLicense",
            docNumber: fields.number,
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
