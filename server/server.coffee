JUMAN_HTML_REGEX = new RegExp /<pre>([^]*)\nEOS/
JUMAN_MATCHES = new RegExp '(^|\\n)(.*?)(?=\\s)', 'g'

WordAnalysis.insert({})

console.log process.env
console.log '*****************************************************************************************'

curl = Meteor.npmRequire('curlrequest')

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
  parseWordAnalysis(stdout)




Meteor.methods

  test: () ->

    return "succeeded"




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
