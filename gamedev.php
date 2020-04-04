<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" type="text/css" media="screen" href="style.css" />
    <title>MatthewD's Website</title>
</head>

<body>
    <?php include("nav.html"); ?>
    <article id="pageContent">
        <section>
            <h3>Game Development</h3>
            <p>At UCSB I am a frequent atendee of the Game Development Club.
                I have yet to find time to dive into serious development,
                but during my study abroad at Lunds University, Sweden, 
                I did find time to participate in the latter half of the 
                JS13k competitition (I started late on September 13th)
                producing the title
                <a target="blank_" href="https://js13kgames.com/entries/peaceful-forest-walk">Peaceful Forest Walk</a>
                and winning 85th place in General, 19th in Mobile. Notably,
                the game has only a single piece of polygonal geometry: a
                blit for rendering a fragment shader. Everything visible in 
                the scene itself is the result of raymarching over a signed
                distance field.
            </p>
            <a target="blank_" href="https://js13kgames.com/entries/peaceful-forest-walk"><img class="brightenim flexim" src="PeacefulForestWalkSS.png" alt="Screenshot of a forest from my JS13K entry Peaceful Forest Walk"/></a>
            <p>For my final project in EDAF80, the Lunds University Computer
                Graphics course, I produced the title ArcticWorld, which is
                notable for being almost raw C++ and OpenGL 4.0. All visible
                shapes are a result of my shader code and parametric geometry.
                The wrapping of the planetoid is achieved using tricks in the 
                vertex shader. The physics were coded by hand and received
                the least TLC.
            </p>
            <iframe width="640" height="360" src="https://www.youtube.com/embed/M8tZMrgkIY0" frameborder="0" allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>
            <p>Prior to university, I and two friends participated in the
                first educational silicon valley Teen Hackathon, producing
                the physics-based game prototype 
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