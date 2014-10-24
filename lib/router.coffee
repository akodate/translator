Router.configure

  layoutTemplate: 'layout',
  loadingTemplate: 'loading'



Router.map ->

  @route 'home',
    path: '/',
    onAfterAction: ->
      GAnalytics.pageview()

  @route 'about',
    path: '/about',
    onAfterAction: ->
      GAnalytics.pageview()