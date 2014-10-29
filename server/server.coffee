JUMAN_HTML_REGEX = new RegExp /<pre>([^]*)\nEOS/
JUMAN_MATCHES = new RegExp '(^|\\n)(.+?)(?=\\s)', 'g'

WordAnalysis.remove({})
WordAnalysis.insert({})

console.log process.env
console.log '*****************************************************************************************'

@curl = Meteor.npmRequire('curlrequest')




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