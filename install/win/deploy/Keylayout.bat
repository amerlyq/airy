:: Bind CapsLock to Control (as in Linux)
:: SEE http://johnhaller.com/useful-stuff/disable-caps-lock

set "KBD_LAYOUT=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
REG ADD "%KBD_LAYOUT%" /V "Scancode Map" /T REG_BINARY /D "0000000000000000020000001d003a0000000000" /F

pause

:: "Scancode Map" is a registry binary value with the following format
:: (each value is a 32-bit integer in little-endian order):
::     <00000000> <00000000> <NumberFollowingIntegers> <Mapping1> <Mapping2> ... <00000000>
:: A mapping consists of two 16-bit scancodes. The second scancode (high word) from the keyboard is replaced with the first scancode (low word). Some relevant scancodes are:
::     0x01 Esc
::     0x1D L-Ctrl
::     0x38 L-Alt
::     0x3A CapsLock
::     0x46 ScrollLock
::     0x0E Backspace
:: For example, the line
::     "Scancode Map"=hex:00,00,00,00,00,00,00,00,02,00,00,00,01,00,3a,00,00,00,00,00
:: consists of one mapping (01,00,3a,00) which replaces the scancode 0x003a with 0x0001.
:: That means that pressing CapsLock (0x3a) will generate Escape (0x01).
