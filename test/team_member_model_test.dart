import 'package:flutter_test/flutter_test.dart';
import 'package:barber_pro_multi_barber/models/team_member.dart';

void main() {
  test('TeamMember JSON roundtrip', () {
    final member = TeamMember(id: 'tm-123', name: 'Hari', phone: '9999999999', specialization: 'Haircut', isActive: true);
    final json = member.toJson();
    final restored = TeamMember.fromJson(json);

    expect(restored.id, equals(member.id));
    expect(restored.name, equals(member.name));
    expect(restored.phone, equals(member.phone));
    expect(restored.specialization, equals(member.specialization));
    expect(restored.isActive, equals(member.isActive));
  });
}
