//
//  GradeService.swift
//  PingPangWang
//
//  Created by 李鹏 on 2018/6/12.
//  Copyright © 2018年 com.jsinda. All rights reserved.
//

import Moya
import Alamofire
import SwiftyJSON

class PP_GradeService: PP_BaseService {
    
    class func buildVenue(_ model: PP_VenueModel, _ block: @escaping (CMResponse) -> ()) {
        cmShowLoading()
        let url = "/grade/venue/insert"
        Alamofire.upload(multipartFormData: { (mData) in
            let timeInt = Date().timeIntervalSince1970
            for (index, image) in model.venueImages.enumerated() {
                if let imgData = image.compress(toSize: imageMaxSize) {
                    mData.append(imgData, withName: "images", fileName: "\(timeInt)_\(index).jpg", mimeType: "image/jpeg")
                }
            }
            
            if let jsonData = model.toJSONString() {
                mData.append(jsonData.data(using: .utf8)!, withName: "jsonData")
            }
            
//            let token = PP_UserModel.userToken()
            let token = "b523a0b55c06930cfec15774de9a1"
            mData.append(token.data(using: .utf8)!, withName: "token")
            
        }, to: gradeServer+url) { (result) in
            switch result {
            case .success(let upload, _, _):
                upload.uploadProgress(closure: { (progress) in
//                    self.progress(progress)
                })

                upload.responseData(completionHandler: { (response) in
                    cmHideLoading()
                    
                    guard let value = response.result.value else {
                        cmShowToast("数据错误")
                        return
                    }
                    
                    let json = JSON(data: value)
                    print(json)
                    
                    if let model = CMResponse.deserialize(from: json.rawString()) {
                        block(model)
                    }
                })
            case .failure(let error):
                cmHideLoading()
                cmShowToast(error.localizedDescription)
            }
        }
    }
    
    class func buildAuditor(_ model: PP_AuditorModel, _ block: @escaping (CMResponse) -> ()) {
        cmShowLoading()
        let url = "/grade/auditor/insert"
        Alamofire.upload(multipartFormData: { (mData) in
            let timeInt = Date().timeIntervalSince1970
            for (index, image) in model.certificateImages.enumerated() {
                if let imgData = image.compress(toSize: imageMaxSize) {
                    mData.append(imgData, withName: "certificate", fileName: "\(timeInt)_\(index).jpg", mimeType: "image/jpeg")
                }
            }
            
            if let avatarImage = model.avatarImage {
                if let image = avatarImage.image {
                    if let imgData = image.compress(toSize: imageMaxSize) {
                        mData.append(imgData, withName: "avatar", fileName: "\(timeInt)_avatar.jpg", mimeType: "image/jpeg")
                    }
                }
            }
            
            if let jsonData = model.toJSONString() {
                mData.append(jsonData.data(using: .utf8)!, withName: "jsonData")
            }
            
//            let token = PP_UserModel.userToken()
            let token = "b523a0b55c06930cfec15774de9a1"
            mData.append(token.data(using: .utf8)!, withName: "token")
            
        }, to: gradeServer+url) { (result) in
            switch result {
            case .success(let upload, _, _):
                upload.uploadProgress(closure: { (progress) in
//                    self.progress(progress)
                })
                
                upload.responseData(completionHandler: { (response) in
                    cmHideLoading()
                    
                    guard let value = response.result.value else {
                        cmShowToast("数据错误")
                        return
                    }
                    
                    let json = JSON(data: value)
                    print(json)
                    
                    if let model = CMResponse.deserialize(from: json.rawString()) {
                        block(model)
                    }
                })
            case .failure(let error):
                cmHideLoading()
                cmShowToast(error.localizedDescription)
            }
        }
    }
    
    class func venueList(province: String, city: String, county: String, _ block: @escaping ([PP_VenueModel?]?) -> ()) {
        let url = "/grade/venue/list"
        let token = "b523a0b55c06930cfec15774de9a1"
        let parameters: Parameters = ["province": province, "city": city, "county": county, "token": token]
        
        Alamofire.request(gradeServer+url, parameters: parameters).responseData(completionHandler: { (handler) in
            guard let value = handler.result.value else {
                block(nil)
                return
            }
            let json = JSON(data: value)
            print(json)
            
            let errCode = json["errorCode"].string
            if errCode == "00000000" {
                let list = [PP_VenueModel].deserialize(from: json.rawString(), designatedPath: "data")
                block(list)
            }
            else {
                block(nil)
            }
        })
    }
    
    class func auditorList(venueid: String, _ block: @escaping ([PP_AuditorModel?]?) -> ()) {
        let url = "/grade/auditor/list"
        let token = "b523a0b55c06930cfec15774de9a1"
        let parameters: Parameters = ["venueid": venueid, "token": token]
        
        Alamofire.request(gradeServer+url, parameters: parameters).responseData(completionHandler: { (handler) in
            guard let value = handler.result.value else {
                block(nil)
                return
            }
            let json = JSON(data: value)
            print(json)
            
            let errCode = json["errorCode"].string
            if errCode == "00000000" {
                let list = [PP_AuditorModel].deserialize(from: json.rawString(), designatedPath: "data")
                block(list)
            }
            else {
                block(nil)
            }
        })
    }
}
