import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaDocumentsCommonTypes
import DiiaDocumentsCore

class DocumentsProcessor {
    private let storeHelper: StoreHelperProtocol
    
    init(storeHelper: StoreHelperProtocol = StoreHelper.instance) {
        self.storeHelper = storeHelper
    }
    
    func documents(with order: [DocTypeCode], actionView: BaseView?) -> [MultiDataType<DocumentModel>] {
        
        let docTypesOrder: [DocType] = order.compactMap({ DocType(rawValue: $0)})
        
        let documents = docTypesOrder.compactMap { docType -> MultiDataType<DocumentModel>? in
            switch docType {
            case .driverLicense:
                // FORK: hidden via visibility toggle
                guard DocumentVisibilityStorage.shared.isVisible(.driverLicense) else { return nil }
                let driverLicense: DSFullDocumentModel? = storeHelper.getValue(forKey: .driverLicense)
                return makeMultiple(cards: processDocs(licenses: driverLicense, docType: .driverLicense))
            case .passport:
                // FORK: hidden via visibility toggle
                guard DocumentVisibilityStorage.shared.isVisible(.passport) else { return nil }
                let passport: DSFullDocumentModel? = storeHelper.getValue(forKey: .passport)
                return makeMultiple(cards: processDocs(licenses: passport, docType: .passport))
            case .birthCertificate:
                // FORK: hidden via visibility toggle
                guard DocumentVisibilityStorage.shared.isVisible(.birthCertificate) else { return nil }
                let birthCert: DSFullDocumentModel? = storeHelper.getValue(forKey: .birthCertificate)
                return makeMultiple(cards: processDocs(licenses: birthCert, docType: .birthCertificate))
            case .taxpayerСard:
                return nil
            }
        }
        
        return documents
    }
    
    private func makeMultiple(cards: [DocumentModel]) -> MultiDataType<DocumentModel>? {
        if cards.isEmpty {
            return nil
        } else if cards.count == 1 {
            return .single(cards[0])
        } else {
            return .multiple(cards)
        }
    }
    
    private func reorderIfNeeded(documents: [DocumentModel], orderIds: [String]) -> [DocumentModel] {
        if !orderIds.isEmpty {
            var newDocs = documents
            for id in orderIds.reversed() {
                if let index = newDocs.firstIndex(where: { $0.orderIdentifier == id }) {
                    let document = newDocs.remove(at: index)
                    newDocs.insert(document, at: 0)
                }
            }
            return newDocs
        }
        return documents
    }
    
    /// FORK: unified processor for all local document types — uses the same
    /// `DriverLicenseViewModel` from DiiaDocuments, just with a different `docType`.
    private func processDocs(licenses: DSFullDocumentModel?, docType: DocType) -> [DocumentModel] {
        let documents: [DocumentModel] = licenses?.data.filter({ $0.docData.validUntil == nil }).map {
            let vm = ForkDocumentViewModelFactory(docType: docType).createViewModel(model: $0)
            // FORK: hook the kebab-button overlay onto the freshly built frontView.
            // The frontView is lazy, so accessing it here forces its creation —
            // which is fine, it would happen anyway when the Documents tab renders.
            if let dsView = vm.frontView as? DSDocumentWithPhotoView {
                dsView.forkHookOnFirstLayout()
            }
            return vm
        } ?? []
        return reorderIfNeeded(documents: documents,
                               orderIds: DocumentReorderingService.shared.order(for: docType.rawValue))
    }
}

extension DocumentsProcessor: DocumentsProvider { }
