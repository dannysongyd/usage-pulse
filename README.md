# UsagePulse

UsagePulse is a native macOS `SwiftUI + WidgetKit` app for tracking Claude and Codex usage in one place.

## Scope

This repository implements the app shell, shared widget cache, provider abstractions, demo data, and unsupported-state messaging for personal accounts.

Official personal-account usage bars are not currently available for both providers through stable public APIs, so v1 ships with:

- a polished dashboard and desktop widget
- a shared App Group cache between app and widget
- demo/sample data for validating layout and behavior
- provider stubs for future official integrations

## Project Structure

- `UsagePulseApp`: main macOS app target
- `UsagePulseWidgetExtension`: WidgetKit extension
- `UsagePulseShared`: shared framework for models, storage, formatting, and providers
- `UsagePulseTests`: unit tests for shared logic
- `scripts/generate_xcodeproj.rb`: generates the Xcode project

## Getting Started

1. Regenerate the Xcode project if needed:

   ```bash
   ruby scripts/generate_xcodeproj.rb
   ```

2. Open `UsagePulse.xcodeproj` in Xcode.
3. Build the `UsagePulse` scheme.

For command-line verification:

```bash
xcodebuild -project UsagePulse.xcodeproj -scheme UsagePulse -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

