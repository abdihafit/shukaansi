import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/screens/profile_labels.dart';

void main() {
  test('names are shown in Title Case without changing what is stored', () {
    expect(displayName('abdihafit ismail'), 'Abdihafit Ismail');
    expect(displayName('AMINA  hassan '), 'Amina Hassan');
    expect(displayName("mary-jane o'neil"), "Mary-Jane O'Neil");
    expect(displayName('Hodan'), 'Hodan');
    expect(displayName(''), '');
  });
}
