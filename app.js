var server = require('http');
var remoteServer = 'www.douban.com';
var http = require('http');
server.createServer(function(q,s){
//    console.dir(q);
    var headers = q.headers;
    headers.host = remoteServer;
    q.method === "GET" ? delete  headers['Content-length']: console.log('Content-length:',headers['Content-lenght']);
    var options = {
        hostname: remoteServer,
        host: remoteServer,
        path: q.url,
        port: 80,
        method: q.method,
        headers: headers
    };

//    console.log(options);
    var request = http.request(options, function(res){
        console.log(options.hostname+options.path);
        res.setEncoding('binary');
        s.setHeader("Access-Control-Allow-Origin", "*");
        s.setHeader("Access-Control-Allow-Headers", "X-Requested-With");
        s.writeHead(res.statusCode,res.headers);

        res.on('data', function (chunk) {
            s.write(chunk,'binary');
        });

        res.on('end', function(){
            s.end();
            request.end();
        });
        res.on('error', function ( e ){
            console.log( 'Error with client ', e );
            request.end();
            console.log('===================================DATA-ERROR===================================');
        });
    });

    request.on('error', function(e) {
        console.log(e);
        s.end('<h1>ERROR WHILE REQUEST REMOTE URL... =_=</h1>');
        console.log('===================================REQUEST-ERROR======================================');
    });

    request.write('\n');
    var request_data = "";
    q.on('data', function ( chunk ){
        console.log( 'Write to server ', chunk.length );
        console.log( chunk.toString( 'utf8' ) );
        request_data = request_data + chunk;
        request.write( chunk, 'binary' );
    } );

    q.on( 'end', function(){
        console.log( 'End chunk write to server' );
    } );

    q.on( 'error', function ( e ){
        console.log( 'Problem with request ', e );
    } );

}).listen(9000);
console.log( 'Proxy started on port ' + 9000 );


//var req = http.request(options, function(res) {
//    console.log('STATUS: ' + res.statusCode);
//    console.log('HEADERS: ' + JSON.stringify(res.headers));
//    res.setEncoding('utf8');
//    res.on('data', function (chunk) {
//        console.log('BODY: ' + chunk);
//    });
//});
//
//req.on('error', function(e) {
//    console.log('problem with request: ' + e.message);
//});
//
//// write data to request body
//req.write('data\n');
//req.write('data\n');
//req.end();