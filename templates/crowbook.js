var display_menu = false;

function toggleMenu() {
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