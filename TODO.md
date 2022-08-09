* Try compiling the USB sample code.
  * Missing a heap of headers and maybe some other stuff. Seems pretty
    straightforward libusb though?
* Try porting USB sample code to ruby (need to find a libusb wrapper gem?)
  * Started in `misc/pin2dmd_usb_test.rb`
* [DONE] Figure out PIN2DMD purchasing options to get some real hardware
* [DONE] Replace the Marshal dump/load with something more robust
* [DONE] Record a game end to figure out best way to detect
* [DONE] Record a multiplayer game to figure out best way to detect
* Work through `bin/missing-digit-templates` for multiplayer
* Sketch out a UI in the rails app
* Extract and test the non-score screens out of script and into lib
* DRY `#identify_segments` with `#identify_digits`
* Fix `extract_digits` part of screen analysis
