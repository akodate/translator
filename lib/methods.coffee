Meteor.methods

  test: () ->
    console.log 'Testing stuff'

  getWordAnalysisJA: (string) ->
    if Meteor.isServer
      rawHTML = Async.runSync((done) ->
        curl.request
          url: 'http://lotus.kuee.kyoto-u.ac.jp/nl-resource/cgi-bin/juman.cgi'
          method: 'POST'
          headers: {'Content-Type': 'multipart/form-data; boundary=----WebKitFormBoundary0nt15XdlaADQJWTe'}
          'data-binary': '------WebKitFormBoundary0nt15XdlaADQJWTe\r\nContent-Disposition: form-data; name="sentence"\r\n\r\n' + string + '\r\n------WebKitFormBoundary0nt15XdlaADQJWTe\r\nContent-Disposition: form-data; name="Execute"\r\n\r\nExecute\r\n------WebKitFormBoundary0nt15XdlaADQJWTe--\r\n'
          verbose: true
          pretend: false
        , (err, stdout, meta) ->
          console.log "%s %s", meta.cmd, meta.args.join(" ")
          console.log "Err: ", err if err
          # console.log "Stdout: ", stdout if stdout
          done err, stdout
      )
      console.log rawHTML.result
      parsedWordArray = parseWordAnalysis rawHTML.result
      console.log 'complete', parsedWordArray
      WordAnalysis.update {}, {parsedWordArray}
      console.log WordAnalysis.findOne()
      return parsedWordArray