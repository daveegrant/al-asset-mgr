/* global MLSearchController */
(function () {
  'use strict';

  angular.module('app.search')
    .controller('SearchCtrl', SearchCtrl);

  SearchCtrl.$inject = ['$scope', '$location', 'userService', 'MLSearchFactory'];

  // inherit from MLSearchController
  var superCtrl = MLSearchController.prototype;
  SearchCtrl.prototype = Object.create(superCtrl);

  function SearchCtrl($scope, $location, userService, searchFactory) {
    var ctrl = this;

    superCtrl.constructor.call(ctrl, $scope, $location, searchFactory.newContext());

    ctrl.init();

    ctrl.updateSearchResults = function (data) {
      superCtrl.updateSearchResults.apply(ctrl, arguments);

      var x2js = new X2JS();
      for (var i=0; i < data.results.length; i++) {
        data.results[i].extractedJson = x2js.xml_str2json(data.results[i].extracted.content[0]);

        if (data.results[i].extractedJson) {
          if (data.results[i].extractedJson.envelope.source.element && data.results[i].extractedJson.envelope.source.element.Image_Name_calc_long) {
            data.results[i].localLabel = data.results[i].extractedJson.envelope.source.element.Image_Name_calc_long;
          } else if (data.results[i].extractedJson.envelope.source.product && data.results[i].extractedJson.envelope.source.product.Product_ID) {
            data.results[i].localLabel = data.results[i].extractedJson.envelope.source.product.Product_ID;

            if (data.results[i].extractedJson.envelope.source.product.Title_big_calc) {
              data.results[i].localLabel = data.results[i].localLabel +
                ' - ' +
                data.results[i].extractedJson.envelope.source.product.Title_big_calc;
            }
          }
        }
      }
    };

    ctrl.setSnippet = function(type) {
      ctrl.mlSearch.setSnippet(type);
      ctrl.search();
    };

    $scope.$watch(userService.currentUser, function(newValue) {
      ctrl.currentUser = newValue;
    });
  }
}());
