//
//  ViewController.m
//  YBPayDemo
//
//  Created by mahong on 16/1/26.
//  Copyright © 2016年 mahong. All rights reserved.
//

#import "ViewController.h"
#import "Order.h"
#import "APAuthV2Info.h"
#import "DataSigner.h"
#import <AliPaySDK/AlipaySDK.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *payButton = [UIButton buttonWithType:UIButtonTypeCustom];
    payButton.frame = CGRectMake(10, 100, self.view.frame.size.width-20, 40);
    [payButton setTitle:@"pay 0.01元" forState:UIControlStateNormal];
    [payButton setTitle:@"pay 0.01元" forState:UIControlStateSelected];
    [payButton setBackgroundColor:[UIColor orangeColor]];
    [payButton addTarget:self action:@selector(payAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:payButton];
}

/**
 *  支付按钮
 */
- (void)payAction
{
    /*============================================================================*/
    /*=======================需要填写商户app申请的===================================*/
    /*============================================================================*/
    NSString *partner = @"2088701787546364"; /** 合作商户ID  PID */
    NSString *seller = @"zfb@runbey.net"; /** 支付宝账号ID  */
    NSString *privateKey = @"MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBANEBTFL65mvm4ep92NTaAj4pXK5d/PGYsGmOlFCFlZGRmk8eggv4nixn91WLwGH4bX1yuNa0/WptFvswlByMAJRYHZ/avUAj2dyl877+X+XRhUmPJPBsmI/pehKKcpUBwYttoexCE7a5yOb05G05PFjp1p9jXf5cIndgRmygg9EzAgMBAAECgYEAw2WpS3LR9VLXJvkcvHJM4nyc709jaSNM2oK32kfpOzyavRlSj4qRpgZUz59l7rHo+v1EHUb8HIF8mL4j2kRxTI5JGRRgvbdM1ALGE3crqtX6rjN9WzYe99p32RoSbZR9Dg2NdQUDFOIt7yqX4ixPDLtJZo0g11bo7AqZN4aZKOECQQDoS8QUbe4ILRgDVkHPjYAB1aevcdxRErWzflyoq2a+oq8N6vhyj8uARPgUMB5zI87wMb6/d7lpL8AK/GHMn8abAkEA5lUbjaU9zT9NKiXupEI9j0juRJBUWIQQcDIQCkI4/PC9QqC9EMU7u91CDB69nO9pmdHthg+mBukcUId2M1f9SQJAbmWjmDnuSAB2Sw+xUxxiW3zYpm6sT/NeWyGQk7BxsePK4ghrbrab9ifQ5nc/4WSBMnHRv1j8ytqgoBf1urOsRQJBALuFlsUfPs2XN8+UylFYzJ2XFsUjbEgUXP27BGwVtifYJ33TN5oruZIddORBMsZN9H+S9forS1Rc/PxjDMyIWmECQQCqEEXbHuQQLED233dOFPC1bwbgjZTtP8XWQK24cCRUADL2SXBY6IobtW914CB3ByXT8m0Dlw6QFz+lGeoVY2B/"; /** 商户私钥 自助生成 */
    /*============================================================================*/
    /*============================================================================*/
    /*============================================================================*/
    
    //partner和seller获取失败,提示
    if ([partner length] == 0 ||
        [seller length] == 0 ||
        [privateKey length] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"缺少partner或者seller或者私钥。"
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    
    /*
     *生成订单信息及签名
     */
    //将商品信息赋予AlixPayOrder的成员变量
    Order *order = [[Order alloc] init];
    order.partner = partner;
    order.seller = seller;
    order.tradeNO = [self generateTradeNO]; //订单ID（由商家自行制定）
    order.productName = @"runbey测试商品"; //商品标题
    order.productDescription = @"runbey商品描述"; //商品描述
    order.amount = @"0.01"; //商品价格
    order.notifyURL =  @"http://api.jsypj.com/v1/peijia/app_port/notify_url.php"; //回调URL 异步通知服务器
    
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showUrl = @"m.alipay.com";
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"ybpaydemo";
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderSpec];
    
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        NSLog(@"签名字符串:%@",orderString);
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"支付结果reslut = %@",resultDic);
        }];
    }
}

#pragma mark -
#pragma mark   ==============产生随机订单号==============


- (NSString *)generateTradeNO
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned)time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
