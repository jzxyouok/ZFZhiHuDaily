//
//  ZFMainViewModel.swift
//  ZFZhiHuDaily
//
//  Created by 任子丰 on 16/1/7.
//  Copyright © 2016年 任子丰. All rights reserved.
//

import UIKit
import SwiftyJSON

class ZFMainViewModel: NSObject {
    var themes : [ZFTheme] = []
    // 回调
    typealias ThemeViewModelSuccessCallBack = (dataSoure : Array<ZFNews>,headerSource : Array<ZFNews>) -> Void
    typealias ListSuccessCallBack = (dataSoure : Array<ZFNews>,dateStr : String) -> Void
    typealias ThemeVieModelErrorCallBack = (error : NSError) -> Void
    /// 今日热闻、轮播图的回调
    var successCallBack : ThemeViewModelSuccessCallBack?
    /// 列表的成功回调
    var listSuccessCallBack : ListSuccessCallBack?
    /// 失败回调
    var errorCallBack : ThemeVieModelErrorCallBack?
    /// dateFormat
    var dateFormat : NSDateFormatter = NSDateFormatter()
    
    /**
     获取今日热闻、轮播图数据
     
     - parameter successCallBack: successCallBack description
     - parameter errorCallBack:   errorCallBack description
     */
    func getData (successCallBack : ThemeViewModelSuccessCallBack?, errorCallBack : ThemeVieModelErrorCallBack?) {
        self.successCallBack = successCallBack
        self.errorCallBack = errorCallBack
        ZFNetworkTool.get(LATEST_NEWS_URL, params: nil, success: { (json) -> Void in
            let result = JSON(json)
            //let date = Int(result["date"].string!)
            //最热新闻
            let top_stories = result["top_stories"].array
            //最新新闻
            let stories = result["stories"].array
            //遍历轮播图数据
            let topNews : [ZFNews]? = self.convertStoriesJson2Vo(top_stories, type: .TOP_NEWS)
            //遍历最新的新闻
            let lastestNews : [ZFNews]? = self.convertStoriesJson2Vo(stories, type: .NEWS)

            // 回调给controller
            if self.successCallBack != nil {
                self.successCallBack!(dataSoure:lastestNews!, headerSource:topNews!)
            }
            }) { (error) -> Void in
                
        }
    }
    /**
     获取往日的新闻
     
     - parameter dateIndex:       页数的下标，相当于取出date，根据date查询当日数据
     - parameter successCallBack: successCallBack description
     - parameter errorCallBack:   errorCallBack description
     */
    func getDataForDate (dateIndex: Int ,successCallBack : ListSuccessCallBack?, errorCallBack : ThemeVieModelErrorCallBack?) {
        let date : NSDate = NSDate(timeIntervalSinceNow: -(dateIndex*24*60*60))
        dateFormat.locale = NSLocale(localeIdentifier: "zh_CN")
        dateFormat.dateFormat = "yyyyMMdd"
        let dateStr : String =  dateFormat.stringFromDate(date)
        
        self.listSuccessCallBack = successCallBack
        //若果需要查询 11 月 18 日的消息，before 后的数字应为 20131119
        ZFNetworkTool.get(BEFORE_NEWS + dateStr, params: nil, success: { (json) -> Void in
            let result = JSON(json)
            //最新新闻
            let stories = result["stories"].array
            //遍历最新的新闻
            let lastestNews : [ZFNews]? = self.convertStoriesJson2Vo(stories, type: .NEWS)
            self.dateFormat.dateFormat = "MM月dd日 cccc"
            let dateStr = self.dateFormat.stringFromDate(date)
            
            // 回调给controller
            if self.listSuccessCallBack != nil {
                self.listSuccessCallBack!(dataSoure:lastestNews!,dateStr:dateStr)
            }
            }) { (error) -> Void in
                
        }
        
    }

    /**
     转换新闻List JSON对象到VO对象
     
     - parameter stories: [JSON]
     - parameter type:    新闻类型,因为TOP 和一般的 结构上有点区别
     
     - returns:
     */
    private func convertStoriesJson2Vo(stories:[JSON]?,type:NewsTypeEnum = .NEWS) ->[ZFNews]? {
        var news:[ZFNews]? = nil
        //遍历最热新闻
        if  let _stories = stories {
            news = []
            for story in _stories {
                //把JSON转换成VO
                let new = self.convertJSON2VO(story, type: type)
                news?.append(new)
            }
        }
        
        return news
    }
    
    /**
     把JSON转换成 ZFNews
     
     - parameter json: JSON
     - parameter type: News类型,因为 最热新闻的结构稍微有点不一样
     
     - returns:
     */
    private func convertJSON2VO(json:JSON,type:NewsTypeEnum = .NEWS) -> ZFNews {
        
        let id = json["id"].int!
        
        let title = json["title"].string!
        
        let gaPrefix = json["ga_prefix"].int
        
        var image:[String]? = nil
        if  type == .TOP_NEWS {
            let  _image = json["image"].string
            
            if  let i = _image {
                image = [i]
            }
        }else {
            let _images = json["images"].array
            
            if let _is = _images {
                image = []
                
                for i in _is {
                    image?.append(i.string!)
                }
            }
        }
        
        let multipic = json["multipic"].bool
        
        return ZFNews(id: id, title: title, images: image, multipic:multipic, gaPrefix: gaPrefix)
    }

    
    enum NewsTypeEnum {
        //轮播图
        case TOP_NEWS
        //新闻列表
        case NEWS
    }
}