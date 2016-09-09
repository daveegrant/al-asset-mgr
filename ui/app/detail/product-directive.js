(function () {

  'use strict';

  angular.module('app.product')
    .directive('mlProduct', mlProduct);

  mlProduct.$inject = ['MLRest'];

  function mlProduct(mlRest) {
    return {
      restrict: 'E',
      templateUrl: 'app/detail/product-directive.html',
      scope: {
        uri: '@',
        data: '='
      }
    };
  }

}());
