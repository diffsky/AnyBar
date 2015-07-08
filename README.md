# AnyBar + custom colors + text: OS X menubar status indicator

This is a fork of [Nikita Prokopov's](https://github.com/tonsky) excellent [AnyBar](https://github.com/tonsky/AnyBar). 

> AnyBar is a small indicator for your menubar that does one simple thing: it displays color dot. What color means is up to you. When to change color is also up to you.

<img src="AnyBar/Resources/screenshot2.png?raw=true" />

This fork adds:

- the ability to use custom colors
- the ability to add an optional text message
- automatic support for Yosemite's Dark mode for custom images
- connection error messages reported in the AnyBar menu

AnyBar's AppleScript property is changed from `image name` to `message` to better reflect the ability to set both an image and text message.

This fork is compatible with OS X 10.10+ (the original AnyBar runs on 10.9).

## Download

Version 0.1.3 + custom colors + text:

<a href="https://s3.amazonaws.com/mowglii/AnyBar-0.1.3-colors-and-text.zip"><img src="AnyBar/Images.xcassets/AppIcon.appiconset/icon_128x128@2x.png?raw=true" style="width: 128px;" width=128/></a>

## Usage

AnyBar is controlled via UDP port (1738 by default). Before commands can be sent, AnyBar.app must be launched:

```sh
open /Users/yourusername/Applications/AnyBar.app
```

Once launched, send it a message and it will change a color:

```sh
echo -n "black" | nc -4u -w0 localhost 1738
```

You can set a custom color:

```sh
echo -n "#ffcc33" | nc -4u -w0 localhost 1738
```

And an optional text message too:

```sh
echo -n "#ffcc33 A nice shade of orange" | nc -4u -w0 localhost 1738
```

The following built-in commands change color:


<img src="AnyBar/Resources/white@2x.png?raw=true" width=19 /> `white`  
<img src="AnyBar/Resources/red@2x.png?raw=true" width=19 /> `red`  
<img src="AnyBar/Resources/orange@2x.png?raw=true" width=19 /> `orange`  
<img src="AnyBar/Resources/yellow@2x.png?raw=true" width=19 /> `yellow`  
<img src="AnyBar/Resources/green@2x.png?raw=true" width=19 /> `green`  
<img src="AnyBar/Resources/cyan@2x.png?raw=true" width=19 /> `cyan`  
<img src="AnyBar/Resources/blue@2x.png?raw=true" width=19 /> `blue`  
<img src="AnyBar/Resources/purple@2x.png?raw=true" width=19 /> `purple`  
<img src="AnyBar/Resources/black@2x.png?raw=true" width=19 /> `black`  
<img src="AnyBar/Resources/question@2x.png?raw=true" width=19 /> `question`  
<img src="AnyBar/Resources/exclamation@2x.png?raw=true" width=19 /> `exclamation`  

And one special command forces AnyBar to quit: `quit`


## Alternative clients

Bash alias:

```sh
$ function anybar { echo -n $1 | nc -4u -w0 localhost ${2:-1738}; }

$ anybar red
$ anybar green 1739
$ anybar "#ffcc33 A nice shade of orange" 1740
```

Go:

- [justincampbell/anybar](https://github.com/justincampbell/anybar)
- [johntdyer/anybar-go](https://github.com/johntdyer/anybar-go)

Node:

- [rumpl/nanybar](https://github.com/rumpl/nanybar)
- [sindresorhus/anybar](https://github.com/sindresorhus/anybar)
- [snippet by skibz](https://github.com/tonsky/AnyBar/issues/11)

PHP:

- [2bj/Phanybar](https://github.com/2bj/Phanybar)

Java:

- [cs475x/AnyBar4j](https://github.com/cs475x/AnyBar4j)

Python:

- [philipbl/pyanybar](https://github.com/philipbl/pyAnyBar)

Ruby:

- [davydovanton/AnyBar_rb](https://github.com/davydovanton/AnyBar_rb)

Rust:

- [urschrei/rust_anybar](https://github.com/urschrei/rust_anybar)

Nim:
- [rgv151/anybar.nim](https://github.com/rgv151/anybar.nim)

Erlang:
- [kureikain/ebar](https://github.com/kureikain/ebar)

AppleScript:

```
tell application "AnyBar" to set message to "green Success"

tell application "AnyBar" to set current to get message as Unicode text
display notification current
```

Alfred:

- [https://github.com/raguay/MyAlfred](https://github.com/raguay/MyAlfred/blob/master/AnyBarWorkflow.alfredworkflow)

## Integrations

- Webpack build status plugin [roman01la/anybar-webpack](https://github.com/roman01la/anybar-webpack)
- boot-clj task [tonsky/boot-anybar](https://github.com/tonsky/boot-anybar)
- Anybar-based CLI journal [Andrew565/anybar-icon-journal](https://github.com/Andrew565/anybar-icon-journal)

## Running multiple instances

You can run several instances of AnyBar as long as they listen on different ports. Use `ANYBAR_PORT` environment variable to change port and `open -n` to run several instances:

```sh
ANYBAR_PORT=1738 open -n ./AnyBar.app
ANYBAR_PORT=1739 open -n ./AnyBar.app
ANYBAR_PORT=1740 open -n ./AnyBar.app
```

## Custom images

AnyBar can use user-local images if you put them under `~/.AnyBar`. E.g. if you have `~/.AnyBar/square@2x.png` present, send `square` to 1738 and it will be displayed. Images should be 19×19px (or twice that for retina). 

If the image name ends in `Template`, it will automatically work in Yosemite's Light and Dark modes without the need for an `_alt` version.

## Ports

- Ubuntu Unity [limpbrains/somebar](https://github.com/limpbrains/somebar)

## Changelog

### 0.1.3

- AppleScript support (PR #8, thx [Oleg Kertanov](https://github.com/okertanov))

### 0.1.2

- Dark mode support. In dark mode AnyBar will first check for `<image>_alt@2x.png` or `<image>_alt.png` image first, then falls back to `<image>.png`
- Support for Mavericks actually works

### 0.1.1

- Support for Mavericks (PR #2, thx [Oleg Kertanov](https://github.com/okertanov))
- Support for custom images via ~/.AnyBar (PR #1, thx [Paul Boschmann](https://github.com/pboschmann))

## License

Copyright © 2015 Nikita Prokopov

Licensed under Eclipse Public License (see [LICENSE](LICENSE)).

