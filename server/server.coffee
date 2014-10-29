JUMAN_HTML_REGEX = new RegExp /<pre>([^]*)\nEOS/
JUMAN_MATCHES = new RegExp '(^|\\n)(.+?)\\s(.+?)\\s(.+?)\\s(.+?)\\s(.+?)\\s(.+?)(?=\\s)', 'g'
JUMAN_EXTRA_MATCHES = new RegExp '\\n@.+?(?=\\n)', 'g'

WordAnalysis.remove({})
WordAnalysis.insert({})

console.log process.env
console.log '*****************************************************************************************'

@curl = Meteor.npmRequire('curlrequest')




@parseWordAnalysisJUMAN = (rawHTML) ->
  resultsSection = rawHTML.match(JUMAN_HTML_REGEX)[1]
  resultsSection = resultsSection.replace(JUMAN_EXTRA_MATCHES, '')
  console.log "Result: "
  console.log resultsSection
  wordArr = getWordArrayJUMAN(resultsSection)
  # console.log WordAnalysis.find().fetch()

getWordArrayJUMAN = (resultsSection) ->
  wordArr = []
  i = 0
  while match = JUMAN_MATCHES.exec resultsSection
    wordArr[i] =
      word: match[2]
      pronunciation: match[3]
      type: match[5]
      subType: match[7]
    i++
  wordArr