* Try compiling the USB sample code.
  * Missing a heap of headers and maybe some other stuff. Seems pretty
    straightforward libusb though?
* Try porting USB sample code to ruby (need to find a libusb wrapper gem?)
  * Started in `misc/pin2dmd_usb_test.rb`
* Figure out PIN2DMD purchasing options to get some real hardware
  * Done, on the way.
* Replace the Marshal dump/load with something more robust
  * DONE with JSON
* Record a game end to figure out best way to detect
* Record a multiplayer game to figure out best way to detect

## Scoring notes

1P
  Score is big numbers in the middle

2P
  1P score is small top aligned, 2P score tiny bottom right frame 102
  2P score is small in middle, 1P score tiny top left frame 345

3P
  1P score is small top left aligned, 2p score tiny top right, 3p score tiny bottom mid left frame 88
  2P score is small top right, 1p score tiny top left, 3p score tiny bottom mid left frame 379
  3P score is small bottom left, 1p score tiny top left, 2p score tiny top right frame 685

4P
  1P score small top left frame 280
  2P score frame 536
  3P score frame 805
  4P score frame 969
