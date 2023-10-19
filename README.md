![Automated Release](https://github.com/NPException/pd-app-template-lua-example/actions/workflows/auto-release.yml/badge.svg?branch=main)

This is an example for how to use the functionalities from my
[Playdate app template repo](https://github.com/NPException/playdate-app-template)
with a game written in Lua.

# A fan copy of [Spin Cross](https://jctwizard.itch.io/spincross)

This game is a slightly modified version of jctwizard's amazing game Spin Cross.
Go get the original on its official [itch.io page](https://jctwizard.itch.io/spincross)
and leave some love in the comments. :)

## Build and run in Playdate simulator

With babashka and the Playdate SDK installed, run the following command:

```bash
bb build-and-sim
```

## Releases

The most recent automated release [can be found here](https://github.com/NPException/playdate-app-template/releases).

## Differences

This version of Spin Cross has the following differences from the original:

- After death, the respawn points of cross and circle are at 90° from the current crank position.
