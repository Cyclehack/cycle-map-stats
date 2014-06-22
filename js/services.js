angular.module('myApp.services', ['ngResource'])
  .factory('AngularIssues', function($resource){
    return $resource(':5000/api/politician/', {})
  })
  .value('version', '0.1');
