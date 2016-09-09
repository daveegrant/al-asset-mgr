(function () {

  'use strict';

  angular.module('app.element')
    .directive('mlElement', mlElement);

  mlElement.$inject = ['MLRest'];

  function mlElement(mlRest) {
    return {
      restrict: 'E',
      templateUrl: 'app/detail/element-directive.html',
      scope: {
        uri: '@',
        data: '='
      }
    };
  }

}());
