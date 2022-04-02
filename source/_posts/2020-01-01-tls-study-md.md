---
layout: post
title: 'TLS握手过程'
date: 2020-01-01 22:24:11
categories:
  - tech
  - TLS
tags:
  - Java
  - TLS
  - HTTPS
  - HTTP2
excerpt: 结合RFC5246标准，对TLS握手过程的理解和通信过程分析
---

## TLS握手过程
```shell script
# https request
$ curl -i https://dev-local.17xyx.app:2001/test_dir/hello.txt 
```

Network Working Group定义的完整的TLS握手过程：
```shell script
      Client                                               Server

      ClientHello                  -------->
                                                      ServerHello
                                                     Certificate*
                                               ServerKeyExchange*
                                              CertificateRequest*
                                   <--------      ServerHelloDone
      Certificate*
      ClientKeyExchange
      CertificateVerify*
      [ChangeCipherSpec]
      Finished                     -------->
                                               [ChangeCipherSpec]
                                   <--------             Finished
      Application Data             <------->     Application Data
```
*表示可选 该类消息不总会发送


- Wireshark 抓包TLS握手通信过程：
![images](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20200731171745.png)

- TLS1.2 TLS握手过程图解：
![images](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20200731182242.png)
注意：在这通信过程中Client的CertificateVerify和服务端CertificateRequest未出现


客户端使用会话的会话ID通过发送ClientHello到，服务器检查其会话缓存匹配，可以进行简单握手(abbreviated handshake),握手过程如下：
```shell script
      Client                                                Server

      ClientHello                   -------->
                                                       ServerHello
                                                [ChangeCipherSpec]
                                    <--------             Finished
      [ChangeCipherSpec]
      Finished                      -------->
      Application Data              <------->     Application Data
```
### 传输数据解析

#### Client Hello 
Client Hello 整个Frame除TCP信息外56Byte外，其余Hex Data结构可以表示为：
```shell script
  struct {
          ProtocolVersion client_version;
          Random random;
          SessionID session_id;
          CipherSuite cipher_suites<2..2^16-2>;
          CompressionMethod compression_methods<1..2^8-1>;
          select (extensions_present) {
              case false:
                  struct {};
              case true:
                  Extension extensions<0..2^16-1>;
          };
      } ClientHello;
```
数据报文与Wireshark解析结果：
```shell script
# Hex Data
0000   16 03 01 00 d7 01 00 00 d3 03 03 1e 82 28 e4 0c   .............(..
0010   04 79 5b 6e 71 6e f3 a9 9e 1f c2 df 93 a7 0e dd   .y[nqn..........
0020   16 b9 9a 58 0c fe 61 73 5c 1a 42 00 00 54 c0 30   ...X..as\.B..T.0
0030   c0 2c c0 28 c0 24 c0 14 c0 0a 00 9f 00 6b 00 39   .,.(.$.......k.9
0040   cc a9 cc a8 cc aa ff 85 00 c4 00 88 00 81 00 9d   ................
0050   00 3d 00 35 00 c0 00 84 c0 2f c0 2b c0 27 c0 23   .=.5...../.+.'.#
0060   c0 13 c0 09 00 9e 00 67 00 33 00 be 00 45 00 9c   .......g.3...E..
0070   00 3c 00 2f 00 ba 00 41 c0 12 c0 08 00 16 00 0a   .<./...A........
0080   00 ff 01 00 00 56 00 00 00 0e 00 0c 00 00 09 6c   .....V.........l
0090   6f 63 61 6c 68 6f 73 74 00 0b 00 02 01 00 00 0a   ocalhost........
00a0   00 08 00 06 00 1d 00 17 00 18 00 0d 00 1c 00 1a   ................
00b0   06 01 06 03 ef ef 05 01 05 03 04 01 04 03 ee ee   ................
00c0   ed ed 03 01 03 03 02 01 02 03 00 10 00 0e 00 0c   ................
00d0   02 68 32 08 68 74 74 70 2f 31 2e 31               .h2.http/1.1

# Wireshark TLS解析后的结果                     
Transmission Control Protocol, Src Port: 53384, Dst Port: 2001, Seq: 1, Ack: 1, Len: 220
Transport Layer Security
    TLSv1.2 Record Layer: Handshake Protocol: Client Hello
        Content Type: Handshake (22)
        Version: TLS 1.0 (0x0301)
        Length: 215
        Handshake Protocol: Client Hello
            Handshake Type: Client Hello (1)
            Length: 211
            Version: TLS 1.2 (0x0303)
            Random: 1e8228e40c04795b6e716ef3a99e1fc2df93a70edd16b99a…
                GMT Unix Time: Mar 22, 1986 11:37:08.000000000 CST
                Random Bytes: 0c04795b6e716ef3a99e1fc2df93a70edd16b99a580cfe61…
            Session ID Length: 0
            Cipher Suites Length: 84
            Cipher Suites (42 suites)
                Cipher Suite: TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (0xc030)
                Cipher Suite: TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 (0xc02c)
                Cipher Suite: TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384 (0xc028)
                Cipher Suite: TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384 (0xc024)
                Cipher Suite: TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA (0xc014)
                .....
                Cipher Suite: TLS_EMPTY_RENEGOTIATION_INFO_SCSV (0x00ff)
            Compression Methods Length: 1
            Compression Methods (1 method)
                Compression Method: null (0)
            Extensions Length: 86
            Extension: server_name (len=14)
                Type: server_name (0)
                Length: 14
                Server Name Indication extension
            Extension: ec_point_formats (len=2)
                Type: ec_point_formats (11)
                Length: 2
                EC point formats Length: 1
                Elliptic curves point formats (1)
                    EC point format: uncompressed (0)
            Extension: supported_groups (len=8)
                Type: supported_groups (10)
                Length: 8
                Supported Groups List Length: 6
                Supported Groups (3 groups)
                    Supported Group: x25519 (0x001d)
                    Supported Group: secp256r1 (0x0017)
                    Supported Group: secp384r1 (0x0018)
            Extension: signature_algorithms (len=28)
                Type: signature_algorithms (13)
                Length: 28
                Signature Hash Algorithms Length: 26
                Signature Hash Algorithms (13 algorithms)
            Extension: application_layer_protocol_negotiation (len=14)
                Type: application_layer_protocol_negotiation (16)
                Length: 14
                ALPN Extension Length: 12
                ALPN Protocol
```

### Server Hello 结构
整个Frame除TCP信息外56Byte外，其余Hex Data结构可以表示为：
```shell script
      struct {
          ProtocolVersion server_version;
          Random random;
          SessionID session_id;
          CipherSuite cipher_suite;
          CompressionMethod compression_method;
          select (extensions_present) {
              case false:
                  struct {};
              case true:
                  Extension extensions<0..2^16-1>;
          };
      } ServerHello;
     #The extension format is:
      struct {
          ExtensionType extension_type;
          opaque extension_data<0..2^16-1>;
      } Extension;

      enum {
          signature_algorithms(13), (65535)
      } ExtensionType;

```
TLS1.2 ServerHello TSL握手除了`ServerHello`,还包含了几个ExtensionType，具体如下：

|ExtensionType | desc |
|:---|:---|
|`Certificate` | 证书信息|
|`Server Key Exchange` | 证书和密钥交换|
|`Server Hello Done` | 证书信息|

`CipherSuite`
```shell script
0000   02 00 00 00 45 00 00 8e 00 00 40 00 40 06 00 00   ....E.....@.@...
0010   7f 00 00 01 7f 00 00 01 07 d1 db 05 4f db 4c ba   ............O.L.
0020   af a4 17 f7 80 18 18 e3 fe 82 00 00 01 01 08 0a   ................
0030   17 fb 61 30 17 fb 61 30 16 03 03 00 55 02 00 00   ..a0..a0....U...
0040   51 03 03 5f 22 ac 4e 6f 61 21 6b 29 77 4a e5 5b   Q.._".Noa!k)wJ.[
0050   64 3b f0 9c f7 d6 45 c9 bb 12 29 4d f1 0b 4d 51   d;....E...)M..MQ
0060   48 9a 33 20 5f 22 ac 41 a5 f7 21 90 3b c4 87 26   H.3 _".A..!.;..&
0070   01 94 81 64 03 52 93 2c 0a 06 57 02 23 b7 65 6e   ...d.R.,..W.#.en
0080   25 c2 0c 70 c0 2f 00 00 09 ff 01 00 01 00 00 17   %..p./..........
0090   00 00                                             ..


# wireshark 解析
Transport Layer Security
    TLSv1.2 Record Layer: Handshake Protocol: Server Hello
        Content Type: Handshake (22)
        Version: TLS 1.2 (0x0303)
        Length: 85
        Handshake Protocol: Server Hello
            Handshake Type: Server Hello (2)
            Length: 81
            Version: TLS 1.2 (0x0303)
            Random: 5f22ac4e6f61216b29774ae55b643bf09cf7d645c9bb1229…
            Session ID Length: 32
            Session ID: 5f22ac41a5f721903bc48726019481640352932c0a065702…
            Cipher Suite: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (0xc02f)
            Compression Method: null (0)
            Extensions Length: 9
            Extension: renegotiation_info (len=1)
            Extension: extended_master_secret (len=0)

# TLS 信息解析
Transport Layer Security
    TLSv1.2 Record Layer: Handshake Protocol: Multiple Handshake Messages
        Content Type: Handshake (22)
        Version: TLS 1.2 (0x0303)
        Length: 2736
        Handshake Protocol: Server Hello
        Handshake Protocol: Certificate
            Handshake Type: Certificate (11)
            Length: 2499
            Certificates Length: 2496
            Certificates (2496 bytes)
                Certificate Length: 975
                Certificate: 308203cb308201b302147059083695fc34358b5511db272c… (pkcs-9-at-emailAddress=it@17xyx.app,id-at-commonName=dev-local.17xyx.app,id-at-organizationalUnitName=Ltd,id-at-organizationName=Singapoe Dev ltd,id-at-localityName=SG,id-at
                Certificate Length: 1515
                Certificate: 308205e7308203cfa0030201020214505c0f62efd92247c9… (pkcs-9-at-emailAddress=it@17xyx.app,id-at-commonName=17xyx.app,id-at-organizationalUnitName=Ltd,id-at-organizationName=Sg 17xyx Tech.Ltd,id-at-localityName=SG,id-at-stateOrP
        Handshake Protocol: Server Key Exchange
            Handshake Type: Server Key Exchange (12)
            Length: 144
            EC Diffie-Hellman Server Params
                Curve Type: named_curve (0x03)
                Named Curve: secp256r1 (0x0017)
                Pubkey Length: 65
                Pubkey: 04078ee25e7303d05a141e56a2303eeb54902766933474b1…
                Signature Algorithm: ecdsa_secp521r1_sha512 (0x0603)
                Signature Length: 71
                Signature: 3045022100c4ab04ba8fa2f5c90cf251be846a8c4bdc30a7…
        Handshake Protocol: Server Hello Done
            Handshake Type: Server Hello Done (14)
            Length: 0
```
###  Client Key Exchange 部分

| message | desc |
|:---|:---|
| Client Key Exchange | 收到ServerHelloDone后，可以通过直接设置premaster机密RSA加密机密的传输或通过允许双方达成共识的Diffie-Hellman参数相同的Premaster秘诀|
|  Change Cipher Spec  |更改密码规范协议以信号转换加密策略
| Finished | 第一条正式加密数据 （The Finished message is the first one protected with the just negotiated algorithms, keys, and secrets）|

```shell script
0000   16 03 03 00 46 10 00 00 42 41 04 73 9d 45 fb 08   ....F...BA.s.E..
0010   0b c5 61 8f 28 d8 87 02 d0 2b 96 82 4e dd 36 90   ..a.(....+..N.6.
0020   a0 8d a6 76 28 f5 ab 5c 1b 03 2e c0 56 9e a5 a3   ...v(..\....V...
0030   95 34 02 2a 84 15 af fb 1e 94 b9 92 0e 09 c5 4a   .4.*...........J
0040   5c ec c1 c2 c8 51 02 d0 7f 93 5f                  \....Q...._

#TLS body 
Transport Layer Security
    TLSv1.2 Record Layer: Handshake Protocol: Client Key Exchange
        Content Type: Handshake (22)
        Version: TLS 1.2 (0x0303)
        Length: 70
        Handshake Protocol: Client Key Exchange
            Handshake Type: Client Key Exchange (16)
            Length: 66
            EC Diffie-Hellman Client Params
                Pubkey Length: 65
                Pubkey: 04739d45fb080bc5618f28d88702d02b96824edd3690a08d…
    TLSv1.2 Record Layer: Change Cipher Spec Protocol: Change Cipher Spec
        Content Type: Change Cipher Spec (20)
        Version: TLS 1.2 (0x0303)
        Length: 1
        Change Cipher Spec Message
    TLSv1.2 Record Layer: Handshake Protocol: Encrypted Handshake Message
        Content Type: Handshake (22)
        Version: TLS 1.2 (0x0303)
        Length: 40
        Handshake Protocol: Encrypted Handshake Message

```

## 参考

[RFC5246-SECTION-7.4.1.2](https://tools.ietf.org/html/rfc5246#section-7.4.1.2)