# SumoLogHandler

A custom LogHandler for [apple/swift-log](https://github.com/apple/swift-log) that sends messages to [SumoLogic](https://www.sumologic.com). 
It does not print to the console so you can use whatever LogHandler you want for console logs. I recommend [EmojiLogHandler](https://github.com/SwiftMN/EmojiLogHandler) 🤓

## Getting Started

### Using a `package.swift` file

add this to your `dependencies` list
```swift
.package(url: "https://github.com/SwiftMN/SumoLogHandler.git", from: "1.0.0")
```

and of course add `"EmojiLogHandler"` to your list target dependencies
```swift
.target(name: "SweetProjectName", dependencies: ["SumoLogHandler"]),
```

### Using Xcode

File > Swift Packages > Add Package Dependency...

Paste the url for this project when prompted
```
https://github.com/SwiftMN/SumoLogHandler
```


## Setup

In your AppDelegate or SceneDelegate, bootstrap an instance of `SumoLogHandler`.

```swift
if
  let sumoUrl = URL(string: sumoUrlString),
  let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String,
  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
  let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
{
  LoggingSystem.bootstrap { label in
    MultiplexLogHandler([
      EmojiLogHandler(label),
      SumoLogHandler(
        label: label,
        sumoUrl: sumoUrl,
        sumoName: "\(appName)/\(appVersion)/\(buildNumber)"
      )
    ])
  }
}
```

Make sure you import the package, too
```swift
import SumoLogHandler
```

If you're using [EmojiLogHandler](https://github.com/SwiftMN/EmojiLogHandler), you're all done! 💯
If you're not into emojis as functions, then you'll need a globally accessible logger.

```swift
import SumoLogHandler
import Logger
public var logger: Logger = Logger(label: "com.SweetProjectName.loggerLabel")
```

## Usage

Because SumoLogHandler uses [apple/swift-log](https://github.com/apple/swift-log), all you have to do is call the globally accessible logger that you set up in the previous step. (or just use the emoji functions set up by EmojiLogger)

```swift
logger.trace("trace message")
logger.debug("debug message")
logger.info("info message")
logger.notice("notice message")
logger.warning("warning message")
logger.error("error message")
logger.critical("critical message")
```

You can then query SumoLogic with things like
```
_sourceCategory=prod/mobile
_sourceHost=ios
_sourceName=sweet-project-name/*
```


## SumoLogic Setup

You'll need to set up a new collector in sumo. Here's more information about that https://help.sumologic.com/Manage/Collection

I named mine `Mobile` and set the Source Category to `dev/mobile`. This is just the default that Sumo uses, but `SumoLogHandler` will overwrite it with whatever you set for `sumoCategory` which is defaulted to `prod/mobile`. This is customizable at any time so you can adjust to `dev/mobile`, `preprod/mobile`, or whatever you name your environments.
