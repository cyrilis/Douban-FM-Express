#$ = jQuery = require('./assert/jquery-1.11.2.min.js');
plyr.setup();

player = document.querySelectorAll(".player")[0].plyr;
player.play()

$(".player-volume").on "input", (e)->
  min = e.target.min
  max = e.target.max
  val = e.target.value
  $(e.target).css({
    "backgroundSize": (val - min) * 100 / (max - min) + "% 100%"
  })
.trigger('input')

# Bind Click pause

$(".controls .icon.play").click ()-> player.play()
$(".controls .icon.pause").click ()-> player.pause()

API_HOST = "http://www.douban.com"
#API_HOST = "http://localhost:8080"

CHANNELS_URL = API_HOST + "/j/app/radio/channels"
AUTH_URL = API_HOST + "/j/app/login"
PLAYLIST_URL = API_HOST + "/j/app/radio/people"

app_name = "radio_desktop_win"
version = 100

Application = class Application

  constructor: ()->
    @channel = 1
    @user_id = null
    @token = null
    @expire = null
    @email = null
    @user_name = null
    @sid = null
    @history = []

  fetchChannels: ()->
    $.ajax(CHANNELS_URL)

  login: (email, password)->
    self = @
    defer = new Q.defer()
    if not email or not password
      defer.reject({err: "Both email and password are needed!"})
    else
      $.post( AUTH_URL, { app_name, version, email, password}).done (result)->
        console.log result
        if result.r
          defer.reject(result.err)
        else
          self.user_id = result.user_id
          self.token = result.token
          self.expire = result.expire
          self.email = result.email
          self.user_name = result.user_name

          defer.resolve(result)
    defer.promise

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

      unless type in ["n", "p"] # Don't need sid.
        data.sid = @sid

      if type is "p"
        data.h = @getHistory()

      $.get(PLAYLIST_URL, data).done (result)->
        console.log "Fetched...."
        if result.r
          defer.reject(result.err)
        else
          self.songList = result.song
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
      @toggleStar(song)
      player.source(song.url)
      @sid = song.sid
      @song = song
      player.play()
      @setAlbum(song)

  setAlbum: (song)->
    pic = song.picture.replace("mpic", 'lpic')
    $(".album img").attr('src', pic)

  toggleStar: (song)->
    star = !!song.like
    $(".player").toggleClass("like", star)



d = new Application()
d.fetchSong("n", true)
