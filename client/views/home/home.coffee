TAB_KEYCODE = 9
AUTOCOMPLETE_MIN_CHARS = 3
NON_AUTOCOMPLETED_CHARS_EN = new RegExp /[^a-zA-Z0-9\s'-]/g

REQUEST_SPLITTER_GT_JA = /[^]{1,250}[$\n。？！?!、,　\s]/g # Greedy up to 250 chars with clean break

SENTENCE_ENDINGS_REGEX_JA = /(.+?([。！？]|･･･|$)(?![。！？]|･･･))/g # Sentence up until end of sentence ending(s)
PRIMARY_WORD_TYPES_JUMAN = ['名詞', '動詞', '形容詞']
DEFINED_WORD_TYPES_JUMAN = ['名詞', '動詞', '形容詞', '副詞', '複合名詞', '複合動詞']

@Translations = new Meteor.Collection(null)
Translations.insert({})









Template.home.rendered = ->

  setWindowResizeListener()

  Translations.remove({})
  Translations.insert({})
  translationArrGT = []
  Translations.update({}, {$set: {translationArrGT}})









Template.home.events

  # Translate
  "click .translate-btn": (event, ui) -> # TODO: Define upper limit for GT requests
    text = $('.original-content').text() # TODO: Slice up request like for JUMAN analysis
    text = text.match(REQUEST_SPLITTER_GT_JA)
    Translations.update({}, {$set: {queryNum: text.length}})

    for textBlock, index in text
      queryNum = Array(index + 1).join '*'
      $.get 'https://www.googleapis.com/language/translate/v2?key=AIzaSyBwSIYMthHNo71Y0XIdAjTns3nOm2OYQDs&source=ja&target=en&format=text&q=' + textBlock + '&q=' + queryNum, (data) ->
        # console.log "Data: ", data
        translation = data.data.translations[0].translatedText
        queryNum = data.data.translations[1].translatedText.length
        console.log "Translations: ", translation
        console.log "Index: ", queryNum
        translationArrGT = Translations.findOne().translationArrGT
        translationArrGT[queryNum] = translation
        Translations.update({}, {$set: {translationArrGT}})

  # JUMAN Analysis
  "click .juman-btn": (event, ui) ->
    text = $('.original-content').text()
    splitText = splitTextJA(text)
    Meteor.call 'getWordAnalysisJUMAN', splitText

  # Tab to accept autocompletion
  "keydown .translation-content": (event, ui) ->
    if event.keyCode is TAB_KEYCODE and window.getSelection().isCollapsed is false
      event.preventDefault()
      event.stopPropagation()
      window.getSelection().collapseToEnd()

  # Autocompletion on keyup
  "keypress .translation-content": (event, ui) -> # TODO: Need to allow mid-content editing, disable if cursor is in word
    input = String.fromCharCode(event.keyCode)
    unless !input or NON_AUTOCOMPLETED_CHARS_EN.test input # TODO: Might not work for all browsers because of special keycodes
      if Translations.findOne().translationWordsGT
        $('.translation-content').on 'keyup', (event) ->
          $('.translation-content').off('keyup')

          target = event.target
          targetText = target.innerText

          humanWords = targetText.split ' '
          lastWord = _.last humanWords

          if lastWord and lastWord.length >= AUTOCOMPLETE_MIN_CHARS
            translationWordsGT = Translations.findOne().translationWordsGT
            unusedWords = _.difference translationWordsGT, humanWords # Case sensitive
            unusedWords = _.uniq unusedWords
            lastWordMatches = unusedWords.filter (word) -> word[0..(lastWord.length - 1)] is lastWord

            if lastWordMatches.length > 0
              addedText = lastWordMatches[0][lastWord.length..-1]
              $(target).text(targetText + addedText)
              selectNewText(target, addedText)









Tracker.autorun ->

  # Generates list of words from machine translated text
  translationArrGT = Translations.findOne().translationArrGT
  if translationArrGT and translationArrGT.length is Translations.findOne().queryNum
    translationGT = translationArrGT.join ''
    translationGT = translationGT.replace(NON_AUTOCOMPLETED_CHARS_EN, '')
    translationWordsGT = translationGT.split ' '
    translationWordsGT = translationWordsGT.filter (word) -> word isnt ''
    Translations.update({}, {$set: {translationWordsGT}})
    console.log "translationWordsGT", translationWordsGT


Tracker.autorun ->

  # Displays current parsed JA word array
  if WordAnalysis.findOne()
    if wordAnalysisJUMAN = WordAnalysis.findOne().wordAnalysisJUMAN
      wordAnalysisJUMAN = processOriginalTextJUMAN(wordAnalysisJUMAN)

      for word, index in wordAnalysisJUMAN
        wordAnalysisJUMAN[index]['id'] = index
        $('.original-content').append('<span id="' + index + '" class="word" data-word-type-ja="' + word.type + '">' + word.word + '</span>')

      console.log wordAnalysisJUMAN
      queryList = (word.word for word in wordAnalysisJUMAN)

      translateListGT queryList









# Methods

@setWindowResizeListener = -> # TODO: Needs a better value than 48
  $('#main').css(height: '100%')
  $('#main').css(height: $('body').height() - $('.navbar-default').height() - parseInt($('.navbar-default').css('margin-bottom')) - 48)
  $( window ).resize ->
    $('#main').css(height: '100%')
    $('#main').css(height: $('body').height() - $('.navbar-default').height() - parseInt($('.navbar-default').css('margin-bottom')) - 48)




@selectNewText = (target, addedText) -> # TODO: Needs testing on Internet Explorer
  doc = document
  firstChild = target.childNodes[0]
  if doc.body.createTextRange
    range = document.body.createTextRange()
    range.moveToElementText target
    range.setStart(firstChild, firstChild.length - addedText.length)
    range.select()
  else if window.getSelection
    selection = window.getSelection()
    range = document.createRange()
    range.selectNodeContents target
    selection.removeAllRanges()
    range.setStart(firstChild, firstChild.length - addedText.length)
    selection.addRange range




@splitTextJA = (text) ->
  splitText = text.split SENTENCE_ENDINGS_REGEX_JA
  splitText = splitText.filter (element) -> SENTENCE_ENDINGS_REGEX_JA.test element # Weeds out extra non-sentence matches




@processOriginalTextJUMAN = (wordAnalysisJUMAN) ->
  $('.original-content').empty()
  for word, index in wordAnalysisJUMAN
    nextType = wordAnalysisJUMAN[index + 1]['type'] if wordAnalysisJUMAN[index + 1]
    if wordConcatenatableJUMAN(word, nextType)
      wordAnalysisJUMAN[index + 1]['type'] = replaceSuffixTypeJUMAN(word, nextType) if replaceSuffixTypeJUMAN(word, nextType)
      wordAnalysisJUMAN[index + 1]['word'] = word.word + wordAnalysisJUMAN[index + 1]['word']
      wordAnalysisJUMAN[index + 1] = _.omit(wordAnalysisJUMAN[index + 1], ['subType', 'pronunciation'])
      wordAnalysisJUMAN[index] = ''

  wordAnalysisJUMAN = wordAnalysisJUMAN.filter Boolean

wordConcatenatableJUMAN = (word, nextType) ->
  (word.type is '名詞' and nextType is '名詞') \
  or (word.type is '接頭辞' and $.inArray(nextType, PRIMARY_WORD_TYPES_JUMAN) isnt -1) \
  or ($.inArray(word.type, PRIMARY_WORD_TYPES_JUMAN) isnt -1 and nextType is '接尾辞') \
  or ($.inArray(word.type, PRIMARY_WORD_TYPES_JUMAN) isnt -1 and nextType is '助動詞')

replaceSuffixTypeJUMAN = (word, nextType) ->
  if word.type is '名詞' and nextType is '接尾辞'
    '複合名詞'
  else if word.type is '動詞' and nextType is '接尾辞' or nextType is '助動詞'
    '複合動詞'




@translateListGT = (list, parseCount, definitionsList) -> # TODO: Split queries, send all at once, reorder all results
  parseCount ||= 0 # TODO: Filter querylist before GT request and match words up afterwards
  definitionsList ||= []

  [queryString, parseCount] = generateQueryGT(list, parseCount)

  $.get 'https://www.googleapis.com/language/translate/v2?key=AIzaSyBwSIYMthHNo71Y0XIdAjTns3nOm2OYQDs&source=ja&target=en&format=text' + queryString
  , (data) ->
    definitionsList = definitionsList.concat(translation.translatedText for translation in data.data.translations) # +GT results
    if parseCount isnt list.length # Recursive if list isn't fully parsed
      translateListGT(list, parseCount, definitionsList)
    else
      unless $('.word').attr('data-define') # Add definition tooltips only if they're not there already (no data-define attr)
        addDefinitions definitionsList

generateQueryGT = (list, parseCount) ->
  if list.length - parseCount > 100
    queryString = ('&q=' + query for query in list[parseCount..(parseCount + 99)]).join ''
    parseCount += 100
  else
    queryString = ('&q=' + query for query in list[parseCount..-1]).join ''
    parseCount = list.length
  [queryString, parseCount]

addDefinitions = (definitionsList) ->
  if definitionsList.length is $('.word').length
    addDefinitionAttributes definitionsList
  else
    throw 'definition list length mismatch!!!'

  setTooltipDefinition()
  setTooltipTextHighlight()

addDefinitionAttributes = (definitionsList) ->
  for definition, index in definitionsList
    $('#' + index).attr("data-definition", definition)
    $('#' + index).attr("data-title", definition)
    $('#' + index).attr('data-define': 'false')

setDefinedWords = ->
  $('.word').filter -> # TODO: Bad tooltip positioning on wrapped words
    wordType = @.getAttribute('data-word-type-ja')
    $.inArray(wordType, DEFINED_WORD_TYPES_JUMAN) isnt -1

setTooltipDefinition = ->
  definedWordElements = setDefinedWords()
  definedWordElements.attr('data-define': 'true')
  definedWordElements.tooltip()

setTooltipTextHighlight = ->
  $(".word").on "show.bs.tooltip", ->
    $(this).animate(backgroundColor: 'lightblue', 400)
  $(".word").on "hide.bs.tooltip", ->
    $(this).animate(backgroundColor: 'white', 100)
