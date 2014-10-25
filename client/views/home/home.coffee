NON_SUGGESTED_EN_CHARS = new RegExp(/[^a-zA-Z0-9\s'-]/g)

@Translation = new Meteor.Collection(null)
Translation.insert({})




Template.home.rendered = ->

  setWindowResizeListener()

  # Meteor.call 'test',
  #   (error, result) ->
  #     if !error
  #       console.log result
  #       result
  #     else
  #       console.log error
  #       error




Template.home.events

  "click .translate-btn": (event, ui) ->
    text = $('.original-content').text()
    $.get 'https://www.googleapis.com/language/translate/v2?key=AIzaSyBwSIYMthHNo71Y0XIdAjTns3nOm2OYQDs&source=ja&target=en&format=text&q=' + text, (data) ->
      console.log "Data: ", data
      translatedText = data.data.translations[0].translatedText
      # $('.translation-content').text(translatedText).focus()
      Translation.update({}, {$set: {translatedText}})
      console.log translatedText

  "keyup .translation-content": (event, ui) ->
    target = event.target
    targetText = target.innerText
    addedText = 'extra'
    $(target).text(targetText + addedText)
    selectNewText(target, addedText)




Tracker.autorun ->

  # Generates list of words from translated text
  if translatedText = Translation.findOne().translatedText
    translatedText = translatedText.replace(NON_SUGGESTED_EN_CHARS, '')
    choppedTextWords = translatedText.split " "
    choppedTextWords = choppedTextWords.filter (word) -> word isnt ''
    Translation.update({}, {$set: {choppedTextWords}})
    console.log choppedTextWords




# Methods

@setWindowResizeListener = ->
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