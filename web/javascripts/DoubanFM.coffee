define ['Backbone',"jquery","underscore"], (Backbone, $, _)->
    BASEURL = "http://www.douban.com/j/app/radio/people"

    SONGINFOURL = "http://music.douban.com/api/song/info?song_id="

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

            if option and option.type is 'p'

                data.h = option.h

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
                        @add songs
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
            @option = {}
            window.next = ()=>
                @next()
            window.collection = @collection
        initPlayer: ()->
            @player = $("<iframe id='player'></iframe>").appendTo("body").contents().find('body').append('<audio id="core" src=""></audio>').find('#core')
            @player.on 'ended', ()=>
                @sendHistory()
            @next()
        sendHistory: ->
            option = {}
            if @currentSong
                @markSong('e')
                option.type = "p"
                option.h = _.map @history, (e,index)->
                    "|#{e.sid}:#{e.type}"
                option.h = option.h.join("")
                option.sid = @currentSong.get 'sid'
                @history = []
            console.debug option
            @next(option)

        next: (option)->
            console.log ("Next....")
            if @noMoreSong() or option
                @collection.fetch(option) ()=>
                    if not @noMoreSong()
                        @currentSong = @newSong()
                        if not @currentSong then return false
                        @play @currentSong.toJSON()
                null
            else
                @currentSong = @newSong()
                if not @currentSong
                    console.error "No song?"
                    return false
                @play @currentSong.toJSON()

        noMoreSong: ->
            if not @collection.models.length
                return true
            else if @currentSong and (@collection.indexOf @currentSong) is (@collection.models.length-1)
                return true
            else return false

        history: []

        play: (song)->
            if not song.url
                song = song.toJSON()
            console.log "Now Playing:","\n", song
            @player.attr 'src', song.url
            @player[0].play()

        newSong: ->
            if @currentSong and not @currentSong.get('type')
                @markSong('s')
                console.log @currentSong.get('type'), 'Marked Current Song', @currentSong.toJSON()
            if @currentSong
                index = @collection.indexOf @currentSong
                if index < 0
                    console.log @currentSong, @collection
                    console.debug "Not in the queue."
                    return @collection.at(0)
                newSong = @collection.at(index+1)
                return if newSong then newSong else console.debug "No Song.... Totally."
            else
                @collection.at(0)
        markSong: (type)->
            if @currentSong.get 'type'
                return false
            @currentSong.set('type', type)
            @history.push @currentSong.toJSON()
        like: ->
            @markSong('r')
            @next(_.extend (_.clone @option), {type : "r", sid: @currentSong?.get('sid')})

        unlike: ->
            @markSong('u')
            @next(_.extend (_.clone @option), {type : "u", sid: @currentSong?.get('sid')})

        trash: ->
            @markSong('b')
            @next(_.extend (_.clone @option), {type : "b", sid: @currentSong?.get('sid')})

        skip: ->
            @markSong('s')
            @next()



