#$ = jQuery = require('./assert/jquery-1.11.2.min.js');
plyr.setup();

__  = (val)-> "\n--------------------------#{val}----------------------------"

window.player = document.querySelectorAll(".player")[0].plyr;

$(".player-volume").on "input", (e)->
  min = e.target.min
  max = e.target.max
  val = e.target.value
  $(e.target).css({
    "backgroundSize": (val - min) * 100 / (max - min) + "% 100%"
  })
.trigger('input')

API_HOST = "http://www.douban.com"

#API_HOST = "http://127.0.0.1:8080"

CHANNELS_URL = API_HOST + "/j/app/radio/channels"
AUTH_URL = API_HOST + "/j/app/login"
PLAYLIST_URL = API_HOST + "/j/app/radio/people"

app_name = "radio_desktop_win"
version = 100

Application = class Application

  constructor: ()->
    @channel = 0
    @user_id = localStorage.getItem("user_id")
    @token = localStorage.getItem("token")
    @expire = localStorage.getItem("expire")
    @email = localStorage.getItem("email")
    @user_name = localStorage.getItem("user_name")
    @sid = null
    @playlist = []
    @song = null
    player.media.addEventListener 'ended', ()=>
      @ended()

    player.media.addEventListener 'canplay', ()=>
      console.log  "Can Play"
      @hideLoading()

    $(".album img").load ()->
      $(this).addClass('show')

    $("img").trigger('load')
    @initSidebar()

    $("button.button.login").click ()=>
      @login()

    $("button.button.logout").click ()=>
      @logout()

    $(".icon").bind "webkitAnimationEnd mozAnimationEnd animationEnd", ()->
      $(this).removeClass("animated")

    $(".icon").click ()->
      $(this).addClass("animated")

    @registerShortCut()

  initSidebar: ()->
    self = @
    console.log "Fetching channels"
    $.ajax(CHANNELS_URL).done (result)->
      console.log result
      channels = result.channels
      if self.user_id and self.token and self.expire
        self.getUserInfo().done ()->
          $(".channels").removeClass("hide")
          $(".sidebar .loading").addClass("hide")
      else
        $(".channels").removeClass("hide")
        $(".sidebar .loading").addClass("hide")
      $channels = $(".channels ul")
      channels.forEach (channel)->
        $("<li data-id='#{channel.channel_id}'>#{channel.name}</li>").appendTo($channels).click (e)->
          id = $(e.currentTarget).data("id")
          self.switchChannel(id)
      $(".channels").find("li[data-id='#{self.channel}']").addClass("active")


      $channels.find("[data-id='#{@channel}']").addClass("active")

  getUserInfo:()->
    self = @
    $(".sidebar .login-form").addClass("hide")
    $(".sidebar .loading").removeClass("hide")
    @user_id = localStorage.getItem("user_id")
    console.log "Getting User Data"
    $.get("https://api.douban.com/v2/user/#{@user_id}?apikey=0776da5f62da51f816648f1e288ef5e8").done (result)->
      console.log "Got user info."
      $(".user-name").text(result.name)
      $(".user-desc").text(result.signature || result.desc)
      $(".avatar").css("background-image", "url(#{result.large_avatar})")
      $(".sidebar .loading").addClass("hide")
      $(".sidebar .user").removeClass("hide")
    .fail (err)->
      console.log JSON.stringify err
#      self.logout()

  login: ()->
    email = $("#user-email").val()
    password = $("#user-password").val()
    $(".sidebar .loading").removeClass("hide")
    $(".login-form").addClass("hide")
    self = @
    defer = new Q.defer()
    if not email or not password
      @logout()
      defer.reject({err: "Both email and password are needed!"})
    else
      console.log "Logging in..."
      $.post( AUTH_URL, { app_name, version, email, password}).done (result)->
        console.log result
        if result.r
          defer.reject(result.err)
          self.logout()
        else
          self.user_id = result.user_id
          self.token = result.token
          self.expire = result.expire
          self.email = result.email
          self.user_name = result.user_name

          localStorage.setItem("user_id", self.user_id)
          localStorage.setItem("token", self.token)
          localStorage.setItem("expire", self.expire)
          localStorage.setItem("email", self.email)
          localStorage.setItem("user_name", self.user_name)

          console.log "Fetching user...."

          self.getUserInfo()

          defer.resolve(result)
    defer.promise

  logout: ()->
    @user_id = null
    @token = null
    @expire = null
    @email = null
    @user_name = null

    localStorage.removeItem("user_id")
    localStorage.removeItem("token")
    localStorage.removeItem("expire")
    localStorage.removeItem("email")
    localStorage.removeItem("user_name")

    $(".login-form").removeClass("hide")
    $(".user").addClass('hide')
    $(".sidebar .loading").addClass("hide")

  fetchSong: (type = "n", shouldPlay, sid)->
    console.log "Fetching"
    self  = @
    defer = new Q.defer()
    if type not in ["b","e","n","p","s","r","s","u"]
      defer.reject({err: "Type Error!"})
    else
      channel = @channel
      data = {app_name, version, type, channel}
      if @user_id and @token and @expire
        data.user_id = @user_id
        data.token = @token
        data.expire = @expire

      unless type is "n" # Don't need sid.
        data.sid = @sid

      if type is 'e'
        data.sid = sid

      $.get(PLAYLIST_URL, data).done (result)->
        console.log "Fetched...."

        if type is 'e'
          return false

        if result.r
          defer.reject(result.err)
        else
          if result.song
            self.playlist = result.song
          else
            console.log "------------------"
            console.log JSON.stringify result
          if shouldPlay
            self.play(result.song[0])
          defer.resolve(result.song)

    defer.promise

  play: (song)->
    console.log "play"
    if not song
      player.play()
    else
      @applyHeart(song)
      player.source(song.url)
      @sid = song.sid
      @song = song
      player.play()
      @setAlbum(song)

  setAlbum: (song)->
    pic = song.picture.replace("mpic", 'lpic')
    $(".album img").attr('src', pic)
    $(".information .title").text(song.title)
    $(".information .artist").text(song.artist)
    $(".information .album-title").text(song.albumtitle)

  applyHeart: (song)->
    star = !!song.like
    $(".player").toggleClass("like", star)

  next: (type = "p")->
    @showLoading()
    self = @
    $(".player-progress-seek").val(0)
    playedHalf = player.media.duration and player.media.currentTime / player.media.duration > 0.5
    console.log player.media.duration
    if playedHalf
      @sendRecord(@sid)
    if @playlist.length
      @play @playlist.pop()
    else
      @fetchSong(type).then ()->
        self.next()
      , (err)->
        console.log err

  heart: ()->
    @fetchSong("r")

  unheart: ()->
    @fetchSong("u")

  toggleHeart: ()->
    self = @
    hasLike = $("#player").hasClass("like")
    promise = if hasLike then @unheart() else @heart()
    sid = @sid
    promise.then ()->
      if sid is self.sid
        $("#player").toggleClass("like",!hasLike)

  sendRecord: (sid)->
    console.log sid
    @fetchSong('e', null, sid)

  block: ()->
    player.pause()
    @fetchSong("b", true)

  skip: ()->
    @next()

  ended: ()->
    @next()

  openLink: ()->
    if @song
      require('shell').openExternal( "http://music.douban.com#{@song.album}" )
    return false

  switchChannel: (id)->
    @channel = id
    @playlist = []
    $(".channels").find("li.active").removeClass("active")
    $(".channels").find("li[data-id='#{@channel}']").addClass("active")
    player.pause()
    @next()

  showLoading: ()->
    $(".album .loading").addClass("show")
    $(".album .img").removeClass("show")

  hideLoading: ()->
    $(".album .loading").removeClass("show")

  playOrPause: ()->
    isPlaying = $(".player").hasClass("playing")
    if isPlaying
      player.pause()
    else
      player.play()

  registerShortCut: ()->
    self = @
    globalShortcut = require('remote').require 'global-shortcut'
    ret1 = globalShortcut.register("MediaPlayPause", ()-> self.playOrPause())
    ret2 = globalShortcut.register("MediaNextTrack", ()-> self.next())
    ret3 = globalShortcut.register("MediaPreviousTrack", ()-> self.heart())

    if ret1 and ret2 and ret3
      console.log __ "Register Success! "
    else
      console.log __ "Register Failed....."
      console.log ret1, ret1, ret3


fm = new Application()
fm.next('n')

$(".album .info").click ()-> fm.openLink()
$(".album .close").click ()-> window.close()
$(".album .menu").click ()->
  $(".wrapper").toggleClass("open");
  remote = require('remote');
  expand = $(".wrapper").hasClass("open")
  width = if expand then 650 else 450
  BrowserWindow = remote.require('browser-window');
  mainWindow = BrowserWindow.getFocusedWindow();
  if expand
    if window._delay
      window.clearTimeout( window._delay )
    mainWindow.setSize(width, 550);
  else
    window._delay = window.setTimeout ()->
      mainWindow.setSize(width, 550)
    , 300
$(".controls .icon.play").click ()-> fm.playOrPause()
$(".controls .icon.next").click ()-> fm.next()
$(".controls .icon.heart").click ()-> fm.toggleHeart()
$(".controls .icon.trash").click ()-> fm.block()

