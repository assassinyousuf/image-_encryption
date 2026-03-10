# image-_encryption

Secure Image-to-Audio Transmission System (Flutter).

This app implements a Sender/Receiver workflow that converts an image into an encrypted bitstream, modulates it into an FSK WAV audio file, and then performs the reverse operation to recover the image.

## Features

- Sender: pick image → device-derived key → XOR bitstream encryption → FSK encode → export WAV
- Receiver: import WAV → Goertzel-based FSK decode → decrypt → reconstruct PNG
- UI styled to match the HTML mockups under `ui folder/`

## Run

1. `flutter pub get`
2. `flutter run`

## Notes

- The app saves exported WAV and decoded PNG into the app documents directory (location varies by platform).
- On Android 13+ the app requests media read permissions for selecting images/audio.
