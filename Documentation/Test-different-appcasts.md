## Test 2 different appcasts

In this repository, there are two appcast files:

`appcast-old.xml`:

- Feed where `sparkle:minimumSystemVersion` is 11.5
- Manages updates for applications 2.9.0 and 3.0.0 (minimum target macOS 11.5)

`appcast.xml`

- Feed where `sparkle:minimumSystemVersion` is 13.5
- Manages updates for applications 3.0.1, 3.2.0 and 3.2.2 (minimum target macOS 13.5)

It's a way to test a repository that has 2 appcasts to notify releases based on the minimum macOS version the app runs on.
