---
layout: post
title: 'HTTP2 TLS加密通信理解与应用'
date: 2020-01-01 22:23:54
categories:
  - tech
  - TLS
tags:
  - java
  - TLS
excerpt: 通过TLS实现端对端的加密场景的实现过程及原理
---

## 需求场景
一个HTTP2通信加密加密需求。

- 网络场景：  
![images](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20200731154733.png)

- 通信协议：
```
HTTP/2 + TLS1.3/TLS1.2(同时支持)
```

- CA证书签发及TLS握手过程示意图：  
![images](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20200805114352.png)




## CA证书的签署和自签署
自签署一份Root-CA用于开发和测试

### TLS加密算法选择 
TLS1.3支持的加密算法较少，需要提前查看兼容性：
```shell script
$ openssl version
```
result print:
```shell script
OpenSSL 1.1.1g  21 Apr 2020
```

- 筛选openssl 支持的TLS加密算法：
```shell script
 openssl ciphers -v 'kEECDH+ECDSA kEDH +RSA !aNULL !eNULL !LOW !3DES !DES !RC2 !RC4 !EXP !DSS !IDEA !SRP !kECDH !MD5 !SEED !PSK !CAMELLIA'
```
result print:
```shell script
TLS_AES_256_GCM_SHA384  TLSv1.3 Kx=any      Au=any  Enc=AESGCM(256) Mac=AEAD
TLS_CHACHA20_POLY1305_SHA256 TLSv1.3 Kx=any      Au=any  Enc=CHACHA20/POLY1305(256) Mac=AEAD
TLS_AES_128_GCM_SHA256  TLSv1.3 Kx=any      Au=any  Enc=AESGCM(128) Mac=AEAD
ECDHE-ECDSA-AES256-GCM-SHA384 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=AESGCM(256) Mac=AEAD
ECDHE-ECDSA-CHACHA20-POLY1305 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=CHACHA20/POLY1305(256) Mac=AEAD
ECDHE-ECDSA-AES256-CCM8 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=AESCCM8(256) Mac=AEAD
ECDHE-ECDSA-AES256-CCM  TLSv1.2 Kx=ECDH     Au=ECDSA Enc=AESCCM(256) Mac=AEAD
ECDHE-ECDSA-ARIA256-GCM-SHA384 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=ARIAGCM(256) Mac=AEAD
ECDHE-ECDSA-AES128-GCM-SHA256 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=AESGCM(128) Mac=AEAD
ECDHE-ECDSA-AES128-CCM8 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=AESCCM8(128) Mac=AEAD
ECDHE-ECDSA-AES128-CCM  TLSv1.2 Kx=ECDH     Au=ECDSA Enc=AESCCM(128) Mac=AEAD
ECDHE-ECDSA-ARIA128-GCM-SHA256 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=ARIAGCM(128) Mac=AEAD
ECDHE-ECDSA-AES256-SHA384 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=AES(256)  Mac=SHA384
ECDHE-ECDSA-AES128-SHA256 TLSv1.2 Kx=ECDH     Au=ECDSA Enc=AES(128)  Mac=SHA256
ECDHE-ECDSA-AES256-SHA  TLSv1 Kx=ECDH     Au=ECDSA Enc=AES(256)  Mac=SHA1
ECDHE-ECDSA-AES128-SHA  TLSv1 Kx=ECDH     Au=ECDSA Enc=AES(128)  Mac=SHA1
DHE-RSA-AES256-GCM-SHA384 TLSv1.2 Kx=DH       Au=RSA  Enc=AESGCM(256) Mac=AEAD
DHE-RSA-CHACHA20-POLY1305 TLSv1.2 Kx=DH       Au=RSA  Enc=CHACHA20/POLY1305(256) Mac=AEAD
DHE-RSA-AES256-CCM8     TLSv1.2 Kx=DH       Au=RSA  Enc=AESCCM8(256) Mac=AEAD
DHE-RSA-AES256-CCM      TLSv1.2 Kx=DH       Au=RSA  Enc=AESCCM(256) Mac=AEAD
DHE-RSA-ARIA256-GCM-SHA384 TLSv1.2 Kx=DH       Au=RSA  Enc=ARIAGCM(256) Mac=AEAD
DHE-RSA-AES128-GCM-SHA256 TLSv1.2 Kx=DH       Au=RSA  Enc=AESGCM(128) Mac=AEAD
DHE-RSA-AES128-CCM8     TLSv1.2 Kx=DH       Au=RSA  Enc=AESCCM8(128) Mac=AEAD
DHE-RSA-AES128-CCM      TLSv1.2 Kx=DH       Au=RSA  Enc=AESCCM(128) Mac=AEAD
DHE-RSA-ARIA128-GCM-SHA256 TLSv1.2 Kx=DH       Au=RSA  Enc=ARIAGCM(128) Mac=AEAD
DHE-RSA-AES256-SHA256   TLSv1.2 Kx=DH       Au=RSA  Enc=AES(256)  Mac=SHA256
DHE-RSA-AES128-SHA256   TLSv1.2 Kx=DH       Au=RSA  Enc=AES(128)  Mac=SHA256
DHE-RSA-AES256-SHA      SSLv3 Kx=DH       Au=RSA  Enc=AES(256)  Mac=SHA1
DHE-RSA-AES128-SHA      SSLv3 Kx=DH       Au=RSA  Enc=AES(128)  Mac=SHA1
```

- 名称映射关系说明：
 OpenSSL的加密算法与IANA的映射关系，可参照[OPENSSL-IANA.MAPPING](https://testssl.sh/openssl-iana.mapping.html)，以下是一个部分示例：
```shell script
Cipher Suite	Name (OpenSSL)	KeyExch.	Encryption	Bits	Cipher Suite Name (IANA)
[0x1301]	TLS_AES_128_GCM_SHA256	ECDH	AESGCM	128	TLS_AES_128_GCM_SHA256
[0x1303]	TLS_CHACHA20_POLY1305_SHA256	ECDH	ChaCha20-Poly1305	256	TLS_CHACHA20_POLY1305_SHA256
```

### OpenSSL 生成Root-CA 根证书
生成一个长期有效的`Root-CA`用于签发其它证书。
```shell script
# 生成CA 私钥
 openssl genrsa -out root-ca.key.pem 4096

# 生成  CA 自签名证书,需要输入各类信息 有效期10年～～～
openssl req -new -x509 -key  root-ca.key.pem -out root-ca.cert.pem -days 3650
```


### 使用Root-CA签署其它证书
因`TLS_CHACHA20_POLY1305_SHA256`使用的加密技术是`ECDH`,需要使用`Openssl ecparam`获取其支持的curves

- 查看Openssl 支持的曲线生成方法：
```shell script
openssl ecparam -list_curves
```
Openssl支持的曲线：
```
 secp112r1 : SECG/WTLS curve over a 112 bit prime field
  secp112r2 : SECG curve over a 112 bit prime field
  secp128r1 : SECG curve over a 128 bit prime field
  secp128r2 : SECG curve over a 128 bit prime field
  secp160k1 : SECG curve over a 160 bit prime field
  secp160r1 : SECG curve over a 160 bit prime field
  secp160r2 : SECG/WTLS curve over a 160 bit prime field
  secp192k1 : SECG curve over a 192 bit prime field
  secp224k1 : SECG curve over a 224 bit prime field
  secp224r1 : NIST/SECG curve over a 224 bit prime field
  secp256k1 : SECG curve over a 256 bit prime field
  secp384r1 : NIST/SECG curve over a 384 bit prime field
  secp521r1 : NIST/SECG curve over a 521 bit prime field
  prime192v1: NIST/X9.62/SECG curve over a 192 bit prime field
  prime192v2: X9.62 curve over a 192 bit prime field
  prime192v3: X9.62 curve over a 192 bit prime field
  prime239v1: X9.62 curve over a 239 bit prime field
  prime239v2: X9.62 curve over a 239 bit prime field
  prime239v3: X9.62 curve over a 239 bit prime field
  prime256v1: X9.62/SECG curve over a 256 bit prime field
  .....
```
注：本例使用 prime256v1

- 生成`ECDH`密钥交换的证书

```shell script
# 生成 ECDH 的私钥
openssl ecparam -out ecparam.pem -name prime256v1
openssl genpkey -paramfile ecparam.pem -out ecdhkey.pem

#  生成 ECDH 的公钥（public key）
openssl pkey -in ecdhkey.pem -pubout -out ecdhpubkey.pem

#生成 CSR（Certificate Request）文件，CSR 是需要自签名的，不能使用 ECDH 算法，因为 ECDH 不是签名算法，本例使用RSA算法生成。
$ openssl genrsa  -out rsakey.pem 4096

# 需要输入一个
$ openssl req -new -key rsakey.pem -out ecdhrsacsr.pem

# 使用上面的 roor-ca CA证书签署证书请求，并添加用户证书扩展名
$ openssl x509 -req -in ecdhrsacsr.pem -CAkey root-ca.key.pem -CA root-ca.cert.pem -force_pubkey ecdhpubkey.pem -out dev-ecdh-cert.pem -CAcreateserial

#目前生成的证书列表如下：
 dev-ecdh-cert.pem  # ECDH certificate(RSA算法的)
 ecdhkey.pem         # ECDH private key
 ecdhpubkey.pem       # ECDH public key
 ecdhrsacsr.pem       # RSA 的 CSR文件
 ecparam.pem         # EC Parameters
 root-ca.cert.pem     # Root CA certificate
 root-ca.cert.srl     
 root-ca.key.pem      # Root CA private key(RSA算法的)
 rsakey.pem           # RSA private key(用于请求证书的)
```


###  证书检查
####  根证书
- 查看根证书 :
```shell script
$ openssl x509 -in root-ca.cert.pem -noout -text
```
- 证书内容
```shell script
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            50:5c:0f:62:ef:d9:22:47:c9:ee:5c:08:11:50:40:74:41:24:88:d0
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = SG, ST = SG, L = SG, O = Sg 17xyx Tech.Ltd, OU = Ltd, CN = 17xyx.app, emailAddress = it@17xyx.app
        Validity
            Not Before: Jul 31 05:52:08 2020 GMT
            Not After : Jul 29 05:52:08 2030 GMT
        Subject: C = SG, ST = SG, L = SG, O = Sg 17xyx Tech.Ltd, OU = Ltd, CN = 17xyx.app, emailAddress = it@17xyx.app
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (4096 bit)
                Modulus:
                    00:a6:3e:cd:08:ea:9e:ea:6f:22:e0:7a:7d:03:dd:
                    ...
                    a5:c2:90:54:11:0b:48:49:55:b2:51:ab:78:35:75:
                    17:65:d3
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                CD:1D:8B:DE:1A:E3:3D:03:E5:3D:87:E0:28:9C:9C:30:77:4B:BD:05
            X509v3 Authority Key Identifier: 
                keyid:CD:1D:8B:DE:1A:E3:3D:03:E5:3D:87:E0:28:9C:9C:30:77:4B:BD:05

            X509v3 Basic Constraints: critical
                CA:TRUE
    Signature Algorithm: sha256WithRSAEncryption
         8f:fa:4f:76:b8:98:6c:e1:18:d1:29:75:c0:51:ae:19:49:e1:
         .....
         6a:85:fa:67:f9:6a:f6:23:ff:80:59:b4:fd:fe:95:2c:4a:a3:
         3e:89:24:0a:e0:44:17:84
```

- 证书的 RFC2253 信息:
```shell script
$ openssl x509 -in cacert.pem -noout -subject -nameopt RFC2253
```
输出内容：
```shell script
subject=emailAddress=ordiymaster@hotmail.com,CN=ZiBoMonten,OU=section,O=ShenZhen ZiBoMonten Tech.Ltd,L=ShenZhen,ST=GuangDong,C=CN
```

#### 查看签署的证书
```shell script
openssl x509 -in  dev-ecdh-cert.pem -noout --text
```
证书内容：
```shell script
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number:
            70:59:08:36:95:fc:34:35:8b:55:11:db:27:2c:4c:46:6a:eb:c7:70
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = SG, ST = SG, L = SG, O = Sg 17xyx Tech.Ltd, OU = Ltd, CN = 17xyx.app, emailAddress = it@17xyx.app
        Validity
            Not Before: Jul 31 06:00:02 2020 GMT
            Not After : Aug 30 06:00:02 2020 GMT
        Subject: C = SG, ST = SG, L = SG, O = Singapoe Dev ltd, OU = Ltd, CN = dev-local.17xyx.app, emailAddress = it@17xyx.app
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:52:36:25:ca:e7:5c:84:f4:44:d5:b4:a8:58:21:
                    ....
                    c2:73:b0:2e:34:eb:01:b1:27:03:62:52:28:5a:0f:
                    e2:9b:da:01:a8
                ASN1 OID: prime256v1
                NIST CURVE: P-256
    Signature Algorithm: sha256WithRSAEncryption
         8a:e0:43:dd:52:55:e9:c0:de:98:bf:04:ed:70:eb:39:6b:37:
         .....
         99:c5:47:5b:d4:d4:d3:60:2d:20:c5:6a:32:f9:0a:44:f4:05:
         bc:60:00:f1:9b:a3:a8:9e
```

## 证书应用
注意：生产环境使用的是中间证书，原理一样，这里直接使用Root-CA证书做示例:

### 导入root-ca 导入到JVM信任库
TLS协议证书验证时需要使用根证书对Server的证书进行验证，Java JKS(java KeyStore)会读取本地配置Root-CA证书。
-方法1 使用JVM System Properties
```
java -Djavax.net.ssl.trustStore=samplecacerts \
     -Djavax.net.ssl.trustStorePassword=changeit Application
```
使用`JVM System Properties`设置JKS比较灵活

- 方法2 将Root-CA导入到JVM信任库：
```shell script
#macOS 为例
keytool -importcert -alias startssl -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit -file root-ca.der

#查看root ca( 也可导入<java-home>/lib/security/jssecacerts,或使用启动参数导入)
keytool -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit -list | grep startssl
```

### 导入根证书到系统证书目录
使用浏览器或者PostMan测试，程序无法读取到JKS中证书信息，所以需要将Root-CA导入到系统的证书目录下。
在开发阶段为方便调试，如果遇到证书验证失败，调试时可以直接将Root-CA导入到系统的证书目录下（生产上实际不要这个操作)：
```shell script
#macos 操作命令：
sudo sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" root-ca.cert.pem
```

### Java应用程序使用 签署的CA证书
JKS(java KeyStore)用于为SSL/TLS配置的组件之间的通信加密,JKS支持导入`.jks`格式的文件。需要将CA 证书进行格式转换：
Openssl PEM格式转换为JKS格式，转换过程：
```shell script
Openssl PEM format --> pkcs12 format  --> jks format
```
执行命令：
```shell script
# opensll pem --< pkcs12 （需要设置密码)
openssl pkcs12 -export -in dev-ecdh-cert.pem -inkey ecdhkey.pem  -CAfile ../root_ca/root-ca.cert.pem -out dev-17xyx-app.ca.p12

# pkcs12 --> jks （需要输入 上一步设置的密码)
keytool -importkeystore -srckeystore dev-17xyx-app.ca.p12 -srcstoretype pkcs12 -destkeystore dev-17xyx-app.ca.jks

# 查看文件目录
dev-17xyx-app.ca.jks   # jks 文件
dev-17xyx-app.ca.p12   
dev-ecdh-cert.der
dev-ecdh-cert.pem
ecdhkey.pem
ecdhpubkey.pem
ecdhrsacsr.pem
ecparam.pem
rsakey.pem
```


#### 程序实现示例
以`netty`示例信息，如需获取源代码(https://github.com/ordiy/demo-project/tree/master/test-http2-tls)
- server http2
```` Java
    static {
        //load root-ca
        System.setProperty("javax.net.ssl.trustStore","./security-ca/root-ca/root-ca.jks");
        System.setProperty("javax.net.ssl.trustStorePassword","hello@2020");
    }
    public static String host = "127.0.0.1";
    public static int port = 9443;

    KeyManagerFactory keyManagerFactory ;
    Http2Client http2Client ;

    @Before
    public void beforeTest(){
        final Path path = Paths.get(".");
        System.out.println("current directory:"+ path.toAbsolutePath().toString());
        String serverPrivateKey="server@2020";
        String serverCertificateFile="security-ca/server-ca/server-ca.jks";
        keyManagerFactory = jksLoad(serverPrivateKey,serverCertificateFile);
    }

    @Test
    public void testServer(){
        try {
            new Http2Server().startServer(host,port,keyManagerFactory);
        } catch (SSLException e) {
            e.printStackTrace();
        }
    }

    public static   KeyManagerFactory jksLoad(String privatePassword, String jksFile){
        try(FileInputStream fileInputStream = new FileInputStream(jksFile)) {
            char[] passphrase = privatePassword.toCharArray();
            KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
            KeyStore ks = KeyStore.getInstance("JKS");
            ks.load(fileInputStream, passphrase);
            kmf.init(ks, passphrase);
            return kmf;
        } catch (NoSuchAlgorithmException | KeyStoreException | CertificateException | UnrecoverableKeyException | IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }
````
-client `SSLSocketFactory`
```java
    static {
        //load root-ca
        System.setProperty("javax.net.ssl.trustStore","./security-ca/root-ca/root-ca.jks");
        System.setProperty("javax.net.ssl.trustStorePassword","hello@2020");
    }
    KeyManagerFactory keyManagerFactory =null; //读取 System properties 中的配置
        static {
        //load root-ca
        System.setProperty("javax.net.ssl.trustStore","./security-ca/root-ca/root-ca.jks");
        System.setProperty("javax.net.ssl.trustStorePassword","hello@2020");
    }
    KeyManagerFactory keyManagerFactory =null; //读取 System properties 中的配置
    Http2Client http2Client ;
    @Before
    public void beforeTest(){

        http2Client = new Http2Client();
    }

    @Test
    public void startHttp2Client() {
        String host =HelloWorldServerTest.host;
        int port = HelloWorldServerTest.port;
        Map<String,String> map = new HashMap<>();
        map.put("/whatever","/whatever");
        map.put("/url2","test data");
        try {
            http2Client.startHttp2Server(host,port,keyManagerFactory,map);
            System.out.println("=====> start ...");
        } catch (SSLException e) {
            e.printStackTrace();
        }
    }

```
* 此部分的代码细节是一个实现的Demo,非项目本身代码(项目涉及甲方知识产权wuwu~)

## 总结
Java8对TLSv1.3的支持有些问题，可能会遇到只支持TLSv1.2的情况，可以安装JDK11在尝试。采用Netty作为通信框架，是因为Netty是一个优秀的NIO通信框架，并且底层通信过程透明，方便理解整个通信过程。
 
## 参考
 
[wiki Transport_Layer_Security#TLS_1.3](https://en.wikipedia.org/wiki/Transport_Layer_Security#TLS_1.3)  
[openssl tlsv1.3](https://wiki.openssl.org/index.php/TLS1.3)   
[openssl-iana.mapping](https://testssl.sh/openssl-iana.mapping.html)   
[TLS 证书生成和使用](https://www.jianshu.com/p/5938432e2130)   
[TLS1.3](https://en.wikipedia.org/wiki/Transport_Layer_Security#TLS_1.3)   
[openssl x509(签署和自签署)](https://www.cnblogs.com/f-ck-need-u/p/6090885.html)   
[sample-truststores](https://docs.oracle.com/javase/10/security/sample-truststores.htm#JSSEC-GUID-51A0A134-F222-4B69-ACCA-C5542AA7D9C8)   

