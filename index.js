/**
 * Created by Cyril on 15/3/9.
 */

var app = require("app");
var BrowserWindow = require('browser-window');

require("crash-reporter").start();

var mainWindow = null;

app.on("window-all-closed", function(){

  app.quit();

});

app.on('ready', function() {
  mainWindow = new BrowserWindow({width: 800, height: 600, frame: false, transparent: true});

  mainWindow.loadUrl('file://' + __dirname + '/index.html');

  mainWindow.on('closed', function() {
    mainWindow = null;
  });
});
