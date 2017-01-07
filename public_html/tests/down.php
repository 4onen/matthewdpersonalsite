<html>
<head>
<title>Down the rabbit hole</title>
<style>
table, th, td {
	border:1px solid black;
}
</style>
<head>

<body>
You've successfully loaded the testing PHP page.
Whether there's any useful data here remains to be seen.

<div style = "border:1px solid black">
	<b>Some hosting tests. Don't mind these.</b>
	<div>
		This segment of the document represents a PHP test. If you're here for other reasons, ignore it.
		<?php
			$self = 'PHP_SELF';
			$snme = 'SERVER_NAME';
			$shst = 'SERVER_HOST';
			$hhst = 'HTTP_HOST';
			$href = 'HTTP_REFERER';
			$mnme = 'SCRIPT_NAME';
			echo '<table>';
			echo '<tr><th>Hello World! It seems this page got PHP\'d, at least a little.</th></tr>';
			echo '<tr><td>';
			echo $self.":".$_SERVER[$self];
			echo '</td></tr><tr><td>';
			echo $snme.":".$_SERVER[$snme];
			echo '</td></tr><tr><td>';
			echo $shst.":".$_SERVER[$shst];
			echo '</td></tr><tr><td>';
			echo $hhst.":".$_SERVER[$hhst];
			echo '</td></tr><tr><td>';
			echo $href.":".$_SERVER[$href];
			echo '</td></tr><tr><td>';
			echo $mnme.":".$_SERVER[$mnme];
			echo '</td></tr></table>';
		?>
	</div>
	<br>
	<div>
		Website size testing section. Ignore this, too, other internetees.
		<a href="./down.php">link</a>
	</div>
</div>

</body>
</html>
