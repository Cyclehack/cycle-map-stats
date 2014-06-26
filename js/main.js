
var app = angular.module('myApp', ['ngResource']);


function searchCtrl($scope, $resource) {
 	

 $scope.VeloAPI = $resource("http://localhost:5000/api/politician/:q",
    {q:'g4+9ss'},
    { get: { method: "JSONP", isArray: true
    }});
 $scope.area = []
  
  $scope.search = function() {
    $scope.area = $scope.VeloAPI.get({ q: $scope.postcode}).sucess(function () {
    	console.log($scope.area);
    	    }) 

  };
}
