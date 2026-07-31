import Foundation
import DiiaDocuments
import DiiaDocumentsCommonTypes
import DiiaUIComponents

/// FORK: a small wrapper that builds a `DriverLicenseViewModel` for ANY of the
/// fork's local document types (passport / birth-certificate / driver-license).
///
/// The Diia `DiiaDocuments` package only ships a concrete `DriverLicenseViewModel`
/// + `DriverLicenseContext` — there is no generic `DocumentViewModel`. Rather than
/// re-implementing the whole DS-card stack from scratch, we reuse that concrete
/// class and vary only the `docType` argument. This is a hack, but it works
/// because `DriverLicenseContext` only uses `docType` to know which `StoringKey`
/// to read/write and which FAQ category to open — none of which is specific to
/// real driver licenses.
struct ForkDocumentViewModelFactory {

    let docType: DocType

    func createViewModel(model: DSDocumentData) -> DriverLicenseViewModel {
        let context = DriverLicenseContext(model: model,
                                           docType: docType,
                                           reservePhotoService: DocumentsReservePhotoService(),
                                           sharingApiClient: SharingDocsAPIClient(),
                                           ratingOpener: RatingServiceOpener(),
                                           faqOpener: FaqOpener(),
                                           appRouter: AppRouter.instance,
                                           replacementModule: nil,
                                           docReorderingModule: { DocumentsReorderingModule() },
                                           docStackReorderingModule: { DocumentsStackReorderingModule(docType: docType) },
                                           storeHelper: ForkDocumentStorageImpl(storage: StoreHelper.instance,
                                                                                 docType: docType),
                                           urlHandler: URLOpenerImpl())
        return DriverLicenseViewModel(context: context)
    }
}

/// FORK: generic storage wrapper that delegates to the correct `StoringKey`
/// based on the `docType` passed in. Mirrors `DriverLicenseDocumentStorageImpl`
/// but works for passport / birth-certificate / driver-license alike.
final class ForkDocumentStorageImpl: DriverLicenseDocumentStorage {

    private let storage: StoreHelperProtocol
    private let docType: DocType

    init(storage: StoreHelperProtocol, docType: DocType) {
        self.storage = storage
        self.docType = docType
    }

    func saveDriverLicense(document: DSFullDocumentModel) {
        guard let key = docType.storingKey() else { return }
        storage.save(document, type: DSFullDocumentModel.self, forKey: key)
    }

    func getDriverLicenseDocument() -> DSFullDocumentModel? {
        guard let key = docType.storingKey() else { return nil }
        return storage.getValue(forKey: key)
    }
}
