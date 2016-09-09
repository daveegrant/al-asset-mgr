(function () {

  'use strict';

  angular.module('app.productTable')
    .directive('mlProductTable', mlProductTable);

  mlProductTable.$inject = ['MLRest'];

  function mlProductTable(mlRest) {
    return {
      restrict: 'E',
      templateUrl: 'app/detail/product-table-directive.html',
      scope: {
        data: '='
      }
    };
  }

}());
