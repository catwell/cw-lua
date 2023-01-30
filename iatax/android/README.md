# Android Build

This is only needed to generate a standalone Android APK. Otherwise you can
just run the .love file with the Löve application from the play store.

Install your Android toolchain and clone
[love-android-sdl2](https://bitbucket.org/MartinFelis/love-android-sdl2). Then:

- put the .love file under `assets/game.love`;
- copy the contents of `res/` (*);
- copy `AndroidManifest.xml`;
- put `IataxActivity.java` under `src/info/catwell/iatax/IataxActivity.java`.

(*) Yes, I am aware that icon is ugly. I kept it for old times' sake, not
because it is a design masterpiece :)

To change the Android target version, edit `project.poperties`.

Run `ndk-build`. If you get duplicate symbol issue with freetype, delete
`jni/freetype2-android/src/base/ftbase.c` and retry.

Run `ant debug`. You will find the APK under `bin/`.
