DMD Analyzer
============

Analyze PIN2DMD dump files (such as can be generated from
https://playfield.dev) and extract game information from them.

Currently just an assorted selection of tools that don't do much, but it can
extract single player scores from Demolition Man which is pretty neat.

Motivation for the project is to one day analyze a live stream from a game to
automatically capture statistics, in the spirit of
https://github.com/ferocia/kartalytics.

A test dump file from Demolition Man is provided in `data` to experiment with.

Usage
-----

### Inspect PIN2DMD Dump

These can be created at https://playfield.dev by clicking the `DMD DUMP` button
in the top right of the UI.

    > bin/inspect-dump data/test-dump-1.raw.gz | head -n 20
    I, [2022-07-31T13:20:08.073870 #29891]  INFO -- : Loading data/test-dump-1.raw.gz
    I, [2022-07-31T13:20:08.578854 #29891]  INFO -- : Loaded data/test-dump-1.raw.gz
    I, [2022-07-31T13:20:08.578941 #29891]  INFO -- : Frames: 437
    I, [2022-07-31T13:20:08.613364 #29891]  INFO -- : Frame 0, timestamp 2294275:
              ▄▄
           ▗▟████▙     ▟          ▗▄   ▄▖
          ▗█▛▀  ▜█▌   ▟▛         ▗█▛  ▟█▘
         ▗█▛ ▐▖ ▐█▙  ▟█▌  ▄ ▄    ██▘ ▐█▛  ▄
         █▛  ▟▌ ▟██ ▗██  ▟▛▐█▌  ▐█▛  ██▘ ▐█▌
        ▐█   █▌ ██▌▗██▌ ▟▛ ▝█▘ ▗██▘ ▟█▛  ▝█▘
     ▗  █▌  ▐█▘▐██▚███▘▟▛      ▟█▛ ▗██▘
    ▗█▘ █  ▗██ ███████▟█▘     ▐██  ██▌
    █▌  █▖▗██▘▐████████▘▗▟█▌ ▗██▌ ▟██  ▄██  ▗▟██▄██ ▗▟█▖ ▟█▖ ▄█▙   ▟
    █▌  ▝██▛▘ ███▛▐███▛▗███▘ ▟██ ▗██▌ ▟██▛ ▗██▘▐██▌▗███▙████▟███▌ ▟█
    ▐█       ▟██▛ ████ ▟██▛ ▟██▌▗██▛ ▐███ ▗██▛ ▐██ █▛▟██▛▐███▚██▘▟█▘
    ▟█▖     ▗██▛  ███▌▐███ ▟███▗███▘▗███▌▗███  ██▌▟█▐███ ███▘██▛▗█▘
    ███▌   ▗██▛   ███  ██▌▟███▙███▛▗████▗███▌ ▟██▗█▘███▘▐██▘▐██▘▟█▙▗
    ██▛   ▗██▘    ██▌  ████▘███▛▝███▛▐███▘██ ▟██▙█▘▐██▘ ██▛ ▐██▟▛▜▛▟
    █▛   ▗█▀      ▝█   ▝█▛▘ ▝█▛  ▜█▛  ▜▛▘ ▝██▘▝█▛▘ ██▛ ▐█▛   ▜█▀ ▝██


### Create Mask

A mask can be created to identify frames of a particular type, for further
analysis later.

    > bin/create-mask \
      -i data/test-dump-1.raw.gz \
      -o masks/dm/ball.json \
      --frame 399 \
      --mask 28,27,18,5 \
      -v
    I, [2022-07-31T13:21:11.747669 #29954]  INFO -- : Loading data/test-dump-1.raw.gz
    I, [2022-07-31T13:21:12.247765 #29954]  INFO -- : Loaded data/test-dump-1.raw.gz
    I, [2022-07-31T13:21:12.276365 #29954]  INFO -- : Extracted frame 399:


                      ▗████  ▄██  ▟████▖ ▟████▖ ▄██  ▟████▖
                      █████  ███  █████▌ █████▌ ███  █████▌
                      ██▘     ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      ██▄▄▖   ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      █████▖  ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      ██▀▜█▌  ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      ██ ▐█▌  ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      ██▄▟█▌▗▄██▄▖██▄▟█▌ ██▄▟█▌▗▄██▄▖██▄▟█▌
                      ▜████▘▐████▌█████▌▖█████▌▐████▌█████▌
                       ▀▀▀▘ ▝▀▀▀▀▘▝▀▀▀▀▗▘▝▀▀▀▀ ▝▀▀▀▀▘▝▀▀▀▀

                  ▄▖ ▄ ▖ ▖   ▗          ▄▄▗▄ ▄▄▗▄▖ ▗▄ ▖ ▗▖▗ ▗
                  ▙▞▐▄▌▌ ▌   ▜          ▙▖▐▄▘▙▖▐▄  ▐▄▘▌ ▙▟ ▚▘
                  ▙▞▐ ▌▙▖▙▖  ▟▖         ▌ ▐ ▌▙▄▐▄▖ ▐  ▙▖▌▐ ▐ ▗
    I, [2022-07-31T13:21:12.307175 #29954]  INFO -- : Mask [28, 27, 18, 5]:













                  ▄▄▄▄▄▄▄▄▄
                  █████████
                  █████████
    I, [2022-07-31T13:21:12.337726 #29954]  INFO -- : Masked image:













                  ▄▖ ▄ ▖ ▖
                  ▙▞▐▄▌▌ ▌
                  ▙▞▐ ▌▙▖▙▖


### Inspect mask

    > bin/inspect-mask masks/dm/ball.json
    I, [2022-07-31T15:48:17.456906 #40472]  INFO -- : Mask:
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                  ▄▄▄▄▄▄▄▄▄                                         
                  █████████                                         
                  █████████                                         
    I, [2022-07-31T15:48:17.484671 #40472]  INFO -- : Image:
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                  ▄▖ ▄ ▖ ▖                                          
                  ▙▞▐▄▌▌ ▌                                          
                  ▙▞▐ ▌▙▖▙▖                                         

### Generate digit templates

Need to repeat this for all digits, finding appropriate frames.

    > bin/extract-dm-digit-templates \
        -i data/dm-all-digits.raw.gz \
        -o masks/dm \
        --frame 70 \
        --score 1,300,000 \
        -v

### Extract scores from a dump

    > bin/extract-dm-scores data/dm-all-digits.raw.gz
    I, [2022-07-31T17:50:30.332476 #47038]  INFO -- : Loading data/dm-all-digits.raw.gz
    I, [2022-07-31T17:50:30.562553 #47038]  INFO -- : Loaded data/dm-all-digits.raw.gz
    I, [2022-07-31T17:50:30.562596 #47038]  INFO -- : Frames: 195
    I, [2022-07-31T17:50:30.568385 #47038]  INFO -- : Extracted new score 0/5.418243: 1000000
    I, [2022-07-31T17:50:30.659546 #47038]  INFO -- : Extracted new score 18/5.64864: 1100000
    I, [2022-07-31T17:50:30.771761 #47038]  INFO -- : Extracted new score 40/5.89952: 1200000
    I, [2022-07-31T17:50:30.864740 #47038]  INFO -- : Extracted new score 59/6.1248: 1300000
    I, [2022-07-31T17:50:30.945535 #47038]  INFO -- : Extracted new score 74/6.3296: 1400000
    I, [2022-07-31T17:50:31.031278 #47038]  INFO -- : Extracted new score 90/6.52928: 1500000
    I, [2022-07-31T17:50:31.121116 #47038]  INFO -- : Extracted new score 107/6.734336: 1600000
    I, [2022-07-31T17:50:31.218574 #47038]  INFO -- : Extracted new score 125/6.959616: 1700000
    I, [2022-07-31T17:50:31.307745 #47038]  INFO -- : Extracted new score 141/7.159296: 1800000
    I, [2022-07-31T17:50:31.400270 #47038]  INFO -- : Extracted new score 159/7.384576: 1900000
    I, [2022-07-31T17:50:31.588119 #47038]  INFO -- : Average frame processing time: 5ms

Development
-----------

We have the initial stirrings of a test suite.

    rspec

Emulation
---------

Assorted pro-tips for playing using the switches on https://playfield.dev

### Demolition Man

* `Ball Launch` doesn't appear to do anything, just start scoring points with
  playfield switches to "launch".
* `Top Popper` is the back sink that starts multiball.
* To drain, close `Trough 5 (left)`, toggle `Eject`, open `Trough 5 (left)`.
  (Optos --- such as the trough --- are "open" when they are blocked.)
