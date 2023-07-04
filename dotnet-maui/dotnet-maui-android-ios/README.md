# .NET MAUI Android and iOS app

This sample project illustrates all of the necessary steps to successfully build and publish a [.NET MAUI](https://github.com/dotnet/maui) apps for Android and iOS with Codemagic. The project is based on [Weather '21](https://github.com/davidortinau/WeatherTwentyOne) offical MAUI sample project and it covers the basic steps such as build versioning, code signing and publishing. 

You can find more detailed instructions as well numerous guides to advanced features in our [official documentation](https://docs.codemagic.io/yaml-quick-start/building-a-dotnet-maui-app/).

## Adding the app to Codemagic
The apps you have available on Codemagic are listed on the Applications page. Click **Add application** to add a new app.

1. If you have more than one team configured in Codemagic, select the team you wish to add the app to.
2. Connect the repository where the source code is hosted. Detailed instructions that cover some advanced options are available [here](https://docs.codemagic.io/getting-started/adding-apps/).
3. Select the repository from the list of available repositories. Select the appropriate project type.
4. Click **Finish: Add application**

## Creating codemagic.yaml
Codemagic uses a YAML configuration file to configure the CI/CD workflow. The name of the file must be `codemagic.yaml` and it must be located in the root directory of the repository. This sample project includes a `codemagic.yaml` file covering all of the steps outlined below. You can update the file with your own information and reuse it to build your own projects.

## Install .NET SDK
In order to build .NET apps in Codemagic, you first need to install the .NET SDK. The easiest way to do it is by downloading and running the official Install script.

``` yaml
  environment:
    vars:
      DOTNET_PATH: $CM_BUILD_DIR/dotnet
      DOTNET: $CM_BUILD_DIR/dotnet/dotnet
  scripts:
    - name: Install .NET SDK
      script: | 
        wget https://dot.net/v1/dotnet-install.sh
        chmod +x dotnet-install.sh
        ./dotnet-install.sh --install-dir $DOTNET_PATH
```

## Install MAUI
Once you have the .NET SDK installed, you can proceed to install the required .NET workloads.

### Android
``` yaml
  scripts:
    - name: Install MAUI
      script: | 
        $DOTNET nuget locals all --clear 
        $DOTNET workload install android maui \
          --source https://aka.ms/dotnet6/nuget/index.json \
          --source https://api.nuget.org/v3/index.json
```

### iOS
``` yaml
  scripts:
    - name: Install MAUI
      script: | 
        $DOTNET nuget locals all --clear 
        $DOTNET workload install ios maui \
          --source https://aka.ms/dotnet6/nuget/index.json \
          --source https://api.nuget.org/v3/index.json
```

## Code signing - Android
All applications have to be digitally signed before they are made available to the public to confirm their author and guarantee that the code has not been altered or corrupted since it was signed.

### Generating a keystore
If you don't have one yet, you can create a keystore for signing your release builds with the Java Keytool utility by running the following command:

```bash
keytool -genkey -v -keystore codemagic.keystore -storetype JKS \
        -keyalg RSA -keysize 2048 -validity 10000 -alias codemagic
```

Keytool then prompts you to enter your personal details for creating the certificate, as well as provide passwords for the keystore and the key. It then generates the keystore as a file called **codemagic.keystore** in the directory you're in. The key is valid for 10,000 days.

### Uploading a keystore

1. Open your Codemagic Team settings, and go to  **codemagic.yaml settings** > **Code signing identities**.
2. Open **Android keystores** tab.
3. Upload the keystore file by clicking on **Choose a file** or by dragging it into the indicated frame.
4. Enter the **Keystore password**, **Key alias** and **Key password** values as indicated.
5. Enter the keystore **Reference name**. This is a unique name used to reference the file in `codemagic.yaml`
6. Click the **Add keystore** button to add the keystore.

For each of the added keystore, its common name, issuer, and expiration date are displayed.

> **Note**: The uploaded keystore cannot be downloaded from Codemagic. It   is crucial that you independently store a copy of the keystore file as all subsequent builds released to Google Play should be signed with the same keystore.
However, keep the keystore file private and do not check it into a public repository.

### Referencing keystores in codemagic.yaml

To tell Codemagic to fetch the uploaded keystores from the **Code signing identities** section during the build, list the reference of the uploaded keystore under the `android_signing` field.

Add the following code to the `environment` section of your `codemagic.yaml` file:

```yaml
workflows:
  android-workflow:
    name: Android Workflow
    # ....
    environment:
      android_signing:
        - keystore_reference
```

Default environment variables are assigned by Codemagic for the values on the build machine:

- Keystore path: `CM_KEYSTORE_PATH`
- Keystore password: `CM_KEYSTORE_PASSWORD`
- Key alias: `CM_KEY_ALIAS`
- Key alias password: `CM_KEY_PASSWORD`

## Code signing - iOS
### Creating the App Store Connect API key
Signing iOS applications requires [Apple Developer Program](https://developer.apple.com/programs/enroll/) membership.

It is recommended to create a dedicated App Store Connect API key for Codemagic in [App Store Connect](https://appstoreconnect.apple.com/access/api). To do so:

1. Log in to App Store Connect and navigate to **Users and Access > Keys**.
2. Click on the + sign to generate a new API key.
3. Enter the name for the key and select an access level. We recommend choosing `App Manager` access rights, read more about Apple Developer Program role permissions [here](https://help.apple.com/app-store-connect/#/deve5f9a89d7).
4. Click **Generate**.
5. As soon as the key is generated, you can see it added to the list of active keys. Click **Download API Key** to save the private key for later. Note that the key can only be downloaded once.

### Adding the App Store Connect API key to Codemagic

1. Open your Codemagic Team settings, and go to **Team integrations** > **Developer Portal** > **Manage keys**.
2. Click the **Add key** button.
3. Enter the `App Store Connect API key name`. This is a human readable name for the key that will be used to refer to the key later in application settings.
4. Enter the `Issuer ID` and `Key ID` values.
5. Click on **Choose a .p8 file** or drag the file to upload the App Store Connect API key downloaded earlier.
6. Click **Save**.

### Adding the code signing certificate

Codemagic lets you upload code signing certificates as PKCS#12 archives containing both the certificate and the private key which is needed to use it. When uploading, Codemagic will ask you to provide the certificate password (if the certificate is password-protected) along with a unique **Reference name**, which can then be used in the `codemagic.yaml` configuration to fetch the specific file.

1. Open your Codemagic Team settings, and go to  **codemagic.yaml settings** > **Code signing identities**.
2. Open **iOS certificates** tab.
3. Upload the certificate file by clicking on **Choose a .p12 or .pem file** or by dragging it into the indicated frame.
4. Enter the **Certificate password** and choose a **Reference name**.
5. Click **Add certificate**


> **Note:** If you do not yet have a Signing certificate, you can have Codemagic create a new certificate automatically or fetch a previously created one. Please check the [iOS code signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/#adding-the-code-signing-certificate) documentation for details.


### Adding the provisioning profile

Codemagic allows you to upload a provisioning profile to be used for the application or to fetch a profile from the Apple Developer Portal.

The profile's type, team, bundle id, and expiration date are displayed for each profile added to Code signing identities. Furthermore, Codemagic will let you know whether a matching code signing certificate is available in Code signing identities (a green checkmark in the **Certificate** field) or not.

You can upload provisioning profiles with the `.mobileprovision` extension, providing a unique **Reference name** is required for each uploaded profile.

1. Open your Codemagic Team settings, and go to  **codemagic.yaml settings** > **Code signing identities**.
2. Open **iOS provisioning profiles** tab.
3. Upload the provisioning profile file by clicking on **Choose a .mobileprovision file** or by dragging it into the indicated frame.
4. Enter the **Reference name** for the profile.
5. Click **Add profile**.


### Referencing certificates and profiles in codemagic.yaml
To fetch all uploaded signing files matching a specific distribution type and bundle identifier during the build, define the `distribution_type` and `bundle_identifier` fields in your `codemagic.yaml` configuration. Note that it is necessary to configure **both** of the fields.

``` yaml
workflows:
  ios-workflow:
    name: iOS Workflow 
    # ....
    environment:
      ios_signing:
        distribution_type: app_store # or: ad_hoc | development | enterprise
        bundle_identifier: com.example.id
```

> **Note:** If you are publishing to the **App Store** or you are using **TestFlight**  to distribute your app to test users, set the `distribution_type` to `app_store`. 
When using a **third party app distribution service** such as Firebase App Distribution, set the `distribution_type` to `ad_hoc`

## Configure scripts to build the app
Add the following scripts to your `codemagic.yaml` file in order to prepare the build environment and start the actual build process.
In this step, you can also define the build artifacts you are interested in. These files will be available for download when the build finishes. For more information about artifacts, see [here](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/).

### Build versioning

If you are going to publish your app to App Store Connect or Google Play, each uploaded artifact must have a new version satisfying each app store’s requirements. Codemagic allows you to easily automate this process and increment the version numbers for each build. For more information and details, see [here](../configuration/build-versioning).

In .NET MAUI, app version and build number are determined by `ApplicationDisplayVersion` and `ApplicationVersion` properties set either in the `.csproject` file or passed via command line. Using Codemagic CLI, you can easily fetch the latest published build version from the respective store and automatically increment it for each new build.

### Code signing
In order to code sign the app, the appropriate properties must be configured either in the `csproject` file or passed via command line.

#### Android
When using the default Codemagic code signing method (codesigning identities), the required environment variables will already be available for use in command line arguments.

#### iOS
When using the default Codemagic code signing method (codesigning identities), the correct certificate and provisioning profile will be automatically prepared. However, since the dotnet build command requires referencing the signing certificate and the provisioning profile by name, two additional script commands are necessary to get those values. Alternatively, you can enter the correct values as strings manually.

### Build script example
This is an example of the final script, including build versioning, code signing and the app building steps.


### Android
``` yaml
  scripts:
    - name: Build the app
      script: | 
        LATEST_BUILD_NUMBER=$(google-play get-latest-build-number --package-name "$PACKAGE_NAME")
        if [ -z $LATEST_BUILD_NUMBER ]; then
          UPDATED_BUILD_NUMBER=$BUILD_NUMBER
        else
          UPDATED_BUILD_NUMBER=$(($LATEST_BUILD_NUMBER + 1))
        fi
        
        cd src
        $DOTNET publish -f net6.0-android \
          -c Release \
          -p:AndroidKeyStore=True \
          -p:AndroidSigningKeyStore=$CM_KEYSTORE_PATH \
          -p:AndroidSigningKeyAlias=$CM_KEY_ALIAS \
          -p:AndroidSigningKeyPass=$CM_KEY_PASSWORD \
          -p:AndroidSigningStorePass=$CM_KEYSTORE_PASSWORD \
          -p:ApplicationVersion=$UPDATED_BUILD_NUMBER \
          -p:ApplicationDisplayVersion="1.0.0" \
          -o ../artifacts
  artifacts:
    - /Users/builder/clone/artifacts/*Signed.aab
```

### iOS
``` yaml
  scripts: 
    - name: Build the app
      script: | 
        LATEST_BUILD_NUMBER=$(app-store-connect get-latest-testflight-build-number "$APP_ID")
        if [ -z $LATEST_BUILD_NUMBER ]; then
          UPDATED_BUILD_NUMBER=$BUILD_NUMBER
        else
          UPDATED_BUILD_NUMBER=$(($LATEST_BUILD_NUMBER + 1))
        fi
          
        CERT_NAME=$(keychain list-certificates | jq -r '.[] | .common_name')
        PROFILE_NAME=$(find ~/Library/MobileDevice/Provisioning\ Profiles -name "*.mobileprovision" -execdir sh -c '/usr/libexec/PlistBuddy -c "print :Name" /dev/stdin <<< $(security cms -D -i {})' \;)
          
        cd src
        $DOTNET publish -f net6.0-ios \
          -c Release \
          -p:BuildIpa=True \
          -p:ApplicationDisplayVersion="1.0.0" \
          -p:ApplicationVersion=$UPDATED_BUILD_NUMBER \
          -p:RuntimeIdentifier=ios-arm64 \
          -p:CodesignKey="$CERT_NAME" \
          -p:CodesignProvision="$PROFILE_NAME" \
          -o ../artifacts
  artifacts:
    - ./artifacts/*.ipa
```

## Publishing
Codemagic offers a wide array of options for app publishing and the list of partners and integrations is continuously growing. For the most up-to-date information, check the guides in the **Configuration > Publishing** section of these docs.
To get more details on the publishing options presented in this guide, please check the [Email publishing](https://docs.codemagic.io/yaml-notification/email/), [App Store Connect](https://docs.codemagic.io/yaml-publishing/app-store-connect/) and the [Google Play Store](https://docs.codemagic.io/yaml-publishing/google-play/) publishing docs.

### Email publishing
If the build finishes successfully, release notes (if passed), and the generated artifacts will be published to the provided email address(es). If the build fails, an email with a link to build logs will be sent.

If you don’t want to receive an email notification on build success or failure, you can set `success` to `false` or `failure` to `false` accordingly.
``` yaml
workflows:
  sample-workflow-id:
    environment: 
      # ...
    scripts: 
      # ...
    publishing: 
      email:
        recipients:
          - user_1@example.com
          - user_2@example.com
        notify:
          success: true
          failure: false
```
### Publishing to Google Play

Configuring Google Play publishing is simple as you only need to provide credentials and choose the desired track. If the app is in `draft` status, please also include the `submit_as_draft: true` or promote the app status in Google Play.
``` yaml
react-native-android:
  # ... 
  publishing:
    # ...
    google_play:
      credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
      track: internal
      submit_as_draft: true
```

### Publishing to App Store
Codemagic enables you to automatically publish your iOS or macOS app to [App Store Connect](https://appstoreconnect.apple.com/) for beta testing with [TestFlight](https://developer.apple.com/testflight/) or distributing the app to users via App Store. Codemagic uses the **App Store Connect API key** for authenticating communication with Apple's services. You can read more about generating an API key from Apple's [documentation page](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api).

Please note that:

1. for App Store Connect publishing, the provided key needs to have [App Manager permission](https://help.apple.com/app-store-connect/#/deve5f9a89d7),
2. and in order to submit your iOS application to App Store Connect, it must be code signed with a distribution [certificate](https://developer.apple.com/support/certificates/).

The following snippet demonstrates how to authenticate with and upload the IPA to App Store Connect, submit the build to beta tester groups in TestFlight and configure releasing the app to App Store. See additional configuration options for App Store Connect publishing [here](https://github.com/codemagic-ci-cd/cli-tools/blob/master/docs/app-store-connect/publish.md).

> **Note:** Please note that you will need to create an **app record** in App Store Connect before you can automate publishing with Codemagic. It is recommended to upload the very first version of the app manually. Suppose you have set up an **app record** but have not manually uploaded the app's first version. In that case, manual configuration of the settings must be done on App Store Connect after the build is complete, such as uploading the required screenshots and providing the values for the privacy policy URL and application category.

``` yaml
# Integration section is required to make use of the keys stored in 
# Codemagic UI under Apple Developer Portal integration.
integrations:
  app_store_connect: <App Store Connect API key name>

publishing:
  app_store_connect:
    # Use referenced App Store Connect API key to authenticate binary upload
    auth: integration 

    # Configuration related to TestFlight (optional)

    # Optional boolean, defaults to false. Whether or not to submit the uploaded
    # build to TestFlight beta review. Required for distributing to beta groups.
    # Note: This action is performed during post-processing.
    submit_to_testflight: true 

    # Specify the names of beta tester groups that will get access to the build 
    # once it has passed beta review.
    beta_groups: 
      - group name 1
      - group name 2
    
    # Configuration related to App Store (optional)

    # Optional boolean, defaults to false. Whether or not to submit the uploaded
    # build to App Store review. Note: This action is performed during post-processing.
    submit_to_app_store: true
    
    # Optional, defaults to MANUAL. Supported values: MANUAL, AFTER_APPROVAL or SCHEDULED
    release_type: SCHEDULED

    # Optional. Timezone-aware ISO8601 timestamp with hour precision when scheduling
    # the release. This can be only used when release type is set to SCHEDULED.
    # It cannot be set to a date in the past.
    earliest_release_date: 2021-12-01T14:00:00+00:00 
    
    # Optional. The name of the person or entity that owns the exclusive rights
    # to your app, preceded by the year the rights were obtained.
    copyright: 2021 Nevercode Ltd
```

## Conclusion
Having followed all of the above steps, you now have a working `codemagic.yaml` file that allows you to build, code sign, automatically version, and publish your project using Codemagic CI/CD.
Save your work, commit the changes to the repository, open the app in the Codemagic UI and start the build to see it in action.

## Next steps
While this basic workflow configuration is incredibly useful, it is certainly not the end of the road and there are numerous advanced actions that Codemagic can help you with.

We encourage you to investigate [Running tests with Codemagic](https://docs.codemagic.io/yaml-testing/testing/) to get you started with testing, as well as additional guides such as the one on running tests on [Firebase Test Lab](https://docs.codemagic.io/yaml-testing/firebase-test-lab/) or [Registering iOS test devices](https://docs.codemagic.io/testing/ios-provisioning/).

Documentation on [using codemagic.yaml](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/) teaches you to configure additional options such as [changing the instance type](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/#instance-type) on which to build, speeding up builds by configuring [Caching options](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/#cache), or configuring builds to be [automatically triggered](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/#triggering) on repository events.