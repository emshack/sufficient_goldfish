'use strict';

var globby = require('globby');
var path = require('path');
var protobuf = require('protobufjs');

var COMMON_PROTO_DIRS = [
  // This list of directories is defined here:
  // https://github.com/googleapis/googleapis/blob/master/gapic/packaging/common_protos.yaml
  'api',
  path.join('logging', 'type'),
  'longrunning',
  'protobuf', // This is an additional path that the common protos depend on.
  'rpc',
  'type',
];

var COMMON_PROTO_GLOB_PATTERNS = COMMON_PROTO_DIRS.map(function(dir) {
  return path.join('google', dir, '**', '*.proto');
});

var COMMON_PROTO_FILES = globby.sync(COMMON_PROTO_GLOB_PATTERNS);

class GoogleProtoFilesRoot extends protobuf.Root {
  constructor() {
    super([].slice.apply(arguments));
  }

  // Causes the loading of an included proto to check if it is a common
  // proto. If it is a common proto, use the google-proto-files proto.
  resolvePath(_, includePath) {
    // Fully qualified paths don't need to be resolved.
    if (includePath.startsWith('/')) {
      return includePath;
    }

    if (COMMON_PROTO_FILES.indexOf(includePath) > -1) {
      return path.join(__dirname, includePath);
    }
    return protobuf.util.path.resolve.apply(null, [].slice.call(arguments));
  }
}

module.exports.loadSync = function(filename) {
  return protobuf.loadSync(filename, new GoogleProtoFilesRoot());
};

module.exports.load = function(filename) {
  return protobuf.load(filename, new GoogleProtoFilesRoot());
};
