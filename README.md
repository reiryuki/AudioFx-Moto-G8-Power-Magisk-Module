# AudioFx Moto G8 Power Magisk Module

## Descriptions
- An equalizer ported from Motorola Moto G8 Power (cebu)
- Global type soundfx

## Requirements
- Android 9, 10, or 11
- Magisk installed

## Installation Guide
- Install the module via Magisk app or recovery
- Reboot

## Optional
- You can enable post process stream mode so the FX can be used together with DTSX or Audio Wizard or any post process type soundfx (but the FX cannot be turned off) by run at Terminal Emulator:
  
  su

  `setprop stream.mode mravn`

  Reflash the module after. On older version, it's `setprop music.stream 1`.

- You can reset the data by run at Terminal Emulator:

  su

  `setprop audiofx.cleanup 1`

  Reflash the module after.

## Troubleshootings
- Install Audio Modification Library module or [ACDB module](https://t.me/viperatmos) ( Android 10 and bellow only for now) (choose one, don't use both!) if you using other audio mods

## Bug Report
- https://t.me/audioryukimods/2618

## Thanks for Donations
- https://t.me/audioryukimods/2619
- https://www.paypal.me/reiryuki

## Download
- Tap "Releases"
