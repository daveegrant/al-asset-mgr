(function () {

  'use strict';

  angular.module('app.elementTable')
    .directive('mlElementTable', mlElementTable);

  mlElementTable.$inject = ['MLRest'];

  function mlElementTable(mlRest) {
    return {
      restrict: 'E',
      templateUrl: 'app/detail/element-table-directive.html',
      scope: {
        uri: '=',
        data: '='
      }
    };
  }

}());
