function TextViewerPlugin() {
    "use strict";

    var self         = this,
        pluginName   = "TextViewerPlugin";

    this.initialize = function ( viewerElement, documentUrl ) {
        var iframe = document.createElement('iframe');

        document.getElementsByTagName("body")[0].className = 'text';

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
