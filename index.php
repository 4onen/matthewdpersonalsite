<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" type="text/css" media="screen" href="style.css" />
    <title>MatthewD's Website</title>
</head>
<body>
    <?php include("nav.php"); ?>
    <article id="pageContent">
        <header>
            <h1 class="nomarg bigheader">MatthewD's Engineering Website</h1>
            <h1 class="nomarg medheader">Computer Engineering, Analysis, and Trickery.</h2>
            <h1 class="nomarg smallheader">plus (<a href="fanfiction.php">fan</a>)fiction writing, roleplaying, etc...</h4>
        </header>
        <section>
            <h2>Computer Engineering</h2>
            <p>I'm a Computer Engineering student at the <a target="blank_" href="https://www.ucsb.edu/">University of California, Santa Barbara</a>.</p>
            <p>My topics of study include computer graphics, ML, and VLSI.</p>
        </section>
        <section>
            <h3>COVID-19 and California fire hermitry</h3>
            <p>Here's the data from the PurpleAir sensor closest to my home. 
            Data here is not using the LRAPA correction for 2.5um laser counters
            exposed to 1.5um wood smoke. In layman's terms: It might be an overestimate.</p>
            <div id='PurpleAirWidget_60509_module_AQI_conversion_C0_average_10_layer_standard'>Loading PurpleAir Widget...</div>
            <script src='https://www.purpleair.com/pa.widget.js?key=9OFZ5QEYFCQ4MOKW&module=AQI&conversion=C0&average=10&layer=standard&container=PurpleAirWidget_60509_module_AQI_conversion_C0_average_10_layer_standard'></script>
        </section>
        <section>
            <h3>Other things</h3>
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