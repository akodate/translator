TAB_KEYCODE = 9
AUTOCOMPLETE_MIN_CHARS = 3
NON_SUGGESTED_EN_CHARS = new RegExp /[^a-zA-Z0-9\s'-]/g

PRIMARY_WORD_TYPES_JUMAN = ['名詞', '動詞']
DEFINABLE_WORD_TYPES_JUMAN = ['名詞', '動詞', '形容詞', '副詞', '複合名詞', '複合動詞']

@Translation = new Meteor.Collection(null)
Translation.insert({})









Template.home.rendered = ->

  setWindowResizeListener()

  machineTranslation = MACHINE_TRANSLATION_EN
  Translation.update({}, {$set: {machineTranslation}})









Template.home.events

  # Translate
  "click .translate-btn": (event, ui) -> # Define upper limit for GT requests
    text = $('.original-content').text()
    $.get 'https://www.googleapis.com/language/translate/v2?key=AIzaSyBwSIYMthHNo71Y0XIdAjTns3nOm2OYQDs&source=ja&target=en&format=text&q=' + text, (data) ->
      console.log "Data: ", data
      machineTranslation = data.data.translations[0].translatedText
      # $('.translation-content').text(machineTranslation).focus()
      Translation.update({}, {$set: {machineTranslation}})
      console.log machineTranslation

  # JUMAN Analysis
  "click .juman-btn": (event, ui) ->
    text = $('.original-content').text()
    Meteor.call 'getWordAnalysisJUMAN', text

  # Tab to accept autocompletion
  "keydown .translation-content": (event, ui) ->
    if event.keyCode is TAB_KEYCODE and window.getSelection().isCollapsed is false
      event.preventDefault()
      event.stopPropagation()
      window.getSelection().collapseToEnd()

  # Autocompletion on keyup
  "keypress .translation-content": (event, ui) -> # Need to allow mid-content editing, disable if cursor is in word
    input = String.fromCharCode(event.keyCode)
    unless !input or NON_SUGGESTED_EN_CHARS.test input # Might not work for all browsers because of special keycodes
      if Translation.findOne().machineTranslationWords
        $('.translation-content').on 'keyup', (event) ->
          $('.translation-content').off('keyup')

          target = event.target
          targetText = target.innerText

          humanWords = targetText.split ' '
          lastWord = _.last humanWords

          if lastWord and lastWord.length >= AUTOCOMPLETE_MIN_CHARS
            machineTranslationWords = Translation.findOne().machineTranslationWords
            unusedWords = _.difference machineTranslationWords, humanWords # Case sensitive
            unusedWords = _.uniq unusedWords
            lastWordMatches = unusedWords.filter (word) -> word[0..(lastWord.length - 1)] is lastWord

            if lastWordMatches.length > 0
              addedText = lastWordMatches[0][lastWord.length..-1]
              $(target).text(targetText + addedText)
              selectNewText(target, addedText)









Tracker.autorun ->

  # Generates list of words from machine translated text
  if machineTranslation = Translation.findOne().machineTranslation
    machineTranslation = machineTranslation.replace(NON_SUGGESTED_EN_CHARS, '')
    machineTranslationWords = machineTranslation.split ' '
    machineTranslationWords = machineTranslationWords.filter (word) -> word isnt ''
    Translation.update({}, {$set: {machineTranslationWords}})
    console.log "machineTranslationWords", machineTranslationWords


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

@setWindowResizeListener = -> # Needs a better value than 48
  $('#main').css(height: '100%')
  $('#main').css(height: $('body').height() - $('.navbar-default').height() - parseInt($('.navbar-default').css('margin-bottom')) - 48)
  $( window ).resize ->
    $('#main').css(height: '100%')
    $('#main').css(height: $('body').height() - $('.navbar-default').height() - parseInt($('.navbar-default').css('margin-bottom')) - 48)

@selectNewText = (target, addedText) -> # Needs testing on Internet Explorer
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
  console.log "wordAnalysisJUMAN: ", wordAnalysisJUMAN
  wordAnalysisJUMAN

@wordConcatenatableJUMAN = (word, nextType) ->
  (word.type is '名詞' and nextType is '名詞') \
  or (word.type is '接頭辞' and $.inArray(nextType, PRIMARY_WORD_TYPES_JUMAN) isnt -1) \
  or ($.inArray(word.type, PRIMARY_WORD_TYPES_JUMAN) isnt -1 and nextType is '接尾辞') \
  or ($.inArray(word.type, PRIMARY_WORD_TYPES_JUMAN) isnt -1 and nextType is '助動詞')

@replaceSuffixTypeJUMAN = (word, nextType) ->
  if word.type is '名詞' and nextType is '接尾辞'
    '複合名詞'
  else if word.type is '動詞' and nextType is '接尾辞' or nextType is '助動詞'
    '複合動詞'

@translateListGT = (list, func) ->
  queryString = ('&q=' + query for query in list).join ''

  $.get 'https://www.googleapis.com/language/translate/v2?key=AIzaSyBwSIYMthHNo71Y0XIdAjTns3nOm2OYQDs&source=ja&target=en&format=text' + queryString
  , (data) ->
    console.log "Data: ", data
    translationsList = (translation.translatedText for translation in data.data.translations)
    console.log "Text: ", translationsList
    addDefinitions translationsList

@addDefinitions = (definitionsList) ->
  if definitionsList.length is $('.word').length
    for definition, index in definitionsList
      $('#' + index).attr("data-definition", definition)
      $('#' + index).attr("data-title", definition)
  else
    console.log 'Definition list length mismatch!!!'

  definableWordElements = $('.word').filter () ->
    wordType = @.getAttribute('data-word-type-ja')
    $.inArray(wordType, DEFINABLE_WORD_TYPES_JUMAN) isnt -1

  definableWordElements.tooltip()


