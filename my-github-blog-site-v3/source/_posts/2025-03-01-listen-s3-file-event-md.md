---
title: 读取S3最新创建的文件并将其发送到Kafka
excerpt: 业务需读取多个账号下的S3 buket的创建的新文件(AWS Cloudfront new log)
layout: post
date: 2025-03-31 15:07:03
tags:
  -tech 
  - s3
  - aws
categories:
    - blog
---

#  整体实现方案
```
Create S3 EventNotification ---> file_metadata_info --> AWS SQS Queue ---> SQS msg body --> 程序通过AWS SDK 消费SQS --> get S3 created file  and read file  content to Kakfa MQ 
                                             
```

![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503311823105.png)

# 技术实现

- S3 配置EventNotification to SQS 

 S3 Envent json格式：

```json
{
   "Records":[
      {
         "eventVersion":"2.1",
         "eventSource":"aws:s3",
         "awsRegion":"us-east-1",
         "eventTime":"2025-03-25T09:42:09.856Z",
         "eventName":"ObjectCreated:Put",
         "userIdentity":{
            "principalId":"AWS:"
         },
         "requestParameters":{
            "sourceIPAddress":"172.70.75.10"
         },
         "responseElements":{
            "x-amz-request-id":"xxx",
            "x-amz-id-2":"xxx/xxx/xxx"
         },
         "s3":{
            "s3SchemaVersion":"1.0",
            "configurationId":"xxx",
            "bucket":{
               "name":"xxxxx",
               "ownerIdentity":{
                  "principalId":"xxx"
               },
               "arn":"xxxxx"
            },
            "object":{
               "key":"xxxx.com/logs/20250325/20250325T094048Z_20250325T094157Z_90d6428f.log.gz",
               "size":8296069,
               "eTag":"36d359368c0721f26aea7a16fd004dbc",
               "sequencer":"0067E27A710FAAB941"
            }
         }
      }
   ]
}

```

- 实现
```SQL 

   


    /**
    * SQS consumer msg 
    */ 
    public  List<Message> receiveMessages(String queueUrl, int batchSize) {
        try {
            ReceiveMessageRequest receiveMessageRequest = ReceiveMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .maxNumberOfMessages(batchSize)
                    .build();
            return sqsClient.receiveMessage(receiveMessageRequest).messages();
        } catch (SqsException e) {
            logger.error(e.awsErrorDetails().errorMessage());
        }catch (Exception e){
            logger.error("SQS receiveMessages failed.cause:", e);
        }
        return Collections.emptyList();
    }

    ```

SQS get S3 file medadata , and send to kafak 
```java

        // 一个线程异步执行
        //任务之间不需要严格的固定频率，在上一个任务完成后等待固定时间再执行下一个任务
        ScheduledExecutorService executorService1 = Executors.newScheduledThreadPool(1);
        executorService1.scheduleWithFixedDelay(() -> {
                try {
                    ObjectMapper objectMapper = new ObjectMapper();
                    //step.1 读取SQS数据
                    List<Message> messages = sqsHelper.receiveMessages(queueUrl, 9);
                    List<S3EventPojo> s3EventList = new ArrayList<>();
                    for (int i = 0; i < messages.size(); i++) {
                        Message msg = messages.get(i);
                        String body = msg.body();
                        //解析 Body msg
                        JsonNode jsonNode = objectMapper.readTree(body);
                        for (JsonNode recordNode : jsonNode.path("Records")) {
                            //eventName
                            String eventName = recordNode.path("eventName").asText();
                            // 提取 key (位于 s3.object.key)
                            String bucketName = recordNode.path("s3").
                                    path("bucket").path("name").asText();
                            String key = recordNode.path("s3")
                                    .path("object").path("key").asText();
                            s3EventList.add(new S3EventPojo(eventName, key, bucketName));
                        }
                    }

                    //step.2 下载S3 object并发送到kafka
                    s3EventList.forEach(el -> {
                        Path tmpFilePath = null;
                        try {
                            tmpFilePath = myS3ClientHelper.downloadS3FileToLocal(el.getBucketName(),
                                    el.getKey(), localDownloadTmpDir);
                            //发送数据到Kafka
                            kafkaMsgHandler.readFileAndSendMsg(el.getKey(),tmpFilePath);
                            logger.info("compete read_and_send_msg to kafka,bucket:{}, key:{}", el.getBucketName(), el.getKey());
                        } catch (IOException e) {
                            logger.error("read_and_send_msg error,cause:", e);
                        } finally {
                            //删除文件
                            if (Objects.nonNull(tmpFilePath)) {
                                try {
                                    Files.deleteIfExists(tmpFilePath);
                                } catch (IOException e) {
                                    logger.error("delete file error,cause:", e);
                                }
                            }
                        }
                    });
                    //step3. 删除SQS中的key值
                    sqsHelper.deleteMessagesBatch(queueUrl, messages);
                } catch (Exception e) {
                    logger.error("execute get msg and read data failed.cause:", e);
                }
        }, 0, 100, TimeUnit.MILLISECONDS);
```

