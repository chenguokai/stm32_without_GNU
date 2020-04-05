# What you need to compile an armv7-m (stm32) project

## Toolchain

My toolchain was compiled from the mainline source code, with clang, clang-tools-extra, lld and lldb enabled.

The key build command can be found as `build_clang.sh`

## What you need to tweak

### Standard peripheral libraries

Several naked functions are defined in core_cm3.c. They decleared variables inside the function body which works fine on gcc but is in fact a violation to the C standard. Clang will not build with those naked functions. What you need is patching naked functions with respect to armv7-m ABI. Fortunately the variables they decleared may be omitted.

Also, neither llvm-as nor the buildin one inside clang deals with all GNU AS syntaxs flawlessly. You need a C version of startup file, whose inline asm contains only syntaxs supported by clang/llvm.

### Compile flags

#### gcc->clang

Clang supports multiple targets by default, thus you need to specify the actual target, that is, add `--target=arm-none-eabi` to CFLAGS

In practice, clang will refer to LDFLAGS, which causes a contradiction.

A project compiled with gcc would happily linked with builtin linker provided by gcc. In clang's case, the builtin one is broken, which cannot identify most of our arguments.

The workaround is use another FLAGS for our final link. LDFLAGS is set to `-fuse-ld=$(PREFIX)ld.lld` and we may define another LLDFLAGS for ld.lld to link: `-T$(LDSCRIPT)` Note that `-nostartfiles` is omitted in LLDFLAG, which is not supported as an argument but is a default behaviour. Detailed description can be found in references.


#### objdump->llvm-objdump

The cross GCC toolchain would identify the thumb instructions correctly, without any explict argument, while for llvm, an argument `--arch-name=thumb ` is needed, for llvm-objdump would recognize our ELF as ARM, rather than thumb. As a result, mostly wrong instructions.

## What's missing

This project does not depend on any GNU libraries including C libs, thus no compiler-rt is needed. For a project that depends on libc, this guide is quite a start point rather than the end point.

## References

1. [https://rust-embedded.github.io/blog/2018-08-2x-psa-cortex-m-breakage/](https://rust-embedded.github.io/blog/2018-08-2x-psa-cortex-m-breakage/)
2. [https://github.com/piratkin/simple/blob/master/build.sh](https://github.com/piratkin/simple/blob/master/build.sh)
3. [https://clang.llvm.org/docs/CrossCompilation.html](https://clang.llvm.org/docs/CrossCompilation.html)
4. [https://llvm.org/docs/HowToCrossCompileLLVM.html](https://llvm.org/docs/HowToCrossCompileLLVM.html)