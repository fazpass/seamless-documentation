# web-trusted-device-v2

## Installation

Load the script in your html like this:

```html
<script src="http://seamless-web-notification.fazpass.com/bundle.js" defer onload="onloadFazpass()"></script>

<script>
    function onloadFazpass() {
        // get fazpass instance after script has been loaded
        let fazpass = window.Fazpass;
    }
</script>
```
## Getting Started

Before using this SDK, make sure to contact us first to get a public key.

This package main purpose is to generate meta which you can use to communicate with Fazpass rest API. But before calling generate meta method, you have to initialize it first by calling this method:

```js
fazpass.init(
    'YOUR_PUBLIC_KEY_FILE', 
    'YOUR_SERVICE_WORKER_FILE'
)
```

Then you have to ask user for notification permission. Note: you should spawn notifications in response to a user gesture.

```html
<!-- Copied examples from: https://developer.mozilla.org/en-US/docs/Web/API/Notification/requestPermission_static -->

<button onclick="askNotificationPermission()">Allow Notification</button>

<script>
    function askNotificationPermission() {
        if (!("Notification" in window)) {
            // Check if the browser supports notifications
            alert("This browser does not support desktop notification");
        } else if (Notification.permission === "granted") {
            // Check whether notification permissions have already been granted;
            // if so, create a notification
            const notification = new Notification("Hi there!");
            // …
        } else if (Notification.permission !== "denied") {
            // We need to ask the user for permission
            Notification.requestPermission().then((permission) => {
            // If the user accepts, let's create a notification
            if (permission === "granted") {
                const notification = new Notification("Hi there!");
                // …
            }
            });

            // At last, if the user has denied notifications, and you want to be respectful there is no need to bother them anymore.
        }
    }
</script>
```

### Serving required files in your website

To initialize this SDK correctly, you have to serve these required files:

1. Your public key
2. Fazpass service worker

You can get the public key file by downloading it from your fazpass dashboard, then change it's extension from *.pub* to *.txt*. For the Fazpass service worker file, you can download it here: [Fazpass Service Worker]("") `TODO: Put the download link here`

Once you have obtained these required files, the easiest way to serve them is to put them in your static folder. Then `init()` method will look like this:

```js
// public key is served at https://www.yourdomain.com/files/public-key.txt
// fazpass service worker is served at https://www.yourdomain.com/sw/my-service-worker.js
fazpass.init(
    '/files/public-key.txt',
    '/sw/fazpass-service-worker.js'
)
```

## Usage

Call `generateMeta()` method to generate meta.

```js
// synchronous example
fazpass.generateMeta()
    .then((meta) => {
        console.log(meta)
    })
    .catch((err) => {
        if (err instanceof fazpass.UninitializedError) {
          console.error("UninitializedError: "+err.message)
        }
        if (err instanceof fazpass.PublicKeyNotExistError) {
          console.error("PublicKeyNotExistError: "+err.message)
        }
        if (err instanceof fazpass.EncryptionError) {
          console.error("EncryptionError: "+err.message)
        }
    })

// asynchronous example
try {
    let meta = await fazpass.generateMeta()
    console.log(meta)
} catch (err) {
    // handle on error...
}
```

## Errors

### UninitializedError

Produced when fazpass init method hasn't been called once.

### PublicKeyNotExistError

Produced when public key with the name registered in init method doesn't exist in the path.

### EncryptionError

Produced when encryption went wrong because you used the wrong public key.

## Set preferences for data collection

This SDK supports application with multiple accounts, and each account can have different settings for generating meta.
To set preferences for data collection, call `setSettings()` method.

```js
// index of an account
let accountIndex = 0

// create preferences
let settings = {
    location: true
}

// save preferences
fazpass.setSettings(accountIndex, settings)

// apply saved preferences by using the same account index
fazpass.generateMeta(accountIndex)
    .then((meta) => {
        console.log(meta)
    })

// get saved preferences
let savedSettings = fazpass.getSettings(accountIndex)

// delete saved preferences
fazpass.setSettings(accountIndex)
```

`generateMeta()` accountIndex parameter has -1 as it's default value.

> We strongly advised against saving preferences into default account index. If your application
> only allows one active account, use 0 instead.

## Data Collection

Data collected and stored in generated meta. Based on how data is collected, data type is divided into two:
General data, Sensitive data.
General data is always collected while Sensitive data requires more complicated procedures before they can be collected.

To enable Sensitive data collection, you need to set preferences for them and specifies which sensitive data you want to collect.

```js
let settings = {
    location: true
}
```

Then, you have to follow the procedure on how to enable each of them as described in their own segment down below.

### General data collected

* Your device platform name (Value will always be "web").
* Your website domain name (If your website is *<https://www.yourdomain.com>*, then *www.yourdomain.com* will be collected).
* Your browser integrity score.
* Your browser user agent.
* Your network IP Address.

### Sensitive data collected

#### Your device location

After you enabled location data collection, `generateMeta()` will automatically ask user for location permission.

## Handle incoming Cross Device Request notification

When website tab is not active, incoming cross device request will enter your system notification tray and shows them as a notification. Pressing said notification will change your active tab into your website tab and send the data into the stream. When website tab is active, incoming cross device request will be sent into the stream without showing any notification.

To retrieve cross device request, you have to setup fazpass service worker as mentioned earlier in [Serving required files in your website](#serving-required-files-in-your-website). Then, you have to get the stream instance by calling `getCrossDeviceRequestStreamInstance()` and start listening to the stream.

```js
// get the stream instance and start listening to the stream
let requestStream = fazpass.getCrossDeviceRequestStreamInstance(
    (request) => {
      console.log(request)
    }
)

// stop listening to the stream
requestStream()
```
