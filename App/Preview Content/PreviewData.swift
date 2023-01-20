import SwiftUI

let previewImage = IamagesImage(
    id: "test",
    createdOn: Date.now,
    owner: "jkelol111",
    isPrivate: false,
    contentType: .jpeg,
    lock: IamagesImage.Lock(
        isLocked: false,
        version: .aes128gcm_argon2
    ),
    thumbnail: IamagesImage.Thumbnail(
        isComputing: false,
        isUnavailable: true
    )
)

let previewImageMetadata = IamagesImageMetadata(
    description: "Test image",
    width: 200,
    height: 200,
    realContentType: nil
)

let previewImageAndMetadata = IamagesImageAndMetadataContainer(
    id: previewImage.id,
    image: previewImage,
    metadataContainer: IamagesImageMetadataContainer(data: previewImageMetadata)
)

let previewUploadContainer = IamagesUploadContainer(
    file: IamagesUploadFile(
        data: NSDataAsset(name: "PreviewImage")!.data,
        type: "image/jpeg"
    )
)

let previewCollection = IamagesCollection(
    id: "test",
    createdOn: Date.now,
    owner: "jkelol111",
    isPrivate: false,
    description: "Test collection"
)
