(function () {
  'use strict';

  angular.module('app')
    .run(['loginService', function(loginService) {
      loginService.protectedRoutes(['root.search', 'root.create', 'root.profile']);
    }])
    .config(Config);

  Config.$inject = ['$stateProvider', '$urlMatcherFactoryProvider',
    '$urlRouterProvider', '$locationProvider'
  ];

  function Config(
    $stateProvider,
    $urlMatcherFactoryProvider,
    $urlRouterProvider,
    $locationProvider) {

    $urlRouterProvider.otherwise('/');
    $locationProvider.html5Mode(true);

    function valToFromString(val) {
      return val !== null ? val.toString() : val;
    }

    function regexpMatches(val) { // jshint validthis:true
      return this.pattern.test(val);
    }

    $urlMatcherFactoryProvider.type('path', {
      encode: valToFromString,
      decode: valToFromString,
      is: regexpMatches,
      pattern: /.+/
    });

    $stateProvider
      .state('root', {
        url: '',
        // abstract: true,
        templateUrl: 'app/root/root.html',
        controller: 'RootCtrl',
        controllerAs: 'ctrl',
        resolve: {
          user: function(userService) {
            return userService.getUser();
          }
        }
      })
      .state('root.landing', {
        url: '/',
        templateUrl: 'app/landing/landing.html',
        navLabel: {
          text: 'Home',
          area: 'dashboard',
          navClass: 'fa-home'
        }
      })
      .state('root.search', {
        url: '/search',
        templateUrl: 'app/search/search.html',
        controller: 'SearchCtrl',
        controllerAs: 'ctrl',
        navLabel: {
          text: 'Search',
          area: 'dashboard',
          navClass: 'fa-search'
        }
      })
      .state('root.create', {
        url: '/create',
        templateUrl: 'app/create/create.html',
        controller: 'CreateCtrl',
        controllerAs: 'ctrl',
        navLabel: {
          text: 'Create',
          area: 'dashboard',
          navClass: 'fa-wpforms'
        },
        resolve: {
          stuff: function() {
            return null;
          }
        }
      })
      .state('root.view', {
        url: '/detail{uri:path}?costType',
        params: {
          uri: {
            value: null
          }
        },
        templateUrl: 'app/detail/detail.html',
        controller: 'DetailCtrl',
        controllerAs: 'ctrl',
        resolve: {
          doc: function(MLRest, $stateParams) {
            var uri = $stateParams.uri;
            return MLRest.getDocument(uri, { format: 'json' }).then(function(response) {
              return response;
            });
          }
        }
      })
      .state('root.asset', {
        url: '/asset?source&id&bookCode&costType',
        templateUrl: 'app/asset/asset.html',
        controller: 'AssetCtrl',
        controllerAs: 'ctrl',
        resolve: {
          doc: function(MLRest, $stateParams) {
            var source = $stateParams.source;
            var id = $stateParams.id;
            var bookCode = $stateParams.bookCode;
            var costType = $stateParams.costType;
            var params = {
              'rs:source': source,
              'rs:sourceTrackingNumber': id
            };

            if (bookCode) {
              params['rs:bookCode'] = bookCode;
            }

            if (costType) {
              params['rs:costType'] = costType;
            }

            return MLRest.extension('products-using-element',
              {
                method: 'GET',
                params: params

              })
              .then(function(res) {
                return res;
              }
            );
          }
        }
      })
      .state('root.source', {
        url: '/source?id&bookCode&costType',
        templateUrl: 'app/source/source.html',
        controller: 'SourceCtrl',
        controllerAs: 'ctrl',
        resolve: {
          doc: function(MLRest, $stateParams) {
            var id = $stateParams.id;
            var bookCode = $stateParams.bookCode;
            var costType = $stateParams.costType;
            var params = {
              'rs:source': id
            };

            if (bookCode) {
              params['rs:bookCode'] = bookCode;
            }

            if (costType) {
              params['rs:costType'] = costType;
            }

            return MLRest.extension('elements-using-source',
              {
                method: 'GET',
                params: params
              })
              .then(function(res) {
                return res;
              }
            );
          }
        }
      })
      .state('root.profile', {
        url: '/profile',
        templateUrl: 'app/user/profile.html',
        controller: 'ProfileCtrl',
        controllerAs: 'ctrl'
      })
      .state('root.login', {
        url: '/login?state&params',
        templateUrl: 'app/login/login-full.html',
        controller: 'LoginFullCtrl',
        controllerAs: 'ctrl'
      });
  }
}());
