<?php
$DOC_DEPTH = $DOC_DEPTH ? $DOC_DEPTH : 0;
$PATH_PARTS = pathinfo($_SERVER['REQUEST_URI']);
$ROOT_URI = $PATH_PARTS['extension'] ? $PATH_PARTS['dirname'].'/' : $_SERVER['REQUEST_URI'];
for(; $DOC_DEPTH>0; $DOC_DEPTH--){
    $ROOT_URI = dirname($ROOT_URI) . '/';
}
?>
<div id="navcontainer">
    <?php echo "<a id='iconLink' href='{$ROOT_URI}'>MD</a>"; ?>
    <nav>
        <?php
        echo "<a href='{$ROOT_URI}classes'>Classwork</a>";
        echo "<a href='{$ROOT_URI}gamedev'>GameDev</a>";
        echo "<a href='{$ROOT_URI}fanfiction.php'>Fanfic</a>";
        echo "<a target='_blank' href='https://github.com/4onen'>GitHub</a>";
        echo "<a target='_blank' href='https://www.linkedin.com/in/4onen/'>LinkedIn</a>";
        ?>
    </nav>
</div>