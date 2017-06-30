Hasklock
========
Hasklock is a Haskell program that displays a binary clock in the terminal, with the HSCurses library.<br />
The Hasklock package comes with two binaries:
* hasklock: The basic binary clock, which allows customization of foreground and background colors, as well as clock size
* randhasklock: A convenience script allowing for the randomization of foreground and/or background colors.

Dependencies
------------
Hasklock depends on:
* ncurses
* ghc: the Glasgow Haskell Compiler, required if it is desired to build Hasklock
* HSCurses: an ncurses library for Haskell. Can be installed with `$ cabal install hscurses`. Required if it is desired to build Hasklock.

Installing Hasklock
-------------------
The git repository at https://github.com/DestructiveReasoning/hasklock provides both source and binary files.
The hasklock executable is provided to avoid having to install ghc and hscurses.
To install the Hasklock binary:
```
$ git clone https://github.com/DestructiveReasoning/hasklock
$ cd hasklock
# make install
```

Building Hasklock
-----------------
As mentioned previously, if it is desired to build Hasklock, you must have ncurses, ghc, and hscurses installed.<br />
Building Hasklock can be accomplished as follows:
```
$ git clone https://github.com/DestructiveReasoning/hasklock
$ make
# make install
```
Alternatively to `make install`, `make install clean` may be run to remove the object files that were generated.
