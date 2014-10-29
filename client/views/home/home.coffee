TAB_KEYCODE = 9
AUTOCOMPLETE_MIN_CHARS = 3
NON_SUGGESTED_EN_CHARS = new RegExp /[^a-zA-Z0-9\s'-]/g

@Translation = new Meteor.Collection(null)
Translation.insert({})




Template.home.rendered = ->

  setWindowResizeListener()

  machineTranslation = MACHINE_TRANSLATION_EN
  Translation.update({}, {$set: {machineTranslation}})




Template.home.events

  # Translate
  "click .translate-btn": (event, ui) ->
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
    if parsedWordAnalysisJUMAN = WordAnalysis.findOne().parsedWordAnalysisJUMAN
      console.log "parsedWordAnalysisJUMAN: ", parsedWordAnalysisJUMAN


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