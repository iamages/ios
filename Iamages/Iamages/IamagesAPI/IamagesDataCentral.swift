import Foundation
import Combine
import PromiseKit
import struct Kingfisher.AnyModifier
import class Kingfisher.ImageCache

class IamagesDataCentral: ObservableObject {
    @Published var latestFiles: [IamagesFileInformationResponse] = []
    
    @Published var isUserLoggedIn: Bool = false
    @Published var userInformation: IamagesUserInformation = IamagesUserInformation(auth: IamagesUserAuth(username: "No username", password: ""), biography: "No biography found.", createdDate: "No created date found.")
    @Published var encodedUserAuth: String = ""
    @Published var userRequestModifier: AnyModifier = AnyModifier(modify: { request in
        return request
    })
    
    @Published var userFiles: [IamagesFileInformationResponse] = []
    
    @Published var randomFiles: [IamagesFileInformationResponse] = []
    
    func fetchLatest() -> Promise<Bool> {
        self.latestFiles = []

        return Promise<Bool> { seal in
            api.get_root_latest().done({ latest in
                for id in latest.ids {
                    api.get_root_info(id: id, encodedUserAuth: nil).done({ information in
                        self.latestFiles.append(information)
                    }).catch({ error in
                        print("Couldn't get information for file: " + String(id) + ", error: " + error.localizedDescription)
                    })
                }
                seal.fulfill(true)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func fetchUser() -> Promise<Bool> {
        self.isUserLoggedIn = false
        self.userInformation.auth = auth.getUserAuthFromKeychain()
        self.encodedUserAuth = auth.getEncodedUserAuth(userAuth: self.userInformation.auth)
        self.userRequestModifier = auth.getRequestModifier(encodedUserAuth: self.encodedUserAuth)
        
        self.userInformation.biography = "No biography found."
        self.userInformation.createdDate = "No created date found."

        self.userFiles = []

        return Promise<Bool> { seal in
            if userInformation.auth.username != "No username" && userInformation.auth.password != "" {
                api.post_root_user_check(userAuth: self.userInformation.auth).done({ yes in
                    self.isUserLoggedIn = yes
                    api.post_root_user_files(userAuth: self.userInformation.auth).done({ userFiles in
                        for id in userFiles.ids {
                            api.get_root_info(id: id, encodedUserAuth: self.encodedUserAuth).done({ information in
                                self.userFiles.append(information)
                            }).catch({ error in
                                print("Couldn't get information for file: " + String(id) + ", error: " + error.localizedDescription)
                            })
                        }
                    }).catch({ error in
                        seal.reject(error)
                    })
                    api.post_root_user_info(userAuth: self.userInformation.auth).done({ userInformationResponse in
                        self.userInformation.biography = userInformationResponse.biography ?? "No biography found."
                        self.userInformation.createdDate = userInformationResponse.createdDate
                    }).catch({ error in
                        print(error)
                    })
                    seal.fulfill(true)
                }).catch({ error in
                    self.userInformation = IamagesUserInformation(auth: IamagesUserAuth(username: "No username", password: ""), biography: "No biography found.", createdDate: "No created date found.")
                    seal.reject(error)
                })
            } else {
                seal.reject(IamagesUnauthenticatedUserError("User is not logged in!"))
            }
        }
    }
    
    func fetchRandom() -> Promise<Bool> {
        self.randomFiles = []

        return Promise<Bool> { seal in
            api.get_root_random().done({ information in
                self.randomFiles.append(information)
                seal.fulfill(true)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func checkEditable(id: Int) -> Bool {
        if self.isUserLoggedIn && self.userFiles.firstIndex(where: {$0.id == id}) != nil {
            return true
        } else {
            return false
        }
    }
    
    func modifyFile(id: Int, modifications: [IamagesFileModifiable: AnyHashable]) -> Promise<Bool> {
        return Promise<Bool> { seal in
            api.patch_root_modify(modifyRequest: IamagesFileModifyRequest(id: id, modifications: modifications), userAuth: self.userInformation.auth).done({ yes in
                let userFileIndex: Int = self.userFiles.firstIndex(where: {$0.id == id})!
                let latestFileIndex: Int? = self.latestFiles.firstIndex(where: {$0.id == id})
                for (modification, value) in modifications {
                    switch modification {
                    case .description:
                        self.userFiles[userFileIndex].description = value as! String
                        if latestFileIndex != nil {
                            self.latestFiles[latestFileIndex!].description = value as! String
                        }
                    case .isNSFW:
                        self.userFiles[userFileIndex].isNSFW = value as! Bool
                        if latestFileIndex != nil {
                            self.latestFiles[latestFileIndex!].isNSFW = value as! Bool
                        }
                    case .isPrivate:
                        self.userFiles[userFileIndex].isPrivate = value as! Bool
                        if latestFileIndex != nil {
                            self.latestFiles[latestFileIndex!].isPrivate = value as! Bool
                        }
                    case .deleteFile:
                        self.userFiles.remove(at: userFileIndex)
                        if latestFileIndex != nil {
                            self.latestFiles.remove(at: latestFileIndex!)
                        }
                    }
                }
                seal.fulfill(yes)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func modifyUser(modifications: [IamagesUserModifiable: String]) -> Promise<Bool> {
        return Promise<Bool> { seal in
            api.patch_root_user_modify(modifyRequest: IamagesUserModifyRequest(modifications: modifications), userAuth: self.userInformation.auth).done({ yes in
                for (modification, value) in modifications {
                    switch modification {
                    case .biography:
                        self.userInformation.biography = value
                    case .password:
                        self.userInformation.auth.password = value
                        do {
                            try auth.saveUserAuthToKeychain(userAuth: self.userInformation.auth)
                        } catch {
                            seal.reject(error)
                        }
                    case .deleteAccount:
                        print("Handled by deleteUser function.")
                    }
                }
                seal.fulfill(yes)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func loginUser(userAuth: IamagesUserAuth) -> Promise<Bool> {
        return Promise<Bool> { seal in
            do {
                try auth.saveUserAuthToKeychain(userAuth: userAuth)
                self.fetchUser().done({ yes in
                    seal.fulfill(yes)
                }).catch({ error in
                    seal.reject(error)
                })
            } catch {
                seal.reject(error)
            }
        }
    }
    
    func logoutUser() -> Promise<Bool> {
        return Promise<Bool> { seal in
            do {
                try auth.deleteUserAuthInKeychain()
                self.clearImageCache()
                self.fetchUser().catch({ error in
                    seal.fulfill(true)
                })
            } catch {
                seal.reject(error)
            }
        }
    }
    
    func deleteUser() -> Promise<Bool> {
        return Promise<Bool> { seal in
            self.modifyUser(modifications: [.deleteAccount: "yes"]).done({ yes in
                self.logoutUser().done({ yes in
                    self.fetchLatest().done({ yes in
                        seal.fulfill(yes)
                    }).catch({ error in
                        print("Could not perform optional latest refresh post user deletion.")
                    })
                }).catch({ error in
                    seal.reject(error)
                })
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func uploadFile(information: IamagesUploadRequest, preferredUploadFormat: IamagesUploadableFormats) -> Promise<IamagesUploadResponse> {
        var userAuth: IamagesUserAuth?
        if userInformation.auth.username != "No username" && userInformation.auth.password != "" {
            userAuth = self.userInformation.auth
        }
        return Promise<IamagesUploadResponse> { seal in
            api.put_root_upload(information: information, preferredUploadFormat: preferredUploadFormat, userAuth: userAuth).done({ response in
                api.get_root_info(id: response.id, encodedUserAuth: self.encodedUserAuth).done({ fileInformation in
                    if !self.isUserLoggedIn || !information.isPrivate {
                        self.latestFiles.insert(fileInformation, at: 0)
                    }
                    if self.isUserLoggedIn {
                        self.userFiles.insert(fileInformation, at: 0)
                    }
                }).catch({ error in
                    print("Could not get info for FileID '\(response.id))' post file upload, error: \(error.localizedDescription)")
                })
                seal.fulfill(response)
            }).catch({ error in
                seal.reject(error)
            })
        }
    }
    
    func clearImageCache() {
        let cache = ImageCache.default
        cache.clearMemoryCache()
        cache.clearDiskCache()
    }
    
    init() {
        ImageCache.default.diskStorage.config.sizeLimit = 1024 * 1024 * 1024
        ImageCache.default.diskStorage.config.expiration = .seconds(600)
    }
}
