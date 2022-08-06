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
    INFO [2022-08-06 13:34:14.990]: Loading data/dm-1p-3ball.raw.gz
    INFO [2022-08-06 13:34:16.741]: Loaded data/dm-1p-3ball.raw.gz
    INFO [2022-08-06 13:34:16.741]: Frames: 1481
    INFO [2022-08-06 13:34:16.748] (9): {:type=>:game_start, :t=>4578304}
    INFO [2022-08-06 13:34:16.872] (49): {:type=>:update_score, :score=>3330, :t=>5182720}
    INFO [2022-08-06 13:34:17.133] (110): {:type=>:update_score, :score=>253330, :t=>5920000}
    INFO [2022-08-06 13:34:17.337] (162): {:type=>:ball_save, :t=>6503936}
    INFO [2022-08-06 13:34:17.471] (235): {:type=>:update_score, :score=>503330, :t=>7297536}
    INFO [2022-08-06 13:34:17.769] (347): {:type=>:drain, :t=>8629248}
    INFO [2022-08-06 13:34:17.775] (350): {:type=>:update_score, :score=>1503330, :t=>9166848}
    INFO [2022-08-06 13:34:18.029] (400): {:type=>:update_score, :score=>1506660, :t=>9894144}
    INFO [2022-08-06 13:34:18.232] (493): {:type=>:update_score, :score=>1756660, :t=>10728704}
    INFO [2022-08-06 13:34:18.304] (560): {:type=>:update_score, :score=>2006660, :t=>11261440}
    INFO [2022-08-06 13:34:18.467] (592): {:type=>:update_score, :score=>2256660, :t=>11712000}
    INFO [2022-08-06 13:34:18.667] (680): {:type=>:drain, :t=>12741376}
    INFO [2022-08-06 13:34:18.674] (737): {:type=>:update_score, :score=>3256660, :t=>13652992}
    INFO [2022-08-06 13:34:18.715] (747): {:type=>:update_score, :score=>4256660, :t=>13821952}
    INFO [2022-08-06 13:34:18.725] (795): {:type=>:update_score, :score=>6256660, :t=>14544128}
    INFO [2022-08-06 13:34:18.734] (797): {:type=>:update_score, :score=>6506660, :t=>14574848}
    INFO [2022-08-06 13:34:18.967] (850): {:type=>:ball_save, :t=>15148288}
    INFO [2022-08-06 13:34:19.110] (931): {:type=>:update_score, :score=>6756660, :t=>15942144}
    INFO [2022-08-06 13:34:19.449] (1042): {:type=>:drain, :t=>17242880}
    INFO [2022-08-06 13:34:19.456] (1056): {:type=>:update_score, :score=>7756660, :t=>17790720}
    INFO [2022-08-06 13:34:19.469] (1417): {:type=>:game_end, :t=>4575163540708794880}
    INFO [2022-08-06 13:34:19.471] (1480): Average frame processing time: 1ms

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
