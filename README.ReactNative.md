# react-native-trusted-device-v2

This is the Official react native package for Fazpass Trusted Device V2.
If you want to use native sdk for android, you can find it here: https://github.com/fazpass-sdk/android-trusted-device-v2 <br>
For ios counterpart, you can find it here: https://github.com/fazpass-sdk/ios-trusted-device-v2 <br>
You can also find this package at npm npmjs.com here: https://www.npmjs.com/package/react-native-trusted-device-v2 <br>
Visit [official website](https://fazpass.com) for more information about the product and see documentation at [online documentation](https://doc.fazpass.com) for more technical details.

## Minimum OS

Android 24, IOS 13.0

## Installation

```sh
npm install react-native-trusted-device-v2
```

## Getting Started

Before using this package, make sure to contact us first to get a public key and an FCM App ID (iOS only).

This package main purpose is to generate meta which you can use to communicate with Fazpass rest API. But
before calling generate meta method, you have to initialize it first by calling this method:

```js
Fazpass.instance.init(
    androidAssetName: 'AndroidAssetName.pub',
    iosAssetName: 'iosAssetName',
    iosFcmAppId: 'iosFcmAppId'
);
```

### Getting Started on Android

Setup your public key:

1. Open your android folder, then go to app/src/main/assets/ (if assets folder doesn't exist, create a new one)
2. Put the public key in this folder

#### Retrieving your application signatures

When creating a new merchant app in Fazpass Dashboard, there is a "signature" input.
![Fazpass Dashboard create new merchant app image](fazpass_dashboard_add_merchant.png)
Here's how to get this signature:

Add this line of code in your main screen React.useEffect() method

```js
Fazpass.instance.getAppSignatures().then((value) => print("APPSGN: $value"));
```

Then build apk for release. Launch it while your device is still connected and debugging in your pc.
Open logcat and query for `APPSGN`. It's value is an array, will look something like this: `[Gw+6AWbS7l7JQ7Umb1zcs1aNA8M=]`.
If item is more than one, pick just one of them. Copy the signature `Gw+6AWbS7l7JQ7Umb1zcs1aNA8M=` and fill the signature
of your merchant app with this value.

After you uploaded your apk or abb into the playstore, download your app from the playstore then check your app's signatures again.
If it's different, make sure to update the signature value of your merchant app.

### Getting Started on iOS

Setup your public key:

1. In your XCode project, open Assets.
2. Add new asset as Data Set.
3. Reference your public key into this asset.
4. Name your asset.

Then, you have to declare NSFaceIDUsageDescription in your Info.plist file to be able to generate meta, because generating meta requires user to do biometry authentication.

Then, in your AppDelegate.swift file in your XCode project, override your `didReceiveRemoteNotification` function.

```swift
override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
  
  // add this line
  Fazpass.shared.getCrossDeviceDataFromNotification(userInfo: userInfo)

  completionHandler(UIBackgroundFetchResult.newData)
}
```

## Usage

Call `generateMeta()` method to launch local authentication (biometric / password) and generate meta
if local authentication is success. Otherwise throws `BiometricAuthFailedError`.

```js
try {
  let meta = await Fazpass.instance.generateMeta();
} catch (e) {
  // on error...
}
```

## Exceptions & Errors

#### UninitializedException

Produced when fazpass init method hasn't been called once.

#### PublicKeyNotExistException

- Android: Produced when public key with the name registered in init method doesn't exist in the assets directory.
- iOS: Produced when public key with the name registered in init method doesn't exist as an asset.

#### EncryptionException

Produced when encryption went wrong because you used the wrong public key.

#### BiometricAuthError

Produced when biometric authentication is finished with an error. (example: User cancelled biometric auth, User failed biometric auth too many times, and many more).

#### BiometricUnavailableError

- Android: Produced when device can't start biometric authentication because there is no suitable hardware (e.g. no biometric sensor or no keyguard) or the hardware is unavailable.
- iOS: Produced when device can't start biometry authentication because biometry is unavailable.

#### BiometricNoneEnrolledError

- Android: Produced when device can't start biometric authentication because there is no biometric (e.g. Fingerprint, Face, Iris) or device credential (e.g. PIN, Password, Pattern) enrolled.
- iOS: Produced when device can't start biometry authentication because there is no biometry (Touch ID or Face ID) or device passcode enrolled.

#### BiometricUnsupportedError

- Android: Produced when device can't start biometric authentication because the specified options are incompatible with the current Android version.
- iOS: Produced when device can't start biometry authentication because displaying the required authentication user interface is forbidden. To fix this, you have to permit the display of the authentication UI by setting the interactionNotAllowed property to false.

### Android Exclusive Exceptions

#### BiometricSecurityUpdateRequiredError

Produced when device can't start biometric authentication because a security vulnerability has been discovered with one or
more hardware sensors. The affected sensor(s) are unavailable until a security update has addressed the issue.

## Set preferences for data collection

This package supports application with multiple accounts, and each account can have different settings for generating meta.
To set preferences for data collection, call `setSettings()` method.

```js
// index of an account
let accountIndex = 0;

// create preferences
let builder = new FazpassSettingsBuilder()
  .enableSelectedSensitiveData([SensitiveData.location])
  .setBiometricLevelToHigh();
let settings = FazpassSettings.fromBuilder(builder)

// save preferences
await Fazpass.instance.setSettings(accountIndex, settings);

// apply saved preferences by using the same account index
let meta = await Fazpass.instance.generateMeta(accountIndex);

// delete saved preferences
await Fazpass.instance.setSettings(accountIndex, null);
```

`generateMeta()` accountIndex parameter has -1 as it's default value.

> We strongly advised against saving preferences into default account index. If your application
> only allows one active account, use 0 instead.

## Data Collection

Data collected and stored in generated meta. Based on how data is collected, data type is divided into three: 
General data, Sensitive data and Other.
General data is always collected while Sensitive data requires more complicated procedures before they can be collected. 
Other is a special case. They collect a complicated test result, and might change how `generateMeta()` method works.

To enable Sensitive data collection, you need to set preferences for them and
specifies which sensitive data you want to collect.

```js
let builder = new FazpassSettingsBuilder()
    .enableSelectedSensitiveData([
      SensitiveData.location,
      SensitiveData.simNumbersAndOperators,
      SensitiveData.vpn
]);
```

Then, you have to follow the procedure on how to enable each of them as described in their own segment down below.

For others, you also need to set preferences for them and specifies which you want to enable.

```js
let builder = new FazpassSettingsBuilder()
    .setBiometricLevelToHigh();
```

For detail, read their description in their own segment down below.

### General data collected

- Your device platform name (Value will be "android" on android, and "ios" on iOS).
- Your app package name (bundle identifier on iOS).
- Your app debug status.
- Your device rooted status (jailbroken status on iOS).
- Your device emulator/simulator status.
- Your app cloned status. (Android only)
- Your device mirroring or projecting status.
- Your app signatures. (Android only)
- Your device information (Android/iOS version, phone brand/model, phone type, phone cpu).
- Your network IP Address.
- Your network vpn status. (Android only)

### Sensitive data collected

#### Your device location and mock location status

AVAILABILITY: ANDROID, IOS

To enable location on android, make sure you ask user for these permissions:

- android.permission.ACCESS_COARSE_LOCATION or android.permission.ACCESS_FINE_LOCATION
- android.permission.FOREGROUND_SERVICE

To enable location on ios, declare NSLocationWhenInUseUsageDescription in your Info.plist file.

#### Your device SIM numbers and operators (if available)

AVAILABILITY: ANDROID

To enable sim numbers and operators on android, make sure you ask user for these permissions:

- android.permission.READ_PHONE_NUMBERS
- android.permission.READ_PHONE_STATE

#### Your network vpn status

AVAILABILITY: IOS

To enable vpn on iOS, enable the Network Extensions capability in your Xcode project.

### Other data collected

#### High-level biometric

Enabling high-level biometrics makes the local authentication in `generateMeta()` method use ONLY biometrics, preventing user to use password as another option. After enabling this for the first time, immediately call `generateNewSecretKey()`
method to create a secret key that will be stored safely in device keystore provider. From now on, calling `generateMeta()`
with High-level biometric preferences will conduct an encryption & decryption test using the newly created secret key. Whenever the test is failed, it means the secret key has been invalidated because one these occurred:

- Device has enrolled another biometric information (new fingerprints, face, or iris)
- Device has cleared all biometric information
- Device removed their device passcode (password, pin, pattern, etc.)

When secret key has been invalidated, trying to hit Fazpass Check API will fail. The recommended action for this is
to sign out every account that has enabled high-level biometric and make them sign in again with low-level biometric settings.
If you want to re-enable high-level biometrics after the secret key has been invalidated, make sure to call `generateNewSecretKey()` once again.

## Handle incoming Cross Device Data notification

When application is in background state (not running), incoming cross device data will enter your system notification tray
and shows them as a notification. Pressing said notification will launch the application with cross device data as an argument.
When application is in foreground state (currently running), incoming cross device data will immediately sent into the application without showing any notification.

To retrieve cross device data when app is in background state, you have to call `getCrossDeviceDataFromNotification()` method.

```js
let data = await Fazpass.instance.getCrossDeviceDataFromNotification();
```

To retrieve cross device data when app is in foreground state, you have to get the stream instance by calling `getCrossDeviceDataStreamInstance()` then start listening to the stream.

```js
// get the stream instance
let crossDeviceStream = Fazpass.instance.getCrossDeviceDataStreamInstance();

// start listening to the stream
crossDeviceStream.listen((data) => {
  // called everytime there is an incoming cross device request notification
  print(data);

  if (data.status === "request") {
    let notificationId = data.notificationId!;
    print(notificationId);
  } else if (data.status === "validate") {
    let action = data.action!;
    print(action);
  }
});

// stop listening to the stream
crossDeviceStream.close();
```
