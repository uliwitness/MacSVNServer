#!/usr/bin/php
<?php
$workingdir = $_SERVER['argv'][1];
$masprefix = $_SERVER['argv'][2];

$httpdconfpath = $masprefix."/conf/httpd.conf";
$conftext = file_get_contents($httpdconfpath);

$conftext = str_replace("\"".$masprefix."/htdocs"."\"","\"/Library/Application Support/MAS/htdocs\"",$conftext);

$pos = strpos($conftext,"<Directory \"/Library/Application Support/MAS/htdocs\">");
if( $pos === false )
	echo "Error: Couldn't fix up htdocs directory (1).\n";
else
{
	$endmarker = "</Directory>";
	$endpos = strpos($conftext,$endmarker,$pos);
	if( $endpos === false )
		echo "Error: Couldn't fix up htdocs directory (2).\n";
	else
		$conftext = substr_replace( $conftext, file_get_contents($workingdir."/httpd.conf.additions2.txt"), $pos, $endpos -$pos +strlen($endmarker) );
}

$fd = fopen($httpdconfpath,"w");
fwrite( $fd, $conftext );
fclose($fd);
?>