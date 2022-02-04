var widgetPageLoadInitiatedStates = [];
var closeButtonActionBlocked = false;

var buttonBody = "<html lang=\"en\"><head><title>Ko-fi Donation Button</title><link rel=\"preconnect\" href=\"https://ko-fi.com/\"><link rel=\"dns-prefetch\" href=\"https://ko-fi.com/\"><link href=\"/styles/kofi-main.css\" rel=\"stylesheet\" type=\"text/css\" /></head><body style=\"margin: 0; position: absolute; bottom: 0;\"><style> .hiddenUntilReady { display: none; } </style><div id=\"kofi-donate\" class=\"hiddenUntilReady closed donate\" style=\"z-index:10000; background-color: #ffffff;\"><img id=\"kofi-donate-image\" src=\"/images/cup-border.png\" class=\"kofiimg\" data-rotation=\"0\" alt=\"Ko-fi coffee cup\"/><span style=\"margin-left: 8px; color:#323842\">Support me</span></div></body></html>";
var iframe = document.getElementById("kofi-container");
var iframeContainerElement = iframe.contentDocument;
var _timer = setInterval(function() {
    var doc = iframe.contentDocument || iframe.contentWindow;
    if (doc && doc.readyState == 'complete') {
        clearInterval(_timer);
        document.getElementsByClassName('container-wrapper')[0].style = 'z-index:10000;';
        document.getElementsByClassName('mobile-container-wrapper')[0].style = 'z-index:10000;';
        iframe.style = '';
    }
}, 300);
iframeContainerElement.write(buttonBody);
iframeContainerElement.close();
var mobiIframe = document.getElementById("kofi-mobile-container");
var mobiIframeContainerElement = mobiIframe.contentDocument;
var _timer = setInterval(function() {
    var doc = mobiIframe.contentDocument || mobiIframe.contentWindow;
    if (doc && doc.readyState == 'complete') {
        clearInterval(_timer);
        document.getElementsByClassName('container-wrapper')[0].style = 'z-index:10000;';
        document.getElementsByClassName('mobile-container-wrapper')[0].style = 'z-index:10000;';
        mobiIframe.style = '';
    }
}, 300);
mobiIframeContainerElement.write(buttonBody);
mobiIframeContainerElement.close();

var desktopDonateButton = iframeContainerElement.getElementById("kofi-donate");
desktopDonateButton.addEventListener('click', function() {
    var desktopDonateButton = iframeContainerElement.getElementById("kofi-donate");
    if (desktopDonateButton.classList.contains("closed")) {
        var kofiIframeState = desktopDonateButton.classList.contains('closed') ? 'open' : 'close';
        var existingPopup = document.getElementById("kofi-popup");
        if (kofiIframeState === 'open') {
            var iframeContainerParent = iframe.parentElement;
            var finalHeight = window.innerHeight - (window.innerHeight - iframeContainerParent.offsetTop) - 60;
            if (finalHeight > 690) {
                finalHeight = 690;
            } else if (finalHeight < 400) {
                finalHeight = 400;
            }
            var widgetPageLoadStateIndex = widgetPageLoadInitiatedStates.findIndex(function(s) {
                return s[0] == desktopDonateButton;
            });
            var widgetPageLoadInitiated = widgetPageLoadInitiatedStates[widgetPageLoadStateIndex][1];
            if (!widgetPageLoadInitiated) {
                var _iframeLoading = false;
                var _iframeDebounce = null;
                var tryLoad = function() {
                    if (!_iframeLoading) {
                        _iframeLoading = true;
                        var iframe = document.createElement('iframe');
                        var parentElement = document.getElementById("kofi-popup-container");
                        iframe.src = 'https://ko-fi.com/cadenhaustein/?hidefeed=true&widget=true&embed=true';
                        iframe.style = 'width: 100%; height: 98%;';
                        parentElement.appendChild(iframe);
                    } else {
                        if (_iframeDebounce === null) {
                            _iframeDebounce = setTimeout(function() {
                                clearTimeout(_iframeDebounce);
                                _iframeDebounce = null;
                                tryLoad();
                            }, 100);
                        }
                    }
                };
                tryLoad();
                widgetPageLoadInitiatedStates[widgetPageLoadStateIndex] = [desktopDonateButton, true];
            }
            existingPopup.style = 'z-index:10000;width:328px!important;height: ' + finalHeight.toString() + 'px!important; transition: height 0.5s ease, opacity 0.3s linear; opacity:1;';
            document.getElementsByClassName("mobile-popup-notice")[0].style.display = "block";
            document.getElementsByClassName("popup-notice")[0].style.display = "block";
            desktopDonateButton.classList.remove('closed');
            desktopDonateButton.classList.add('open');
            closeButtonActionBlocked = true;
            setTimeout(function() {
                closeButtonActionBlocked = false;
            }, 1000);
        }
    } else if (!closeButtonActionBlocked) {
        var popup = document.getElementById("kofi-popup");
        popup.style = 'height: 0px; width:0px; transition:height 0.3s ease 0s , width 1s linear,opacity 0.3s linear; opacity:0;';
        desktopDonateButton.classList.remove('open');
        desktopDonateButton.classList.add('closed');
        document.getElementsByClassName("mobile-popup-notice")[0].style.display = "none";
        document.getElementsByClassName("popup-notice")[0].style.display = "none";
    }
});
widgetPageLoadInitiatedStates.push([desktopDonateButton, false]);

var mobileDonateButton = mobiIframeContainerElement.getElementById("kofi-donate");
mobileDonateButton.addEventListener('click', function() {
    var mobileDonateButton = mobiIframeContainerElement.getElementById("kofi-donate");
    if (mobileDonateButton.classList.contains("closed")) {
        var kofiIframeState = desktopDonateButton.classList.contains('closed') ? 'open' : 'close';
        var existingPopup = document.getElementById("kofi-mobile-popup");
        if (kofiIframeState === 'open') {
            var iframeContainerParent = mobiIframe.parentElement;
            var finalHeight = window.innerHeight - (window.innerHeight - iframeContainerParent.offsetTop) - 60;
            if (finalHeight > 690) {
                finalHeight = 690;
            } else if (finalHeight < 350) {
                finalHeight = 350;
            }
            var widgetPageLoadStateIndex = widgetPageLoadInitiatedStates.findIndex(function(s) {
                return s[0] == mobileDonateButton;
            });
            var widgetPageLoadInitiated = widgetPageLoadInitiatedStates[widgetPageLoadStateIndex][1];
            if (!widgetPageLoadInitiated) {
                var _iframeLoading = false;
                var _iframeDebounce = null;
                var tryLoad = function() {
                    if (!_iframeLoading) {
                        _iframeLoading = true;
                        var iframe = document.createElement('iframe');
                        var parentElement = document.getElementById("kofi-mobile-popup-container");
                        iframe.src = 'https://ko-fi.com/cadenhaustein/?hidefeed=true&widget=true&embed=true';
                        iframe.style = 'width: 100%; height: 98%;';
                        parentElement.appendChild(iframe);
                    } else {
                        if (_iframeDebounce === null) {
                            _iframeDebounce = setTimeout(function() {
                                clearTimeout(_iframeDebounce);
                                _iframeDebounce = null;
                                tryLoad();
                            }, 100);
                        }
                    }
                };
                tryLoad();
                widgetPageLoadInitiatedStates[widgetPageLoadStateIndex] = [mobileDonateButton, true];
            }
            existingPopup.style = 'z-index:10000;width:328px!important;height: ' + finalHeight.toString() + 'px!important; transition: height 0.5s ease, opacity 0.3s linear; opacity:1;';
            document.getElementsByClassName("mobile-popup-notice")[0].style.display = "block";
            document.getElementsByClassName("popup-notice")[0].style.display = "block";
            mobileDonateButton.classList.remove('closed');
            mobileDonateButton.classList.add('open');
            closeButtonActionBlocked = true;
            setTimeout(function() {
                closeButtonActionBlocked = false;
            }, 1000);
        }
    } else if (!closeButtonActionBlocked) {
        var popup = document.getElementById("kofi-mobile-popup");
        popup.style = 'height: 0px; width:0px; transition:height 0.3s ease 0s , width 1s linear,opacity 0.3s linear; opacity:0;';
        mobileDonateButton.classList.remove('open');
        mobileDonateButton.classList.add('closed');
        document.getElementsByClassName("mobile-popup-notice")[0].style.display = "none";
        document.getElementsByClassName("popup-notice")[0].style.display = "none";
    }
});
widgetPageLoadInitiatedStates.push([mobileDonateButton, false]);

document.getElementsByClassName("popup-close")[0].addEventListener('click', function(event) {
    var popup = document.getElementById("kofi-popup");
    popup.style = 'height: 0px; width:0px; transition:height 0.3s ease 0s , width 1s linear,opacity 0.3s linear; opacity:0;';
    desktopDonateButton.classList.remove('open');
    desktopDonateButton.classList.add('closed');
    document.getElementsByClassName("mobile-popup-notice")[0].style.display = "none";
    document.getElementsByClassName("popup-notice")[0].style.display = "none";
});

document.getElementsByClassName("mobile-popup-close")[0].addEventListener('click', function(event) {
    var popup = document.getElementById("kofi-mobile-popup");
    popup.style = 'height: 0px; width:0px; transition:height 0.3s ease 0s , width 1s linear,opacity 0.3s linear; opacity:0;';
    mobileDonateButton.classList.remove('open');
    mobileDonateButton.classList.add('closed');
    document.getElementsByClassName("mobile-popup-notice")[0].style.display = "none";
    document.getElementsByClassName("popup-notice")[0].style.display = "none";
});