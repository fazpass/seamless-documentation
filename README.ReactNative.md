# react-native-trusted-device-v2

Visit [official website](https://fazpass.com) for more information about the product and see documentation at [online documentation](https://doc.fazpass.com) for more technical details.

## Minimum OS

Android 24, IOS 13.0

## Installation

For installation, please refer to these documentation:

Android: https://github.com/fazpass/seamless-documentation/blob/main/README.Android.md#installation <br>
IOS (Use Cocoapods Intallation): https://github.com/fazpass/seamless-documentation/blob/main/README.iOS.md#installation <br>

After the installation is finished, go back immediately to this documentation.

## Bridging between native SDK and React Native Application

To use native SDK on your react native application, you have to bridge it by writing native code in your native project, then import it in your react native project.

### Writing Native Code in Android

Make sure Fazpass SDK is installed correctly by importing the SDK in your android project. If there is no error, then continue reading.

1. Open your android project, then find your main application file (app/src/main/"java/kotlin"/<app_package>/MainApplication.kt). Then add FazpassPackage in getPackages() function:

```kotlin
class MainApplication : Application(), ReactApplication {

  override val reactNativeHost: ReactNativeHost =
      object : DefaultReactNativeHost(this) {
        override fun getPackages(): List<ReactPackage> =
            PackageList(this).packages.apply {
              // Packages that cannot be autolinked yet can be added manually here, for example:
              // add(MyReactNativePackage())

                // Add Fazpass Package
                add(FazpassPackage())
            }

        override fun getJSMainModuleName(): String = "index"

        override fun getUseDeveloperSupport(): Boolean = BuildConfig.DEBUG

        override val isNewArchEnabled: Boolean = BuildConfig.IS_NEW_ARCHITECTURE_ENABLED
        override val isHermesEnabled: Boolean = BuildConfig.IS_HERMES_ENABLED
      }

  override val reactHost: ReactHost
    get() = getDefaultReactHost(applicationContext, reactNativeHost)

  override fun onCreate() {
    super.onCreate()
    SoLoader.init(this, false)
    if (BuildConfig.IS_NEW_ARCHITECTURE_ENABLED) {
      // If you opted-in for the New Architecture, we load the native entry point for this app.
      load()
    }
  }
}
```

2. Create the FazpassPackage class:

```kotlin
class FazpassPackage: ReactPackage {

    private val fazpass = FazpassFactory.getInstance()

    override fun createNativeModules(context: ReactApplicationContext): MutableList<NativeModule> {
        fazpass.init(context.applicationContext, YOUR-PUBLIC-KEY.pub)
        return listOf(FazpassModule(context, fazpass), CrossDeviceModule(context, fazpass)).toMutableList()
    }

    override fun createViewManagers(p0: ReactApplicationContext): MutableList<ViewManager<View, ReactShadowNode<*>>> =
        mutableListOf()
}
```

3. Create the FazpassModule class:

```kotlin
class FazpassModule(context: ReactApplicationContext, private val fazpass: Fazpass): ReactContextBaseJavaModule(context) {

    override fun getName(): String = "FazpassModule"

    @ReactMethod
    fun generateMeta(accountIndex: Double, promise: Promise) {
        val activity = reactApplicationContext.currentActivity
        if (activity == null) {
            promise.reject(NullPointerException("Activity not found!"))
            return
        }

        UiThreadUtil.runOnUiThread {
            fazpass.generateMeta(activity, accountIndex.toInt()) { meta, e ->
                if (e != null) {
                    promise.reject(e.exception)
                    return@generateMeta
                }

                promise.resolve(meta)
            }
        }
    }

    @ReactMethod
    fun generateNewSecretKey(promise: Promise) {
        fazpass.generateNewSecretKey(reactApplicationContext.applicationContext)
        promise.resolve(null)
    }

    @ReactMethod
    fun setSettings(accountIndex: Double, settingsString: String?, promise: Promise) {
        val settings = if (settingsString != null) FazpassSettings.fromString(settingsString) else null
        fazpass.setSettings(reactApplicationContext.applicationContext, accountIndex.toInt(), settings)
        promise.resolve(null)
    }

    @ReactMethod
    fun getSettings(accountIndex: Double, promise: Promise) {
        val settings = fazpass.getSettings(accountIndex.toInt())
        promise.resolve(settings?.toString())
    }

    @ReactMethod
    fun getCrossDeviceDataFromNotification(promise: Promise) {
        val activity = reactApplicationContext.currentActivity
        if (activity == null) {
            promise.reject(NullPointerException("Activity not found!"))
            return
        }

        val data = fazpass.getCrossDeviceDataFromNotification(activity.intent)
        val map = if (data != null) Arguments.makeNativeMap(data.toMap()) else null
        promise.resolve(map)
    }

    @ReactMethod
    fun getAppSignatures(promise: Promise) {
        val activity = reactApplicationContext.currentActivity
        if (activity == null) {
            promise.reject(NullPointerException("Activity not found!"))
            return
        }

        val signatures = fazpass.getAppSignatures(activity)
        val array = Arguments.createArray()
        signatures.forEach { item -> array.pushString(item) }
        promise.resolve(array)
    }
}
```

4. Create the CrossDeviceModule class:

```kotlin
class CrossDeviceModule(reactContext: ReactApplicationContext, fazpass: Fazpass): ReactContextBaseJavaModule(reactContext) {

    companion object {
        const val NAME = "CrossDevice"
    }

    override fun getName(): String = NAME

    private val streamInstance: CrossDeviceDataStream =
        fazpass.getCrossDeviceDataStreamInstance(reactApplicationContext.applicationContext)

    private var listenerCount = 0

    private fun sendEvent(reactContext: ReactContext, eventName: String, params: WritableMap?) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
    }

    @ReactMethod
    fun addListener(eventName: String) {
        if (listenerCount == 0) {
            // Set up any upstream listeners or background tasks as necessary
            streamInstance.listen {
                sendEvent(
                    reactApplicationContext,
                    eventName,
                    Arguments.makeNativeMap(it.toMap())
                )
            }
        }

        listenerCount += 1
    }

    @ReactMethod
    fun removeListeners(count: Int) {
        listenerCount -= count
        if (listenerCount == 0) {
            streamInstance.close()
        }
    }
}
```

### Using Written Native Code in React Native

1. In your root project, create a fazpass module directory (modules/fazpass)
2. Create index.tsx file:

```ts
import { NativeModules, Platform } from 'react-native';
import { SensitiveData } from './sensitive-data.tsx';
import FazpassSettings, { FazpassSettingsBuilder } from './fazpass-settings.tsx';
import CrossDeviceDataStream from './cross-device-data-stream.tsx';
import CrossDeviceData from './cross-device-data.tsx';
import type FazpassInterface from './fazpass-interface.tsx';

const LINKING_ERROR =
  'The package \'react-native-trusted-device-v2\' doesn\'t seem to be linked. Make sure: \n\n' +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const TrustedDeviceV2 = NativeModules.TrustedDeviceV2
  ? NativeModules.TrustedDeviceV2
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

const CrossDevice = NativeModules.CrossDevice
  ? NativeModules.CrossDevice
  : new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  );

export default class Fazpass implements FazpassInterface {

  static instance = new Fazpass();

  #getCrossDeviceDataStream: CrossDeviceDataStream;

  private constructor() {
    this.#getCrossDeviceDataStream = new CrossDeviceDataStream(CrossDevice);
  }

  generateMeta(accountIndex: number = -1): Promise<string> {
    return TrustedDeviceV2.generateMeta(accountIndex);
  }

  generateNewSecretKey(): Promise<void> {
    return TrustedDeviceV2.generateNewSecretKey();
  }

  setSettings(accountIndex: number, settings?: FazpassSettings | undefined): Promise<void> {
    return TrustedDeviceV2.setSettings(accountIndex, settings?.toString());
  }

  async getSettings(accountIndex: number): Promise<FazpassSettings | undefined> {
    const settingsString = await (TrustedDeviceV2.getSettings(accountIndex) as Promise<string | undefined>);
    return settingsString ? FazpassSettings.fromString(settingsString) : undefined;
  }

  getCrossDeviceDataStreamInstance(): CrossDeviceDataStream {
    return this.#getCrossDeviceDataStream;
  }

  async getCrossDeviceDataFromNotification(): Promise<CrossDeviceData | undefined> {
    const data = await (TrustedDeviceV2.getCrossDeviceRequestFromNotification() as Promise<any>);
    return data ? new CrossDeviceData(data) : undefined;
  }

  async getAppSignatures(): Promise<Array<string>> {
    if (Platform.OS === 'android') {
      return await TrustedDeviceV2.getAppSignatures();
    }

    return [];
  }
}

export { SensitiveData };
export { FazpassSettings, FazpassSettingsBuilder };
export { CrossDeviceData };
export { CrossDeviceDataStream };
```

3. Create fazpass-interface.tsx file:

```ts
import { CrossDeviceData, CrossDeviceDataStream, FazpassSettings } from '.';

export default interface FazpassInterface {

  /**
   * Retrieves application signatures.
   *
   * Only works in android. Will return empty list in iOS.
   */
  getAppSignatures(): Promise<Array<string> | undefined>;

  /**
   * Collects specific data according to settings and generate meta from it as Base64 string.
   *
   * You can use this meta to hit Fazpass API endpoint. Calling this method will automatically launch
   * local authentication (biometric / password). Any rules that have been set in method {@link Fazpass.setSettings()}
   * will be applied according to the `accountIndex` parameter.
   *
   * Throws any {@link FazpassException} if an error occurred.
   */
  generateMeta(accountIndex: number): Promise<string>;

  /**
   * Generates new secret key for high level biometric settings.
   *
   * Before generating meta with "High Level Biometric" settings, You have to generate secret key first by
   * calling this method. This secret key will be invalidated when there is a new biometric enrolled or all
   * biometric is cleared, which makes your active fazpass id to get revoked when you hit Fazpass Check API
   * using meta generated with "High Level Biometric" settings. When secret key has been invalidated, you have
   * to call this method to generate new secret key and enroll your device with Fazpass Enroll API to make
   * your device trusted again.
   *
   * Might throws exception when generating new secret key. Report this exception as a bug when that happens.
   */
  generateNewSecretKey(): Promise<void>;

  /**
   * Sets rules for data collection in{@link Fazpass.generateMeta()} method.
   *
   * Sets which sensitive information is collected in {@link Fazpass.generateMeta()} method
   * and applies them according to `accountIndex` parameter. Accepts {@link FazpassSettings} for `settings`
   * parameter. Settings will be stored in SharedPreferences (UserDefaults in iOS), so it will
   * not persist when application data is cleared / application is uninstalled. To delete
   * stored settings, pass undefined on `settings` parameter.
   */
  setSettings(accountIndex: number, settings?: FazpassSettings): Promise<void>;

  /**
   * Retrieves the rules that has been set in {@link Fazpass.setSettings()} method.
   *
   * Retrieves a stored {@link FazpassSettings} object based on the `accountIndex` parameter.
   * Returns null if there is no stored settings for this `accountIndex`.
   */
  getSettings(accountIndex: number): Promise<FazpassSettings | undefined>;

  /**
   * Retrieves the stream instance of cross device notification data.
   */
  getCrossDeviceDataStreamInstance(): CrossDeviceDataStream;

  /**
   * Retrieves a {@link CrossDeviceData} object obtained from notification.
   *
   * If user launched the application from notification, this method will return data
   * contained in that notification. Will return undefined if user launched the application
   * normally.
   */
  getCrossDeviceDataFromNotification(): Promise<CrossDeviceData | undefined>;

}
```

4. Create sensitive-data.tsx file:

```ts
/**
 * Sensitive data requires the user to grant certain permissions so they could be collected.
 * All sensitive data collection is disabled by default, which means you have to enable each of
 * them manually. Until their required permissions are granted, sensitive data won't
 * be collected even if they have been enabled. Required permissions for each sensitive data have been
 * listed in this member's documentation.
 */
export enum SensitiveData {
    /**
     * AVAILABILITY: ANDROID, IOS
     *
     * To enable location on android, make sure you ask user for these permissions:
     * - android.permission.ACCESS_COARSE_LOCATION or android.permission.ACCESS_FINE_LOCATION
     * - android.permission.FOREGROUND_SERVICE
     *
     * To enable location on ios, declare NSLocationWhenInUseUsageDescription in your Info.plist file
     */
    location = 'location',

    /**
     * AVAILABILITY: IOS
     *
     * To enable vpn on ios, add Network Extensions capability in your project.
     */
    vpn = 'vpn',

    /**
     * AVAILABILITY: ANDROID
     *
     * To enable sim numbers and operators on android, make sure you ask user for these permissions:
     * - android.permission.READ_PHONE_NUMBERS
     * - android.permission.READ_PHONE_STATE
     */
    simOperatorsAndNumbers = 'simOperatorsAndNumbers'
}
```

5. Create fazpass-settings.tsx file:

```ts
import { SensitiveData } from './sensitive-data';

/**
 * An object to be used as settings for {@link Fazpass.setSettings()} method.
 *
 * To construct this object, use it's builder class.
 *
 * @see {@link FazpassSettingsBuilder} for implementation details.
 */
export default class FazpassSettings {
    readonly sensitiveData: SensitiveData[];
    readonly isBiometricLevelHigh: boolean;

    private constructor(sensitiveData: SensitiveData[],  isBiometricLevelHigh: boolean) {
        this.sensitiveData = sensitiveData;
        this.isBiometricLevelHigh = isBiometricLevelHigh;
    }

    static fromBuilder(builder: FazpassSettingsBuilder): FazpassSettings {
        return new FazpassSettings(builder.sensitiveData, builder.isBiometricLevelHigh)
    }

    static fromString(settingsString: string): FazpassSettings {
        const splitter = settingsString.split(";");
        const sensitiveData = splitter[0]!.split(",")
            .filter((it) => it != "")
            .map<SensitiveData>((it) => SensitiveData[it as keyof typeof SensitiveData]);
        const isBiometricLevelHigh = splitter[1] === 'true';

        return new FazpassSettings(sensitiveData ?? [], isBiometricLevelHigh);
    }

    toString(): string {
        return this.sensitiveData.map<string>((it) => it).join(',') + ';' + (this.isBiometricLevelHigh === true ? 'true' : 'false');
    }
}

/**
 * A builder to create {@link FazpassSettings} object.
 *
 * To enable specific sensitive data collection, call `enableSelectedSensitiveData` method
 * and specify which data you want to collect.
 * Otherwise call `disableSelectedSensitiveData` method
 * and specify which data you don't want to collect.
 * To set biometric level to high, call `setBiometricLevelToHigh`. Otherwise call
 * `setBiometricLevelToLow`.
 * To create {@link FazpassSettings} object with this builder configuration, use {@link FazpassSettings.fromBuilder()} method.
 * ```typescript
 * // create builder
 * const builder: FazpassSettingsBuilder = FazpassSettingsBuilder()
 *   .enableSelectedSensitiveData([SensitiveData.location])
 *   .setBiometricLevelToHigh();
 *
 * // construct FazpassSettings with the builder
 * const settings: FazpassSettings = FazpassSettings.fromBuilder(builder);
 * ```
 *
 * You can also copy settings from {@link FazpassSettings} by using the secondary constructor.
 * ```typescript
 * const builder: FazpassSettingsBuilder =
 *   FazpassSettingsBuilder(settings);
 * ```
 */
export class FazpassSettingsBuilder {
   #sensitiveData: SensitiveData[];
   #isBiometricLevelHigh: boolean;

   get sensitiveData() {
       return this.#sensitiveData.map((v) => v);
   }
   get isBiometricLevelHigh() { 
       return this.#isBiometricLevelHigh;
   }

   constructor(settings?: FazpassSettings) {
       this.#sensitiveData = settings ? [...settings.sensitiveData] : [];
       this.#isBiometricLevelHigh = settings?.isBiometricLevelHigh ?? false;
   }

   enableSelectedSensitiveData(sensitiveData: SensitiveData[]): this  {
       for (const data in sensitiveData) {
           const key = data as keyof typeof SensitiveData;
           if (this.#sensitiveData.includes(SensitiveData[key])) {
               continue;
           } else {
               this.#sensitiveData.push(SensitiveData[key]);
           }
       }
       return this;
   }

   disableSelectedSensitiveData(sensitiveData: SensitiveData[]): this {
       for (const data in sensitiveData) {
           const key = data as keyof typeof SensitiveData;
           const willRemoveIndex = this.#sensitiveData.indexOf(SensitiveData[key], 0);
           if (willRemoveIndex > -1) {
               this.#sensitiveData.splice(willRemoveIndex, 1);
           } else {
               continue;
           }
       }
       return this;
   }

   setBiometricLevelToHigh(): this {
       this.#isBiometricLevelHigh = true;
       return this;
   }

   setBiometricLevelToLow(): this {
       this.#isBiometricLevelHigh = false;
       return this;
   }
}
```

6. Create cross-device-data.tsx file:

```ts
/**
 * An object containing data from cross device notification data.
 *
 * This object is only used as data retrieved from {@link Fazpass.getCrossDeviceDataStreamInstance()}
 * and {@link Fazpass.getCrossDeviceDataFromNotification()}.
 */
export default class CrossDeviceData {
    readonly merchantAppId : string;
    readonly deviceReceive : string;
    readonly deviceRequest : string;
    readonly deviceIdReceive : string;
    readonly deviceIdRequest : string;
    readonly expired : string;
    readonly status : string;
    readonly notificationId: string | null;
    readonly action: string | null;

    constructor(data: any) {
        this.merchantAppId = data.merchant_app_id as string;
        this.deviceReceive = data.device_receive as string;
        this.deviceRequest = data.device_request as string;
        this.deviceIdReceive = data.device_id_receive as string;
        this.deviceIdRequest = data.device_id_request as string;
        this.expired = data.expired as string;
        this.status = data.status as string;
        this.notificationId = data.notification_id as string | null;
        this.action = data.action as string | null;
    }
}
```

7. Create cross-device-data-stream.tsx file:

```ts
import { NativeEventEmitter, type EmitterSubscription } from 'react-native';
import CrossDeviceData from './cross-device-data';

/**
 * An instance acquired from {@link Fazpass.getCrossDeviceDataStreamInstance()} to start listening for
 * incoming cross device request notification.
 *
 * call `listen` method to start listening, and call `close` to stop.
 */
export default class CrossDeviceDataStream {
    private static eventType = 'com.fazpass.trusted-device-cd';

    #emitter: NativeEventEmitter;
    #listener: EmitterSubscription | undefined;

    constructor(module: any) {
        this.#emitter = new NativeEventEmitter(module);
    }

    listen(callback: (request: CrossDeviceData) => void) {
        if (this.#listener !== undefined) {
            this.close();
        }
        this.#listener = this.#emitter.addListener(CrossDeviceDataStream.eventType, (event) => {
            const data = new CrossDeviceData(event);
            callback(data);
        });
    }

    close() {
        this.#listener?.remove();
        this.#listener = undefined;
    }
}
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
