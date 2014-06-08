define ['Backbone',"jquery","underscore"], (Backbone, $, _)->
    BASEURL     = "http://www.douban.com/j/app/radio/people"
    SONGINFOURL = "http://music.douban.com/api/song/info?song_id="
    LOGINURL    = "http://www.douban.com/j/app/login"

    # DEVELOP ENV
    BASEURL     = "http://127.0.0.1:2222/j/app/radio/people"
    LOGINURL    = "http://127.0.0.1:2222/j/app/login"
    SONGINFOURL = 'http://127.0.0.1:3333/api/song/info?song_id='
    #require('nw.gui').Window.get().showDevTools()

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
            if option?.sid
                data.sid = option.sid
            console.debug data
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
            .done

    class SongView extends Backbone.View
        constructor: ()->
            @collection = new SongCollection
            console.debug @collection
            @initPlayer()
            @option = {}
            @collection.on 'update', ()->
                @render()
            ### Global handler ###
            window.next = ()=>
                @next()
            window.unlike = ()=>
                @unlike()
            window.like = ()=>
                @like()
            window.skip = ()=>
                @skip()
            window.trash = ()=>
                @trash()
            ### Global handler end ###

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
            @next(option)

        next: (option)->
            console.log ("Next....")
            if @noMoreSong() or option.fetch
                if option?.type is 'p'
                    @history = []
                @collection.fetch(option) ()=>
                    if not @noMoreSong()
                        @currentSong = @newSong()
                        if not @currentSong then return false
                        @play @currentSong.toJSON()
                    else
                        console.error 'No more song ???? WTF!!!'

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
            @collection.fetch(_.extend (_.clone @option), {type : "r", sid: @currentSong?.get('sid')})

        unlike: ->
            @markSong('u')
            @collection.fetch(_.extend (_.clone @option), {type : "u", sid: @currentSong?.get('sid')})

        trash: ->
            @markSong('b')
            @next(_.extend (_.clone @option), {fetch: true, type: "b", sid: @currentSong?.get('sid')})
            console.log @collection.length, "Before Remove"
            @collection.find(@currentSong).remove()
            console.log @collection.length, "After Remove"

        skip: ->
            @markSong('s')
            @next()

        login: ->
            if @email and @password
                data =
                    app_name: "radio_desktop_win"
                    version: "100"
                    email: @email
                    password: @password
                $.ajax
                    url: LOGINURL
                    type: "POST"
                    dataType: 'json'
                    data: data
                    success: (data)=>
                        console.log data
                        if not data.r
                            @user.user_name = data.user_name
                            @user.user_id   = data.user_id
                            @user.token     = data.token
                            @user.expire    = data.expire
                            @option.user_id = data.user_id
                            @option.expire  = data.expire
                            @option.token   = data.token
                            @trigger 'login', data

                        else
                            @trigger 'loginfailed'
                            console.error(data)
