import 'package:flutter_test/flutter_test.dart';

import 'package:campusconnect/core/constants/app_constants.dart';
import 'package:campusconnect/core/utils/validators.dart';

void main() {
  group('College email validation', () {
    test('accepts allowed domains', () {
      expect(
        Validators.isCollegeEmailInDomains(
          '23csu211@ncuindia.edu',
          AppConstants.allowedCollegeEmailDomains,
        ),
        isTrue,
      );

      expect(
        Validators.isCollegeEmailInDomains(
          'abc123@college.edu',
          AppConstants.allowedCollegeEmailDomains,
        ),
        isTrue,
      );
    });

    test('rejects non-college domains', () {
      expect(
        Validators.isCollegeEmailInDomains(
          'user@gmail.com',
          AppConstants.allowedCollegeEmailDomains,
        ),
        isFalse,
      );
    });
  });
}
