(function () {
  'use strict';

  angular.module('app', [
    'ml.common',
    'ml.search',
    'ml.search.tpls',
    'ml.utils',
    'ngJsonExplorer',
    'app.asset',
    'app.create',
    'app.detail',
    'app.error',
    'app.login',
    'app.root',
    'app.search',
    'app.source',
    'app.user',
    'ui.bootstrap',
    'ui.router',
    'ui.tinymce',
    'ngToast'
  ]);

  angular.module('app.rt.encode', [])
    .filter('escape', function () {
      return window.encodeURIComponent;

      // return function(input) {
      //   var eValue = window.encodeURIComponent(input);
      //   console.log(eValue);
      //   return eValue;
      //   // return window.encodeURIComponent(input);
      // };
    });

}());
