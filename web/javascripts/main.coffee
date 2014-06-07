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
        Backbone: 'lib/backbone-min.js'
        $       : 'lib/jquery.min.js'

requirejs['app']