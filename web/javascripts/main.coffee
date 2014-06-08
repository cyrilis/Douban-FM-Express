#requirejs.config({
#    baseUrl: 'lib',
#    paths: {
#        app: '../app'
#    }
#});
#
#// Start loading the main app file. Put all of
#// your application logic in there.
#requirejs(['app/main']);

requirejs.config
    baseUrl: 'javascripts'
    paths:
        FM: "DoubanFm"
        Color: "Color"
        jquery           : 'lib/jquery.min'
        underscore  : 'lib/underscore-min'
        Backbone    : 'lib/backbone-min'
        app         : 'app'
    shim:
        Backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'
        underscore:
            exports: "_"

require ['app'], (app)->
