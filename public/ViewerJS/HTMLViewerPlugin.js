function HTMLViewerPlugin() {
    "use strict";

    var self         = this,
        pluginName   = "HTMLViewerPlugin";

    function initCSS() {
        var pluginCSS;

        pluginCSS = (document.createElementNS(document.head.namespaceURI, 'style'));
        pluginCSS.setAttribute('media', 'screen, print, handheld, projection');
        pluginCSS.setAttribute('type', 'text/css');
        pluginCSS.appendChild(document.createTextNode('#toolbarContainer { display: none; }'));
        document.head.appendChild(pluginCSS);
    }

    this.initialize = function ( viewerElement, documentUrl ) {
        initCSS();

        document.getElementsByTagName("body")[0].className = 'html';

        var iframe = document.createElement('iframe');
        iframe.style.width = '100%';
        iframe.style.height = '99.5%';
        iframe.style.border = 'none';
        iframe.style.backgroundColor = '#fff';
        iframe.src = documentUrl;
        viewerElement.appendChild(iframe);
        this.onLoad();
    };

    this.isSlideshow = function () {
    };

    this.onLoad = function () {
    };

    this.fitToWidth = function ( width ) {
    };

    this.fitToHeight = function ( height ) {
    };

    this.fitToPage = function ( width, height ) {
    };

    this.fitSmart = function ( width ) {
    };

    this.getZoomLevel = function () {
    };

    this.setZoomLevel = function ( value ) {
    };

    // return a list of tuples (pagename, pagenode)
    this.getPages = function () {
        return [1];
    };

    this.showPage = function ( n ) {
    };

    this.getPluginName = function () {
        return pluginName;
    };

    this.getPluginVersion = function () {
    };

    this.getPluginURL = function () {
        return pluginURL;
    };
}
