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
            <h3>FanFiction Writing</h3>
            <p>I picked up FanFiction writing about the end of high school, as I was inspired by reading <b>Mass Effect</b> FanFiction on 
                <a href=https://www.FanFiction.net>FanFiction dot net</a>. Perhaps ironically, none of my published FanFiction work has 
                related to <b>Mass Effect</b>, with the vast majority (by volume of words) going to Dreamworks Animation's <b>How To Train 
                Your Dragon</b> movie series.</p>
            <p>Before I post a link, I feel I should warn you that (as one may expect from a teenager's writing) this content is not entirely 
                Safe-For-Work. <i>Remember, stop reading a story if it strikes a theme you can't stand.</i></p>
            <p>My works are published at <a href="https://www.fanfiction.net/u/6387259/">https://www.fanfiction.net/u/6387259/</a>.</p>
        </section>
    </article>
    <footer>
        <p>Page last updated: <?php echo date("D, jS F, Y, H:i e", getlastmod());?></p>
    </footer>
</body>

</html>