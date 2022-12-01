//
//  WGEncryptUtil.h
//  WGFcodeNotes
//
//  Created by 白菜 on 2022/12/1.
//  Copyright © 2022 WG. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WGEncrypt : NSObject
/* ⚠️public_key.der(公钥) private_key.p12(私钥)
 生成公私钥流程如下:
 cd到指定的文件下，然后执行如下命令
    //1.生成模长为 1024bit 的私钥文件 private_key.pem
    openssl genrsa -out private_key.pem 1024
 
    //2. 生成证书请求文件 rsaCertReq.csr；⚠️这一步会提示输入国家/省份/mail等信息，可以根据实际情况填写，或者全部不用填写，直接全部敲回车
    openssl req -new -key private_key.pem -out rsaCerReq.csr
    
    //3.生成证书 rsaCert.crt，并设置有效时间为 10 年
    openssl x509 -req -days 3650 -in rsaCerReq.csr -signkey private_key.pem -out rsaCert.crt
    
    //4. 生成供 iOS 使用的公钥文件 public_key.der
    openssl x509 -outform der -in rsaCert.crt -out public_key.der
 
    //5. 生成供 iOS 使用的私钥文件 private_key.p12
    //⚠️这一步会提示给私钥文件设置密码，直接输入想要设置密码即可，然后敲回车，然后再验证刚才设置的密码，再次输入密码，然后敲回车，完毕！
    在解密时，private_key.p12 文件需要和这里设置的密码配合使用，因此需要牢记此密码.
    openssl pkcs12 -export -out private_key.p12 -inkey private_key.pem -in rsaCert.crt
 
    //6. 生成供 Java 使用的公钥 rsa_public_key.pem
    openssl rsa -in private_key.pem -out rsa_public_key.pem -pubout
 
    //7. 生成供 Java 使用的私钥 pkcs8_private_key.pem
    openssl pkcs8 -topk8 -in private_key.pem -out pkcs8_private_key.pem -nocrypt
 
    //8执行完会看到生成如下的文件
    rsa_public_key.pem           :供 Java 使用的公钥
    pkcs8_private_key.pem        :供 Java 使用的私钥
    public_key.der               :供 iOS 使用的公钥
    private_key.p12              :供 iOS 使用的私钥
    private_key.pem
    rsaCertReq.csr               :证书请求文件
    rsaCert.crt                  :证书
    保存的密码.txt                 :执行命令行过程中需要保存的密码写在这个文件下，用私钥解密时需要这个密码
 */

/* 下面两个方法 用项目中生成的证书进行验证，验证案例如下：success
 //用公钥加密
 NSString *publicKeyPath = [[NSBundle mainBundle] pathForResource:@"public_key" ofType:@"der"];
 NSString *encryptContent = [WGEncrypt encryptWithRSA:@"123456" publicKeyWithContentsOfFile:publicKeyPath];
 //用私钥解密
 NSString *privateKeyPath = [[NSBundle mainBundle] pathForResource:@"private_key" ofType:@"p12"];
 NSString *content = [WGEncrypt decryptString:encryptContent privateKeyWithContentsOfFile:privateKeyPath password:@"baicai"];
 NSLog(@"明文是:%@",content); //明文是:123456
 */

//MARK: 公钥加密  通过公钥证书获取 path: .der格式的公钥文件路径
+(NSString *)encryptWithRSA:(NSString *)contentText publicKeyWithContentsOfFile:(NSString *)path;
//MARK: 私钥解密 通过私钥证书获取 path: .p12格式的私钥文件路径 password: 私钥文件密码
+(NSString *)decryptString:(NSString *)contentText privateKeyWithContentsOfFile:(NSString *)path password:(NSString *)password;




//RSA加密 公钥字符串 https://github.com/ideawu/Objective-C-RSA
//MARK: 公钥加密 返回base64编码字符串
+(NSString *)encryptWithRSA:(NSString *)contentText publicKey:(NSString *)key;
//MARK: 公钥解密，将base64编码的字符串，解密为字符串（非base64编码）
+(NSString *)decryptWithRSA:(NSString *)contentText publieKey:(NSString *)key;

//MARK: 公钥加密 返回data
+(NSData *)encryptWithRSAData:(NSData *)contentData publicKey:(NSString *)key;
//MARK: 公钥解密 返回data
+(NSData *)decryptWithRSAData:(NSData *)contentData publieKey:(NSString *)key;

//MARK: 私钥加密 返回base64编码字符串
+(NSString *)encryptWithRSA:(NSString *)contentText privateKey:(NSString *)key;
//MARK: 私钥解密，将base64编码的字符串，解密为字符串（非base64编码）
+(NSString *)decryptWithRSA:(NSString *)contentText privateKey:(NSString *)key;

//MARK: 私钥加密 返回data
+(NSData *)encryptWithRSAData:(NSData *)contentData privateKey:(NSString *)key;
//MARK: 私钥解密 返回data
+(NSData *)decryptWithRSAData:(NSData *)contentData privateKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
