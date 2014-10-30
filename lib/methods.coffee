Meteor.methods

  getWordAnalysisJUMAN: (splitText) ->
    if Meteor.isServer
      # Meteor.setTimeout ->
      #   JUMANRequest(splitText)
      # ), 1000
      wordAnalysisJUMAN = []
      for text in splitText
        rawHTML = JUMANRequest(text)
        wordAnalysisJUMAN = wordAnalysisJUMAN.concat parseWordAnalysisJUMAN rawHTML.result

      console.log 'Complete: ', wordAnalysisJUMAN
      WordAnalysis.update {}, {wordAnalysisJUMAN}




@JUMANRequest = (text) ->
  rawHTML = Async.runSync((done) ->
    curl.request
      url: 'http://lotus.kuee.kyoto-u.ac.jp/nl-resource/cgi-bin/juman.cgi'
      method: 'POST'
      headers: {'Content-Type': 'multipart/form-data; boundary=----WebKitFormBoundary0nt15XdlaADQJWTe'}
      'data-binary': '------WebKitFormBoundary0nt15XdlaADQJWTe\r\nContent-Disposition: form-data; name="sentence"\r\n\r\n' + text + '\r\n------WebKitFormBoundary0nt15XdlaADQJWTe\r\nContent-Disposition: form-data; name="Execute"\r\n\r\nExecute\r\n------WebKitFormBoundary0nt15XdlaADQJWTe--\r\n'
      verbose: true
    , (err, stdout, meta) ->
      console.log "%s %s", meta.cmd, meta.args.join(" ")
      console.log "Err: ", err if err
      console.log "Stdout: ", stdout if stdout
      done err, stdout
  )