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
        <header>
            <h1 class="nomarg bigheader">MatthewD's Engineering Website</h1>
            <h1 class="nomarg medheader">Computer Engineering, Analysis, and Trickery.</h2>
            <h1 class="nomarg smallheader">plus (<a href="fanfiction.html">fan</a>)fiction writing, roleplaying, etc...</h4>
        </header>
        <section>
            <h2>Computer Engineering</h2>
            <p>I'm a Computer Engineering student at the <a target="blank_" href="https://www.ucsb.edu/">University of California, Santa Barbara</a>.</p>
            <p>My topics of study include computer graphics, ML, and VLSI.</p>
        </section>
        <section>
            <p>While you're here, take a look at my work in <a href="classes">class</a>,
                <a href="gamedev.php">game development</a> side projects, and
                <a href="fanfiction.php">fanfiction</a>.
        </section>
        <section>
            <p>If you're one of my friends from the Pathfinder, Shadowrun, Star Trek Adventures, or WFRP games,
                that page has moved to <a href="roleplay.php">here</a>.
        </section>
    </article>
    <footer>
        <p>Page last updated: <?php echo date("D, jS F, Y, H:i e", getlastmod());?></p>
    </footer>
</body>
</html>