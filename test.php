<?php
$headers = getallheaders();

$cookies = $_SERVER['HTTP_COOKIE'];

$redirectUrl = isset($_GET['url']) ? $_GET['url'] : 'No URL parameter';

echo "Redirect URL: " . htmlspecialchars($redirectUrl) . "<br><br>";
echo "Cookies received: <pre>" . htmlspecialchars($cookies) . "</pre><br><br>";
echo "Headers received: <pre>" . htmlspecialchars(print_r($headers, true)) . "</pre><br><br>";
?>
