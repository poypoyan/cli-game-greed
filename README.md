# Greed CLI Game

This is an implementation of [Greed](https://www.youtube.com/watch?v=XQHq6tdxylk) in Python and (WIP) Zig. Tested on Linux and Windows. At least Python 3.6 (because of **f-strings**) and exactly Zig 0.11 are required. Controls are as follows:

```
q w e
 \|/ 
a-+-d
 /|\ 
z x c
```
However, this is editable through `CONTROL` variable. Also, press &lt;space&gt; to quit, but this is also editable through `QUITKEY` variable.

Required third-party libraries for Python are **numpy** (for multidimensional array) and **readchar** (for getting keypress). To install:
```console
pip install numpy readchar
```
