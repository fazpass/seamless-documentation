# Seamless

## Introduction
![Logo](flow_system.png)

## Preparation
### 1. Choose your stack technology and install it.

| No | Stack Technology | Link 		|
| -- | --	 			| --	 	|
| 1  | Android Native  	| [Link](https://github.com/fazpass-sdk/android-trusted-device-v2)  		|
| 2  | IOS Native		| [Link](https://github.com/fazpass-sdk/ios-trusted-device-v2)  			|
| 3  | Flutter			| [Link](https://github.com/fazpass-sdk/flutter-trusted-device-v2)  		|
| 4  | React Native		| [Link](https://github.com/fazpass-sdk/react-native-trusted-device-v2)  	|
| 5  | Web Browser		| On The Way|

This sdk will generate META that will be used in the next step. As looked in the chart.

### 2. Whitelist IP
Whitelist IP is used to secure your API from unauthorized access. You can whitelist your IP in [here](https://fazpass.com).

### 3. Handle Response
After you call the API, you will get the response. This should like this
```JSON
"status":true,
"code":200
"data":{
  "meta":"encrypted"
}
```
You need to decrypt the meta using your private key. You can get the private key in [here](https://fazpass.com).

### 4. Decrypt Meta
For decrypting the meta, you can use this library 
| No | Stack Technology | Link 		|
| -- | --	 			| --	 	|
| 1  | Golang  			| [Link](https://github.com/fazpass-sdk/go-trusted-device-v2)  		|
| 2  | Node Js			| [Link](https://github.com/fazpass-sdk/nodejs-trusted-device-v2)  			|
| 3  | Python			| [Link](https://github.com/fazpass-sdk/python-trusted-device-v2)  		|
| 4  | Java				| [Link](https://github.com/fazpass-sdk/java-trusted-device-v2)  	|

If you want to decrypt the meta manually, you can decrypt this meta into byte[] using Base64. After that, you can decrypt the byte[] using your private key with PKCS1v15.