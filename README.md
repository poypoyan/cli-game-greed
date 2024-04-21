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
At least Python 3.6 is required because of **f-strings**. Required third-party libraries for Python are **numpy** (for multidimensional array) and **readchar** (for getch/get keypress). To install:
```console
pip install numpy readchar
```
Note that as of writing, readchar only works for Linux and Windows.

### Zig
Zig 0.12 is required. Only works for Linux because there is still no cross-platform getch package for Zig (this is a TODO). To compile:
```console
zig build-exe -lc greed.zig
```

## License
GPLv3 FTW!
