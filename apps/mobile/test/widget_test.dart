import 'package:flutter_test/flutter_test.dart';
import 'package:creatorverse_mobile/main.dart';

void main() {
  group('parseSkillsInput', () {
    test('trims skills and ignores empty entries', () {
      expect(parseSkillsInput('  Video editing, AI tools ,, Writing  '),
          ['Video editing', 'AI tools', 'Writing']);
    });

    test('returns an empty list for blank input', () {
      expect(parseSkillsInput('   , , '), isEmpty);
    });

    test('keeps multi-word skill names intact', () {
      expect(parseSkillsInput('Prompt engineering, Social media management'),
          ['Prompt engineering', 'Social media management']);
    });
  });

  group('sanitizeSearchTerm', () {
    test('removes PostgREST filter syntax from search input', () {
      expect(sanitizeSearchTerm('Ada, (admin). %'), 'Ada admin');
    });

    test('keeps ordinary names and usernames searchable', () {
      expect(sanitizeSearchTerm('Cletus-Tech 2026'), 'Cletus-Tech 2026');
    });
  });
}
