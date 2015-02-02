window.getStackTrace = ->
    trace = printStackTrace()
    for value, index in trace
       if value.indexOf("getStackTrace@") >= 0
           trace.splice(0, index) if index >= 0
           break
    trace.join("\n ○ ")

window.open_external_url = (url) ->
    if magic_unicorn?
        magic_unicorn.open_in_external_browser(url)
    else
        window.open(url)

app = angular.module("app",
    ["ngResource", "ui.router", 'ngIdle', "app.services", "app.directives", "ui.bootstrap",
     "ui.validate", "xeditable", "pascalprecht.translate", "pageslide-directive", "ui.grid", "utils.autofocus"])

app.run ($rootScope, $location, $idle, $state, $interval, $window, $templateCache, $translate, editableOptions, editableThemes) ->
    $templateCache.put 'ui-grid/uiGridViewport',
        '''<div class="ui-grid-viewport">
             <div class="ui-grid-canvas">
               <div ng-repeat="(rowRenderIndex, row) in rowContainer.renderedRows track by row.uid" class="ui-grid-row" ng-class="row.entity.type" ng-style="containerCtrl.rowStyle(rowRenderIndex)">
                 <div ui-grid-row="row" row-render-index="rowRenderIndex"></div>
               </div>
              </div>
           </div>'''

    $rootScope.context_help = {locale: "en", show: false, file: "", open: false}
    app_history = []

    $rootScope.magic_unicorn = if magic_unicorn? then magic_unicorn else false
    $rootScope.magic_unicorn.log_message(navigator.userAgent) if $rootScope.magic_unicorn

    window.navigate_to = (path) ->
        if path[0] == "/"
            window.location.href = "/#" + path
        else
            $state.go(path)

    editableOptions.theme = 'default'
    editableThemes['default'].submitTpl = '<button type="submit" class="btn btn-sm btn-primary"><i class="fa fa-check fa-lg"></i></button>'
    editableThemes['default'].cancelTpl = '<button type="button" ng-click="$form.$cancel()" class="btn btn-sm btn-warning"><i class="fa fa-times fa-lg"></i></button>'

    $rootScope.$on "$stateChangeSuccess", (event, toState, toParams, fromState, fromParams) ->
        app_history.push {state: fromState.name, params: fromParams} if fromState.name

    $rootScope.history_back = ->
        return false if app_history.length == 0
        loop
            prev_page = app_history.pop()
            break unless prev_page
            break unless prev_page.state == "createwallet" or prev_page.state == "unlockwallet"
        $state.go(prev_page.state, prev_page.params) if prev_page
        return !!prev_page

    $rootScope.history_forward = ->
        $window.history.forward()

    $rootScope.loading_indicator = {show: false,  progress: null}
    $rootScope.showLoadingIndicator = (promise, progress = null) ->
        li = $rootScope.loading_indicator
        li.show = true
        li.progress = if progress then progress.replace("{{value}}", '0') else ""
        promise.then ->
            li.show = false
        , ->
            li.show = false
        ,  (value) ->
            li.progress = progress.replace("{{value}}", value) if progress

    $rootScope.showContextHelp = (name) ->
        if name
            $rootScope.context_help.show = true
            $rootScope.context_help.file = "context_help/#{$translate.preferredLanguage()}/#{name}.html"
        else
            $rootScope.context_help.show = false
            $rootScope.context_help.file = ""

    $rootScope.current_account = null

    $idle.watch()

app.config ($idleProvider, $stateProvider, $urlRouterProvider, $translateProvider, $tooltipProvider, $compileProvider) ->

    $compileProvider.debugInfoEnabled(false);

    $tooltipProvider.options { appendToBody: true }

    $translateProvider.useStaticFilesLoader
        prefix: 'locale-',
        suffix: '.json'

    lang = switch(window.navigator.language)
      when "zh-CN" then "zh-CN"
      when "de", "de-DE", "de-de" then "de"
      when "ru", "ru-RU", "ru-ru" then "ru"
      when "it", "it-IT", "it-it" then "it"
      when "ko", "ko-KR", "ko-kr" then "ko"
      else "en"
    moment.locale(lang)

    $translateProvider.preferredLanguage(lang)

    $idleProvider.idleDuration(1776)
    $idleProvider.warningDuration(60)

    $urlRouterProvider.otherwise('/accounts')

    sp = $stateProvider


    sp.state "preferences",
        url: "/preferences"
        templateUrl: "preferences.html"
        controller: "PreferencesController"

    sp.state "console",
        url: "/console"
        templateUrl: "console.html"
        controller: "ConsoleController"

    sp.state "createaccount",
        url: "/create/account"
        templateUrl: "createaccount.html"
        controller: "CreateAccountController"

    sp.state "accounts",
        url: "/accounts"
        templateUrl: "accounts.html"
        controller: "AccountsController"

    sp.state "delegates",
        url: "/delegates"
        templateUrl: "delegates/delegates.html"
        controller: "DelegatesController"

    sp.state "account",
        url: "/accounts/:name"
        templateUrl: "account.html"
        controller: "AccountController"

    sp.state "account.transactions", { url: "/account_transactions?pending_only", views: { 'account-transactions': { templateUrl: 'account_transactions.html', controller: 'TransactionsController' } } }

    sp.state "account.delegate", { url: "/account_delegate", views: { 'account-delegate': { templateUrl: 'account_delegate.html', controller: 'AccountDelegate' } } }

    sp.state "account.transfer", { url: "/account_transfer?from&to&amount&memo&asset", views: { 'account-transfer': { templateUrl: 'transfer.html', controller: 'TransferController' } } }

    sp.state "account.manageAssets", { url: "/account_assets", views: { 'account-manage-assets': { templateUrl: 'manage_assets.html', controller: 'ManageAssetsController' } } }

    sp.state "account.keys", { url: "/account_keys", views: { 'account-keys': { templateUrl: 'account_keys.html' } } }

    sp.state "account.edit", { url: "/account_edit", views: { 'account-edit': { templateUrl: 'account_edit.html', controller: 'AccountEditController' } } }

    sp.state "account.vote", { url: "/account_vote", views: { 'account-vote': { templateUrl: 'account_vote.html', controller: 'AccountVoteController' } } }

    sp.state "account.wall", { url: "/account_wall", views: { 'account-wall': { templateUrl: 'account_wall.html', controller: 'AccountWallController' } } }

    sp.state "asset",
        url: "/assets/:ticker"
        templateUrl: "asset.html"
        controller: "AssetController"

    sp.state "createwallet",
        url: "/createwallet"
        templateUrl: "createwallet.html"
        controller: "CreateWalletController"

    sp.state "block",
        url: "/blocks/:number"
        templateUrl: "block.html"
        controller: "BlockController"

    sp.state "transaction",
        url: "/tx/:id"
        templateUrl: "transaction.html"
        controller: "TransactionController"

    sp.state "unlockwallet",
        url: "/unlockwallet"
        templateUrl: "unlockwallet.html"
        controller: "UnlockWalletController"

    sp.state "markets",
        url: "/markets"
        templateUrl: "market/markets.html"
        controller: "MarketsController"

    sp.state "market",
        abstract: true
        url: "/market/:name/:account"
        templateUrl: "market/market.html"
        controller: "MarketController"

    sp.state "market.buy", { url: "/buy", templateUrl: "market/buy.html" }
    sp.state "market.sell", { url: "/sell", templateUrl: "market/sell.html" }
    sp.state "market.short", { url: "/short", templateUrl: "market/short.html" }

    sp.state "transfer",
        url: "/transfer?from&to&amount&memo&asset"
        templateUrl: "transfer.html"
        controller: "TransferController"

    sp.state "newcontact",
        url: "/newcontact?name&key"
        templateUrl: "newcontact.html"
        controller: "NewContactController"

    sp.state "mail",
        url: "/mail/:box"
        templateUrl: "mail.html"
        controller: "MailController"
    
    sp.state "mail.compose",
        url: "/compose"
        onEnter: ($modal, $state) ->
            modal = $modal.open
                templateUrl: "dialog-mail-compose.html"
                controller: "ComposeMailController"
                
            modal.result.then(
                (result) ->
                    $state.go 'mail'
                () ->
                    $state.go 'mail'
            )
    
    sp.state "mail.show",
        url: "/show/:id"
        onEnter: ($modal, $state) ->
            modal = $modal.open
                templateUrl: "dialog-mail-show.html"
                controller: "ShowMailController"
                
            modal.result.then(
                (result) ->
                    $state.go 'mail'
                () ->
                    $state.go 'mail'
            )

    sp.state "referral_code",
        url: "/referral_code?faucet&code"
        templateUrl: "referral_code.html"
        controller: "ReferralCodeController"

    sp.state "advanced",
        url: "/advanced"
        templateUrl: "advanced/advanced.html"
        controller: "AdvancedController"

    sp.state "advanced.preferences", { url: "/preferences", views: { 'advanced-preferences': { templateUrl: 'advanced/preferences.html', controller: 'PreferencesController' } } }
    sp.state "advanced.console", { url: "/console", views: { 'advanced-console': { templateUrl: 'advanced/console.html', controller: 'ConsoleController' } } }
