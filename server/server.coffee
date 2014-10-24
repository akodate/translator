console.log process.env

console.log '*****************************************************************************************'

text = encodeURIComponent '装填完了'

Meteor.http.get 'https://www.googleapis.com/language/translate/v2?key=AIzaSyCiYb-vRVwNB1YkjLU6grB83aGTP42Qya0&source=ja&target=en&q=' + text,
  (error, result) ->
    if !error
      console.log result
    else
      console.log error