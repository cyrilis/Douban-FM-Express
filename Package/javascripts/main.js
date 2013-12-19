/**
 * Created by Cyril on 13-12-11.
 */
// init
var i=0
    ,history
    ,songs
    ,local=localStorage
    ,currentSong
    ,logindata
    ,user_items=["email","islogin","user_name",'user_id','expire','token','password']
    ,channel=1
    ,user={
        islogin:false
    }
    ,$jp=$("#iframe").contents().find("body").append("<div id='jplayer'></div>").find("#jplayer");
var getp=false;
var gui = require('nw.gui');
$jp.jPlayer({timeupdate: function(event) {
        $("#status").attr("style" , "width:"+parseInt(event.jPlayer.status.currentPercentAbsolute, 10)+"%");
        timeLeft = event.jPlayer.status.duration - event.jPlayer.status.currentTime;
        $("#timer").html("-" + $.jPlayer.convertTime(timeLeft))
    }}
);
local.getItem("token");
local.getItem('expire');
if(local.getItem("islogin")=='true'){
    user_items.forEach(function(item,index){
        user[item]=local.getItem(item);
    })
}
var fdata;
function initpdata(){
    fdata={
        app_name:"radio_desktop_win",
        version:100,
        //sid:songs[i].sid,
        user_id:user.user_id,
        expire:user.expire,
        token:user.token,
        channel:channel,
        type:"n",
        from:"mainsite",
        r:Math.floor(Math.random()*10E7)
    };
    if(!!currentSong){
        fdata.sid=currentSong.sid;
    }
}

initpdata();

// bind controlls actions
$('#next').click(function(){
    next();
});
$('#pause').click(function(){
    if($(this).hasClass("icon-play")){
        $jp.jPlayer("play");
        $(this).toggleClass("icon-play");
        $('#poster').removeClass('paused');
    }else{
        $jp.jPlayer('pause');
        $('#poster').addClass('paused');
        $(this).toggleClass("icon-play");
    }
});
$('#trash').click(function(){
    trash();
});
// Bind
$jp.bind($.jPlayer.event.ended, function(event) {
    marked();
    next();
});
$jp.bind($.jPlayer.event.play, function(event) {
    currentSong=songs[i];
    fdata.sid=currentSong.sid;
    var cover = $jp.find("img").attr("src");
    $("#poster").find("img").attr("src",cover).end().parent().css("background",cover);
    $('#style').html("body:before{background: url("+cover+")}")
    $.adaptiveBackground.run({
        parent: "body"
    });
    $("h2#title").html(currentSong.title).attr("title",currentSong.title);
    $("h3#artist").html(currentSong.artist);
    $("h4#album").html(currentSong.albumtitle);
    if(currentSong.like==1){
        $("#fave").addClass("faved").css({color:'rgb(244, 74, 110)'});
    }else{
        $("#fave").removeClass("faved").css({color:$('#trash').css("color")});
    }
    //getsonginfo();
});
$('#login').on("click",function(){
    login(true);
});
$("#cancel").on("click",function(){
   $("#loginform").hide("fast");
});
$("#fave").click(function(){
    if($(this).hasClass("faved")){
        unfave();
    }else{
        fave();
    }
});
$("#trash").click(function(){
    trash();
});


function loginshow(){
    $("#loginform").show("fast");
}
// controls
function next(){
    i++;
    if (!!songs[i]){
        $jp.jPlayer("setMedia",{mp3:songs[i].url,poster:songs[i].picture}).jPlayer('play');
    }else{
        newlist();
    }
}



function getsonginfo(){
    $.ajax({
        url:'http://localhost:3000/songinfo?song_id='+currentSong.sid,
        type:'GET',
        dataType:"json",
        success:function(data){
            if(data.artist_name){
                //alert(data.artist_name);
            }
        },
        error:function(){
            //alert('get songinfo error')
        }
    })
}
// get playlist and callback next;
function playlist(callback,sdata){
    console.log("Geting Playlist.....");
    data={
        app_name:"radio_desktop_win",
        version:100,
        channel:channel,
        type:"n"
    };
    data=sdata||data;
    $.ajax({
        url:"http://www.douban.com/j/app/radio/people",
        type:"GET",
        dataType:"json",
        data:data,
        success:function(data){
            if(data.r==0&&data.song){
                gotp=true;
                songs=data.song;
            }else{
                gotp=false;
            }
        },
        error:function(){
            gotp=false;
            alert("Get Playlist Failed")
        }
    }).done(function(){
            if(!!gotp){
                history=[];
                i=0;
                initpdata();
                songs.forEach(function(song,index){
                    songs[index].mp3=song.url;
                    songs[index].picture=song.picture.replace(/mpic/, "lpic");
                    console.log(song.title+"--"+song.artist);
                });

                callback();
            }else{
                console.log('what the fuck!');
                //login(false,openlogin);
            }
        })
}
// callbacks
login(false,openlogin);
function openlogin(){
    i=0;
    if (user.islogin) {
        playlist(first,fdata);
    }else{
        playlist(first);
    }
}

function first(){
    i = 0;
    $jp.jPlayer("setMedia",{mp3:songs[i].url,poster:songs[i].picture}).jPlayer('play');
}
// Login playlist
function fave(){
    if (user.islogin) {
        var pdata=fdata;
        pdata.type="r";
        pdata.sid=currentSong.sid;
        var faveit=function(){
            $("#fave").addClass("faved").css({color:'rgb(244, 74, 110)'});
        };
        playlist(faveit,pdata);
    }else{
        loginshow();
    }
}

function unfave(){
    var pdata=fdata;
    pdata.sid=currentSong.sid;
    pdata.type="u";
    var unfaveit=function(){
        i=0;
        $("#fave").removeClass("faved").css({color:$('#trash').css("color")});
    };
    playlist(unfaveit,pdata)
}

function trash(){
    var pdata=fdata;
    pdata.type="b";
    var trashit=function(){
        i=0;
        $jp.jPlayer("setMedia",{mp3:songs[i].url,poster:songs[i].picture}).jPlayer('play');
    };
    playlist(trashit,pdata)
}

function marked(){
    var pdata=fdata;
    pdata.type="e";
    function markit(){}
    playlist(markit,pdata);
}
function newlist(){
    var pdata=fdata;
    pdata.sid=currentSong.sid;
    history=[];
    type="p";
    songs.forEach(function(song,index){
        history.push(song.sid+":"+type);
    });
    history=history.join("|");
    pdata.type="p";
    pdata.h=history;
    var getmore=function(){
        i=0;
        $jp.jPlayer("setMedia",{mp3:songs[i].url,poster:songs[i].picture}).jPlayer('play');
    };
    playlist(getmore,data)
}

function login(really,callback){
    console.log("Logining in...")
    if (really) {
        var email=$('#email').val()
            ,password=$('#password').val();
        logindata={
            app_name:"radio_desktop_win",
            version:100,
            email:email,
            password:password
        }
    }else{
        logindata={
            app_name:"radio_desktop_win",
            version:100,
            email:user.email,
            password:user.password
        }
    }
    $.ajax({
        url:"http://www.douban.com/j/app/login",
        type:"POST",
        dataType:"json",
        data:logindata,
        success:function(sdata){
            if(sdata.r==0){
                user={
                    islogin:true,
                    user_id:sdata.user_id,
                    token:sdata.token,
                    expire:sdata.expire,
                    user_name:sdata.user_name,
                    email:sdata.email,
                    password:logindata.password
                };
                console.log(user.islogin,user.name);
                user_items.forEach(function(item,index){
                    local.setItem(item,user[item]);
                })
                local.password=user.password;
                $('#user_name').html(user.user_name);
                $("#loginform").hide();
            }else{
                console.error(sdata.err)
            }
        },
        error:function(){
            alert("Login Failed!")
        }
    }).done(function(){
            initpdata();
            if(!!callback){
                callback();
            }
        })
}

// Set Volume
$('#vol').grab({
    onstart: function(e){
    },
    onmove: function(e){
        var vol=180-e.position.y;
        if (0<vol<50) {
            $("#vol_bar_in").css("height", vol*2+"%");
            volume = vol/50;
            $jp.jPlayer("volume", volume);
        }
    }
});
document.addEventListener("keyup",function(e){
    if(e.keyIdentifier=="F12"){
        console.log('Show DevTool');
        require('nw.gui').Window.get().showDevTools();
    }
});

var $poster = $("#poster");
$poster.on('click',function(){
    var link ="http://music.douban.com"+songs[i].album;
    gui.Shell.openExternal(link);
});
// adaptive background
$poster.find("img").on('ab-color-found', function(e, data) {
    $("#controller").find("div").css({
        color: data.palette[0].replace('0.7)', "1)")
    });
    $("#fave").hasClass('faved')? $('#fave').css({color: 'rgb(244, 74, 110)'}):"";
    console.log("Color:",data.palette[0].replace('0.7)',"1)"));
});