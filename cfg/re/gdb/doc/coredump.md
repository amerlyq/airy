---
# title: 'GDB & MIPS Coredump'
# author: 'amerlyq'
patat:
    # columns: 40
    incrementalLists: false
    wrap: true
    theme:
        # bulletListMarkers: '=+'
        emph: [dullGreen, onVividBlack, bold]
        imageTarget: [onDullWhite, vividRed]
---

# Problems
- GDB -- *sole* tool
- Coredump -- no runtime
- MIPS -- no ???

# Coredump
## NO
- no breakpoints and step execution
- no controllable/fixed environment
- no dynamic code edits
- no in-place func calls
- no hacks and perversions, sad :(

# Coredump
## YES
- regs in _last_ frame
- all allocated memory regions
- no some sections from binary
- ? some kernel structs ?
- ? patched version of relocation table, etc ?

# GDB
- can't redirect output
- half-hearted batch scripting
- python disabled
- ? no access to AST

# MIPS
- many tools/exts anavailable
    * <valgrind> (double-free, who-point-at)
    * ~~radare2~~
- hard to identify stack frames

# Coredump
- registers baked on #0 only
    = investigate readelf -n ./core

# ASM feats
> * specifics
>     - kernel
>     - compiler
>     - language
> * patterns
>     - optimization
>     - security

# GDB
## Scripting
```bash
# -ex "layout regs" -ex "layout asm" -ex "b *0x4006b5"
gdb -q ./main.bin  -ex "b f" -ex "r" -ex 'x/16gx $rsp'
```
Auto-load local ./.gdbinit (default)
set auto-load local-gdbinit on (in global ~/.gdbinit if currently not enabled)

# ASM
## How to find frames
- hz

# ASM
## How to find frames
- hz

# Cases
Signals
: segfault
: abort
: deadlock

# MIPS
- read memory
```fasm
lw 0(sp)
```

# Logging


# TEMP: breaking
Legen

. . .

wait for it

. . .

Dary!
