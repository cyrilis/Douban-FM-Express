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

    // Define Statics
    var APIURL;
    var debug = true;
    var require = require;
    var _currentSong = {};
    var _currentUser = localStorage['user.user_id'] ?{
        email:     localStorage['user.email'],
        expire:    localStorage['user.expire'],
        token:     localStorage['user.token'],
        user_id:   localStorage['user.user_id'],
        user_name: localStorage['user.user_name']
    } :{};
    var _currentChannel = localStorage['channel']||1,_currentPlaylist = [];
    var _self = this;
    var _history = [];
    var _currentPlaylistId = 0;
    if(require&&!debug){
        APIURL = "http://www.douban.com/j/app/";
    }else{
        APIURL = "http://localhost:9000/j/app/";
    }

    // Main Class
    function DoubanFmExpress (obj){
        _self = this;
        this.defaultConfig = {
            autoPlay: localStorage['config.autoPlay']||true,
            channel: localStorage['config.channel']||1,
            mode: localStorage['config.mode']||'queue' // Optins : 'queue', 'loop'
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
        iframe.contentDocument.body.innerHTML = '<audio src="images/1.mp3"></audio>';
        _player().volume = 0.5;
        _player().play();
        document.body.addEventListener('click',function(){
//            _isPlaying()? _player().pause():_player().play();
            console.log('Paused');
        });
        // play next after current song ended
        _player().addEventListener('ended', function(){
            _next();
        },false);
    }

    // Bind Event
    function _bindEvent(){
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
    function _setUrl(playlistId){
        if(_isPlaying()){
            _fadeOut();
            window.setTimeout(function(){
                _player().src=_currentPlaylist[playlistId].url;
                _currentSong = _currentPlaylist[playlistId];
                _currentPlaylistId = playlistId;
                _player().play();
            },1100);
        }else{
            _player().src=_currentPlaylist[playlistId].url;
            _currentSong = _currentPlaylist[playlistId];
            _currentPlaylistId = playlistId;
            _player().play();
        }
    }

    // flash notify message
    function _flash(className,message){
        console.error(message);
    }

    // Save to Storage
    function _saveStorage(data,keyName) {
        var keyCount = 0;
        for(var key in data){
            if(data.hasOwnProperty(key)){
                localStorage[keyName+"."+key] = data[key];
                keyCount++;
            }
        }
        if(!keyCount){
            localStorage[keyName] = data;
        }
    }
    // Get Storage
    function _getStorage(keyName){
        return localStorage[keyName];
    }

    function _getHistory (){
        _history.join("|");
    }
    function _clearHitory(){
        _history = [];
    }
    // Get Channels
    function _getChannels (){
        _ajax({
            url: APIURL + "radio/channels",
            method: 'GET',
            success: function(data){
                if(data.e){
                    console.log('New Error');
                }else{
                    console.log(data);
                    var selectChannel = document.createElement('select');
                    var options = [];
                    data.channels.forEach(function(e){
                        options.push('<option value=\''+ e.channel_id+'\'>'+ e.name+'</option>');
                    });
                    selectChannel.innerHTML = options.join('');
                    selectChannel.onchange = function(){
                        var newValue = this.options[this.selectedIndex].value;
                        console.log(newValue);
                        _changeChannel(newValue);
                    };
                    document.body.appendChild(selectChannel);
                }
            },
            error: function(){
                console.log("Error!");
                _flash('error',"Get channels Failed, Please check your network");
                throw new Error('Net Wrok Error!');
            }
        });
    }

    function _getPlayList(channel_id,type){
        var data =  {
            app_name: "radio_desktop_win",
            version: "100",
            h: _getHistory(),
            channel: channel_id||_currentChannel,
            type: type,
            sid: null
        };
        if(type === "n"){
            delete data.sid
        }else{
            data.sid = _currentSong.sid
        }
        type === "p"? data.h = _getHistory():delete data.h;
        if(_currentUser.user_id){
            data.user_id=_currentUser.user_id;
            data.expire= _currentUser.expire;
            data.token= _currentUser.token;
        }else{
            delete data.h;
        }
        if(data.h){
            _clearHitory();
        }
        debug && console.log(data);
        _ajax({
            url: APIURL + "radio/people",
            method: "GET",
            data: data,
            success: function(data){
                if(data.r){
                    _flash('error',"Get Playlist Failed because:"+ data.err);
                    return;
                }
                debug&&console.log(data);
                _currentChannel = channel_id||_currentChannel;
                _saveStorage(channel_id,'channel');
                _currentPlaylist = data.song;
                _setUrl(0);
            },
            error: function(){}
        })
    }

    function _changeChannel(n){
        _getPlayList(n,'p');
    }
    function _next (force){
        if(_currentPlaylistId>=_currentPlaylist.length-1){
            var type = !force ? 'p' : 's';
            if(!_currentPlaylist){
                type = 'n';
            }
            _currentPlaylistId = 0;
            _getPlayList(null,type);
        }else{
            _setUrl(_currentPlaylistId+1);
        }
        _history.push(_currentPlaylist[_currentPlaylistId].sid + (force ? ':s': ':p'));
    }

    function _fave(){
        if(!_currentUser.user_id){
            _flash('error',"You haven't login yet.");
            return;
        }
        _getPlayList(_currentChannel,'r');
    }

    function _login (userEmail, userPassword){
        _ajax({
            method:"POST",
            url: APIURL+'login',
            data: {
                version: '100',
                app_name: 'radio_desktop_win',
                email: userEmail,
                password: userPassword
            },
            success: function(data){
                if(!data.r){
                    _currentUser = data;
                    _saveStorage(_currentUser,'user');
                    _getPlayList("0","n");
                    _flash('success',"User Login successfully");
                }else{
                    _flash('error', "Login Failed because of:"+ data.err);
                }

            },
            error: function (){
                _flash('error', "User login Failed because of Network Error");
            }
        });
    }

    // Ajax library
    function _ajax(obj){
        var urlEncode = [];
        for(var key in obj.data){
            if(obj.data.hasOwnProperty(key)){
                urlEncode.push(key+'='+obj.data[key]);
            }
        }
        if(obj.method == "GET"){
            obj.url+=("?"+urlEncode.join('&'));
            console.log(obj.url);
            delete obj.data;
        }else{
            obj.data = urlEncode.join('&');
        }
        var request = new XMLHttpRequest();
        request.open(obj.method, obj.url, true);
        request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
        request.onload = function() {
            if (request.status >= 200 && request.status < 400){
                obj.success(JSON.parse(request.responseText));
            } else {
                obj.error();
            }
        };

        request.onerror = function() {
            obj.error();
        };
        request.send(obj.data||null);
    }

    // FadeOut Effect
    function _fadeOut(){
        var i = 0, max = 100;
        var volume = _player().volume;
        console.log(volume);
        function loopVol(){
            if(i>max){
                _player().pause();
                _setVolume(volume*100);
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


    // set the Volume of Player
    function _setVolume(n){
        _player().volume = typeof n ==='number'?n/100: + _player().volume * n.slice(0,-1)/100;
        return _player();
    }
    // setup DoubanFmExpress instance
    function _init(){
        _makeDom();
        window._player = _player();
        _getChannels();
        _bindEvent();
        console.log(_self);
        _getPlayList(_self.defaultConfig.channel,"n");
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
        next: _next,
        // Play Previous Song
        previous: function(){},
        // Set play mode (queue, one-repeat)
        changeMode: function(){},
        // Change to another Channel
        changeChannel: _changeChannel,
        // Get current song's information
        currentInfo: function(){return _currentSong},
        // Login to Douban.fm
        login:_login,
        // Add current song to fave list
        fave: _fave,
        // Toggle Play or Pause
        playOrPause: function(){
            _isPlaying()? this.pause(): this.play();
        }
    };
    exports.DoubanFmExpress = DoubanFmExpress;
    return DoubanFmExpress;
}));