# Greed CLI Game

This is an implementation of [Greed](https://www.youtube.com/watch?v=XQHq6tdxylk) in Python and Zig. Controls are as follows:

```
q w e
 \|/ 
a-+-d
 /|\ 
z x c
```
However, this is editable through `CONTROL` variable. Also, press &lt;space&gt; to quit, but this is also editable through `QUITKEY` variable.

### Python
At least Python 3.6 is required because of **f-strings**. Required third-party library is **readchar** (for getch/get a keypress). Note that as of writing, readchar only works for Linux and Windows. To install:
```console
pip install readchar
```

### Zig
Zig 0.12 is required. Works for Linux and Windows, although a cross-platform getch package for Zig is still a TODO. To compile:
```console
zig build-exe -lc greed.zig
```

## License
GPLv3 FTW!
