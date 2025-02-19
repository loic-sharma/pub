// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:pub/src/io.dart';
import 'package:pub/src/validator.dart';
import 'package:pub/src/validator/readme.dart';
import 'package:test/test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator readme() => ReadmeValidator();

void main() {
  group('should consider a package valid if it', () {
    test('looks normal', () async {
      await d.validPackage.create();
      await expectValidation(readme);
    });

    test('has a non-primary readme with invalid utf-8', () async {
      await d.validPackage.create();
      await d.dir(appPath, [
        d.file('README.x.y.z', [192])
      ]).create();
      await expectValidation(readme);
    });

    test('has a gitignored README with invalid utf-8', () async {
      await d.validPackage.create();
      var repo = d.git(appPath, [
        d.file('README', [192]),
        d.file('.gitignore', 'README')
      ]);
      await repo.create();
      await expectValidation(readme);
    });
  });

  group('should consider a package invalid if it', () {
    test('has no README', () async {
      await d.validPackage.create();

      deleteEntry(p.join(d.sandbox, 'myapp/README.md'));
      await expectValidation(readme, warnings: isNotEmpty);
    });

    test('has only a .gitignored README', () async {
      await d.validPackage.create();
      await d.git(appPath, [d.file('.gitignore', 'README.md')]).create();
      await expectValidation(readme, warnings: isNotEmpty);
    });

    test('has a primary README with invalid utf-8', () async {
      await d.validPackage.create();
      await d.dir(appPath, [
        d.file('README', [192])
      ]).create();
      await expectValidation(readme, warnings: isNotEmpty);
    });

    test('has only a non-primary readme', () async {
      await d.validPackage.create();
      deleteEntry(p.join(d.sandbox, 'myapp/README.md'));
      await d.dir(appPath, [d.file('README.whatever')]).create();
      await expectValidation(readme, warnings: isNotEmpty);
    });

    test('Uses only deprecated readme name .markdown', () async {
      await d.validPackage.create();
      deleteEntry(p.join(d.sandbox, 'myapp/README.md'));
      await d.dir(appPath, [d.file('README.markdown')]).create();
      await expectValidation(readme, warnings: isNotEmpty);
    });

    test('Uses only deprecated readme name .mdown', () async {
      await d.validPackage.create();
      deleteEntry(p.join(d.sandbox, 'myapp/README.md'));
      await d.dir(appPath, [d.file('README.mdown')]).create();
      await expectValidation(readme, warnings: isNotEmpty);
    });
  });
}
