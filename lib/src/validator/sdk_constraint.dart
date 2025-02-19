// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:pub_semver/pub_semver.dart';

import '../sdk.dart';
import '../validator.dart';

/// A validator of the SDK constraint.
///
/// Validates that a package's SDK constraint:
/// * doesn't use the "^" syntax.
/// * has an upper bound.
/// * is not depending on a prerelease, unless the package itself is a
/// prerelease.
class SdkConstraintValidator extends Validator {
  /// Get SDK version constraint from `pubspec.yaml` without any defaults or
  /// overrides.
  VersionConstraint _sdkConstraintFromPubspecYaml() {
    final env = entrypoint.root.pubspec.fields['environment'];
    if (env is Map && env['sdk'] is String) {
      try {
        return VersionConstraint.parse(env['sdk']);
      } on FormatException {
        // ignore
      }
    }
    return VersionConstraint.any;
  }

  @override
  Future validate() async {
    final dartConstraint = _sdkConstraintFromPubspecYaml();
    if (dartConstraint is VersionRange) {
      if (dartConstraint.max == null) {
        errors.add(
            'Published packages should have an upper bound constraint on the '
            'Dart SDK (typically this should restrict to less than the next '
            'major version to guard against breaking changes).\n'
            'See https://dart.dev/tools/pub/pubspec#sdk-constraints for '
            'instructions on setting an sdk version constraint.');
      }

      final constraintMin = dartConstraint.min;
      final packageVersion = entrypoint.root.version;

      if (constraintMin != null &&
          constraintMin.isPreRelease &&
          !packageVersion.isPreRelease) {
        warnings.add(
            'Packages with an SDK constraint on a pre-release of the Dart SDK '
            'should themselves be published as a pre-release version. '
            'If this package needs Dart version $constraintMin, consider '
            'publishing the package as a pre-release instead.\n'
            'See https://dart.dev/tools/pub/publishing#publishing-prereleases '
            'For more information on pre-releases.');
      }
    }

    for (var sdk in sdks.values) {
      if (sdk.identifier == 'dart') continue;
      if (entrypoint.root.pubspec.sdkConstraints.containsKey(sdk.identifier)) {
        validateSdkConstraint(
          sdk.firstPubVersion,
          "Older versions of pub don't support ${sdk.name} SDK constraints.",
        );
      }
    }
  }
}
