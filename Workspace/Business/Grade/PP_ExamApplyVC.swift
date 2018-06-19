//
//  PP_ExamApplyVC.swift
//  PingPangWang
//
//  Created by 李鹏 on 2018/6/19.
//  Copyright © 2018年 com.jsinda. All rights reserved.
//

import UIKit
import TZImagePickerController
import MWPhotoBrowser

class PP_ExamApplyVC: CMBaseVC {

    let cellIdentifier0 = "EE_ImageCell"
    let cellIdentifier1 = "EE_AddCell"
    let headerIdentifier = "UICollectionReusableView"
    let numberOfLine: CGFloat = 3.0
    let cellPadding: CGFloat = 15.0
    let maxImageCount = 6
    
    @IBOutlet weak var avatarView: UIButton!
    @IBOutlet weak var nameView: UITextField!
    @IBOutlet weak var sexView: UITextField!
    @IBOutlet weak var ageView: UITextField!
    @IBOutlet weak var phoneView: UITextField!
    @IBOutlet weak var idcardView: UITextField!
    @IBOutlet weak var introduceText: UITextView!
    @IBOutlet weak var venueView: UITextField!
    @IBOutlet weak var auditorView: UITextField!
    @IBOutlet weak var timeView: UITextField!
    @IBOutlet weak var gradeView: UITextField!
    
    @IBOutlet var pickerWindow: UIView!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var dateWindow: UIView!
    @IBOutlet var dateView: UIDatePicker!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var headView: UIView!
    @IBOutlet weak var submitView: UIButton!
    
    var venue_id = ""
    var auditor_id = ""
    let gradePickerData = ["一级", "二级", "三级", "四级", "五级", "六级", "七级", "八级", "九级"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "考试报名"
        
        self.performSelector(inBackground: #selector(loadAddressData), with: nil)
        
        collectionView.register(UINib(nibName: cellIdentifier0, bundle: Bundle.main), forCellWithReuseIdentifier: cellIdentifier0)
        collectionView.register(UINib(nibName: cellIdentifier1, bundle: Bundle.main), forCellWithReuseIdentifier: cellIdentifier1)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier)
        
        venueView.tapAction { (view) in
            let vc = PP_VenueSelectVC()
            vc.callBack = { (model) in
                self.venue_id = model.kid
                self.venueView.text = model.name
            }
            cmPushViewController(vc)
        }
        
        auditorView.tapAction { (view) in
            if self.venue_id == "" {
                cmShowToast("请先选择考点")
                return
            }
            let vc = PP_AuditorSelectVC()
            vc.venue_id = self.venue_id
            vc.callBack = { (model) in
                self.auditor_id = model.kid
                self.auditorView.text = model.name
            }
            cmPushViewController(vc)
        }
        
        timeView.tapAction { (view) in
            self.showDateView()
        }
        
        gradeView.tapAction { (view) in
            self.showPickerView()
        }
    }
    
    func loadAddressData() {
        CitiesDataTool.sharedManager().requestGetData()
    }
    
    @IBAction
    func selAvatar() {
        if let picker = TZImagePickerController(maxImagesCount: 1, delegate: self) {
            self.present(picker, animated: true)
        }
    }
    
    func showPickerView() {
        cmMainWindow()?.addSubview(self.pickerWindow)
        self.pickerWindow.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.view.bringSubview(toFront: self.pickerWindow)
        self.pickerView.reloadAllComponents()
    }
    
    func showDateView() {
        cmMainWindow()?.addSubview(self.dateWindow)
        self.dateWindow.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.view.bringSubview(toFront: self.dateWindow)
    }
    
    @IBAction
    func cancelPicker() {
        self.pickerWindow.removeFromSuperview()
    }
    
    @IBAction
    func okPicker() {
        self.pickerWindow.removeFromSuperview()
        self.gradeView.text = gradePickerData[self.pickerView.selectedRow(inComponent: 0)]
    }
    
    @IBAction
    func cancelDate() {
        self.dateWindow.removeFromSuperview()
    }
    
    @IBAction
    func okDate() {
        self.dateWindow.removeFromSuperview()
        let date = self.dateView.date
        
        timeView.text = date.dateToString()
    }
    
    @IBAction
    func doSubmit() {
        guard let name = nameView.text, name.count>0 else {
            cmShowToast("请填写姓名")
            return
        }
        guard let sex = sexView.text, sex.count>0 else {
            cmShowToast("请选择性别")
            return
        }
        guard let age = ageView.text, age.count>0 else {
            cmShowToast("请填写年龄")
            return
        }
        guard let phone = phoneView.text, phone.count>0 else {
            cmShowToast("请填写联系电话")
            return
        }
        guard let idcard = idcardView.text, idcard.count>0 else {
            cmShowToast("请填写身份证号")
            return
        }
        guard let introduce = introduceText.text, introduce.count>0 else {
            cmShowToast("请填写自我介绍")
            return
        }
        guard let venue = venueView.text, venue.count>0 else {
            cmShowToast("请选所在考点")
            return
        }
        
        guard let imageView = avatarView.imageView else {
            cmShowToast("请选头像图片")
            return
        }
        guard let avatarImage = imageView.image else {
            cmShowToast("请选头像图片")
            return
        }
        
        let model = PP_AuditorModel()
        model.name = name
        model.sex = sex
        model.age = age
        model.phone = phone
        model.idcard = idcard
        model.introduce = introduce
        model.venueid = venue_id
        let imageModel = PP_ImageModel()
        imageModel.image = avatarImage
        model.avatarImage = imageModel
        
        PP_GradeService.buildAuditor(model) { (response) in
            if response.isSuccess() {
                cmShowToast("提交成功")
                cmPopViewController()
            }
            else {
                cmShowToast(response.errorInfo)
            }
        }
    }
}

extension PP_ExamApplyVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if (indexPath.row == imageArray.count) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier1, for: indexPath) as! EE_AddCell
            return cell
//        }
//        else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier0, for: indexPath) as! EE_ImageCell
//            cell.imageView.image = self.imageArray[indexPath.row]
//            cell.enableDelete(true)
//            cell.delBlock = {
//                self.imageArray.remove(at: indexPath.row)
//                collectionView.reloadData()
//            }
//            return cell
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = floor((collectionView.bounds.width - 20*2 - (numberOfLine-1)*cellPadding) / numberOfLine)
        return CGSize(width: cellWidth, height: cellWidth*0.81)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(cellPadding, 20, cellPadding, 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if (indexPath.row == imageArray.count) {
            // add
            if let imagePickerVc = TZImagePickerController(maxImagesCount: maxImageCount, delegate: self) {
                self.present(imagePickerVc, animated: true) {
                    
                }
            }
//        }
//        else {
//            let browser = MWPhotoBrowser(delegate: self)
//            cmPushViewController(browser)
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 530)
    }
    
    // header
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier, for: indexPath)
            if !headerView.subviews.contains(self.headView) {
                headerView.addSubview(headView)
                headView.snp.makeConstraints({ (make) in
                    make.left.equalToSuperview()
                    make.right.equalToSuperview()
                    make.top.equalToSuperview()
                    make.bottom.equalToSuperview()
                })
            }
            return headerView
        }
        return UICollectionReusableView()
    }
}

extension PP_ExamApplyVC: TZImagePickerControllerDelegate {
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool, infos: [[AnyHashable : Any]]!) {
        if photos.count > 0 {
            avatarView.setImage(photos[0], for: .normal)
        }
    }
}

extension PP_ExamApplyVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return gradePickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return gradePickerData[row]
    }
}
