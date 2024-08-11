---
tags: Blog/AwSW
title: Mod Load Order
author: 4onen
date: 2024-08-10
---
## Introduction

Recently in the AwSW community I have noticed some confusion about the order in which the Ren'Py game engine, augmented with our community's wonderful core modtools, loads mods. There's a lot to unpack, from compatibility issues to unexpected gameplay changes. I'll be breaking down the importance of load order for AwSW mods, outlining the common pitfalls, and offering best practices to ensure a smooth and enjoyable experience.

## What is a Load Order?

A load order is the sequence in which mods are loaded into the game. This sequence determines how the game processes and applies the changes made by each mod. The order in which mods are loaded can significantly impact the gameplay experience, as mods can conflict with each other or overwrite each other's changes if not loaded in a compatible order.

Let's consider a few scenarios:

* **Overwritten Changes:** Imagine a mod modifies a specific character's appearance. If another mod tries to change the same character's appearance later in the load order, it might overwrite the previous changes, resulting in a jarring or inconsistent look.[^0]
* **Compatibility Issues:** Different mods may rely on different game functionality or on functions provided by other mods. If a mod that depends on another mod is loaded before that dependency, it might not function correctly.
* **Gameplay Changes:** Mods can introduce new characters, dialogue, or gameplay mechanics. The order in which these changes are applied can affect the overall narrative or gameplay experience. With a consistent load order, modders can design their mods to complement each other, creating a more cohesive and enjoyable experience for players. Without it, mods might clash, leading to unexpected outcomes or breaking the game entirely.
* **Debugging and Troubleshooting:** When mods are loaded in a predictable order, it becomes easier to identify the source of issues or conflicts. Modders can more effectively debug their mods and provide better support to players encountering problems.

[^0]: I've experienced this directly in my own modding projects, where another mod unexpectedly replaced a custom asset I had added, mistakenly transforming a character into a completely different character.

## The Ren'Py Load Order

Angels with Scaly Wings ships with the Ren'Py game engine version 6.99.12.2.2029, which is available at their GitHub repository, commit [183327eec](https://github.com/renpy/renpy/tree/183327eec5920060af4a2db808ed19e0de4f1211){target="_blank"}. It's this code I'm referencing when I talk about load orders in AwSW. Future versions of Ren'Py likely differ.

### Script File Loading

The Ren'Py game engine, during startup, produces and caches a scan[^1] of all the game files on its "search path." This path includes the game directory, the game archive, and any directories specified in the `config.searchpath` variable. The script modules (and their compiled bytecode) are then copied from this cache into a list[^2], which is then sorted by the path of each file _relative to the search path directory it was found in._[^3] Normally this would produce an order that is inconsistent between different systems, as Windows uses `\\` as a path separator while Linux uses `/`. However, Ren'Py normalizes all paths as it caches them.[^4]

[^1]: See <https://github.com/renpy/renpy/blob/183327eec5920060af4a2db808ed19e0de4f1211/renpy/loader.py#L248>{target="_blank"}
[^2]: See <https://github.com/renpy/renpy/blob/183327eec5920060af4a2db808ed19e0de4f1211/renpy/script.py#L223>{target="_blank"}
[^3]: See <https://github.com/renpy/renpy/blob/183327eec5920060af4a2db808ed19e0de4f1211/renpy/script.py#L259>{target="_blank"}
[^4]: See <https://github.com/renpy/renpy/blob/183327eec5920060af4a2db808ed19e0de4f1211/renpy/loader.py#L183>{target="_blank"}

The game will search for both rpy and rpyc files at each path, and compile and load them in this sorted order. Notably, the rpyc file takes precedence, unless the game is in a full-recompilation mode or the MD5 hash of the rpy file does not match the hash stored at the end of the rpyc file.[^5] This is why Ren'Py can take a while to load as players add more, larger mods. Ren'Py is taking the MD5 hash of every rpy file to check if it needs to recompile it. The more mods added, the more files it has to check, since the modding community has chosen to distribute mods as source code.

[^5]: See <https://github.com/renpy/renpy/blob/183327eec5920060af4a2db808ed19e0de4f1211/renpy/script.py#L701>{target="_blank"}

### Init Phases

After loading the script files, Ren'Py will collect all the `init` blocks from the script files into a list called `initcode`, which is then sorted _stably_ by priority.[^6] This priority is an attribute of every init block that determines the order in which they are executed. Negative priorities are executed first, then zero, then positive. Because we sort the list stably, if two `init` blocks have the same priority, they will be executed in the order they were found in the script files. Within one script file, this means they execute in order as you go down the file. Between script files, this means they execute in the order the files were loaded, described above.

[^6]: See <https://github.com/renpy/renpy/blob/183327eec5920060af4a2db808ed19e0de4f1211/renpy/script.py#L266>

Init phases that are allowed for users to manipulate in their game range from -999 to 999. The default init phase for an init block is 0, which is the init phase used by the majority of AwSW.

Mods are loaded during init phase 0, so whenever the `modloader/bootstrap.rpy` file appears in the list of script files. This falls in the midst of the game's own init blocks, before all files alphabetically sorted after `modloader` and after all files alphabetically sorted before `modloader`. As `modloader` sorts before `mods`, the modtools run and import mod configurations before any mod scripts with init priority 0 are have run, but after the Ren'Py game engine has loaded all script files and solidified their load order. Any negative priority `init` blocks have already run. Any positive priority `init` blocks will run after the modtools have finished their loading process.

## The Modtools Load Order

All of the above applies to Ren'Py script files and their compiled bytecode, those in `rpy`, `rpyc`, `rpym` and `rpymc` formats. The modtools and mods built with them, however, are written in Python and are loaded as Python modules. These python modules from Ren'Py's perspective are all loaded the moment the `modloader/bootstrap.rpy` file gets to run its `init 0` phase. So during that blink of time from the game engine's perspective, what's actually happening?

Code in this section of the post is referencing [this commit](https://github.com/AWSW-Modding/AWSW-Modtools/commit/06304d15a98a0c357693caaf5fa6abfbfc1568ea){target="_blank"} of the AwSW modtools repository.

### Discovering Mods

The modtools first discover all the mods in the `game/mods` directory by listing its contents. Importantly, this list is *not sorted* in any way; it is the order the operating system lists the subdirectories in the mod directory. This means that the order in which mods are discovered is not predictable and can vary between systems. This is why it's important to avoid relying on the order of mod discovery for any `import` statements or other code required just to load your mod's configuration.

If any non-folders are found in the `game/mods` directory, the modtools will raise an error and halt the game. This is to prevent any accidental inclusion of files that are not mods, such as packed zips or incorrectly unpacked loose files.

### Importing Mod Configs

Once the list of mods is discovered, the modtools will import each mod's `__init__.py` file. This executes all code in the file top to bottom, including import statements, variable assignments, and function+class definitions. It is expected that each mod will include exactly one `class` definition that inherits from `modclass.Mod` (typically named `AWSWMod`) _and_ has the decorator `@modclass.loadable_mod`. This is how the modtools know where to get the mod's configuration from, and how to load the mod's scripts.

Each `modclass.Mod` subclass must have the following defined to be loaded successfully:

* **Mod Info**: Either one of the following:
  * `mod_info`: An (optionally static) method that returns a tuple of `(Name, Version, Author)` (where each of `Name`, `Version`, and `Author` are appropriate strings. (Optionally, this may be a 4-tuple where the 4th value is a bool indicating whether the mod is NSFW. A mod lacking this 4th value is assumed to be SFW.)
  * `name`, `version`, and `author` class variables: Strings that define the mod's name, version, and author, respectively. (Optionally, a 4th class variable `nsfw` may be defined as a bool indicating whether the mod is NSFW. A mod lacking this 4th variable is assumed to be SFW.)
* **`mod_load`**: A method that takes no arguments and is called when the mod is loaded. This is where the mod should set up any global variables, register any new screens, or perform any other setup that should happen before the game starts. This method is called after all mods have been discovered and imported, but before any mod's `mod_complete` method is called.
* **`mod_complete`**: A method that takes no arguments and is called when the mod is fully loaded. This is where the mod should perform any final setup that requires all mods to be loaded. This method is called after all mods' `mod_load` methods have been called.

### Dependency resolution

Each mod's subclass of `modclass.Mod` may also define a `dependencies` class variable that is a list of strings. These strings come in three different forms:

* **Simple Dependency**: A string that is the name of another mod that this mod depends on. The mod declaring this dependency will not be loaded until the mod it depends on has been loaded. If the mod it depends on is not found, the game will raise an error and halt.
* **Optional Dependency**: A string starting with `?` (a question mark) followed by the name of another mod. No error is raised if the dependency is not found, but the mod declaring this optional dependency will not be loaded until the mod it depends on has been loaded if both are present.
* **Incompatibility**: A string starting with `!` (an exclamation point) followed by the name of another mod. If the mod declaring this incompatibility is to be loaded on the same copy of the game as the mod declared incompatible, the game will raise an error and halt.

An example dependency list might look like this:

```python
dependencies = [
    "MagmaLink",
    "?Side Images",
    "!My Cool Game-Breaking Mod",
]
```

The order of dependencies in this list is not important, nor is it preserved in any way -- the list is treated like a set of dependencies. The modtools will then topologically sort the mods based on their dependencies, ensuring that mods that have no dependencies are loaded first, followed by mods that depend on those mods, and so on. If a cycle is detected in the dependency graph, the game will raise an error and halt.

The implementation of the topological sort is an unstable O(N^2), which is performed on the already-unstable order that mods were discovered. This means that unless a dependency relation is explicitly declared, no ordering of mod loading can be strictly guaranteed. If a mod intends to have any cross-mod functionality, it should declare the other mod(s) as at least optional dependenc(ies) to ensure the other(s) load(s) first.

### `mod_load`

The `mod_load` method of each mod is called in the order the mods were topologically sorted. This means that mods with no dependencies are loaded first, followed by mods that depend on those mods, and so on. This is where the mod should set up any scene changes, register any new screens, or perform any other setup that should happen before the game starts.

Many mods depend on a mod called MagmaLink, which provides a framework to massively ease the process of manipulating the game's scenes. All functionality relating to MagmaLink should typically be performed in this `mod_load` method, as MagmaLink is not guaranteed to be loaded prior to this point, and most mods expect game scene manipulations to be complete by the time their `mod_complete` method is called.

### `mod_complete`

The `mod_complete` method of each mod is called in the order the mods were topologically sorted, after all mods' `mod_load` methods. This is where the mod should perform any final setup that requires all mods to be loaded. Before dependency resolution was added to the modtools, this was the only place where mods could be sure that all other mods were loaded. Now, this method is largely vestigial, but it is still a required definition for each mod to have.

Some mods still choose to wait until here to load their "Side Images" or other optional mod assets.

### Magmalink Scene Builders

MagmaLink is a mod that provides a framework for other mods to manipulate the game's scenes. One of the ways it does this by providing a series of "scene builders" that know how to manipulate some of the game's most complex scenes without breaking them, such as the Answering Machine scene or the character selection screens. These scene builders are like forms that each mod fills out, asking for certain changes to these scenes.

Because MagmaLink must be fully loaded before any mod can use its scene builders, MagmaLink can't have the scene builders actually apply their changes at that time. As it's still technically legal to fill out the scene builders in `mod_complete` (albeit bad practice,) MagmaLink also can't apply the changes in its own `mod_complete` method. Instead, MagmaLink waits until the `init 999` phase to apply the changes specified by the scene builders. This is the last phase of the game's user-land initialization, and it is the only phase where MagmaLink can be sure that all mods have been loaded and all scene builders have been filled out.

It is illegal to access any MagmaLink functionality after this phase, as the game is now in the process of finalizing its internal state and preparing to start. No MagmaLink functionality may be used at runtime due to the delicate nature of the game's internal assumptions about its state after this point.

## The Unified Load Order

If you're here just to see when each piece of code runs, here it is:

* **Ren'Py Script Files:** Loaded in a consistent order based on their path relative to each search path directory.
* **Ren'Py `init` Blocks, Phases -9999 to -1000:** Game engine internal initialization. These init phases should never appear in code outside the game engine `common` directory.
* **Ren'Py `init` Blocks, Phases -999 to -1:** User-defined initialization. These init phases are available for the game and modders to use, but generally best avoided.
* **Modloader Bootstrapping**
  * **Mod Discovery:** Mods are discovered and imported in the order the operating system lists the subdirectories in the mod directory.
  * **Mod Configs:** Mod configurations are imported in the order the mods were discovered.
  * **Dependency Resolution:** Mods are topologically sorted based on their dependencies, with mods that have no dependencies sorted first.
  * **`mod_load`:** The `mod_load` function of each mod is called in the order the mods were topologically sorted.
  * **`mod_complete`:** The `mod_complete` function of each mod is called in the order the mods were topologically sorted.
* **Ren'Py `init` Blocks, Phases 0 to 998:** User-defined initialization. These init phases are available for the game and modders to use.
* **MagmaLink Linking (Init phase 999):** MagmaLink finally performs the linking specified by its Answering Machine scene builders, as well as replaces the Status screen with its own multi-mod-supporting version.
* **Ren'Py `init` Blocks, Phases 1000 to 9999:** Game engine internal finalization. These init phases should never appear in code outside the game engine `common` directory.

## Best Practices

To ensure a smooth modding experience for modders and users, here are some best practices to follow when working with mods in AwSW.

### Users

* **Read the Mod Descriptions:** Before installing a mod, read the mod description to understand its functionality and compatibility. Usually mods declare their incompatible mods in their description, to save you the effort of downloading and installing incompatible mods.
* **Use the Steam Workshop:** The Steam Workshop provides an easy way to manage and install mods for AwSW. It automatically updates mods and suggests necessary dependencies.
* **Report Bugs:** If you encounter any bugs or issues with mods, report them to the mod author or AwSW Unofficial Fan Discord so they can be addressed.

### Modders

* **Use the Mod Tools:** The mod tools are a valuable resource for managing dependencies and ensuring your mods work as intended. Strictly speaking, it is possible to write separate bootstrapping and have it work, but it's far more likely to break of its own accord or have incompatibilities with future modding work.
  * **Declare Dependencies:** Declare any dependencies your mod has on other mods to ensure they are loaded in the correct order.
* **Use MagmaLink:** MagmaLink provides a framework for manipulating the game's scenes and is widely used by modders. It also supports translation mods and other complex scene manipulations in a compatible way, so it's a good idea to use it for your mod for future compatibility.
  * **Import MagmaLink in `mod_load`:** MagmaLink must be fully loaded before any mod can use its scene builders. Import MagmaLink in your mod's `mod_load` method, rather than at the top of your mod's `__init__.py` file, to make absolutely sure it is loaded in the correct order.
* **Use Version Control:** Use a version control system (like Git) to track changes to your mod. For example, if stored on GitHub, people with moddable copies of the game not playing on Steam can easily download the latest version of your mod.
  * **Commit only working code:** Make sure your mod is in a working state before committing changes to your repository. This helps prevent issues for users who download your mod and helps you review past states of your mod.
* **Write Clear Mod Descriptions:** Include detailed descriptions of your mod's functionality, compatibility, and any special instructions.
* **Keep Up-to-Date:** Regularly update your mod to fix bugs, add new features, and improve compatibility with other mods.

These best practices help create a more enjoyable and stable modding experience for both users and modders alike.

## Conclusion

Understanding the load order of mods in AwSW is crucial for creating, using, and maintaining mods. While it can be fun and interesting to dive deep into how mods are loaded and executed, it's important to try to keep things simple and limit your mod's complexity as much as possible, to ensure compatibility with other mods and future versions of the game.

This post is meant to be a starting point for understanding the intricacies of the load order, not a comprehensive guide to abusing it. With great power comes great responsibility, and modders should strive to create mods that get along with the rest of the modding ecosystem, to allow players to mix and match mods to create their ideal AwSW experience.
