"use strict";

(function(root, factory){
    if(typeof exports == 'object'){
        // CommonJS
        factory(exports);
    }else if(typeof define === 'function' && define.amd){
        // AMD. Register as an anonymous module.
        define(['exports'], factory);
    }else {
        // Browser Globals
        factory(root);
    }
}(this,function(exports){
    // default config/variables
    var VERSION = '0.1.0';

    /**
    * DoubanFmExpress main Class
    *
    * @class DoubanFmExpress
    */

    function DoubanFmExpress (obj){
        this.defaultConfig = {
            autoPlay: true,
            channel: 1,
            mode: 'queue'
        };
        var _config = {};
        for(var _key in this.defaultConfig){
            if(this.defaultConfig.hasOwnProperty(_key)){
                _config[_key]=obj[_key]||this.defaultConfig[_key];
            }
        }
        _init();
    }

    /**
     *   Private functions
     */

    // makePlayer DomElement (I'm trying hard in Pure js -_-# )
    function _makeDom(){
        var iframe = document.createElement('iframe');
        document.body.appendChild(iframe);
        iframe.contentDocument.body.innerHTML = '<audio src="1.mp3"></audio>';
        _player().volume = 0.5;
        _player().play();
        document.body.addEventListener('click',function(){
            _isPlaying()? _player().pause():_player().play();
            console.log('Paused');
        })
    }

    // Get play status
    function _isPlaying(){
        return !_player().paused;
    }
    // Get the _palyer Element
    function _player(){
        return document.querySelector('iframe').contentDocument.querySelector('audio');
    }

    // Set Audio source of the player
    function _setUrl(url){
        _player().src=url;
        return _player();
    }

    // FadeOut Effect
    function _fadeOut(){
        var i = 0, max = 100;
        var volume = _player().volume;
        function loopVol(){
            if(i>max){
                _player().pause();
                _setVolume(volume);
                return false;
            }
            window.setTimeout(function(){
                _setVolume(volume*(100-i));
                i++;
                loopVol();
            },10)
        }
        loopVol();
    }

    // FadeIn Effect
    function _fadeIn(){

    }
    // set the Volume of Player
    function _setVolume(n){
        _player().volume = typeof n ==='number'?n/100: + _player().volume * n.slice(0,-1)/100;
        return _player();
    }
    // setup DoubanFmExpress instance
    function _init(){
        _makeDom();
        window._player = _player();
    }
    // Prototype inheritance
    DoubanFmExpress.fn = DoubanFmExpress.prototype = {
        // Play
        play: function(){
            _player().play();
        },
        // Pause
        pause: function(){
            _player().pause();
        },
        // Stop
        stop: function(){
            _player().load();
        },
        // Play next song
        next: function(){},
        // Play Previous Song
        previous: function(){},
        // Set play mode (queue, one-repeat)
        changeMode: function(){},
        // Change to another Channel
        changeChannel: function(n){},
        // Get current song's information
        currentInfo: function(){},
        // Login to Douban.fm
        login:function(){},
        // Add current song to fave list
        fave: function(){}
    };
    exports.DoubanFmExpress = DoubanFmExpress;
    return DoubanFmExpress;
}));