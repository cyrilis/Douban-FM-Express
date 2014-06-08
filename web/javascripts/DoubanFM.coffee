define ['Backbone',"jquery","underscore"], (Backbone, $, _)->
    BASEURL = "http://www.douban.com/j/app/radio/people"

    # DEVELOP ENV
    BASEURL = "http://127.0.0.1:2222/j/app/radio/people"

    class SongModel extends Backbone.Model
        default:
            album   : ""
            picture : ""
            ssid    : ""
            artist  : ""
            url     : ""
            company : ""
            title   : ""
            rating_avg: 0
            length  : 0
            subtype : ""
            public_time: ""
            sid     : ""
            aid     : ""
            kbps    : ""
            albumtitle: ""
            like    : 0

    class SongCollection extends Backbone.Collection
        model: SongModel

        fetch: (option)->
            console.debug 'Begin to Fetch......'
            data =
                app_name: "radio_desktop_win"
                version: 100
                channel: option?.channel || 1
                type: option?.type||"n"
                from: 'mainsite'
                r: Math.floor(Math.random()*10000000)
            if option?.user_id
                _.extend data, {
                    user_id: option.user_id
                    expire: option.expire
                    token: option.token
                    channel: option.channel || 0
                }
            $.ajax
                url: BASEURL
                type: "GET"
                dataType: "json"
                data: data
                success: (data)=>
                    if data.r is 0 and data.song
                        songs = _.clone data.song
                        _.map songs, (song)->
                            song.picture = song.picture.replace /\/mpic\//, 'lpic'
                            return song
                        console.debug songs
                        @set songs
                        console.log @models
                    else if data.r
                        console.debug data

                error: ->
                    console.error "Error While Geting Song list.", arguments
                    @trigger 'update'
            .done

    class SongView extends Backbone.View
        constructor: ()->
            @collection = new SongCollection
            console.debug @collection
            @initPlayer()
        initPlayer: ()->
            @player = $("<iframe id='player'></iframe>").appendTo("body").contents().find('body').append('<audio id="core" src=""></audio>').find('#core')
            @next()
        next: (option)->
            if @noMoreSong()
                @collection.fetch() ()=>
                    if not @noMoreSong()
                        @currentSong = _.clone @newSong()
                        if not @currentSong then return false
                        @play @currentSong
            else
                @currentSong = _.clone @newSong()
                if not @currentSong then return false
                @play @currentSong

        noMoreSong: ->
            if not @collection.models.length
                return true
            else if @currentSong and (@collection.indexOf @currentSong) is @collection.models.length
                return true
            else return false

        play: (song)->
            console.log "Now Playing:","\n", song
            @player.attr 'src', song.url
            @player[0].play()

        newSong: ->
            if @currentSong
                index = @collection.indexOf @currentSong
                newSong = @collection.index(index+1)
                return if newSong then newSong else console.debug "No Song.... Totally."
            else
                @collection.toJSON()[0]





