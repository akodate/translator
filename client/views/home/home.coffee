TAB_KEYCODE = 9
AUTOCOMPLETE_MIN_CHARS = 3
NON_AUTOCOMPLETED_CHARS_EN = /[^a-zA-Z0-9\s'-]/g
LAST_WORD_REGEX_EN = /\w+$/

REQUEST_SPLITTER_GT_JA = /[^]{1,250}[$\n。？！?!、,　\s]/g # Greedy up to 250 chars with clean break

SENTENCE_ENDINGS_REGEX_JA = /(.+?([。！？]|･･･|$)(?![。！？]|･･･))/g # Sentence up until end of sentence ending(s)
PRIMARY_WORD_TYPES_JUMAN = ['名詞', '動詞', '形容詞', '複合名詞', '複合動詞', '複合形容詞']
DEFINED_WORD_TYPES_JUMAN = ['名詞', '動詞', '形容詞', '副詞', '複合名詞', '複合動詞', '複合形容詞']
EXTRA_INFO_TYPES_JUMAN = ['名詞', '動詞', '形容詞', '副詞']

@Translations = new Meteor.Collection(null)
Translations.insert({})









Template.home.rendered = ->

  Session.set 'keydownNum', 0
  translationArrGT = []
  definitionArrGT = []
  Translations.remove({})
  Translations.insert({translationArrGT, definitionArrGT})
  id = WordAnalysis.findOne()._id if WordAnalysis.findOne()
  WordAnalysis.remove(_id: id) if id

  setWindowResizeListener()









Template.home.events

  # Google translate original
  "click .translate-btn": (event, ui) -> # TODO: Define upper limit for GT requests
    fieldName = 'translationArrGT'
    text = $('.original-content')[0].innerText
    text = text.match(REQUEST_SPLITTER_GT_JA)
    Translations.update({}, {$set: {translationArrNumGT: text.length, translationArrGT: []}})

    for textBlock, index in text
      queryNum = Array(index + 1).join '*'
      $.get 'https://www.googleapis.com/language/translate/v2?key=AIzaSyBwSIYMthHNo71Y0XIdAjTns3nOm2OYQDs&source=ja&target=en&format=text&q=' + queryNum + '&q=' + textBlock, (data) ->

        translation = data.data.translations[1].translatedText
        updateGT fieldName, translation, data

  # JUMAN Analysis
  "click .juman-btn": (event, ui) ->
    text = $('.original-content')[0].innerText
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
        keydownNum = keydownTracker 1
        $('.translation-content').on 'keyup', (event) ->
          $('.translation-content').off('keyup')
          keydownNum = keydownTracker -1

          if keydownNum is 0
            target = event.target
            targetText = target.innerText
            lastWord = targetText.match(LAST_WORD_REGEX_EN)[0] if targetText.match(LAST_WORD_REGEX_EN)

            if lastWord and lastWord.length >= AUTOCOMPLETE_MIN_CHARS
              translationWordsGT = Translations.findOne().translationWordsGT
              # unusedWords = _.difference translationWordsGT, humanWords # Case sensitive
              # unusedWords = _.uniq unusedWords
              lastWordMatches = translationWordsGT.filter (word) -> word[0..(lastWord.length - 1)] is lastWord

              if lastWordMatches.length > 0 # TODO: Keep newlines from being crushed
                addedText = lastWordMatches[0][lastWord.length..-1]
                $(target).text(targetText + addedText)
                selectNewText(target, addedText)









Tracker.autorun ->

  # Generates list of words from machine translated text
  translationArrGT = Translations.findOne().translationArrGT
  if translationArrGT and (translationArrGT.length is Translations.findOne().translationArrNumGT) and (translationArrGT.every (set) -> set isnt undefined)

    translationGT = translationArrGT.join ''

    if ($('.translation-content')[0].innerText.indexOf translationGT) is -1
      addedText = translationGT
      $('.translation-content').text($('.translation-content')[0].innerText + addedText)
      selectNewText($('.translation-content')[0], addedText)

    translationGT = translationGT.replace(NON_AUTOCOMPLETED_CHARS_EN, '')
    translationWordsGT = translationGT.split ' '
    translationWordsGT = translationWordsGT.filter (word) -> word isnt ''
    Translations.update({}, {$set: {translationWordsGT}})
    console.log "translationWordsGT: " + translationWordsGT


Tracker.autorun ->

  # Activates tooltips
  definitionArrGT = Translations.findOne().definitionArrGT
  definitionArrNumGT = Translations.findOne().definitionArrNumGT
  if definitionArrGT and (definitionArrGT.length is definitionArrNumGT) and (definitionArrGT.every (set) -> set isnt undefined)
    if definitionArrGT.length > 1
      # definitionWordsGT = (definitionArrGT[0].concat(definitionSet)) for definitionSet in definitionArrGT[1..-1]
      definitionWordsGT = []
      for definitionSet in definitionArrGT[0..-1]
        definitionWordsGT = definitionWordsGT.concat definitionSet
    else
      definitionWordsGT = definitionArrGT[0]
    Translations.update({}, {$set: {definitionWordsGT}})
    console.log "definitionWordsGT", definitionWordsGT
    unless $('.word').attr('data-define') # Add definition tooltips only if they're not there already (no data-define attr)
      addDefinitions definitionWordsGT


Tracker.autorun ->

  # Displays current parsed JA word array
  if WordAnalysis.findOne()
    if wordAnalysisJUMAN = WordAnalysis.findOne().wordAnalysisJUMAN
      wordAnalysisJUMAN = processOriginalTextJUMAN(wordAnalysisJUMAN)

      for word, index in wordAnalysisJUMAN
        wordAnalysisJUMAN[index]['id'] = index
        $('.original-content').append('<span id="' + index + '" class="word" data-word-type-ja="' + word.type + '">' + word.word + '</span>')
        if word.type in EXTRA_INFO_TYPES_JUMAN
          $($('.original-content')[0].lastChild).attr('data-pronunciation', word.pronunciation)

      console.log 'wordAnalysisJUMAN: ', wordAnalysisJUMAN
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
  else if word.type is '形容詞' and nextType is '接尾辞'
    '複合形容詞'
  else if word.type in ['複合名詞', '複合動詞', '複合形容詞']
    word.type



@updateGT = (fieldName, result, data) ->
  queryNum = data.data.translations[0].translatedText.length # Number of query result that needs to be recombined
  arr = Translations.findOne()[fieldName] # Retrieves array for recombining query results
  arr[queryNum] = result # Puts the query result in the properly numbered element of the array
  (obj = {})[fieldName] = arr # Creates an object with the needed dynamic key a.k.a. array name
  Translations.update({}, {$set: obj})

@translateListGT = (list) ->
  fieldName = 'definitionArrGT'

  queryStringArr = generateQueryGT(list)
  for queryString in queryStringArr
    $.get 'https://www.googleapis.com/language/translate/v2?key=AIzaSyBwSIYMthHNo71Y0XIdAjTns3nOm2OYQDs&source=ja&target=en&format=text' + queryString
    , (data) ->

      definitions = []
      definitions.push(definition.translatedText) for definition in data.data.translations[1..-1]
      updateGT fieldName, definitions, data

generateQueryGT = (list, parseCount) ->
  queryStringArr = []
  definitionArrNumGT = Math.floor(list.length / 100) + 1
  Translations.update({}, {$set: {definitionArrNumGT, definitionArrGT: []}})
  for index in [0..(definitionArrNumGT - 1)]
    queryNum = Array(index + 1).join '*'
    if index < definitionArrNumGT
      queryString = '&q=' + queryNum + (('&q=' + query for query in list[(index * 100)..((index * 100) + 99)]).join '')
    else
      queryString = '&q=' + queryNum + (('&q=' + query for query in list[(index * 100)..-1]).join '')
    queryStringArr.push queryString
  queryStringArr

addDefinitions = (definitionsList) ->
  if definitionsList.length is $('.word').length
    addDefinitionAttributes definitionsList
  else
    throw 'definition list length mismatch!!!'

  setTooltipDefinition()
  setTooltipTextHighlight()

addDefinitionAttributes = (definitionsList) ->
  for definition, index in definitionsList
    pronunciation = $('#' + index).attr('data-pronunciation')
    definition = definition + ' (' + pronunciation + ')' if pronunciation
    $('#' + index).attr('data-definition', definition)
    $('#' + index).attr('data-title', definition)
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




@keydownTracker = (increment) ->
  keydownNum = Session.get('keydownNum') + increment
  Session.set 'keydownNum', keydownNum
  keydownNum