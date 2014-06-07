define ['Backbone',"$"], (Backbone, $)->
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

        fetch: (option)=>
            console.debug 'Begin to Fetch......'
            data =
                app_name: "radio_desktop_win"
                version: 100
                channel: option.channel || 1
                type: option.type
                from: 'mainsite'
                r: Math.floor(Math.random()*10000000)
            if option.isLogin
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
                error: ->
                    console.error "Error While Geting Song list.", arguments
                    @trigger 'update'
            .done ()->
                console.debug 'Fetch finished!'

    class SongView extends Backbone.View
        initialize: ()->
            @initPlayer()
        initPlayer: ()->
        collection: SongCollection





