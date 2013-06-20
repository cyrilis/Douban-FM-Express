exports.login = function(req, res){ 
    var app_name = req.body.app_name 
        , version = req.body.version 
        , email = req.body.email 
        , password = req.body.password 
        , querystring = require('querystring') 
        , host = "www.douban.com"; 
  
    //http://www.douban.com/j/app/login 
  
    // app_name     radio_dsktop_win 
    // version      100 
    // email        用户登录的邮箱名 
    // password     用户密码 
  
    var data = querystring.stringify({ 
        app_name: app_name, 
        version: version, 
        email: email, 
        password: password 
    }); 
  
    var options = { 
        host: 'www.douban.com', 
        port: 80, 
        path: '/j/app/login', 
        method: 'POST', 
        headers: { 
            'Content-Type': 'application/x-www-form-urlencoded', 
            'Content-Length': data.length 
        } 
    }; 
    var http=require("http"); 
    var proxy = http.request(options, function(response) { 
        response.setEncoding('utf8'); 
        response.on('data', function (chunk) { 
            var headers=res.headers; 
            res.setHeader('Access-Control-Allow-Origin' , '*'); 
            res.setHeader('Access-Control-Allow-Headers' , 'X-Requested-With'); 
            res.setHeader('Content-Type', 'application/json; charset=utf-8'); 
            res.send(chunk) 
        }); 
    }); 
    proxy.write(data); 
    proxy.end(); 
    //res.send(req.body.version); 
}; 
exports.playlist = function(req, res){ 
    var url = require("url"); 
    requrl = url.parse(req.url, true).query; 
    var app_name = requrl.app_name 
        , version = requrl.version 
        , email = requrl.email 
        , password = requrl.password 
        , user_id = requrl.user_id 
        , expire =  requrl.expire
        , token = requrl.token 
        , sid = requrl.sid 
        , h = requrl.h 
        , from = requrl.from
        , channel = requrl.channel 
        , type = requrl.type 
        , querystring = require('querystring') 
        , host = "www.douban.com"; 
        console.log() 
    // url http://www.douban.com/j/app/radio/people 
    // app_name 必选  string  radio_desktop_win 
    // version  必选  int     100 
    // user_id  非必选 string  user_id 
    // expire   非必选 int     expire 
    // token    非必选 string  token 
    // sid      非必选 int     song id 
    // h        非必选 string  最近播放列表 
    // channel  非必选 int     频道id 
    // type     必选  string  报告类型 
  
    var data = querystring.stringify({ 
        app_name:app_name, 
        version:version, 
        user_id:user_id, 
        expire:expire, 
        token:token, 
        sid:sid, 
        h:h, 
        channel:channel, 
        type:type, 
    }); 
    console.log(data); 
  
    var options = { 
        host: 'www.douban.com', 
        port: 80, 
        path: '/j/app/radio/people?'+data, 
        method: 'GET', 
        headers: { 
            'Content-Type': 'application/x-www-form-urlencoded', 
            'Content-Length': data.length 
        } 
    }; 
    res.setHeader('Access-Control-Allow-Origin' , '*'); 
    res.setHeader('Access-Control-Allow-Headers' , 'X-Requested-With'); 
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    var result;
    var http=require("http"); 
    var proxy = http.request(options, function(response) { 
        response.setEncoding('utf8'); 
        response.on('data', function (chunk) {
            console.log(chunk);
            result=chunk;
            // res.end(chunk);
            // res.end(result)
            res.write(chunk);
        }); 
        response.on('end', function (chunk){
            console.log(chunk);
            res.end();
            console.log("send!");
        })
    }); 
    proxy.write(data); 
    proxy.end(); 
}