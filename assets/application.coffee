#$('input[type=range]').on('input', function(e){
#    var min = e.target.min,
#    max = e.target.max,
#    val = e.target.value;
#
#  $(e.target).css({
#    'backgroundSize': (val - min) * 100 / (max - min) + '% 100%'
#  });
#}).trigger('input');

plyr.setup({});

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

apiHost = "http://www.douban.com"
apiHost = "http://localhost:8080"
CHANNELS_URL = apiHost + "/j/app/radio/channels"
AUTH_URL = apiHost + "/j/app/login"
PLAYLIST_URL = apiHost + "/j/app/radio/people"

Application = class Application

  constructor: ()->

  fetchChannels: ()->
    $.ajax(CHANNELS_URL)

  login: (email, password)->
    self = @
    defer = new Q.defer()
    app_name = "radio_desktop_win"
    version = 100
    if not email or not password then return false
    $.post( AUTH_URL, { app_name, version, email, password}).done (result)->
      console.log result
      if result.r
        defer.reject(result.err)
      else
        self.setToken()
        defer.resolve(result)




new Application().login("houshoushuai@gmail.com", "houshuai")
