## Install SwiftLint

To install **SwiftLint** simply run the following line in your terminal:

```ruby
brew install swiftlint
```

**SwiftLint** will run every time you build the project and show you all warnings and errors for the possible violations in your Xcode IDE.

## Install SwiftLint Autocorrect

⚠ ️This plugin will not work with Xcode 8 or later without disabling SIP(System Integrity Protection). But disabling SIP is not recommended.

To enable **SwiftLint autocorrect** in your Xcode project you need to install the Xcode-plugin **SwiftLintXcode**. To load third-party plugins in Xcode 8 we have to re-codesign Xcode, because Xcode 8 won't load any unsigned plugins without resigning Xcode itself. 

#### Re-codesign Xcode

1. Close Xcode.
2. Open **Keychain Access** and select **login** in the left pane.
3. Go to **KeyChain Access** -> **Certificate Assistant** Select **Create a Certificate**.
4. Set `XcodeSigner` as the name and select **Code Signing** for **Certificate Type**.
5. Press **Create**.
6. Go to **Terminal** and write the following command to re-codesign Xcode with the new certificate:
```sudo codesign -f -s XcodeSigner /Applications/Xcode.app```
(this can take a few minutes)

**SwiftLintXcode** is available through [Alcatraz](https://github.com/alcatraz/Alcatraz).

#### Install Alcatraz

1. Download Alcatraz [here](https://github.com/alcatraz/Alcatraz/archive/master.zip).
2. Open and build the Xcode project. `Alcatraz.xcplugin` will be created and saved automatically to Xcode's Plug-ins folder.
2. Restart Xcode.
3. When a pop-up asks to load or skip bundle, choose **Load Bundle**.

#### Install SwiftLintXcode

1. In Xcode go to **Window** -> **Package Manager**, search for `SwiftLintXcode` and press **Install**.
2. Restart Xcode.
3. When a pop-up asks to load or skip bundle, choose **Load Bundle**.

That's it! Now everytime your swift file is (auto)saved, the autocorrect is executed.

#### Change the SwiftLint file

Run the command `open .swiftlint.yml` from your project to adjust the rules.
