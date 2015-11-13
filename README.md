Douban-FM-Express
==================

###Declaration: Deprecated due to the api change of http://douban.fm

-----

DoubanFM Desktop Client Powered by Atom-shell.

More info:  http://cyrilis.com/posts/another-doubanfm-implementation

[Updated: 2015-03-22]
> Changed from Node-webkit to Atom-shell.

Features: 
-----------
* User login
* Star / Unstar / Trash songs.
* Draggable progress bar.
* Change channels.
* Global short cuts. ( Play/pause, next, Star[via press previous media key])

Screenshot:
-----------
<a href="http://s3.again.cc/capture/2015-04-19_233548.png" target="_blank" title="点击查看大图"><img src="http://s3.again.cc/capture/2015-04-19_233548.png" style="width: 430px" alt="DoubanFM screenshot-1"></a>
<a href="http://s3.again.cc/capture/2015-04-19_234127.png" target="_blank" title="点击查看大图"><img src="http://s3.again.cc/capture/2015-04-19_234127.png" style="width: 320px" alt="DoubanFM screenshot-1"></a>
<video id="video1" style="width: 100%" loop="loop" autoplay>
    <source src="http://s3.again.cc/capture/DoubanFM-2015-04-19.mp4" type="video/mp4">
</video>

Dependencies:
-----------
`atom-shell` is needed to run this project in dev mode. or you can download release for Mac at release page.

```shell
	sudo npm install atom-shell -g
```


Usage(Develop):
-----------
```shell

   git clone git@github.com:cyrilis/Douban-FM-Express.git

   cd Douban-FM-Express
   
   atom-shell .

   # Here we go!
```
Usage(Production):
-----------

Download Mac binary file from [release page](https://github.com/cyrilis/Douban-FM-Express/releases). run DoubanFM.app.

Todo:
-----------
* Show lyrics and album and artist info in side panel.
* Desktop Lyrics.

-----------
Thanks:
-----------
https://github.com/atom/atom-shell

http://douban.fm
