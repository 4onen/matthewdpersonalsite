<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" type="text/css" media="screen" href="../style.css" />
    <title>MatthewD's Website</title>
</head>

<body>
    <?php include("../nav.php"); ?>
    <article id="pageContent">
        <section>
            <h3>Game Development</h3>
            <p>At UCSB I am a frequent atendee of the Game Development Club.
                I have yet to find time to dive into serious development,
                
            </p>
            <p>In Fall of 2018, I studied abroad at Lunds University.
                For my final project in EDAF80, the Lunds Uni course on
                Computer Graphics, I produced the title ArcticWorld, which is
                notable for being almost raw C++ and OpenGL 4.0. All visible
                shapes are a result of my shader code and parametric geometry.
                The wrapping of the planetoid is achieved using tricks in the 
                vertex shader. The physics were coded by hand and received
                the least TLC.
            </p>
            <iframe width="640" height="360" src="https://www.youtube.com/embed/M8tZMrgkIY0" frameborder="0" allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>
            <p>During my study abroad at Lunds University, Sweden, 
                I also found time to participate in the latter half of the 
                September 2018 JS13k competitition (I started late on September 13th)
                producing the title
                <a target="blank_" href="https://js13kgames.com/entries/peaceful-forest-walk">Peaceful Forest Walk</a>
                and winning 85th place in General, 19th in Mobile. Notably,
                the game has only a single piece of polygonal geometry: a
                blit for rendering a fragment shader. Everything visible in 
                the scene itself is the result of raymarching over a signed
                distance field.
            </p>
            <p>Click the image below to go to the competition entry!</p>
            <a target="blank_" href="https://js13kgames.com/entries/peaceful-forest-walk"><img class="brightenim flexim" src="gamedev/PeacefulForestWalkSS.png" alt="Screenshot of a forest from my JS13K entry Peaceful Forest Walk"/></a>
            <p>Also during my study abroad, I participated in the September 2018
                <a target="blank_" href="https://www.meetup.com/tretton37-Tech-Meetup-Stockholm/events/253971995/">Game Jam: Part Deux</a> 
                game dev challenge, where we had 30 hours to build a game. My
                game was <a target="blank_" href="https://github.com/4onen/super-duper-fiesta">super-duper-fiesta</a>,
                a small WebGL spinning-top fighting game built in Elm-lang.
                Upon demoing it, everyone told me it reminded them of Beyblade,
                but at the time I had not heard of it.
            </p>
            <p>Features include WebGL with complicated fragment shaders, live
                keyboard input, a deterministic collisions engine, a simplistic
                bot AI for singleplayer, and a couple-minute day/night cycle.
            </p>
            <p>
            Click the screenshot below to go to the project page and try it out! Word of 
            warning: the constant camera rotation can be nauseating for some people.
            </p>
            <a target="blank_" href="https://github.com/4onen/super-duper-fiesta"><img class="flexim" src="gamedev/sdf3.jpg" alt="Screenshot of 3 dice from my Game Jam Part Deux game: Super Duper Fiesta"/></a>
            <p>Prior to university, in March 2015, I and two friends 
                participated in the first educational silicon valley 
                Teen Hackathon, producing the physics-based game prototype 
                <a target="blank_" href="https://teenhackathon.devpost.com/submissions/34686-aphellion">Aphellion</a>
                which won first place in the event.
            </p>
            <a target="blank_" href="https://teenhackathon.devpost.com/submissions/34686-aphellion"><img class="flexim" src="https://challengepost-s3-challengepost.netdna-ssl.com/photos/production/solution_photos/000/230/749/datas/original.png" alt="Menu screenshot from Aphellion" /></a>
        </section>
    </article>
    <footer>
        <p>Page last updated: <?php echo date("D, jS F, Y, H:i e", getlastmod());?></p>
    </footer>
</body>

</html>