JUMAN_HTML_REGEX = new RegExp /<pre>([^]*)\nEOS/
JUMAN_MATCHES = new RegExp '(^|\\n)(.*?)(?=\\s)', 'g'

WordAnalysis.remove({})
WordAnalysis.insert({})

@parseWordAnalysis = (rawHTML) ->
  resultsSection = rawHTML.match(JUMAN_HTML_REGEX)[1]
  # console.log "Result: "
  # console.log resultsSection
  wordArr = getWordArray(resultsSection)
  # console.log WordAnalysis.find().fetch()

getWordArray = (resultsSection) ->
  wordArr = []
  while match = JUMAN_MATCHES.exec resultsSection
    wordArr.push match[2]
  console.log "Results: "
  console.log wordArr.join('')
  wordArr

console.log process.env
console.log '*****************************************************************************************'

curl = Meteor.npmRequire('curlrequest')

rawHTML = Async.runSync((done) ->
  curl.request
    url: 'http://lotus.kuee.kyoto-u.ac.jp/nl-resource/cgi-bin/juman.cgi'
    method: 'POST'
    headers: {'Content-Type': 'multipart/form-data; boundary=----WebKitFormBoundary0nt15XdlaADQJWTe'}
    'data-binary': '------WebKitFormBoundary0nt15XdlaADQJWTe\r\nContent-Disposition: form-data; name="sentence"\r\n\r\n\u306a\u3093\u3067\u3060\u3088\r\n------WebKitFormBoundary0nt15XdlaADQJWTe\r\nContent-Disposition: form-data; name="Execute"\r\n\r\nExecute\r\n------WebKitFormBoundary0nt15XdlaADQJWTe--\r\n'
    verbose: true
    pretend: false
  , (err, stdout, meta) ->
    # console.log "%s %s", meta.cmd, meta.args.join(" ")
    console.log "Err: ", err if err
    # console.log "Stdout: ", stdout if stdout
    done err, stdout
)
console.log rawHTML.result
parsedWordArray = parseWordAnalysis rawHTML.result
console.log 'complete', parsedWordArray
WordAnalysis.update {}, {parsedWordArray}
console.log WordAnalysis.findOne()


Meteor.methods

  test: () ->

    return "succeeded"








#declare a simple async function
@delayedMessage = (delay, message, callback) ->
  console.log 'Executing delayedMessage'
  setTimeout (->
    callback null, message
  ), delay

#wrapping
@wrappedDelayedMessage = Async.wrap(delayedMessage)

#usage
Meteor.methods delayedEcho: (message) ->
  console.log 'Executing delayedEcho'
  response = wrappedDelayedMessage(500, message)
  return response

console.log Meteor.call 'delayedEcho', 'sample message'



response = Async.runSync((done) ->
  setTimeout (->
    done null, 1001
  ), 100
)
console.log response.result # 1001

