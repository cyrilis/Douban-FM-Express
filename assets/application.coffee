#$ = jQuery = require('./assert/jquery-1.11.2.min.js');
plyr.setup();

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
    @channel = 1
    @user_id = localStorage.getItem("user_id")
    @token = localStorage.getItem("token")
    @expire = localStorage.getItem("expire")
    @email = localStorage.getItem("email")
    @user_name = localStorage.getItem("user_name")
    @sid = null
    @history = []
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

  initSidebar: ()->
    console.log "Fetching channels"
    $.ajax(CHANNELS_URL).done (result)->
      console.log result
      channels = result.channels
      $(".channels").removeClass("hide")
      $(".sidebar .loading").addClass("hide")
      $channels = $(".channels ul")
      channels.forEach (channel)->
        $("<li data-id='#{channel.channel_id}'>#{channel.name}</li>").appendTo($channels)

      $channels.find("[data-id='#{@channel}']").addClass("active")

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
          $.get("https://api.douban.com/v2/user/#{self.user_id}").done (result)->
            console.log "Got user info."
            $(".user-name").text(result.name)
            $(".user-desc").text(result.signature || result.desc)
            $(".avatar").attr("src", result.avatar)
            $(".sidebar .loading").addClass("hide")
            $(".sidebar .user").removeClass("hide")

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

  fetchSong: (type = "n", shouldPlay)->
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

      if type is "p"
        data.h = @getHistory()

      $.get(PLAYLIST_URL, data).done (result)->
        console.log "Fetched...."
        if result.r
          defer.reject(result.err)
        else
          if type is 'p'
            self.clearHistory()
          self.playlist = result.song
          if shouldPlay
            self.play(result.song[0])
          defer.resolve(result.song)

    defer.promise

  addHistory: (sid, type)->
    @history.push("#{sid}:#{type}")

  getHistory: ()->
    "|" + @history.join("|")

  clearHistory: ()->
    @history = []

  play: (song)->
    console.log "play"
    if not song
      player.play()
    else
      @applyHeart(song)
      player.source(song.url)
      if @sid
        @addHistory(@sid, "e")
      @sid = song.sid
      @song = song
      player.play()
      @setAlbum(song)

  setAlbum: (song)->
    pic = song.picture.replace("mpic", 'lpic')
    $(".album img").attr('src', pic)

  applyHeart: (song)->
    star = !!song.like
    $(".player").toggleClass("like", star)

  next: (type = "e")->
    @showLoading()
    self = @
    $(".player-progress-seek").val(0)
    playedHalf = player.media.duration and player.media.currentTime / player.media.duration > 0.5
    console.log player.media.duration
    if playedHalf
      @addHistory(@sid,type)
    if @playlist.length
      @play @playlist.pop()
    else
      @fetchSong(type).then ()->
        self.clearHistory()
        self.next()
      , (err)->
        console.log err

  heart: ()->
    @fetchSong("r")

  unheart: ()->
    @fetchSong("u")

  toggleHeart: ()->
    hasLike = $("#player").hasClass("like")
    promise = if hasLike then @unheart() else @heart()
    promise.then ()->
      $("#player").toggleClass("like",!hasLike)

  block: ()->
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
    @next()

  showLoading: ()->
    $(".album .loading").addClass("show")
    $(".album .img").removeClass("show")

  hideLoading: ()->
    $(".album .loading").removeClass("show")

fm = new Application()
fm.next('n')

# Bind Click pause
$(".album .info").click ()-> fm.openLink()
$(".album .close").click ()-> window.close()
$(".album .menu").click ()->
  $(".wrapper").toggleClass("open");
  width = if $(".wrapper").hasClass("open") then 650 else 450
#  remote = require('remote');
#  BrowserWindow = remote.require('browser-window');
#  mainWindow = BrowserWindow.getFocusedWindow();
#  mainWindow.setSize(width, 550);
$(".controls .icon.play").click ()-> player.play()
$(".controls .icon.pause").click ()-> player.pause()
$(".controls .icon.next").click ()-> fm.next()
$(".controls .icon.heart").click ()-> fm.toggleHeart()
$(".controls .icon.trash").click ()-> fm.block()

