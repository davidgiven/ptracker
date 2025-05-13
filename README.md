p-tracker
=========


## What?

p-tracker is a polyphonic chiptune tracker for the Commodore PET.

The PET barely has any sound hardware; there's a single GPIO connected to a
piezoelectric speaker, which can be set to two states: on and off. It normally
generates crude square-wave tones by oscillating the GPIO at different
frequencies.

p-tracker horribly abuses this by using 1-bit music techniques to make it play
three channels of music and one channel of drum sounds, simultaneously. Yes, you
can do chords. No, you don't need any extra hardware, but an external speaker
will probably help.

It features:

- 85 32-step patterns
- 128 patterns per sequence
- three tone channels plus noise channel
- ⅓-semitone pitch resolution
- approximately three octaves of approximately notes
- customisable envelopes
  - 16 envelopes
  - 64 individually controllable volume and pitch steps each
  - 100Hz resolution
  - 'graphic' user interface
- will run on any PET with BASIC 2 or 4 ROMs and 32kB (i.e. a 3032 or later,
  i.e. not a 2001) although a disk system is required
  - although if you're on an 80-column PET, the screen will be corrupted (but
    it'll all still work)
  - the only thing stopping it running on a 2001 is that all the zero page
    kernal variables for doing file handling have moved and I haven't bothered
    fixing it. The 2001 doesn't have sound anyway

Unlike traditional trackers, which were designed for machines with more memory
(_cough_ Amiga _cough_), p-tracker has 32 steps per pattern, and each note can
be either a note _or_ a command (because that uses half as much space).


## Warning

This is not my first tracker. That would be
[b-tracker](https://cowlark.com/btracker/), which is a chiptune tracker for the
BBC Micro.

p-tracker is very nearly the same program; it copies huge chunks of code from
b-tracker (both machines have a 40x25 screen, so a lot of code is trivially
reusable). It even uses the same file format, mostly: but while you can copy
files from b-tracker to p-tracker and vice versa, bits are implemented
differently so they won't work quite right and will need touching up before
they'll play properly.


## How?

To build, you need a Unix and a pile of dependencies. The whole program is
written in hand-tooled machine code, but I'm using the llvm-mos assembler
(because I know it). There's some support tooling which also needs libraries
installed.

You'll need:

  - `python3`
  - `make`
  - `llvm-mos`
  - `cc1541`
  - `libfreeimage` and `libfreeimageplus`

Then, you should just be able to do `make` and it'll build. Look at
`.github/workflows/ccpp.yml` for the autobuilder script. You'll get a `.prg`
file, which is the program itself, and a `.d64` which is a disk image containing
both the program and a sample file (a cover of Proton's cover of Jugi's _Onward
Ride_).

Following are brief instructions 

There are four screens, which you can cycle through with the `CLR/HOME` button
(or `TAB` if you're lucky enough to have a PET which has got one).

### File

This allows you to load and save files, as well as clear the workspace for a
new file.

When saving, it won't let you overwrite existing files; to get around this, use
filenames like `@0:music` (if you're a PET user you'll be used to this).

### Pattern

This is the heart of the editor, and allows you to edit patterns (i.e., the
music itself). Many of the keys use the Control key as a modifier; if you're on
a PET which doesn't have a Control key, use `RVS/OFF` instead.

- the cursor keys move around the pattern.
- `A`-`G` and `0`-`9` enter data into the pattern. If you're on a note, `A`-`G` are
  interpreted as a note name and `0`-`3` select octave. Otherwise, you're entering
  a hex digit. (Trackers traditionally use hexadecimal. The fact that it's
  easier to draw has nothing to do with things.) To get accidentals, enter a
  note name and then press + or -.
- `+` and `-` increment and decrement whatever the cursor is on.
- Shift plus `A`-`Z` enter a command. See below for the list of supported commands.
- Control plus the up and down cursor keys move between patterns (by pattern
  ID).
- Control plus the left and right cursor keys move between sequence entries.
  You'll be automatically taken to the appropriate pattern.
- `INS/DLT` removes the current note (writes a `B` command).
- `^N` creates a new pattern and takes you there. The sequence is left untouched.
- `^S` saves the current pattern to the visible slot in the sequence.
- `^A` inserts the current pattern _after_ the visible slot in the sequence,
  extending the sequence.
- `^W` inserts the current pattern _before_ the visible slot in the sequence,
  extending the sequence.
- `^D` removes the current pattern from the sequence, making the sequence
  shorter. The pattern itself is untouched.
- `^T` changes the global tempo. The default is 10.
- `^L` change the pattern length, globally. The maximum is 1f. This doesn't
  change the amount of memory used per pattern (always 256 bytes) but allows
  songs which don't fit the power-of-two pattern size.
- `SPACE` toggles playback.

Each note is displayed as the note, followed by two hex digits: the first is the
tone number used for the note, and the second is the volume, with `0` being
silent and `f` being loudest. For commands, these digits contain the command
parameter.

The drum channel doesn't play ordinary notes, instead playing various different
kinds of noise. Use the number keys to set these. You can't set volume or tone
for these, but you can set commands. (Pitch bend won't do what you expect.)

There's a fairly small set of commands currently implemented:

- `B`: does nothing. This is displayed as `....` in the pattern editor. Any
  existing note on the channel continues to play. Pressing `INS/DLT` while
  set this.
- `O`: off. Cancels any note being played on the channel. This is displayed as
  '====' in the pattern editor.
- `P`: sets the channel's pitch delta to the parameter, in ⅓-semitone intervals.
- `V`: sets the channel's volume to the parameter.
- `N`: skips to the next pattern in the sequence --- useful if you want just one
  short pattern.
- `X`: stops playing.

### Tone

This is the envelope editor, allowing you to edit the notes being played. Use
the up and down cursor keys to move between fields; when on the graphs, use
left and right to move. Press + and - to change a value.

The fields are:

- Tone: which tone you're looking at.
- Repeat: the start and end of the repeat segment. The note will play until it
  hits the end marker, and then loop back to the start marker, which must be
  smaller than the end marker.
- Edit mode: whether the graph is showing the pitch delta or the volume delta.

The graph can be edited one sample at a time by placing the cursor on it and
pressing + or -. Note that the pitch can be increased or decreased, but the
volume should only ever be decreased from the value actually being played.

To play a sample note, press `A`-`G` to set the note and `0`-`5` to set the
octave.

**Important note:** the engine used to actually generate the notes doesn't do a
very good job of changing the volume, but it _does_ cause the timbre to change
significantly allowing you to do things like sidechain effects. I may change
the name of the graph at some point.

### Help

Shows a quick cheat sheet for the keys.


## Why?

Because it's hard?


## Why not?

There are bugs, although it seems pretty robust to me.


## License?

Two-clause BSD; see the COPYING file. Go nuts.


## Who?

This program was written by myself, David Given <dg@cowlark.com>; I have a
website at http://cowlark.com. There may or may not be anything interesting
there.

The sample track, _Onward Ride_, is a cover of Proton's SID version
(https://csdb.dk/sid/?id=57172) of Jugi's MOD classic
(https://modarchive.org/index.php?request=view_by_moduleid&query=50820) which
was the soundtrack to Dope (https://www.pouet.net/prod.php?which=37), one of the
most significant demoscene works ever.
