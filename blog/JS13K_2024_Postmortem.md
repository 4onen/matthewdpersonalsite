---
tags: Blog/JS13K
title: "The City Without That Number: Postmortem"
author: 4onen
date: 2024-10-01
---
# The City Without That Number: Postmortem

At the end of this post, you'll find [Appendix A](#appendix-a) where I have the initial notes I made for my game's plan. I typed them into my phone while taking a walk the very day the theme for this year's JS13K was announced. That initial scope was exceptional, planning for far more than I think I'd be able to fit in 13kb even given arbitrary time to work on it. Given that initial exceptional scope, I think it's no surprise that the game didn't turn out quite like I'd hoped. The final result, however, did not meet even my scaled-back expectations, despite how I felt about it at 2am the night of submission. Let's talk about that.

## The Good

At submission, the game was genuinely impeessive in a number of aspects that I _should_ feel accomplished having achieved. I don't, due to its flaws, but we'll get to those. First, the areas of success:

* **Reducing scope**: My original plan was for a city builder on the scale of a hundredth-size Sim City 4, something with growth, zoning, demand, and autonomous development. When I was halfway through the month and had only a static, flat grid of house development stages in-engine, I knew something had to change. So I switched to the puzzle genre, focusing on tight maps that would emphasize the aversion to 13. This was the right move to make, and resulted in something at the end I felt comfortable calling "complete," despite how incorrect that statement turned out to be.

* Toolset: I wrote my own dev server, minifier, and handcrafted a build pipeline in GNU Make. While I did lean on Python3, `aiohttp`, `watchfiles`, and the terrible practice of Regex to make that build pipeline and those tools happen, I did put those pieces together as part of the competition, and doing so fed back to work I was doing wt my IRL job position, helping a little to justify the late nights.

* Demo mode: The best decision I made for the game was letting it play itself. Even before I had game logic and UI, filling the map with random, supposedly valid building combinations revealed all sorts of bugs and glitches. Remember, fuzz your tests!

* Graphics: The game carries an incredibly cheap, distinctive, and (at least in my opinion) charming graphical style, with details preserved for the places they have the most impact. Nearly branchless graphics coding also makes the game performant on both desktop and mobile, even facing excessively large (for the toolset) maps.

* Sound: Outsourcing my attempts to do audio to the ZzFX sound engine was a genuinely good plan and justifies the day I spent shopping around for sound engine options. As sound is a secondary component of my game experience, this let me build on what I was developing without sacrificing excessive developmemt time as I have in my other WebAudio ventures.

* Licensing: One thing I've felt increasingly awkward about in recent projects is that large companies can snap up and use certain kinds of open source code with barely a line of attribution in a well-hidden page. By licensing under GPLv3, I'm preserving the ability for people to see and build on the code for their own edification in perpetuity, which I feel builds on the spirit of the entire JS13K competition and ecosystem as I have experienced it. That leads into...

* Commenting: After rereading the rules and rediscovering there was an educational component to this challenge, I renewed my efforts to make a comment-stripping minifier, then commented the _everliving heck_ out of my code. Combined with off-the-shelf VSCode go-to-definition, I think anyone with an understanding of JavaScript can keep up with where the code is going.

The trouble is, while all of these are nice outcomes, I feel they were overshadowed by some pretty large defects.

## The Bad

I made some pretty massive mistakes in this project. It, and I, deserve our negative feedback for these errors.

### The Last Minute Change

Let's start with the big one. At 1:53am CDT, just 4 hours before the competition ended, I looked at what I had and decided, in my infinite wisdom as the developer who made it, that my game wasn't _challenging_ enough. So I made a one-line change to increase the dificulty from rejecting _powers_ of 13 to rejecting _multiples_ of 13.

```diff
-const can_see = (n) => n != N && n != N * N && n != N * N * N && n != N * N * N * N && n != N * N * N * N * N;
+const can_see = (n) => n != 0 && n % N != 0;
```

Astute programmers may already see the error. Yes, my zero check and the `&&` condition are reversed from what they should be: `n == 0 || ...`.

In the submission copy of The City Without That Number, it is impossible to bring any number in stats _back_ to zero after it has been nonzero. This results in cripplingly confusing gameplay and makes some maps utterly worthless for their intended purpose. Two of the most critically impacted are `dbl` and `chkr`. On `dbl` because there is only room for one building and no stories, you can only placw one building ever, making learning the bulldozer tool and building rotation impossible. `chkr` similarly allows 2x2 buildings, but placing one in the only possible space is now a trap, preventing you from using the space to work up your 1x1 count.

Of course, these dead ends lead into a bigger issue.

### Goals: What are we doing here?

The first feedback for my game, and what led to me recognizing I had shipped [the big bug](#the-last-minute-change) was:

> I do not know how to play your game.

This cannot even slightly be attributed to the big bug. I made a mistake that four and five year olds should be growing out of: I forgot the theory of mind. I forgot to remember other people aren't me and don't know what I know.

The tutorial levels were designed to be tiny practical examples of the game's behavior, but I failed to communicate that behavior alongside those examples. I gave no indication of success or failure. To make an outdated reference, I had given them cow tools without comment and had assumed they were obvious.

I had two plans in mind, either of which would have greatly helped, both of which at midnight before submission I had decided were unnecessary luxuries, despite their necessity:

1. Goals. Literally a function on the stats or city info to tell when a win condition was reached and show a "You win" of some kind in the level select. With these, the tutorials would have at least indicated when their learning content was achieved.

2. Descriptions. Literally just text describing the purpose of each level. Instead, I left users staring at abbreviations so terse they were questioning even their meaning.

I had assumed, having started in the city building genre, that I could get away with the freeform nature of something like Sim City 4. Surely I wouldn't need to guide the exploration-driven audience of my title. This assumption completely ignored my pivot from the city sim genre to the puzzle genre.

In short, this was an **unacceptable** failure of game design. It is also perhaps the purest lesson in how "the users are dumb" is almost never the right response to someone struggling with what you've made. I wrote an entire lengthy reply of descriptive instructions to that first feedback, only to then test the game myself and discover my big shipped bug. I did not describe my game well enough for them to know there was a bug, to know why it was not working, and to commiserate with me on the perils of last-minute editing. Their confusion was non-obvious to me because _I_ was the one confused first.

Those two major flaws aside, I still made some other painful mistakes with my project, wasting my already-limited time and effort.

## The Ugly

These wouldn't have sunk the ship, unlike the above, but they certainly contributed to the problem.

* Dark-Mode: Did you know my game follows your system color mode preferences? I'm almost certain you didn't, and that almost nobody else will notice or care, ever. I need to focus on consistent, pleasant experiences, not trying to support every web platform feature.

* Keydown Handling: The keydown function uses the keys-pressed set for its checks. Concise code, yes, but if a player holds one key and presses another, both keys are re-executed. That isn't how that should work.

* Music: Approximately 5 days of dev time was spent on music. For something left on the cutting room floor, that's an egregious amount of wasted effort.

* The Underhood Rewrite: When I first added double-size buildings, I tried to bit-pack it into the type info sign bit, of a city info array that only had two float entries. Needless to say, this was a mess, and when I wanted building rotation and even bigger buildings, I had to redo all that hackey effort, which led to days of bugs. Until you actually run out of space, don't play funny games with your data.

* Not-Invented-Here Syndrome: I get it. Writing my own dev tools was pretty fun. But when I'm spending whole days on it and, compared to alternatives, they kinda suck? That's not fun. I spent a day fighting the Python 3.10 `asyncio` runtime's terrible yield choices rather than fighting WebGL incompatibilities. That's time I could have spent more wisely.

* Self-care Shmelf-care: I would sit and work on this for hours, to the exclusion of all else. Considering I already had a desk job writing code, this was not okay. The days I skipped going on walks or lost sleep over this project were especially harmful to me and it both.

## The Means

Last of all, some of you may be wondering why, after all this, my submission is 9,965 bytes and not around 12,999. Why not something more reasonable? Why, in all my wisdom, did I take a late project with such mistakes and keep crushing it so small?

Two reasons:

* I didn't know I was late: I thought my remaining features would go in faster, would come together on the weekends, all that. They didn't. Weekends were spent out with friends and features were always bikeshedded into overtime, even in my team of one. By the time I realized I would need to crunch, it was obviously already crunch time.

* I didn't know it was small: Building my own pipeline atop Make led to one critical mistake: I didn't clear the build artifacts. It should always clobber those, right? The trouble is, `zip` doesn't replace existing archives -- it updates them in place. So when an extra 2.3kB file (zipped) snuck in, I didn't know it until my last week. When I did, and my project dropped from ~11kB to ~8.7kB, I chose to make 10kB my new target for no sane reason I can recall now.

These arbitrary limitations self-justified my big mistake of leaving out goals and descriptions until the very last, letting them get bumped from the game entirely.

## The Ends

I clearly made mistakes managing this project. Do I regret submitting it under "Completed"? No. I feel like by getting any harsh feedback to my face, it reinforces the lessons I should be learning from this about project management and design:

* Teach users everywhere, not just one place.
  * Clear descriptions, goals, UI, etc.
  * Accesibility is good for everyone. My emoji buttons were cute. Not including `title=` attributes to give descriptive tooltips was not.
* Prioritize the project first.
  * Try external tools. They exists for a reason. Accept "Not-Invented-Here" only if it makes sense.
  * Working before clever. Just use more RAM and GPU bandwidth. Optimize when necessary.
  * Features of the now, not later. Don't watch YouTube videos for what might be cool to add. Watch videos on features you need.
* Take care of yourself.
  * Eat
  * Drink
  * Exercise
  * Sleep

All y'all be happy out there. Best of luck in the JS13K grading. (I think we established I don't need that luck.) And, most of all, have a happy winter 2024.

# Appendix A: Original notes for The City Without That Number

We did it! It's okay! You're safe. Welcome to _The City Without That Number._

Small SimCity-like where nothing is 13 (or any multiple)

* Buildings cannot construct if it would make the total count, or count of the same type, 13
* Walkable urban environments only -- full streets only for commeecial imports/exports (loading/unloading)
* Currency: Numberlessens (Short: Lsns. Icon: V)
* Bulding types:
  * Residential (rand color sides, rand color roof, green yard)
  * Commercial (blue-beige sides, beige-blue roof, white yard
  * Hub (Import/Export) (white sides, black roof)
  * Police (white sides, blue roof)
  * Plaza/Park (stretch)
  * Fire (stretch)
* Demand Types:
  * Residential
  * Import
  * Commercial
  * Export
* Terrain:
  * Use a heightmap to determine rendering
    * Hill/Plain
      * Normal square buildings
    * Waterfront (stretch)
      * Roof pins at water surf, raytraces toy visuals:
        * Residential: Dock + Party
        * Commercial: Fishing warf
        * Hub: Tug warf
        * Police: Police dock

