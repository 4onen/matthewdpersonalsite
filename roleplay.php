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
        <section>
            <h3>Tabletop Roleplaying</h3>
            <p>During my time at UCSB, I joined up with a few roleplaying groups. First was a game of <a target="_blank" href="https://paizo.com/pathfinder/rpg">Pathfinder</a>
                with a few friends during the Freshman Summer Start Program. Second was a long-running game of the 
                <a target="_blank" href="https://www.shadowruntabletop.com/">Shadowrun</a> tabletop roleplaying game, played with my roommate and some of 
                his friends over Discord. <i>(Theoretically the second game is stil running, but we have not had a session in four months.)</i>
            </p>
            <p>I'm currently in two games running right now:</p>
            <ul>
                <li>The <a href="WFRP">Wish Fulfillment RP</a> with the Shadowrun group and a few additional friends.</li>
            </ul>
            <p>Past games:</p>
            <ul>
                <li>Pathfinder</li>
                <li>Shadowrun</li>
                <li><a target="_blank" href="https://www.modiphius.net/collections/star-trek-adventures">Star Trek Adventures</a> with the UCSB Star Trek club.</li>
            </ul>
        </section>
    </article>
    <footer>
        <p>Page last updated: <?php echo date("D, jS F, Y, H:i e", getlastmod());?></p>
    </footer>
</body>

</html>