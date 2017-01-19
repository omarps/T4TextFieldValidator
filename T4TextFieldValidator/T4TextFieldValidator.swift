//
//  T4TextFieldValidator.swift
//  CustomTextField
//
//  Created by SB 3 on 10/16/15.
//  Copyright © 2015 T4nhpt. All rights reserved.
//

import UIKit

public class T4TextFieldValidator: UITextField {
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
    var strLengthValidationMsg = ""
    var supportObj:TextFieldValidatorSupport = TextFieldValidatorSupport()
    var strMsg = ""
    var arrRegx:NSMutableArray = []
    var popUp :IQPopUp?
    
    @IBInspectable var isMandatory:Bool = true   /**< Default is YES*/
    
    @IBOutlet var presentInView:UIView?    /**< Assign view on which you want to show popup and it would be good if you provide controller's view*/
    
    @IBInspectable var popUpColor:UIColor?   /**< Assign popup background color, you can also assign default popup color from macro "ColorPopUpBg" at the top*/
    
    private var _validateOnCharacterChanged  = false
    @IBInspectable var validateOnCharacterChanged:Bool { /**< Default is YES, Use it whether you want to validate text on character change or not.*/
        
        get {
            return _validateOnCharacterChanged
        }
        set {
            supportObj.validateOnCharacterChanged = newValue
            _validateOnCharacterChanged = newValue
        }
    }
    
    private var _validateOnResign = false
    @IBInspectable var validateOnResign:Bool {
        get {
            return _validateOnResign
        }
        set {
            supportObj.validateOnResign = newValue
            _validateOnResign = newValue
        }
    }
    
    private var ColorPopUpBg = UIColor(red: 0.702, green: 0.000, blue: 0.000, alpha: 1.000)
    private var MsgValidateLength = NSLocalizedString("THIS_FIELD_CANNOT_BE_BLANK", comment: "This field can not be blank")
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    public override var delegate:UITextFieldDelegate? {
        didSet {
            supportObj.delegate = delegate
            super.delegate=supportObj
        }
    }
    
    func setup() {
        validateOnCharacterChanged = true
        isMandatory = true
        validateOnResign = true
        popUpColor = ColorPopUpBg
        strLengthValidationMsg = MsgValidateLength.copy() as! String
        
        supportObj.validateOnCharacterChanged = validateOnCharacterChanged
        supportObj.validateOnResign = validateOnResign
        let notify = NotificationCenter.default
        notify.addObserver(self, selector: #selector(T4TextFieldValidator.didHideKeyboard), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    public func addRegx(strRegx:String, withMsg msg:String) {
        let dic:NSDictionary = ["regx":strRegx, "msg":msg]
        arrRegx.add(dic)
    }
    
    public func updateLengthValidationMsg(msg:String){
        strLengthValidationMsg = msg
    }
    
    public func addConfirmValidationTo(txtConfirm:T4TextFieldValidator, withMsg msg:String) {
        let dic = [txtConfirm:"confirm", msg:"msg"] as [AnyHashable : String]
        arrRegx.add(dic)
    }
    
    public func validate() -> Bool {
        if isMandatory {
            if self.text?.characters.count == 0 {
                self.showErrorIconForMsg(msg: strLengthValidationMsg)
                return false
            }
        }
        
        for i in 0 ..< arrRegx.count {
            
            let dic = arrRegx.object(at: i) as AnyObject
            
            if dic.object(forKey: "confirm") != nil {
                let txtConfirm = dic.object(forKey: "confirm") as! T4TextFieldValidator
                if txtConfirm.text != self.text {
                    self.showErrorIconForMsg(msg: dic.object(forKey: "msg") as! String)
                    return false
                }
            } else if dic.object(forKey: "regx") as! String != "" &&
                self.text?.characters.count != 0 &&
                !self.validateString(stringToSearch: self.text!, withRegex:dic.object(forKey: "regx") as! String) {
                self.showErrorIconForMsg(msg: dic.object(forKey: "msg") as! String)
                return false
            }
        }
        self.rightView=nil
        return true
    }
    
    public func dismissPopup() {
        popUp?.removeFromSuperview()
    }
    
    // MARK: Internal methods
    
    func didHideKeyboard() {
        popUp?.removeFromSuperview()
    }
    
    func tapOnError() {
        self.showErrorWithMsg(msg: strMsg)
    }
    
    func validateString(stringToSearch:String, withRegex regexString:String) ->Bool {
        let regex = NSPredicate(format: "SELF MATCHES %@", regexString)
        return regex.evaluate(with: stringToSearch)
    }
    
    func showErrorIconForMsg(msg:String) {
        let btnError = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        btnError.addTarget(self, action: #selector(T4TextFieldValidator.tapOnError), for: UIControlEvents.touchUpInside)
        btnError.setBackgroundImage(UIImage(named: "icon_error"), for: .normal)
        
        self.rightView = btnError
        self.rightViewMode = UITextFieldViewMode.always
        strMsg = msg
    }
    
    func showErrorWithMsg(msg:String) {
        
        if (presentInView == nil) {
            
            //            [TSMessage showNotificationWithTitle:msg type:TSMessageNotificationTypeError]
            print("Should set `Present in view` for the UITextField")
            return
        }
        
        popUp = IQPopUp(frame: CGRect.zero)
        popUp!.strMsg = msg as NSString
        popUp!.popUpColor = popUpColor
        popUp!.showOnRect = self.convert(self.rightView!.frame, to: presentInView)
        
        popUp!.fieldFrame = self.superview?.convert(self.frame, to: presentInView)
        
        popUp!.backgroundColor = UIColor.clear
        
        presentInView!.addSubview(popUp!)
        
        popUp!.translatesAutoresizingMaskIntoConstraints = false
        let dict = ["v1":popUp!]
        
        popUp?.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v1]-0-|", options: NSLayoutFormatOptions.directionLeadingToTrailing, metrics: nil, views: dict))
        
        popUp?.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v1]-0-|", options: NSLayoutFormatOptions.directionLeadingToTrailing, metrics: nil, views: dict))
        
        supportObj.popUp=popUp
    }
    
}


//  -----------------------------------------------


class TextFieldValidatorSupport : NSObject, UITextFieldDelegate {
    
    var delegate:UITextFieldDelegate?
    var validateOnCharacterChanged: Bool = false
    var validateOnResign = false
    var popUp :IQPopUp?
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        if delegate!.responds(to: Selector(("textFieldShouldBeginEditing"))) {
            return delegate!.textFieldShouldBeginEditing!(textField)
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if delegate!.responds(to: Selector(("textFieldDidBeginEditing"))) {
            delegate!.textFieldDidEndEditing!(textField)
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        if delegate!.responds(to: Selector(("textFieldShouldEndEditing"))) {
            return delegate!.textFieldShouldEndEditing!(textField)
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if delegate!.responds(to: Selector(("textFieldDidEndEditing"))) {
            delegate?.textFieldDidEndEditing!(textField)
            
        }
        popUp?.removeFromSuperview()
        if validateOnResign {
            (textField as! T4TextFieldValidator).validate()
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        (textField as! T4TextFieldValidator).dismissPopup()
        
        if validateOnCharacterChanged {
            
            (textField as! T4TextFieldValidator).perform(#selector(T4TextFieldValidator.validate), with: nil, afterDelay:0.1)
        }
        else {
            (textField as! T4TextFieldValidator).rightView = nil
        }
        
        if delegate!.responds(to: #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:))) {
            return delegate!.textField!(textField, shouldChangeCharactersIn: range, replacementString: string)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        if delegate!.responds(to: Selector(("textFieldShouldClear"))){
            delegate?.textFieldShouldClear!(textField)
        }
        return true
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if delegate!.responds(to: Selector(("textFieldShouldReturn"))) {
            delegate?.textFieldShouldReturn!(textField)
        }
        return true
    }
}

//  -----------------------------------------------

class IQPopUp : UIView {
    
    var showOnRect:CGRect?
    var popWidth:Int = 0
    var fieldFrame:CGRect?
    var strMsg:NSString = ""
    var popUpColor:UIColor?
    var FontSize:CGFloat = 15
    
    var PaddingInErrorPopUp:CGFloat = 5
    var FontName = "Helvetica-Bold"
    
    override func draw(_ rect:CGRect) {
        let color = popUpColor!.cgColor.components
        
        UIGraphicsBeginImageContext(CGSize(width: 30, height: 20))
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.setFillColor(red: color![0], green: color![1], blue: color![2], alpha: 1)
        ctx!.setShadow(offset: CGSize(width: 0, height: 0), blur: 7.0, color: UIColor.black.cgColor)
        
        let points = [ CGPoint(x: 15, y: 5), CGPoint(x: 25, y: 25), CGPoint(x: 5, y: 25)]
        ctx!.addLines(between: points)
        ctx!.closePath()
        ctx?.fillPath()
        let viewImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let imgframe = CGRect(x: (showOnRect!.origin.x + ((showOnRect!.size.width-30)/2)), y: ((showOnRect!.size.height/2) + showOnRect!.origin.y), width: 30, height: 13)
        
        let img = UIImageView(image: viewImage, highlightedImage: nil)
        
        self.addSubview(img)
        img.translatesAutoresizingMaskIntoConstraints = false
        var dict:Dictionary<String, AnyObject> = ["img":img]
        
        
        img.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format:"H:|-%f-[img(%f)]", imgframe.origin.x, imgframe.size.width), options:NSLayoutFormatOptions.directionLeadingToTrailing, metrics:nil, views:dict))
        img.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format:"V:|-%f-[img(%f)]",imgframe.origin.y,imgframe.size.height), options:NSLayoutFormatOptions.directionLeadingToTrailing,  metrics:nil, views:dict))
        
        let font = UIFont(name: FontName, size: FontSize)
        
        var size:CGSize = self.strMsg.boundingRect(with: CGSize(width: fieldFrame!.size.width - (PaddingInErrorPopUp*2), height: 1000), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName:font!], context: nil).size
        
        
        size = CGSize(width: ceil(size.width), height: ceil(size.height))
        
        
        let view = UIView(frame: CGRect.zero)
        self.insertSubview(view, belowSubview:img)
        view.backgroundColor=self.popUpColor
        view.layer.cornerRadius=5.0
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius=5.0
        view.layer.shadowOpacity=1.0
        view.layer.shadowOffset=CGSize(width: 0, height: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        dict = ["view":view]
        
        view.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format:"H:|-%f-[view(%f)]",fieldFrame!.origin.x+(fieldFrame!.size.width-(size.width + (PaddingInErrorPopUp*2))),size.width+(PaddingInErrorPopUp*2)), options:NSLayoutFormatOptions.directionLeadingToTrailing, metrics:nil, views:dict))
        
        view.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format:"V:|-%f-[view(%f)]",imgframe.origin.y+imgframe.size.height,size.height+(PaddingInErrorPopUp*2)), options:NSLayoutFormatOptions.directionLeadingToTrailing,  metrics:nil, views:dict))
        
        let lbl = UILabel(frame: CGRect.zero)
        lbl.font = font
        lbl.numberOfLines=0
        lbl.backgroundColor = UIColor.clear
        lbl.text=self.strMsg as String
        lbl.textColor = UIColor.white
        view.addSubview(lbl)
        
        lbl.translatesAutoresizingMaskIntoConstraints = false
        dict = ["lbl":lbl]
        lbl.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format:"H:|-%f-[lbl(%f)]", PaddingInErrorPopUp, size.width), options:NSLayoutFormatOptions.directionLeadingToTrailing , metrics:nil, views:dict))
        lbl.superview?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: String(format:"V:|-%f-[lbl(%f)]", PaddingInErrorPopUp,size.height), options:NSLayoutFormatOptions.directionLeadingToTrailing, metrics:nil, views:dict))
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        self.removeFromSuperview()
        return false
    }
}
