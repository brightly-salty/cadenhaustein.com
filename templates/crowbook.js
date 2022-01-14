function on(name) {
    var elements = document.getElementsByClassName(name);
    for (var i = 0; i < elements.length; i++) {
        var elem = elements[i];
        elem.style.backgroundColor = "pink";
    }
}

function off(name) {
    var elements = document.getElementsByClassName(name);
    for (var i = 0; i < elements.length; i++) {
        var elem = elements[i];
        elem.style.backgroundColor = "white";
    }
}

var display_menu = false;

function toggle() {
    if (display_menu) {
        display_menu = false;
        document.getElementById("nav").style.left = "-21%";
        document.getElementById("content").style.marginLeft = "0%";
        document.getElementById("menu").style.left = "1em";
    } else {
        display_menu = true;
        document.getElementById("nav").style.left = "0";
        document.getElementById("content").style.marginLeft = "20%";
        document.getElementById("menu").style.left = "20%";
    }
}

function readingTime() {
    const WPM = 200;
    var string = document.getElementById("page").innerText;
    const time = (string.replace(/^\s+/, '').replace(/\s+$/, '').replace(new RegExp('<\\w+(\\s+("[^"]*"|\\\'[^\\\']*\'|[^>])+)?>|<\\/\\w+>', 'gi'), '').match(new RegExp('\\w+', 'g')) || []).length / WPM;
    if (time < 0.5) {
        document.getElementById('time').innerText = 'less than a minute';
    } else if (time >= 0.5 && time < 1.5) {
        document.getElementById('time').innerText = '1 minute';
    } else {
        document.getElementById('time').innerText = `${Math.ceil(time)} minutes`
    }
}