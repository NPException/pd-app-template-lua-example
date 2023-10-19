This is a small template project to build games for the [Playdate](https://play.date) console.  
It allows you to program your Playdate app in [Lua](https://www.lua.org/),
[Fennel](https://fennel-lang.org/), or a mix of both languages.

* _**Do I need a Playdate console to be able to make games for it?**_  
  No! The Playdate SDK comes with a simulator, so you can create games for the Playdate
  even without owning one.  
  😎

## Requirements

* [babashka](https://babashka.org/) ( `bb` in snippets here) is used to execute build tasks.
  _(It's recommended to add it to your `PATH` environment variable, so you can invoke it directly from the commandline.
  Alternatively just chuck the executable in your project directory and add it to the `.gitignore`.)_
* The [PlaydateSDK](https://play.date/dev/) must be available to the build process either via the `PLAYDATE_SDK_PATH` environment variable,
  or by explicitly adding its directory path to the config section of `bb.edn` under `:playdate-sdk-path`.
* **[only when using Fennel]**  
  The Fennel binary must be available to the build process either
  by a `fennel` executable on your `PATH` environment variable, or by explicitly adding a path for
  the binary to the config section of `bb.edn` under `:fennel-binary-path`.

All the heavy lifting is done by [babashka](https://babashka.org/). If you want to adapt this build process for
your existing projects, all you need to do is to copy the [bb.edn file](bb.edn) into
your project and maybe adjust the values in the `bb.edn`'s `config` section according to your needs
if necessary. If you also want the automated draft release when you push your changes to GitHub,
you just need to copy the `.github` folder into your project as well.

## Getting started with [Lua](https://www.lua.org/)

All you need to do is to add a `main.lua` file in the `source` folder.  
By default, that file will serve as the starting point for the Playdate compiler
when building your application.

Here's a small code snippet you can add to `main.lua` to see some text on screen:

```lua
function playdate.update()
  playdate.graphics.drawText("Hello *Lua* _World_", 30, 30)
end
```

## Getting started with [Fennel](https://fennel-lang.org/)

All you need to do is to add a `main.fnl` file in the `source` folder.  
Fennel files will be compiled to Lua files of the same name (f.e. `main.fnl -> main.lua`).  
By default, that file will serve as the starting point for the Playdate compiler
when building your application.

Here's a small code snippet you can add to `main.fnl` to see text on screen:

```fennel
(fn playdate.update []
  (playdate.graphics.drawText "Hello *Fennel* _World_" 30 30))
```

## Hey, you just wrote the same thing twice?!

Pretty much, yes. This project template is set up in such a way that you can use both Lua and Fennel
at the same time in your project if you want. For example if you want write your game in Fennel,
but still want to use some of the amazing libraries for Playdate that are written in Lua.
([Like Noble Engine!](https://noblerobot.com/nobleengine))

Just make sure you don't have Fennel and Lua files with the same name sit in the same directory.
(for example having a `utils/text.lua` and `utils/text.fnl` file)  
In such cases, the Lua file will be copied over the compiled Fennel file when the app is built.

## Building and testing

To run a full build, start the Playdate Simulator, and have the app available in the main menu
of the simulator too, just run the `build-copy-sim` Babashka task by executing:

```bash
bb build-copy-sim
```

This will compile all Fennel `.fnl` files (if any) in the `source` directory to Lua,
and copy the compiled Lua files as well as any other files in the `source` directory into a `compiled-source` directory.
_(Note to caution: Any `.lua` file that has the same name as a `.fnl` file
in the same directory will overwrite its compiled file!)_  
Then the Playdate compiler `pdc` will be called with the compiled sources as its input, and creates the PDX app.

(If there are no `.fnl` files to compile, the `compiled-source` directory won't be used,
and the Playdate compiler will be called with the `source` directory as its input instead.)

Then the PDX app will be copied into the Simulator's games director to make it available in the
Simulator's menu. (So you can check your menu artwork, animations, etc.)

Finally, the Simulator will be started with the PDX app.

#### Using Visual Studio Code?

I've included a `.vscode/tasks.json` file with 3 common tasks preconfigured. If you run the default
build task (`Ctrl+Shift+B`), `bb build-copy-sim` will be run in the terminal.

### Release

To create a `.pdx.zip` file of your game which you can distribute online (for example on [itch.io](https://itch.io)),
you execute the following:

```bash
bb build-release
```

This will build the project and pack everything up into a `.pdx.zip` file in a `builds` subdirectory.

### Automatic GitHub release via GitHub action

This template includes a GitHub action, which will create a new release (or update an existing
one) for the current version in the `source/pdxinfo` file. By default, this action triggers whenever
changes within the `source` folder are pushed to the `main` branch. This then will automatically
run `bb build-release` on one of GitHub's machines, and (if the build succeeds) upload a `.pdx.zip`
file of your app to a GitHub draft release for your current version.  
You can then manually publish, edit, or delete the release in the "Releases" section of your GitHub repo.
See the `:automated-release` config section in `bb.edn` for a bit more details.

If you don't want the automatic release build, you can just delete the `.github/workflows/auto-release.yml` file.

### Build config

Near the top of the `bb.edn` file is a config map, that is used to determine where the different
parts of the build process get their input and where they write their output. Here's a description
of each config key:

|         Key           | Description                                                                                                                                                                                                                                                                                            |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `:release-name`       | The name that the zip file will get which is created by the `build-release` task. Can take placeholders for values from the pdxinfo file.                                                                                                                                                              |
| `:release-tag`        | When an automatic release is created via the GitHub action, this string will be used as the git tag name for the release.                                                                                                                                                                              |
| `:playdate-sdk-path`  | The location of the Playdate SDK. If this is empty, the build process will try to get the path from the `PLAYDATE_SDK_PATH` environment variable.                                                                                                                                                      |
| `:fennel-binary-path` | The location of the Fennel binary. If this is empty, the build process checks if `fennel` is available on the `PATH` environment variable.                                                                                                                                                             |
| `:sources`            | The directory where all your code and asset files are expected to be.                                                                                                                                                                                                                                  |
| `:fennel-macros`      | A path relative to the `:sources` directory where Fennel macro modules are kept. These are only used by Fennel during compilation, and will not be compiled themselves. Non-`.fnl` files will still be picked up by the Playdate compiler if present.                                                  |
| `:compiled-sources`   | The directory where the combination of compiled `.fnl` files and copies of all other files in the `:sources` directory will be put by the `compile` task. It is also the directory that is used as input for the Playdate compiler. If there are no `.fnl` files to compile, this directory is unused. |
| `:main-file`          | A relative path to the Lua file with which the Playdate compiler will start compilation. This is usually the file which defines the `playdate.update()` function. (If your main Fennel file is `game.fnl`, then put `game.lua` as the main file.)                                                      |
| `:build-output`       | The directory where the PDX app built by the Playdate compiler will be put.                                                                                                                                                                                                                            |

## Babashka tasks

The `build-and-sim` task is just a convenient predefined combination
of the tasks `build` and `start-sim`.

Other available tasks are:

|         Task         | Description                                                                                                                                                                                                  |
|:---------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `clean-compiled`     | Deletes the directory generated via the `compile` task.                                                                                                                                                      |
| `compile`            | Compiles all Fennel files using `fennel` and copies all other files to the `:compiled-sources` directory. Does nothing if there are no `.fnl` files in the project.                                          |
| `clean`              | Removes the PDX build output directory                                                                                                                                                                       |
| `create-pdx`         | Builds all files in the `:compiled-sources` directory into a Playdate PDX app.                                                                                                                               |
| `build`              | Compiles Fennel (if necessary) and builds everything into a Playdate PDX app.                                                                                                                                |
| `copy-pdx-to-sim`    | Copies the PDX app to the Playdate simulator's games directory, so it can be selected in the simulator's menu.                                                                                               |
| `start-sim`          | Starts the Playdate simulator with the PDX app in the build output directory                                                                                                                                 |
| `build-and-sim`      | Calls the `build` task and then starts the Playdate simulator.                                                                                                                                               |
| `build-copy-sim`     | Calls the `build` and `copy-pdx-to-sim` tasks, then starts the Playdate Simulator.                                                                                                                           |
| `build-release`      | Increments the `buildNumber` in pdxinfo (if sources changes since last release), calls `build` and puts the resulting PDX app in a zip. The name of the zip is determined by the `:release-name` config key. |

You can get the list of all available tasks and what they do by running:

```bash
bb tasks
```

## License

I've put this project under the very permissive MIT License (unless specified otherwise in a file).
For your convenience I also put the license text at the bottom of the `bb.edn` file,
so you don't need to bother mention the original copyright and license of the file in your own projects.

When using this repository as a template for your own project, I recommend replacing the `LICENSE`
file with a license of your choice. (Or just remove it if you prefer full restrictive ownership
of your code)

## Questions?

If you have any questions feel free to open an issue or contact me on social media:

* Discord: [.npexception (formerly NPException#2597)](https://discordapp.com/users/107443773834797056)
* Twitter: [@NPException](https://twitter.com/NPException)
