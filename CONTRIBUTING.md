# Contributing to the Train-Coupler mod

Thank you for helping improve the **Train-Coupler** mod for *Scrap Mechanic*!

## Contributor Licensing Agreement (Inbound = Outbound)

By submitting a pull request, patch, 3D model, texture, audio file, or any other
contribution to this repository, you agree to the following terms:

1. **License Grant:** You license your contribution under the **GNU General
   Public License, version 3 (GPLv3)** AND the **Additional Permissions
   (`LICENSE-EXCEPTION`)** included in this repository.
2. **Platform & Game Rights:** You expressly authorize the project maintainers
   (and any downstream forks complying with the GPLv3) to upload, distribute,
   and license your contribution via the **Steam Workshop** under the Steam
   Subscriber Agreement and the *Scrap Mechanic* End User License Agreement
   (Axolot Games AB).
3. **Originality & Authority:** You confirm that your contribution is your
   original work (or that you have the legal right to submit it under these
   terms) and does not include ripped assets from *Scrap Mechanic* or other
   proprietary games/mods.
4. **Source Files for 3D & Media Assets:** If you contribute new or modified 3D
   models, rigs, or textures, please include the editable source files (such as
   `.blend`, `.psd`, or `.xcf` files) alongside the compiled game assets so the
   repository remains compliant with GPLv3's Corresponding Source requirement.

If you do not agree to these terms, please do not submit a pull request.

## Project Vision & Design Philosophy

Our goal is for the **Train-Coupler** mod to feel like an official, seamless
expansion of *Scrap Mechanic* rather than a disconnected add-on. Every code
change, part, and feature should follow two core principles:

1. **Balanced, Non-Game-Breaking Gameplay:**
   * New parts, mechanics, and recipes should integrate naturally into *Scrap
     Mechanic*'s progression, resource economy, and physics limits.
   * Avoid "overpowered" or "cheat-like" shortcuts (e.g., weightless blocks,
     infinite power/fuel, or trivializing survival challenges) unless explicitly
     gated behind fair late-game costs and trade-offs.
   * Every feature should solve a problem or enable creative engineering without
     making existing vanilla parts obsolete.

2. **Vanilla-Friendly Style & Direction ("Vanilla+"):**
   * **Visuals & Audio:** 3D models, textures, animations, and sound effects
     should match *Scrap Mechanic*'s chunky, industrial, hand-crafted aesthetic,
     color palette, and grid proportions so they never feel out of place next to
     vanilla blocks.
   * **Mechanics & Flow:** Interactions, UI prompts, and part behaviors should
     follow the game's existing logic and tactile feel. They should be intuitive
     to learn without needing a manual.

## Proposing Changes: Open an Issue First!

Before investing time in coding or modeling a noticeable change, **please open a
GitHub Issue first** so we can discuss it together.

* **When to open an Issue first:**
  * Adding new parts, blocks, tools, or gameplay mechanics.
  * Changing crafting recipes, part stats (weight, durability, speed, power), or
    game balance.
  * Altering user workflows, UI interactions, or existing part behavior.
* **When a direct Pull Request is fine:**
  * Bug fixes, crash/error resolutions, or multiplayer sync fixes that restore
    intended behavior.
  * Performance optimizations, code cleanup, or typo fixes that do not change
    gameplay or balance.

Opening an issue early helps align on balance, visual direction, and scope
before work begins, saving you from writing code or building 3D assets that
might not fit the mod's vision.

## Use of AI Tools

We welcome modern development workflows, including AI tools, provided the
resulting work is high-quality, maintainable, and legally compatible with this
project's **GPLv3** license.

### 1. Code & Configurations (`.lua`, `.json`)
* **Allowed without disclosure:** You are free to use AI coding assistants for
  writing, refactoring, or debugging Lua scripts and JSON files without needing
  to disclose it.
* **Human accountability & quality bar:** You are fully responsible for every
  line you submit. Do not submit unreviewed AI output. All code must be tested
  in-game (including multiplayer client/server behavior where applicable), free
  of hallucinated Scrap Mechanic API functions, and written cleanly enough that
  you can explain how it works during review.

### 2. 3D Models, Textures & Audio
* **Allowed as a helper/starting tool only:** You may use AI tools to assist
  your workflow, such as generating reference imagery, base textures, or rough
  blockout meshes, **provided you substantially rebuild, retopologize,
  UV-unwrap, and clean up the asset** to meet Scrap Mechanic's art style and
  performance standards.
* **No raw AI generations:** Unedited text-to-3D meshes, raw AI-generated
  textures/icons, or unedited AI audio files will be rejected.
* **Editable source files required:** Per our GPLv3 terms, any AI-assisted asset
  must still include your cleaned, editable project files (`.blend`, `.psd`,
  `.xcf`, etc.), not just exported `.obj` or `.tga` files.

### 3. Licensing & Originality
* You must ensure that the Terms of Service of any AI tool you use permit
  releasing the output under the **GNU GPLv3** and our `LICENSE-EXCEPTION`.
* Do not use AI tools to deliberately recreate copyrighted characters, assets
  from other games, or other modders' work.
* Please write your Pull Request description yourself, clearly explaining what
  your change does and how you tested it in *Scrap Mechanic*.